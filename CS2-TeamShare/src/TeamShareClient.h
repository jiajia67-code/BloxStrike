// ============================================================================
// TeamShareClient.h — 隊友分享客戶端
// 連接 Named Pipe 伺服器，接收實體資料，寫入本地共享記憶體
// ============================================================================

#pragma once
#include <Windows.h>
#include <cstdint>
#include <cstring>
#include "../CS2-Offsets/TeamShare.h"

// ============================================================================
// 本地共享記憶體（讓 C# GUI 讀取接收到的資料）
// ============================================================================

static constexpr const char* TEAMSHARE_LOCAL_MAP = "Local\\CS2TeamShareClient";
static constexpr int TEAMSHARE_LOCAL_SIZE = sizeof(TeamShareFullUpdate);

// ============================================================================
// TeamShareClient 類別
// ============================================================================

class TeamShareClient
{
public:
    // 連接狀態
    enum class State : int {
        Disconnected = 0,
        Connecting   = 1,
        Connected    = 2,
        Error        = -1,
    };

    static State GetState() { return g_state; }
    static int GetPlayerCount() { return g_playerCount; }
    static uint32_t GetLastTick() { return g_lastTick; }

    // ========================================================================
    // 初始化：建立本地共享記憶體 + 連接 Pipe
    // ========================================================================
    static bool Initialize()
    {
        // Generate session key (matches server's key generation)
        g_sessionKey = GenerateKey(GetTickCount64());

        // 建立本地共享記憶體（讓 C# GUI 讀取）
        g_hLocalMap = CreateFileMappingA(
            INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
            0, TEAMSHARE_LOCAL_SIZE, TEAMSHARE_LOCAL_MAP);

        if (!g_hLocalMap) {
            g_state = State::Error;
            return false;
        }

        g_pLocalData = (TeamShareFullUpdate*)MapViewOfFile(
            g_hLocalMap, FILE_MAP_ALL_ACCESS, 0, 0, TEAMSHARE_LOCAL_SIZE);

        if (!g_pLocalData) {
            CloseHandle(g_hLocalMap);
            g_hLocalMap = NULL;
            g_state = State::Error;
            return false;
        }

        // 清空本地資料
        memset(g_pLocalData, 0, TEAMSHARE_LOCAL_SIZE);

        g_state = State::Disconnected;
        return true;
    }

    // ========================================================================
    // 連接 Named Pipe 伺服器
    // ========================================================================
    static bool Connect()
    {
        if (g_state == State::Connected && g_hPipe != INVALID_HANDLE_VALUE)
            return true;

        g_state = State::Connecting;

        // 嘗試連接 Named Pipe
        g_hPipe = CreateFileA(
            TEAMSHARE_PIPE_NAME,
            GENERIC_READ | GENERIC_WRITE,
            0,              // 不共享
            NULL,           // 預設安全性
            OPEN_EXISTING,  // 打開現有的
            0,              // 預設屬性
            NULL);          // 無範本

        if (g_hPipe == INVALID_HANDLE_VALUE) {
            g_state = State::Disconnected;
            return false;
        }

        // 設定為訊息模式
        DWORD mode = PIPE_READMODE_MESSAGE;
        SetNamedPipeHandleState(g_hPipe, &mode, NULL, NULL);

        // Authentication handshake
        DWORD bytesWritten = 0;
        DWORD bytesRead = 0;

        // Send challenge
        uint32_t challenge = TEAMSHARE_AUTH_CHALLENGE;
        if (!WriteFile(g_hPipe, &challenge, sizeof(uint32_t), &bytesWritten, NULL)) {
            Disconnect();
            return false;
        }

        // Read encrypted response
        uint32_t encResponse = 0;
        if (!ReadFile(g_hPipe, &encResponse, sizeof(uint32_t), &bytesRead, NULL)
            || bytesRead != sizeof(uint32_t)) {
            Disconnect();
            return false;
        }

        // Decrypt and verify
        uint32_t response = encResponse ^ g_sessionKey;
        if (response != TEAMSHARE_AUTH_RESPONSE) {
            Disconnect();
            return false;
        }

        // Send confirmation
        uint32_t confirm = TEAMSHARE_AUTH_OK ^ g_sessionKey;
        if (!WriteFile(g_hPipe, &confirm, sizeof(uint32_t), &bytesWritten, NULL)) {
            Disconnect();
            return false;
        }

        g_state = State::Connected;
        g_lastSequence = 0;
        g_reconnectTimer = 0;

        return true;
    }

    // ========================================================================
    // 斷開連接
    // ========================================================================
    static void Disconnect()
    {
        if (g_hPipe != INVALID_HANDLE_VALUE) {
            CloseHandle(g_hPipe);
            g_hPipe = INVALID_HANDLE_VALUE;
        }
        g_state = State::Disconnected;
        g_playerCount = 0;
    }

    // ========================================================================
    // 讀取一筆資料（非阻塞）
    // ========================================================================
    static bool ReadUpdate()
    {
        if (g_state != State::Connected || g_hPipe == INVALID_HANDLE_VALUE)
            return false;

        // 使用 PeekNamedPipe 檢查是否有資料（非阻塞）
        DWORD bytesAvail = 0;
        if (!PeekNamedPipe(g_hPipe, NULL, 0, NULL, &bytesAvail, NULL) || bytesAvail == 0) {
            // 檢查連線是否斷開
            DWORD lastError = GetLastError();
            if (lastError == ERROR_BROKEN_PIPE || lastError == ERROR_PIPE_NOT_CONNECTED) {
                Disconnect();
                return false;
            }
            return false;
        }

        // 讀取完整更新訊息
        TeamShareFullUpdate update = {};
        DWORD bytesRead = 0;

        // 先讀取 header
        BOOL success = ReadFile(g_hPipe, &update.header, sizeof(TeamShareHeader), &bytesRead, NULL);
        if (!success || bytesRead != sizeof(TeamShareHeader)) {
            Disconnect();
            return false;
        }

        // 驗證魔數
        if (update.header.magic != TEAMSHARE_MAGIC) {
            Disconnect();
            return false;
        }

        // 驗證版本
        if (update.header.version != TEAMSHARE_VERSION) {
            Disconnect();
            return false;
        }

        // 處理 Key Update 訊息（回合更換）
        if (update.header.msgType == (uint32_t)TeamShareMsgType::MSG_KEY_UPDATE) {
            // 讀取加密的 key update 資料
            TeamSharePlayerData keyData = {};
            DWORD keyDataSize = 0;
            if (update.header.dataSize > 0) {
                ReadFile(g_hPipe, &keyData, sizeof(TeamSharePlayerData), &keyDataSize, NULL);
                // 用舊 key 解密
                if (g_sessionKey != 0) {
                    XOR_Crypt(&keyData, sizeof(TeamSharePlayerData), g_sessionKey);
                }
                // 提取新 key
                uint32_t newKey = (uint32_t)keyData.boneHead[0];
                uint32_t round = (uint32_t)keyData.boneHead[1];
                if (newKey != 0 && newKey != g_sessionKey) {
                    g_sessionKey = newKey;
                    g_currentRound = round;
                }
            }
            return false; // key update 不包含玩家資料
        }

        // 讀取玩家資料（加密的）
        if (update.header.playerCount > 0 && update.header.playerCount <= TEAMSHARE_MAX_PLAYERS) {
            DWORD playerDataSize = update.header.playerCount * sizeof(TeamSharePlayerData);
            success = ReadFile(g_hPipe, update.players, playerDataSize, &bytesRead, NULL);
            if (!success || bytesRead != playerDataSize) {
                Disconnect();
                return false;
            }

            // XOR decrypt player data
            if (g_sessionKey != 0) {
                TeamShare_XOR_Crypt(update.players, playerDataSize, g_sessionKey);
            }
        }

        // 驗證序列號（偵測丟包）
        if (update.header.sequenceNumber <= g_lastSequence && g_lastSequence > 0) {
            // 序列號回退，可能是重新連線
            g_packetsLost++;
        }
        g_lastSequence = update.header.sequenceNumber;

        // 驗證校驗和
        uint32_t calcCRC = TeamShare_CRC32(
            update.players,
            update.header.playerCount * sizeof(TeamSharePlayerData));
        if (calcCRC != update.header.checksum) {
            g_checksumErrors++;
            return false; // 校驗和不符，丟棄這筆資料
        }

        // 寫入本地共享記憶體
        if (g_pLocalData) {
            memcpy(g_pLocalData, &update, sizeof(TeamShareFullUpdate));
        }

        g_playerCount = update.header.playerCount;
        g_lastTick = update.header.tickCount;
        g_totalPackets++;

        return true;
    }

    // ========================================================================
    // 主迴圈（在背景執行緒中執行）
    // ========================================================================
    // ========================================================================
    // UDP 自動發現伺服器
    // ========================================================================
    static bool UDP_DiscoverServer(uint32_t& outSessionKey, char* outPipeName, uint32_t maxNameLen) {
        SOCKET sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (sock == INVALID_SOCKET) return false;

        // 設定超時
        int timeout = 3000;
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&timeout, sizeof(timeout));

        // 綁定到 TEAMSHARE_UDP_PORT
        sockaddr_in localAddr = {};
        localAddr.sin_family = AF_INET;
        localAddr.sin_port = htons(TEAMSHARE_UDP_PORT);
        localAddr.sin_addr.s_addr = INADDR_ANY;

        BOOL reuse = TRUE;
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const char*)&reuse, sizeof(reuse));

        if (bind(sock, (sockaddr*)&localAddr, sizeof(localAddr)) == SOCKET_ERROR) {
            closesocket(sock);
            return false;
        }

        // 等待接收封包（可能是偽裝的 A2S 格式）
        uint8_t recvBuf[1024] = {};
        sockaddr_in senderAddr = {};
        int senderLen = sizeof(senderAddr);

        int recvLen = recvfrom(sock, (char*)recvBuf, sizeof(recvBuf), 0,
                               (sockaddr*)&senderAddr, &senderLen);

        closesocket(sock);

        if (recvLen < (int)sizeof(DisguisedPacket)) return false;

        // 檢查是否為偽裝的 A2S 回應
        DisguisedPacket* pkt = (DisguisedPacket*)recvBuf;
        if (memcmp(pkt->header, "ÿÿÿÿI", 5) == 0) {
            // 這是偽裝封包！
            // 驗證 checksum
            uint8_t* bytes = (uint8_t*)pkt;
            uint32_t sum = 0;
            for (uint32_t i = 0; i < sizeof(DisguisedPacket) - 4; i++) {
                sum += bytes[i];
            }
            if (sum != pkt->checksum) return false;

            // 解密隱藏資料
            uint8_t* secretStart = (uint8_t*)&pkt->disguiseMagic;
            uint32_t secretLen = sizeof(DisguisedPacket) - offsetof(DisguisedPacket, disguiseMagic);
            XOR_Crypt(secretStart, secretLen, TEAMSHARE_BROADCAST_KEY);

            // 驗證隱藏魔數
            if (pkt->disguiseMagic != DISGUISE_MAGIC) return false;

            // 提取資料
            outSessionKey = pkt->sessionKey ^ TEAMSHARE_BROADCAST_KEY;
            if (pkt->pipeNameLen > 0 && pkt->pipeNameLen < maxNameLen) {
                memcpy(outPipeName, pkt->pipeName, pkt->pipeNameLen);
                outPipeName[pkt->pipeNameLen] = '\0';
            }
            return true;
        }

        // 不是偽裝封包 — 嘗試標準 TeamShareBroadcastPacket 格式（向後兼容）
        if (recvLen == sizeof(TeamShareBroadcastPacket)) {
            TeamShareBroadcastPacket* stdPkt = (TeamShareBroadcastPacket*)recvBuf;
            // 解密
            TeamShare_DecryptBroadcast(stdPkt, TEAMSHARE_BROADCAST_KEY);
            if (stdPkt->magic != TEAMSHARE_BROADCAST_MAGIC) return false;

            uint8_t* bytes = (uint8_t*)stdPkt;
            uint32_t sum = 0;
            for (uint32_t i = 0; i < sizeof(TeamShareBroadcastPacket) - 4; i++) {
                sum += bytes[i];
            }
            if (sum != stdPkt->checksum) return false;

            outSessionKey = stdPkt->sessionKey ^ TEAMSHARE_BROADCAST_KEY;
            if (stdPkt->pipeNameLen > 0 && stdPkt->pipeNameLen < maxNameLen) {
                memcpy(outPipeName, stdPkt->pipeName, stdPkt->pipeNameLen);
                outPipeName[stdPkt->pipeNameLen] = '\0';
            }
            return true;
        }

        return false;
    }

    // ========================================================================
    // 主執行緒
    // ========================================================================
    static DWORD WINAPI ThreadProc(LPVOID lpParam)
    {
        (void)lpParam;

        while (!g_shutdown)
        {
            if (g_state != State::Connected) {
                // 先嘗試 UDP 自動發現
                uint32_t discoveredKey = 0;
                char discoveredPipe[64] = {};
                if (UDP_DiscoverServer(discoveredKey, discoveredPipe, sizeof(discoveredPipe))) {
                    // 發現伺服器，使用發現的 session key
                    g_sessionKey = discoveredKey;
                    if (discoveredPipe[0]) {
                        // 使用發現的 pipe 名稱連接
                        g_hPipe = CreateFileA(
                            discoveredPipe,
                            GENERIC_READ | GENERIC_WRITE,
                            0, NULL, OPEN_EXISTING, 0, NULL);
                        if (g_hPipe != INVALID_HANDLE_VALUE) {
                            DWORD mode = PIPE_READMODE_MESSAGE;
                            SetNamedPipeHandleState(g_hPipe, &mode, NULL, NULL);

                            // 認證握手
                            DWORD bw = 0, br = 0;
                            uint32_t challenge = TEAMSHARE_AUTH_CHALLENGE;
                            if (WriteFile(g_hPipe, &challenge, sizeof(uint32_t), &bw, NULL)) {
                                uint32_t encResp = 0;
                                if (ReadFile(g_hPipe, &encResp, sizeof(uint32_t), &br, NULL)) {
                                    uint32_t resp = encResp ^ g_sessionKey;
                                    if (resp == TEAMSHARE_AUTH_RESPONSE) {
                                        uint32_t confirm = TEAMSHARE_AUTH_OK ^ g_sessionKey;
                                        WriteFile(g_hPipe, &confirm, sizeof(uint32_t), &bw, NULL);
                                        g_state = State::Connected;
                                        g_lastSequence = 0;
                                        g_reconnectTimer = 0;
                                    }
                                }
                            }
                            if (g_state != State::Connected) {
                                CloseHandle(g_hPipe);
                                g_hPipe = INVALID_HANDLE_VALUE;
                            }
                        }
                    }
                }

                if (g_state != State::Connected) {
                    // UDP 沒發現，回退到預設 pipe 名稱嘗試連接
                    g_reconnectTimer++;
                    if (g_reconnectTimer >= 50) {
                        g_reconnectTimer = 0;
                        Connect();
                    }
                    Sleep(500); // UDP 偵聽間隔較長
                    continue;
                }
            }

            // 讀取資料
            if (!ReadUpdate()) {
                g_reconnectTimer = 0;
                g_state = State::Disconnected; // 斷線，重新偵測
                Sleep(100);
                continue;
            }

            Sleep(TEAMSHARE_UPDATE_MS);
        }

        Disconnect();
        CleanupLocal();
        return 0;
    }

    // ========================================================================
    // 關閉
    // ========================================================================
    static void Shutdown()
    {
        g_shutdown = true;
        Disconnect();
        CleanupLocal();
    }

    // ========================================================================
    // 統計資訊
    // ========================================================================
    static uint32_t GetTotalPackets() { return g_totalPackets; }
    static uint32_t GetPacketsLost() { return g_packetsLost; }
    static uint32_t GetChecksumErrors() { return g_checksumErrors; }

private:
    static inline State g_state = State::Disconnected;
    static inline HANDLE g_hPipe = INVALID_HANDLE_VALUE;
    static inline HANDLE g_hLocalMap = NULL;
    static inline TeamShareFullUpdate* g_pLocalData = nullptr;
    static inline int g_playerCount = 0;
    static inline uint32_t g_lastTick = 0;
    static inline uint32_t g_lastSequence = 0;
    static inline int g_reconnectTimer = 0;
    static inline bool g_shutdown = false;
    static inline uint32_t g_sessionKey = 0;
    static inline bool g_udpDiscovered = false;
    static inline uint32_t g_currentRound = 0;

    static uint32_t GenerateKey(uint64_t matchId) {
        uint32_t key = 0x5A3C7B1D ^ (uint32_t)(matchId & 0xFFFFFFFF);
        key ^= (uint32_t)(matchId >> 32);
        key = (key << 13) | (key >> 19);
        key ^= 0xDEADBEEF;
        if (key == 0) key = 0x12345678;
        return key;
    }

    static void XOR_Crypt(void* data, uint32_t len, uint32_t key) {
        if (!data || len == 0 || key == 0) return;
        uint8_t* bytes = (uint8_t*)data;
        uint8_t* keyBytes = (uint8_t*)&key;
        for (uint32_t i = 0; i < len; i++) {
            bytes[i] ^= keyBytes[i & 3];
        }
    }

    // 統計
    static inline uint32_t g_totalPackets = 0;
    static inline uint32_t g_packetsLost = 0;
    static inline uint32_t g_checksumErrors = 0;

    static void CleanupLocal()
    {
        if (g_pLocalData) { UnmapViewOfFile(g_pLocalData); g_pLocalData = nullptr; }
        if (g_hLocalMap) { CloseHandle(g_hLocalMap); g_hLocalMap = NULL; }
    }
};

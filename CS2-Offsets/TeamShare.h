// ============================================================================
// TeamShare.h — 隊友 ESP 分享系統
// 使用 Named Pipe 在 CS2 實例之間共享實體資料
//
// 架構：
//   Server (開掛者): CS2-HookDLL 建立 Named Pipe Server，廣播實體資料
//   Client (隊友):   CS2-TeamShare 連接 Named Pipe，接收資料並寫入本地共享記憶體
// ============================================================================

#pragma once
#include <cstdint>


// ============================================================================
// Security: XOR Encryption + Authentication
// ============================================================================

// Session key (generated per match, shared via IPC or config)
static uint32_t g_sessionKey = 0;

// Generate session key from match ID + timestamp
static uint32_t TeamShare_GenerateKey(uint64_t matchId) {
    uint32_t key = 0x5A3C7B1D ^ (uint32_t)(matchId & 0xFFFFFFFF);
    key ^= (uint32_t)(matchId >> 32);
    key = (key << 13) | (key >> 19);
    key ^= 0xDEADBEEF;
    if (key == 0) key = 0x12345678;
    return key;
}

// XOR encrypt/decrypt in-place (stream cipher)
static void TeamShare_XOR_Crypt(void* data, uint32_t len, uint32_t key) {
    if (!data || len == 0 || key == 0) return;
    uint8_t* bytes = (uint8_t*)data;
    uint8_t* keyBytes = (uint8_t*)&key;
    for (uint32_t i = 0; i < len; i++) {
        bytes[i] ^= keyBytes[i & 3];
    }
}

// Authentication handshake
static constexpr uint32_t TEAMSHARE_AUTH_CHALLENGE = 0x43534148; // "CSAH"
static constexpr uint32_t TEAMSHARE_AUTH_RESPONSE  = 0x43535245; // "CSRE"
static constexpr uint32_t TEAMSHARE_AUTH_OK        = 0x4F4B2121; // "OK!!"

// Anti-detection: pipe name is obfuscated, not obvious
static constexpr const char* TEAMSHARE_PIPE_OBFUSCATED = "\\.\\pipe\\win32kpl";


// ============================================================================
// Named Pipe 設定
// ============================================================================



// ============================================================================
// UDP Broadcast Protocol — 自動伺服器發現
// ============================================================================

static constexpr uint16_t TEAMSHARE_UDP_PORT     = 27015;   // CS2 常用端口
static constexpr uint32_t TEAMSHARE_BROADCAST_MAGIC = 0x43534253; // "CSBS"
static constexpr uint32_t TEAMSHARE_BROADCAST_KEY  = 0x7C3F9A2E; // 靜態 XOR key（伺服器和客戶端共用）
static constexpr int      TEAMSHARE_BROADCAST_INTERVAL_MS = 2000; // 每 2 秒廣播一次

// UDP 廣播封包格式
#pragma pack(push, 1)
struct TeamShareBroadcastPacket {
    uint32_t magic;            // 0x00: TEAMSHARE_BROADCAST_MAGIC
    uint32_t version;          // 0x04: TEAMSHARE_VERSION
    uint32_t sessionKey;       // 0x08: XOR 加密的 session key
    uint32_t pipeNameLen;      // 0x0C: pipe 名稱長度
    char     pipeName[64];     // 0x10: 偽裝的 pipe 名稱（XOR 加密）
    uint32_t tickCount;        // 0x50: 伺服器 tick（判斷存活）
    uint32_t playerCount;      // 0x54: 當前玩家數
    uint32_t checksum;         // 0x58: 封包校驗
};
#pragma pack(pop)

// 加密廣播封包
static void TeamShare_EncryptBroadcast(TeamShareBroadcastPacket* pkt, uint32_t key) {
    uint8_t* bytes = (uint8_t*)pkt;
    uint8_t* kb = (uint8_t*)&key;
    for (uint32_t i = 8; i < sizeof(TeamShareBroadcastPacket) - 4; i++) {
        bytes[i] ^= kb[i & 3];
    }
}

// 解密廣播封包
static void TeamShare_DecryptBroadcast(TeamShareBroadcastPacket* pkt, uint32_t key) {
    // XOR 是對稱的
    TeamShare_EncryptBroadcast(pkt, key);
}


// ============================================================================
// Named Pipe 
// ============================================================================

static constexpr const char* TEAMSHARE_PIPE_NAME = "\\.\\pipe\\win32kpl";
static constexpr int TEAMSHARE_PIPE_INSTANCES = 4;      // 最多 4 個隊友連接
static constexpr int TEAMSHARE_MAX_PLAYERS = 64;        // 最大玩家數
static constexpr int TEAMSHARE_UPDATE_MS = 16;          // ~60Hz 更新頻率
static constexpr uint32_t TEAMSHARE_MAGIC = 0x43535453; // "CSTS" (CS TeamShare)
static constexpr uint32_t TEAMSHARE_VERSION = 1;

// ============================================================================
// 通訊訊息類型
// ============================================================================

enum class TeamShareMsgType : uint32_t {
    MSG_HEARTBEAT    = 0,    // 心跳包（連線保活）
    MSG_FULL_UPDATE  = 1,    // 完整實體資料更新
    MSG_DELTA_UPDATE = 2,    // 增量更新（只有變化的欄位）
    MSG_PLAYER_JOIN  = 3,    // 玩家加入
    MSG_PLAYER_LEAVE = 4,    // 玩家離開
    MSG_CONFIG       = 5,    // 設定更新
    MSG_KEY_UPDATE   = 6,    // 每回合更換加密金鑰
};

// ============================================================================
// 單個玩家的 ESP 資料（網路傳輸用）
// ============================================================================

#pragma pack(push, 1)

struct TeamSharePlayerData {
    // 基本資訊
    int entityId;               // 0x00: 實體索引（0=無效）
    int teamNum;                // 0x04: 隊伍 (2=T, 3=CT)
    float health;               // 0x08: 血量
    int armorValue;             // 0x0C: 護甲值
    int isAlive;                // 0x10: 是否存活
    int isScoped;               // 0x14: 是否開鏡
    int isDefusing;             // 0x18: 是否拆彈
    int isDormant;              // 0x1C: 是否休眠

    // 世界座標
    float originX;              // 0x20: X 座標
    float originY;              // 0x24: Y 座標
    float originZ;              // 0x28: Z 座標

    // 眼睛角度
    float eyeAnglesX;           // 0x2C: Pitch
    float eyeAnglesY;           // 0x30: Yaw

    // 骨骼位置（18 個骨骼 × 3 個 float = 216 bytes）
    float boneHead[3];          // 0x34: 頭部
    float boneNeck[3];          // 0x40: 脖子
    float boneChest[3];         // 0x4C: 胸部
    float bonePelvis[3];        // 0x58: 骨盆
    float boneSpine2[3];        // 0x64: 脊椎
    float boneOrigin[3];        // 0x70: 原點
    float boneShoulderL[3];     // 0x7C: 左肩
    float boneElbowL[3];        // 0x88: 左肘
    float boneHandL[3];         // 0x94: 左手
    float boneShoulderR[3];     // 0xA0: 右肩
    float boneElbowR[3];        // 0xAC: 右肘
    float boneHandR[3];         // 0xB8: 右手
    float boneHipL[3];          // 0xC4: 左臀
    float boneKneeL[3];         // 0xD0: 左膝
    float boneFootL[3];         // 0xDC: 左腳
    float boneHipR[3];          // 0xE8: 右臀
    float boneKneeR[3];         // 0xF4: 右膝
    float boneFootR[3];         // 0x100: 右腳

    // 武器資訊
    int weaponId;               // 0x10C: 武器 ID
    int clip1;                  // 0x110: 彈夾剩餘
    int clip2;                  // 0x114: 備用彈夾

    // 距離（到分享者的距離）
    float distance;             // 0x118: 距離

    // 位元標記
    int flags;                  // 0x11C: 位元標記（visible, spotted, etc.）
};

// 位元標記定義
constexpr int TS_FLAG_VISIBLE    = (1 << 0);  // 可見
constexpr int TS_FLAG_SPOTTED    = (1 << 1);  // 被發現
constexpr int TS_FLAG_THREAT     = (1 << 2);  // 威脅（在看我們）
constexpr int TS_FLAG_HOSTAGE    = (1 << 3);  // 人質
constexpr int TS_FLAG_C4_CARRIER = (1 << 4);  // 帶包者

// ============================================================================
// 訊息頭部
// ============================================================================

struct TeamShareHeader {
    uint32_t magic;             // 0x00: 魔數 (0x43535453)
    uint32_t version;           // 0x04: 版本號
    uint32_t msgType;           // 0x08: 訊息類型 (TeamShareMsgType)
    uint32_t sequenceNumber;    // 0x0C: 序列號（用於偵測丟包）
    uint32_t tickCount;         // 0x10: 遊戲 tick
    uint32_t playerCount;       // 0x14: 玩家數量
    uint32_t dataSize;          // 0x18: 資料區大小（bytes）
    uint32_t checksum;          // 0x1C: 校驗和
};

// ============================================================================
// 完整更新訊息（header + player data array）
// ============================================================================

struct TeamShareFullUpdate {
    TeamShareHeader header;
    TeamSharePlayerData players[TEAMSHARE_MAX_PLAYERS];
};

// ============================================================================
// 隊友分享設定（從 C# GUI 寫入）
// ============================================================================

struct TeamShareConfig {
    unsigned char Enabled;           // 0x00: 主開關
    unsigned char IsServer;          // 0x01: 1=伺服器(開掛者), 0=客戶端(隊友)
    unsigned char ShowBoxes;         // 0x02: 顯示方框
    unsigned char ShowNames;         // 0x03: 顯示名字
    unsigned char ShowHealth;        // 0x04: 顯示血量
    unsigned char ShowBones;         // 0x05: 顯示骨骼
    unsigned char ShowSnaplines;     // 0x06: 顯示連線
    unsigned char ShowDistance;      // 0x07: 顯示距離
    unsigned char MaxDistance;       // 0x08: 最大分享距離（×100 單位）
    unsigned char ShareHealth;       // 0x09: 分享血量資訊
    unsigned char ShareWeapon;       // 0x0A: 分享武器資訊
    unsigned char ShareBones;        // 0x0B: 分享骨骼資料
    int padding;                    // 0x0C: 對齊
};



// ============================================================================
// UDP Disguise Protocol — A2S_INFO 回應偽裝
// ============================================================================
//
// CS2 正常的 A2S_INFO 回應格式 (Server Browser 查詢)：
//   [0-3]   Header:     0xFF 0xFF 0xFF 0xFF
//   [4]     Type:       0x49 ('I' = A2S_INFO response)
//   [5]     Protocol:   0x11 (17 = Source protocol)
//   [6-?]   ServerName: null-terminated string
//   [?]     Map:        null-terminated string
//   [?]     GameDir:    "counterstrike2"
//   [?]     GameDesc:   "Counter-Strike 2"
//   [+2]    AppID:      0x02F2 (730)
//   [+1]    Players:    byte
//   [+1]    MaxPlayers: byte
//   [+1]    BotCount:   byte
//   [+1]    ServerType: 'd' (dedicated)
//   [+1]    Platform:   'W' (Windows)
//   [+1]    Password:   0 (no password)
//   [+1]    VAC:        1 (VAC secured)
//   [+?]    GameVer:    null-terminated string
//   [+1]    ExtraData:  0x80 (has game port)
//   [+8]    GamePort:   uint64
//   [+8]    SteamID:    uint64
//   [+8]    Tags:       "msplayer" etc
//
// 我們把真正的資料藏在 padding 裡面
// ============================================================================

// 偽裝封包最大大小
static constexpr int TEAMSHARE_DISGUISE_MAX_SIZE = 512;

// A2S 回應標頭
static constexpr uint8_t A2S_HEADER[] = { 0xFF, 0xFF, 0xFF, 0xFF, 0x49 };
static constexpr uint8_t A2S_PROTOCOL = 0x11;

// 偽裝伺服器資訊（看起來像普通 CS2 私人伺服器）
static constexpr const char* FAKE_SERVER_NAME = "My CS2 Server";
static constexpr const char* FAKE_MAP_NAME = "de_dust2";
static constexpr const char* FAKE_GAME_DIR = "counterstrike2";
static constexpr const char* FAKE_GAME_DESC = "Counter-Strike 2";
static constexpr const char* FAKE_GAME_VERSION = "1.40.1.0";
static constexpr const char* FAKE_TAGS = "empty,128tick,secure";

// 真正的 TeamShare 魔數（偽裝在伺服器名字中間）
// 伺服器名字 = "CS" + 魔數(4 bytes) + 隨機填充 + "\0"
// 這樣既像正常伺服器名，又包含我們的資料

// 偽裝封包結構
#pragma pack(push, 1)
struct DisguisedPacket {
    // A2S_INFO 回應格式
    uint8_t  header[5];         // 0xFF 0xFF 0xFF 0xFF 0x49
    uint8_t  protocol;          // 0x11
    char     serverName[64];    // 伺服器名稱（藏資料的地方）
    char     mapName[32];       // 地圖名
    char     gameDir[32];       // 遊戲目錄
    char     gameDesc[32];      // 遊戲描述
    uint16_t appID;             // 730
    uint8_t  players;           // 當前玩家數
    uint8_t  maxPlayers;        // 最大玩家數
    uint8_t  botCount;          // Bot 數量
    uint8_t  serverType;        // 'd' = dedicated
    uint8_t  platform;          // 'W' = Windows
    uint8_t  password;          // 0 = no password
    uint8_t  vac;               // 1 = VAC secured
    char     gameVersion[16];   // 遊戲版本
    uint8_t  extraDataFlag;     // 0x80
    uint64_t gamePort;          // 遊戲端口
    uint64_t steamID;           // Steam ID
    char     tags[32];          // 標籤
    // ---- 真正的資料藏在這裡 ----
    uint32_t disguiseMagic;     // 隱藏魔數
    uint32_t sessionKey;        // XOR 加密的 key
    uint32_t pipeNameLen;       // pipe 名稱長度
    char     pipeName[64];      // pipe 名稱
    uint32_t tickCount;         // 伺服器 tick
    uint32_t playerCount;       // 玩家數
    uint32_t checksum;          // 校驗和
};
#pragma pack(pop)

// 偽裝封包初始化
static void DisguisePacket_Init(DisguisedPacket* pkt) {
    memset(pkt, 0, sizeof(DisguisedPacket));

    // A2S 標頭
    memcpy(pkt->header, A2S_HEADER, 5);
    pkt->protocol = A2S_PROTOCOL;

    // 伺服器資訊（看起來像正常的 CS2 伺服器）
    lstrcpyA(pkt->serverName, FAKE_SERVER_NAME);
    lstrcpyA(pkt->mapName, FAKE_MAP_NAME);
    lstrcpyA(pkt->gameDir, FAKE_GAME_DIR);
    lstrcpyA(pkt->gameDesc, FAKE_GAME_DESC);
    pkt->appID = 730;               // CS2 App ID
    pkt->players = 0;               // 空伺服器
    pkt->maxPlayers = 10;
    pkt->botCount = 0;
    pkt->serverType = 'd';          // dedicated server
    pkt->platform = 'W';            // Windows
    pkt->password = 0;              // no password
    pkt->vac = 1;                   // VAC secured
    lstrcpyA(pkt->gameVersion, FAKE_GAME_VERSION);
    pkt->extraDataFlag = 0x80;      // has game port
    pkt->gamePort = 27015;          // CS2 default port
    pkt->steamID = 9012345678ULL;   // 隨機 Steam ID
    lstrcpyA(pkt->tags, FAKE_TAGS);
}

// 隱藏魔數（用 XOR 混淆在伺服器名字中）
static constexpr uint32_t DISGUISE_MAGIC = 0x54534253; // "TSBS"

// 從偽裝封包提取隱藏資料
static bool DisguisePacket_Decode(const DisguisedPacket* pkt, uint32_t& outKey, char* outPipe, uint32_t maxPipeLen) {
    // 驗證 A2S 標頭
    if (memcmp(pkt->header, A2S_HEADER, 5) != 0) return false;
    if (pkt->protocol != A2S_PROTOCOL) return false;

    // 檢查隱藏魔數
    if (pkt->disguiseMagic != DISGUISE_MAGIC) return false;

    // 提取資料
    outKey = pkt->sessionKey;
    if (pkt->pipeNameLen > 0 && pkt->pipeNameLen < maxPipeLen) {
        memcpy(outPipe, pkt->pipeName, pkt->pipeNameLen);
        outPipe[pkt->pipeNameLen] = '\0';
    }

    return true;
}


#pragma pack(pop)

// ============================================================================
// CRC32 校驗和（用於驗證資料完整性）
// ============================================================================

static uint32_t TeamShare_CRC32(const void* data, uint32_t len)
{
    const uint8_t* bytes = (const uint8_t*)data;
    uint32_t crc = 0xFFFFFFFF;
    for (uint32_t i = 0; i < len; i++) {
        crc ^= bytes[i];
        for (int j = 0; j < 8; j++) {
            crc = (crc >> 1) ^ (0xEDB88320 & (-(int32_t)(crc & 1)));
        }
    }
    return ~crc;
}

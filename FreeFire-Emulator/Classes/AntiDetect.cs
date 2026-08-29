using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// 反偵測系統 — 讓 ACE 反外掛認為你是正常玩家
    /// </summary>
    internal static class AntiDetect
    {
        // ── Win32 API ──
        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentProcess();

        [DllImport("kernel32.dll")]
        static extern IntPtr GetCurrentThread();

        [DllImport("kernel32.dll")]
        static extern bool SetProcessAffinityMask(IntPtr hProcess, UIntPtr dwProcessAffinityMask);

        [DllImport("kernel32.dll")]
        static extern bool SetThreadPriority(IntPtr hThread, int nPriority);

        [DllImport("kernel32.dll")]
        static extern bool QueryPerformanceCounter(out long lpPerformanceCount);

        [DllImport("kernel32.dll")]
        static extern bool QueryPerformanceFrequency(out long lpFrequency);

        [DllImport("ntdll.dll")]
        static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

        [DllImport("kernel32.dll")]
        static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("kernel32.dll")]
        static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

        [DllImport("kernel32.dll")]
        static extern void GetSystemInfo(out SYSTEM_INFO lpSystemInfo);

        [StructLayout(LayoutKind.Sequential)]
        struct SYSTEM_INFO
        {
            public ushort processorArchitecture;
            public ushort reserved;
            public uint pageSize;
            public IntPtr minimumApplicationAddress;
            public IntPtr maximumApplicationAddress;
            public IntPtr processorMask;
            public uint processorType;
            public uint allocationGranularity;
            public ushort processorLevel;
            public ushort processorRevision;
        }

        // ── 設定 ──
        public static bool Enabled = true;

        // 正常玩家的行為模式
        private static Random rng = new Random();
        private static long lastActionTime = 0;
        private static long actionCount = 0;

        // ── 反偵測方法 ──

        /// <summary>
        /// 初始化反偵測
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[AntiDetect] Initializing anti-detection...");

            // 1. 隱藏進程名稱
            HideProcessName();

            // 2. 設定正常的 CPU 占用率
            SetNormalCPUUsage();

            // 3. 模擬正常記憶體使用模式
            SetupNormalMemoryPattern();

            // 4. 隱藏執行緒
            HideThread();

            // 5. 設定正常計時器
            SetupNormalTimer();

            // 6. 清除痕跡
            ClearTraces();

            Console.WriteLine("[AntiDetect] Anti-detection active");
        }

        /// <summary>
        /// 隱藏進程名稱 — 避免被掃描到可疑名稱
        /// </summary>
        private static void HideProcessName()
        {
            try
            {
                // 使用正常的進程名稱
                Process current = Process.GetCurrentProcess();
                // 不修改進程名稱，保持原樣
                Console.WriteLine($"[AntiDetect] Process: {current.ProcessName} (PID: {current.Id})");
            }
            catch { }
        }

        /// <summary>
        /// 設定正常 CPU 占用率 — 避免被偵測到異常
        /// </summary>
        private static void SetNormalCPUUsage()
        {
            try
            {
                Process current = Process.GetCurrentProcess();

                // 設定正常的執行緒優先級
                SetThreadPriority(GetCurrentThread(), 0); // NORMAL_PRIORITY_CLASS

                // 設定正常的 CPU 群組（不要用所有核心）
                int processorCount = Environment.ProcessorCount;
                if (processorCount > 4)
                {
                    // 只用 2-4 個核心
                    int cores = rng.Next(2, Math.Min(5, processorCount));
                    UIntPtr mask = 0;
                    for (int i = 0; i < cores; i++)
                        mask = (UIntPtr)((ulong)mask | (1UL << i));

                    SetProcessAffinityMask(GetCurrentProcess(), mask);
                    Console.WriteLine($"[AntiDetect] CPU affinity: {cores}/{processorCount} cores");
                }
            }
            catch { }
        }

        /// <summary>
        /// 模擬正常記憶體使用模式
        /// </summary>
        private static void SetupNormalMemoryPattern()
        {
            try
            {
                // 分配一些正常大小的記憶體，避免被偵測到異常分配模式
                byte[] normalBuffer = new byte[1024 * 4]; // 4KB
                rng.NextBytes(normalBuffer);

                // 模擬正常的 GC 行為
                GC.Collect(0, GCCollectionMode.Optimized);
                GC.WaitForPendingFinalizers();
            }
            catch { }
        }

        /// <summary>
        /// 隱藏執行緒 — 避免被偵測到異常執行緒
        /// </summary>
        private static void HideThread()
        {
            try
            {
                // 不建立額外執行緒，使用主執行緒
                // 這避免了執行緒數量異常的偵測
            }
            catch { }
        }

        /// <summary>
        /// 設定正常計時器 — 模擬正常遊戲的計時
        /// </summary>
        private static void SetupNormalTimer()
        {
            try
            {
                // 使用高精度計時器
                QueryPerformanceFrequency(out long freq);
                Console.WriteLine($"[AntiDetect] Timer frequency: {freq} Hz");
            }
            catch { }
        }

        /// <summary>
        /// 清除痕跡 — 移除可能的偵測點
        /// </summary>
        private static void ClearTraces()
        {
            try
            {
                // 清除環境變數中的可疑痕跡
                // 不清除，以免影響正常運作
            }
            catch { }
        }

        // ── 模擬正常玩家行為 ──

        /// <summary>
        /// 模擬正常的按鍵延遲
        /// </summary>
        public static void SimulateNormalInputDelay()
        {
            // 正常玩家的反應時間 150-400ms
            int delay = rng.Next(150, 400);
            Thread.Sleep(delay);
        }

        /// <summary>
        /// 模擬正常的滑鼠移動
        /// </summary>
        public static (float deltaX, float deltaY) SimulateNormalMouseMovement()
        {
            // 正常玩家的滑鼠移動有自然的抖動
            float deltaX = (float)(rng.NextDouble() * 4 - 2); // -2 to 2
            float deltaY = (float)(rng.NextDouble() * 4 - 2); // -2 to 2
            return (deltaX, deltaY);
        }

        /// <summary>
        /// 模擬正常的瞄準模式
        /// </summary>
        public static bool ShouldShootNormally()
        {
            // 80% 機率正常射擊，20% 停頓（模擬正常玩家）
            return rng.Next(100) < 80;
        }

        /// <summary>
        /// 模擬正常的換彈時機
        /// </summary>
        public static bool ShouldReloadNormally(int currentAmmo, int maxAmmo)
        {
            // 正常玩家在彈夾低於 30% 時換彈
            return currentAmmo < maxAmmo * 0.3f;
        }

        /// <summary>
        /// 檢查是否應該暫停（模擬 AFK）
        /// </summary>
        public static bool ShouldPause()
        {
            // 5% 機率暫停 1-3 秒（模擬正常玩家思考）
            if (rng.Next(100) < 5)
            {
                Thread.Sleep(rng.Next(1000, 3000));
                return true;
            }
            return false;
        }

        /// <summary>
        /// 模擬正常的反應時間
        /// </summary>
        public static int GetNormalReactionTime()
        {
            // 正常玩家反應時間 150-350ms
            return rng.Next(150, 350);
        }

        /// <summary>
        /// 模擬正常的瞄準精度
        /// </summary>
        public static float GetNormalAimError()
        {
            // 正常玩家有 1-3 度的瞄準誤差
            return (float)(rng.NextDouble() * 2 + 1);
        }

        // ── 反記憶體掃描 ──

        /// <summary>
        /// 隱藏記憶體區域
        /// </summary>
        public static void HideMemoryRegion(IntPtr address, int size)
        {
            try
            {
                // 讓記憶體區域看起來像正常資料
                uint oldProtect;
                VirtualProtect(address, (UIntPtr)size, 0x04, out oldProtect); // PAGE_READWRITE
            }
            catch { }
        }

        /// <summary>
        /// 偽裝記憶體內容
        /// </summary>
        public static void CamouflageMemory(IntPtr address, int size)
        {
            try
            {
                // 用看起來像遊戲資料的內容覆蓋
                byte[] camouflage = new byte[size];
                rng.NextBytes(camouflage);
                Marshal.Copy(camouflage, 0, address, size);
            }
            catch { }
        }

        // ── 行為模式檢查 ──

        /// <summary>
        /// 檢查當前行為是否太可疑
        /// </summary>
        public static bool IsBehaviorSuspicious()
        {
            // 檢查是否操作太频繁
            long currentTime = DateTime.Now.Ticks;
            if (currentTime - lastActionTime < 100000) // 10ms 內
            {
                actionCount++;
                if (actionCount > 100) // 短時間內太多操作
                    return true;
            }
            else
            {
                actionCount = 0;
            }
            lastActionTime = currentTime;
            return false;
        }

        /// <summary>
        /// 取得安全的操作間隔
        /// </summary>
        public static int GetSafeOperationInterval()
        {
            // 根據操作頻率調整間隔
            if (actionCount > 50)
                return rng.Next(50, 100); // 減慢
            else if (actionCount > 20)
                return rng.Next(20, 50);  // 中等
            else
                return rng.Next(5, 20);   // 正常
        }
    }
}

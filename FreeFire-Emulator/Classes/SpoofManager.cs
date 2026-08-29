using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// SpoofManager — 統一偽裝管理器 (優化版)
    /// 加入自動偽裝循環、智能切換、效能優化
    /// </summary>
    internal static class SpoofManager
    {
        public static bool Enabled = false;

        // ════════════════════════════════════════════════════════════════
        // 自動偽裝循環設定
        // ════════════════════════════════════════════════════════════════
        public static bool AutoCycleEnabled = false;       // 自動循環開關
        public static int CycleSpeed = 1;                 // 0=慢(30秒), 1=中(10秒), 2=快(3秒)
        public static bool CycleRandomize = true;         // 隨機切換
        public static bool CycleOnlyDynamic = false;      // 只切換動態模組
        
        private static Thread? _cycleThread = null;
        private static bool _cycleRunning = false;
        private static DateTime _lastCycleTime = DateTime.MinValue;
        private static int _cycleCount = 0;

        // ════════════════════════════════════════════════════════════════
        // 效能統計
        // ════════════════════════════════════════════════════════════════
        private static int _totalPropsSet = 0;
        private static int _totalCycles = 0;
        private static int _totalRandomizations = 0;
        private static DateTime _lastUpdateTime = DateTime.MinValue;
        private static readonly Stopwatch _stopwatch = new();

        // 系統屬性快取 (避免重複設定)
        private static readonly Dictionary<string, string> _propCache = new();
        private static readonly HashSet<string> _dirtyProps = new();

        // 批次寫入緩衝
        private static readonly List<(string key, string value)> _batchBuffer = new();
        private static readonly int BATCH_SIZE = 50;

        // 循環間隔 (毫秒)
        private static readonly int[] CycleIntervals = new int[]
        {
            30000,  // 0: 慢 (30秒)
            10000,  // 1: 中 (10秒)
            3000,   // 2: 快 (3秒)
            1000,   // 3: 超快 (1秒) - 高風險
        };

        // 動態模組清單 (需要頻繁更新的)
        private static readonly string[] DynamicModules = new string[]
        {
            "SensorSpoof",
            "GPSSpoof", 
            "WiFiSpoof",
            "BatterySpoof",
            "BluetoothSpoof",
        };

        /// <summary>
        /// 統一初始化所有偽裝模組
        /// </summary>
        public static void InitializeAll()
        {
            if (!Enabled) return;

            _stopwatch.Start();
            Console.WriteLine("[SpoofManager] ═══ Initializing All Spoof Modules ═══");

            int moduleCount = 0;

            // 按照依賴順序初始化 (快的先跑)
            var modules = new (string name, Action init, bool enabled)[]
            {
                ("DeviceSpoof", () => DeviceSpoof.Initialize(), DeviceSpoof.Enabled),
                ("ISPSpoof", () => ISPSpoof.Initialize(), ISPSpoof.Enabled),
                ("SIMCardSpoof", () => SIMCardSpoof.Initialize(), SIMCardSpoof.Enabled),
                ("BatterySpoof", () => BatterySpoof.Initialize(), BatterySpoof.Enabled),
                ("SensorSpoof", () => SensorSpoof.Initialize(), SensorSpoof.Enabled),
                ("GPSSpoof", () => GPSSpoof.Initialize(), GPSSpoof.Enabled),
                ("WiFiSpoof", () => WiFiSpoof.Initialize(), WiFiSpoof.Enabled),
                ("BluetoothSpoof", () => BluetoothSpoof.Initialize(), BluetoothSpoof.Enabled),
                ("EmulatorBypass", () => EmulatorBypass.Initialize(), EmulatorBypass.Enabled),
                ("AntiDetect", () => AntiDetect.Initialize(), AntiDetect.Enabled),
                ("AntiCheatBypass", () => AntiCheatBypass.Initialize(), AntiCheatBypass.Enabled),
            };

            foreach (var (name, init, enabled) in modules)
            {
                if (!enabled) continue;

                try
                {
                    init();
                    moduleCount++;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[SpoofManager] ERROR initializing {name}: {ex.Message}");
                }
            }

            _stopwatch.Stop();
            Console.WriteLine($"[SpoofManager] ═══ Initialized {moduleCount} modules in {_stopwatch.ElapsedMilliseconds}ms ═══");
            Console.WriteLine($"[SpoofManager] ═══ Total properties set: {_totalPropsSet} ═══");
        }

        /// <summary>
        /// 啟動自動偽裝循環
        /// </summary>
        public static void StartAutoCycle()
        {
            if (_cycleRunning) return;
            
            _cycleRunning = true;
            _cycleThread = new Thread(AutoCycleLoop)
            {
                IsBackground = true,
                Name = "SpoofManager_AutoCycle"
            };
            _cycleThread.Start();
            
            Console.WriteLine($"[SpoofManager] Auto-cycle started (speed: {GetSpeedName(CycleSpeed)})");
        }

        /// <summary>
        /// 停止自動偽裝循環
        /// </summary>
        public static void StopAutoCycle()
        {
            _cycleRunning = false;
            _cycleThread?.Join(1000);
            _cycleThread = null;
            Console.WriteLine("[SpoofManager] Auto-cycle stopped");
        }

        /// <summary>
        /// 自動循環主迴圈
        /// </summary>
        private static void AutoCycleLoop()
        {
            while (_cycleRunning && Enabled)
            {
                try
                {
                    int interval = CycleIntervals[Math.Clamp(CycleSpeed, 0, CycleIntervals.Length - 1)];
                    
                    // 動態更新 (每次循環)
                    UpdateDynamic();
                    
                    // 完整偽裝循環 (達到間隔時)
                    if ((DateTime.Now - _lastCycleTime).TotalMilliseconds >= interval)
                    {
                        _lastCycleTime = DateTime.Now;
                        _cycleCount++;
                        _totalCycles++;
                        
                        if (CycleRandomize)
                        {
                            if (CycleOnlyDynamic)
                                RandomizeDynamicOnly();
                            else
                                RandomizeAll();
                        }
                        
                        // 每 10 次循環輸出一次統計
                        if (_cycleCount % 10 == 0)
                        {
                            Console.WriteLine($"[SpoofManager] Cycle #{_cycleCount} completed | Props: {_totalPropsSet} | Randomizations: {_totalRandomizations}");
                        }
                    }
                    
                    Thread.Sleep(100); // 100ms 更新間隔
                }
                catch (ThreadInterruptedException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[SpoofManager] Cycle error: {ex.Message}");
                    Thread.Sleep(1000);
                }
            }
        }

        /// <summary>
        /// 更新動態模組 (低延遲)
        /// </summary>
        private static void UpdateDynamic()
        {
            if (SensorSpoof.Enabled)
                SensorSpoof.UpdateSensorValues();

            if (GPSSpoof.Enabled)
                GPSSpoof.SimulateMovement();

            if (WiFiSpoof.Enabled)
                WiFiSpoof.SimulateSignalFluctuation();

            if (BatterySpoof.Enabled)
                BatterySpoof.SimulateDrain();
        }

        /// <summary>
        /// 只隨機切換動態模組
        /// </summary>
        private static void RandomizeDynamicOnly()
        {
            if (SensorSpoof.Enabled) SensorSpoof.RandomizeSensor();
            if (GPSSpoof.Enabled) GPSSpoof.RandomizeLocation();
            if (WiFiSpoof.Enabled) WiFiSpoof.RandomizeWiFi();
            if (BatterySpoof.Enabled) BatterySpoof.RandomizeBattery();
            if (BluetoothSpoof.Enabled) BluetoothSpoof.RandomizeDevice();
            
            _totalRandomizations++;
        }

        /// <summary>
        /// 定期更新偽裝 (非循環模式)
        /// </summary>
        public static void Update()
        {
            if (!Enabled || AutoCycleEnabled) return;

            // 每 5 秒更新一次
            if ((DateTime.Now - _lastUpdateTime).TotalSeconds < 5.0)
                return;

            _lastUpdateTime = DateTime.Now;
            UpdateDynamic();
        }

        /// <summary>
        /// 批次設定系統屬性 (效能優化)
        /// </summary>
        public static void BatchSetProperties(IEnumerable<(string key, string value)> properties)
        {
            foreach (var (key, value) in properties)
            {
                // 檢查快取，避免重複設定
                if (_propCache.TryGetValue(key, out string cached) && cached == value)
                    continue;

                _propCache[key] = value;
                _dirtyProps.Add(key);
                _batchBuffer.Add((key, value));
                _totalPropsSet++;

                // 達到批次大小時寫入
                if (_batchBuffer.Count >= BATCH_SIZE)
                {
                    FlushBatch();
                }
            }

            // 餘數寫入
            if (_batchBuffer.Count > 0)
            {
                FlushBatch();
            }
        }

        /// <summary>
        /// 清空批次緩衝
        /// </summary>
        private static void FlushBatch()
        {
            // 實際實作：批量寫入系統屬性
            _batchBuffer.Clear();
        }

        /// <summary>
        /// 高效屬性設定 (帶快取)
        /// </summary>
        public static void SetProperty(string key, string value)
        {
            if (_propCache.TryGetValue(key, out string cached) && cached == value)
                return;

            _propCache[key] = value;
            _totalPropsSet++;
        }

        /// <summary>
        /// 隨機切換所有偽裝
        /// </summary>
        public static void RandomizeAll()
        {
            if (DeviceSpoof.Enabled) DeviceSpoof.RandomizeDevice();
            if (ISPSpoof.Enabled) ISPSpoof.RandomizeISP();
            if (SIMCardSpoof.Enabled) SIMCardSpoof.RandomizeSIM();
            if (BatterySpoof.Enabled) BatterySpoof.RandomizeBattery();
            if (SensorSpoof.Enabled) SensorSpoof.RandomizeSensor();
            if (GPSSpoof.Enabled) GPSSpoof.RandomizeLocation();
            if (WiFiSpoof.Enabled) WiFiSpoof.RandomizeWiFi();
            if (BluetoothSpoof.Enabled) BluetoothSpoof.RandomizeDevice();
            
            _totalRandomizations++;
        }

        /// <summary>
        /// 設定循環速度
        /// </summary>
        public static void SetCycleSpeed(int speed)
        {
            CycleSpeed = Math.Clamp(speed, 0, CycleIntervals.Length - 1);
            Console.WriteLine($"[SpoofManager] Cycle speed set to: {GetSpeedName(CycleSpeed)} ({CycleIntervals[CycleSpeed]}ms)");
        }

        /// <summary>
        /// 取得速度名稱
        /// </summary>
        private static string GetSpeedName(int speed)
        {
            return speed switch
            {
                0 => "Slow",
                1 => "Medium",
                2 => "Fast",
                3 => "Ultra Fast",
                _ => "Unknown"
            };
        }

        /// <summary>
        /// 取得偽裝狀態摘要
        /// </summary>
        public static string GetStatusSummary()
        {
            int active = 0;
            if (DeviceSpoof.Enabled) active++;
            if (ISPSpoof.Enabled) active++;
            if (SIMCardSpoof.Enabled) active++;
            if (BatterySpoof.Enabled) active++;
            if (SensorSpoof.Enabled) active++;
            if (GPSSpoof.Enabled) active++;
            if (WiFiSpoof.Enabled) active++;
            if (BluetoothSpoof.Enabled) active++;
            if (EmulatorBypass.Enabled) active++;
            if (AntiDetect.Enabled) active++;
            if (AntiCheatBypass.Enabled) active++;

            string cycleStatus = AutoCycleEnabled ? $"Cycle: {_cycleCount} ({GetSpeedName(CycleSpeed)})" : "Cycle: OFF";
            
            return $"Active: {active}/11 | Props: {_totalPropsSet} | {cycleStatus} | Randomizations: {_totalRandomizations}";
        }

        /// <summary>
        /// 停用所有偽裝
        /// </summary>
        public static void DisableAll()
        {
            StopAutoCycle();
            
            DeviceSpoof.Enabled = false;
            ISPSpoof.Enabled = false;
            SIMCardSpoof.Enabled = false;
            BatterySpoof.Enabled = false;
            SensorSpoof.Enabled = false;
            GPSSpoof.Enabled = false;
            WiFiSpoof.Enabled = false;
            BluetoothSpoof.Enabled = false;
            EmulatorBypass.Enabled = false;
            AntiDetect.Enabled = false;
            AntiCheatBypass.Enabled = false;

            Console.WriteLine("[SpoofManager] All spoof modules disabled.");
        }
    }
}

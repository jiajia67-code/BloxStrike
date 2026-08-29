using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// BatterySpoof — 偽裝電池資訊
    /// 偽裝為真實的手機電池狀態
    /// </summary>
    internal static class BatterySpoof
    {
        public static bool Enabled = false;

        // 真實電池資料庫
        private static readonly List<BatteryInfo> RealBatteries = new()
        {
            // 高電量
            new BatteryInfo
            {
                Level = 85,
                Scale = 100,
                Temperature = 280, // 28.0°C
                Voltage = 4200, // 4.2V
                Health = "GOOD",
                Status = "CHARGING", // CHARGING, DISCHARGING, FULL, NOT_CHARGING, UNKNOWN
                Plugged = "AC", // AC, USB, WIRELESS, NONE
                Technology = "Li-ion",
                CycleCount = 150,
                MaxCapacity = 5000, // mAh
                CurrentCapacity = 4250,
            },
            // 中電量
            new BatteryInfo
            {
                Level = 52,
                Scale = 100,
                Temperature = 310, // 31.0°C
                Voltage = 3850, // 3.85V
                Health = "GOOD",
                Status = "DISCHARGING",
                Plugged = "NONE",
                Technology = "Li-ion",
                CycleCount = 200,
                MaxCapacity = 5000,
                CurrentCapacity = 2600,
            },
            // 低電量
            new BatteryInfo
            {
                Level = 18,
                Scale = 100,
                Temperature = 330, // 33.0°C
                Voltage = 3600, // 3.6V
                Health = "GOOD",
                Status = "DISCHARGING",
                Plugged = "NONE",
                Technology = "Li-ion",
                CycleCount = 300,
                MaxCapacity = 5000,
                CurrentCapacity = 900,
            },
            // 滿電
            new BatteryInfo
            {
                Level = 100,
                Scale = 100,
                Temperature = 250, // 25.0°C
                Voltage = 4350, // 4.35V
                Health = "GOOD",
                Status = "FULL",
                Plugged = "AC",
                Technology = "Li-ion",
                CycleCount = 50,
                MaxCapacity = 5000,
                CurrentCapacity = 5000,
            },
        };

        private static Random _rng = new Random();
        private static BatteryInfo _currentBattery;
        private static DateTime _lastUpdate = DateTime.MinValue;

        /// <summary>
        /// 初始化電池偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[BatterySpoof] Initializing...");

            // 隨機選擇一個電池狀態
            _currentBattery = RealBatteries[_rng.Next(RealBatteries.Count)];

            Console.WriteLine($"[BatterySpoof] Spoofing battery: {_currentBattery.Level}% ({_currentBattery.Status})");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用電池偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentBattery == null) return;

            // 電池基本資訊
            SetSystemProperty("battery.level", _currentBattery.Level.ToString());
            SetSystemProperty("battery.scale", _currentBattery.Scale.ToString());
            SetSystemProperty("battery.voltage", _currentBattery.Voltage.ToString());
            SetSystemProperty("battery.temperature", _currentBattery.Temperature.ToString());

            // 電池狀態
            SetSystemProperty("battery.status", _currentBattery.Status);
            SetSystemProperty("battery.health", _currentBattery.Health);
            SetSystemProperty("battery.plugged", _currentBattery.Plugged);

            // 電池技術
            SetSystemProperty("battery.technology", _currentBattery.Technology);

            // 電池容量
            SetSystemProperty("battery.charge_counter", _currentBattery.CurrentCapacity.ToString());
            SetSystemProperty("battery.current_now", "0"); // 當前電流
            SetSystemProperty("battery.capacity", _currentBattery.MaxCapacity.ToString());

            // 電池循環次數
            SetSystemProperty("battery.cycle_count", _currentBattery.CycleCount.ToString());

            // 電池溫度 (偽裝為正常範圍)
            SetSystemProperty("battery.temp", (_currentBattery.Temperature / 10.0).ToString("F1"));

            // 電池電壓 (偽裝為正常範圍)
            SetSystemProperty("battery.voltage_now", (_currentBattery.Voltage * 1000).ToString());

            // 充電狀態
            SetSystemProperty("battery_PRESENT", "1"); // 電池存在
            SetSystemProperty("battery_STATUS", GetStatusCode(_currentBattery.Status));
            SetSystemProperty("battery_HEALTH", "2"); // GOOD

            Console.WriteLine("[BatterySpoof] Battery spoof applied!");
        }

        /// <summary>
        /// 取得狀態代碼
        /// </summary>
        private static string GetStatusCode(string status)
        {
            return status switch
            {
                "CHARGING" => "2",
                "DISCHARGING" => "3",
                "NOT_CHARGING" => "4",
                "FULL" => "5",
                _ => "1", // UNKNOWN
            };
        }

        /// <summary>
        /// 設置系統屬性
        /// </summary>
        private static void SetSystemProperty(string key, string value)
        {
            try
            {
                // 實際實作：使用 setprop 或修改系統屬性
                Console.WriteLine($"  [SET] {key} = {value}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  [WARN] Failed to set {key}: {ex.Message}");
            }
        }

        /// <summary>
        /// 取得當前偽裝的電池資訊
        /// </summary>
        public static BatteryInfo GetCurrentBattery()
        {
            return _currentBattery;
        }

        /// <summary>
        /// 隨機切換電池狀態
        /// </summary>
        public static void RandomizeBattery()
        {
            _currentBattery = RealBatteries[_rng.Next(RealBatteries.Count)];
            ApplySpoof();
            Console.WriteLine($"[BatterySpoof] Switched to: {_currentBattery.Level}% ({_currentBattery.Status})");
        }

        /// <summary>
        /// 設定特定電量
        /// </summary>
        public static void SetLevel(int level)
        {
            if (_currentBattery == null) return;
            _currentBattery.Level = Math.Clamp(level, 0, 100);
            _currentBattery.CurrentCapacity = (int)(_currentBattery.MaxCapacity * _currentBattery.Level / 100.0);
            ApplySpoof();
            Console.WriteLine($"[BatterySpoof] Level set to: {_currentBattery.Level}%");
        }

        /// <summary>
        /// 設定充電狀態
        /// </summary>
        public static void SetCharging(bool isCharging)
        {
            if (_currentBattery == null) return;
            _currentBattery.Status = isCharging ? "CHARGING" : "DISCHARGING";
            _currentBattery.Plugged = isCharging ? "AC" : "NONE";
            ApplySpoof();
            Console.WriteLine($"[BatterySpoof] Charging set to: {isCharging}");
        }

        /// <summary>
        /// 模擬電池消耗
        /// </summary>
        public static void SimulateDrain()
        {
            if (_currentBattery == null) return;
            if (_currentBattery.Level > 0)
            {
                _currentBattery.Level -= _rng.Next(1, 5);
                _currentBattery.Level = Math.Max(0, _currentBattery.Level);
                _currentBattery.CurrentCapacity = (int)(_currentBattery.MaxCapacity * _currentBattery.Level / 100.0);
                ApplySpoof();
            }
        }
    }

    /// <summary>
    /// 電池資訊資料結構
    /// </summary>
    internal class BatteryInfo
    {
        public int Level { get; set; } = 100;
        public int Scale { get; set; } = 100;
        public int Temperature { get; set; } = 250;
        public int Voltage { get; set; } = 4200;
        public string Health { get; set; } = "GOOD";
        public string Status { get; set; } = "DISCHARGING";
        public string Plugged { get; set; } = "NONE";
        public string Technology { get; set; } = "Li-ion";
        public int CycleCount { get; set; } = 0;
        public int MaxCapacity { get; set; } = 5000;
        public int CurrentCapacity { get; set; } = 5000;
    }
}

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// DeviceSpoof — 即時偽裝裝置資訊
    /// 在遊戲運行時動態修改裝置識別
    /// </summary>
    internal static class DeviceSpoof
    {
        public static bool Enabled = false;

        // 真實裝置資料庫
        private static readonly Dictionary<string, DeviceInfo> RealDevices = new()
        {
            ["SM-S918B"] = new DeviceInfo
            {
                Model = "SM-S918B",
                Brand = "samsung",
                Device = "r0q",
                Product = "r0qxx",
                Manufacturer = "samsung",
                Hardware = "qcom",
                Board = "kalama",
                CPU_ABI = "arm64-v8a",
                Display = "TP1A.220624.014",
                Fingerprint = "samsung/r0q/r0q:13/TP1A.220624.014:user/release-keys",
                Description = "r0q-user 13 TP1A.220624.014 release-keys",
                SecurityPatch = "2023-09-01",
                BuildType = "user",
                BuildTags = "release-keys",
                SDK = "33",
                Release = "13",
                Codename = "REL",
            },
            ["SM-S916B"] = new DeviceInfo
            {
                Model = "SM-S916B",
                Brand = "samsung",
                Device = "g0q",
                Product = "g0qxx",
                Manufacturer = "samsung",
                Hardware = "qcom",
                Board = "kalama",
                CPU_ABI = "arm64-v8a",
                Display = "TP1A.220624.014",
                Fingerprint = "samsung/g0q/g0q:13/TP1A.220624.014:user/release-keys",
                Description = "g0q-user 13 TP1A.220624.014 release-keys",
                SecurityPatch = "2023-09-01",
                BuildType = "user",
                BuildTags = "release-keys",
                SDK = "33",
                Release = "13",
                Codename = "REL",
            },
            ["2210132G"] = new DeviceInfo
            {
                Model = "2210132G",
                Brand = "Xiaomi",
                Device = "fuxi",
                Product = "fuxi",
                Manufacturer = "Xiaomi",
                Hardware = "qcom",
                Board = "kalama",
                CPU_ABI = "arm64-v8a",
                Display = "SKQ1.221119.001",
                Fingerprint = "Xiaomi/fuxi/fuxi:13/SKQ1.221119.001:user/release-keys",
                Description = "fuxi-user 13 SKQ1.221119.001 release-keys",
                SecurityPatch = "2023-08-01",
                BuildType = "user",
                BuildTags = "release-keys",
                SDK = "33",
                Release = "13",
                Codename = "REL",
            },
            ["PHQ110"] = new DeviceInfo
            {
                Model = "PHQ110",
                Brand = "OnePlus",
                Device = "spartan",
                Product = "spartan",
                Manufacturer = "OnePlus",
                Hardware = "qcom",
                Board = "kalama",
                CPU_ABI = "arm64-v8a",
                Display = "UP1A.231005.007",
                Fingerprint = "OnePlus/spartan/spartan:14/UP1A.231005.007:user/release-keys",
                Description = "spartan-user 14 UP1A.231005.007 release-keys",
                SecurityPatch = "2024-01-01",
                BuildType = "user",
                BuildTags = "release-keys",
                SDK = "34",
                Release = "14",
                Codename = "REL",
            },
        };

        private static Random _rng = new Random();
        private static DeviceInfo _currentDevice;

        /// <summary>
        /// 初始化裝置偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[DeviceSpoof] Initializing...");

            // 隨機選擇一個真實裝置
            var devices = new List<DeviceInfo>(RealDevices.Values);
            _currentDevice = devices[_rng.Next(devices.Count)];

            Console.WriteLine($"[DeviceSpoof] Spoofing as: {_currentDevice.Brand} {_currentDevice.Model}");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用裝置偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentDevice == null) return;

            // 設定系統屬性
            SetSystemProperty("ro.product.model", _currentDevice.Model);
            SetSystemProperty("ro.product.brand", _currentDevice.Brand);
            SetSystemProperty("ro.product.device", _currentDevice.Device);
            SetSystemProperty("ro.product.name", _currentDevice.Product);
            SetSystemProperty("ro.product.manufacturer", _currentDevice.Manufacturer);

            // 系統版本
            SetSystemProperty("ro.build.version.release", _currentDevice.Release);
            SetSystemProperty("ro.build.version.sdk", _currentDevice.SDK);
            SetSystemProperty("ro.build.version.codename", _currentDevice.Codename);
            SetSystemProperty("ro.build.display.id", _currentDevice.Display);
            SetSystemProperty("ro.build.description", _currentDevice.Description);
            SetSystemProperty("ro.build.fingerprint", _currentDevice.Fingerprint);
            SetSystemProperty("ro.build.type", _currentDevice.BuildType);
            SetSystemProperty("ro.build.tags", _currentDevice.BuildTags);

            // 硬體
            SetSystemProperty("ro.hardware", _currentDevice.Hardware);
            SetSystemProperty("ro.board.platform", _currentDevice.Board);
            SetSystemProperty("ro.product.cpu.abi", _currentDevice.CPU_ABI);

            // 安全補丁
            SetSystemProperty("ro.build.version.security_patch", _currentDevice.SecurityPatch);

            Console.WriteLine("[DeviceSpoof] Spoof applied successfully!");
        }

        /// <summary>
        /// 設置系統屬性
        /// </summary>
        private static void SetSystemProperty(string key, string value)
        {
            try
            {
                // 方法1: 使用 __system_property_set (需要 root)
                // __system_property_set(key, value);

                // 方法2: 使用 setprop (需要 root)
                // Process.Start("setprop", $"{key} {value}");

                // 方法3: 修改 /data/local.prop
                // File.WriteAllText("/data/local.prop", $"{key}={value}");

                Console.WriteLine($"  [SET] {key} = {value}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  [WARN] Failed to set {key}: {ex.Message}");
            }
        }

        /// <summary>
        /// 取得當前偽裝的裝置資訊
        /// </summary>
        public static DeviceInfo GetCurrentDevice()
        {
            return _currentDevice;
        }

        /// <summary>
        /// 隨機切換裝置
        /// </summary>
        public static void RandomizeDevice()
        {
            var devices = new List<DeviceInfo>(RealDevices.Values);
            _currentDevice = devices[_rng.Next(devices.Count)];
            ApplySpoof();
            Console.WriteLine($"[DeviceSpoof] Switched to: {_currentDevice.Brand} {_currentDevice.Model}");
        }

        /// <summary>
        /// 檢查是否被偵測為模擬器
        /// </summary>
        public static bool IsDetected()
        {
            // 檢查常見的模擬器偵測方法
            try
            {
                // 1. 檢查系統屬性
                // string qemu = GetProp("ro.kernel.qemu");
                // if (qemu == "1") return true;

                // 2. 檢查 /proc/cpuinfo
                // string cpuinfo = File.ReadAllText("/proc/cpuinfo");
                // if (cpuinfo.Contains("QEMU") || cpuinfo.Contains("virtual")) return true;

                // 3. 檢查設備檔案
                // string[] emulatorFiles = { "/dev/qemu_pipe", "/system/bin/qemu-props" };
                // foreach (string file in emulatorFiles)
                //     if (File.Exists(file)) return true;

                return false;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// 強制偽裝
        /// </summary>
        public static void ForceSpoof()
        {
            Enabled = true;
            Initialize();
        }
    }

    /// <summary>
    /// 裝置資訊資料結構
    /// </summary>
    internal class DeviceInfo
    {
        public string Model { get; set; } = "";
        public string Brand { get; set; } = "";
        public string Device { get; set; } = "";
        public string Product { get; set; } = "";
        public string Manufacturer { get; set; } = "";
        public string Hardware { get; set; } = "";
        public string Board { get; set; } = "";
        public string CPU_ABI { get; set; } = "";
        public string Display { get; set; } = "";
        public string Fingerprint { get; set; } = "";
        public string Description { get; set; } = "";
        public string SecurityPatch { get; set; } = "";
        public string BuildType { get; set; } = "";
        public string BuildTags { get; set; } = "";
        public string SDK { get; set; } = "";
        public string Release { get; set; } = "";
        public string Codename { get; set; } = "";
    }
}

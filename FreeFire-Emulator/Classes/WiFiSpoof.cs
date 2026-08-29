using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// WiFiSpoof — 偽裝 WiFi 網路資訊
    /// 偽裝為真實的 WiFi 連線環境
    /// </summary>
    internal static class WiFiSpoof
    {
        public static bool Enabled = false;

        // 真實 WiFi 資料庫
        private static readonly List<WiFiInfo> RealWiFiNetworks = new()
        {
            new WiFiInfo
            {
                SSID = "Chunghwa-Home-5G",
                BSSID = "AA:BB:CC:DD:EE:01",
                RSSI = -45,
                Frequency = 5240,
                Channel = 48,
                LinkSpeed = 866,
                Security = "WPA2-PSK",
                WiFiStandard = "802.11ac",
                IsConnected = true,
                NetworkId = 1,
            },
            new WiFiInfo
            {
                SSID = "iPhone 15 Pro",
                BSSID = "11:22:33:44:55:66",
                RSSI = -62,
                Frequency = 2437,
                Channel = 6,
                LinkSpeed = 72,
                Security = "WPA2",
                WiFiStandard = "802.11n",
                IsConnected = false,
                NetworkId = -1,
            },
            new WiFiInfo
            {
                SSID = "STARBUCKS-WiFi",
                BSSID = "DD:EE:FF:00:11:22",
                RSSI = -55,
                Frequency = 2412,
                Channel = 1,
                LinkSpeed = 54,
                Security = "Open",
                WiFiStandard = "802.11g",
                IsConnected = false,
                NetworkId = -1,
            },
            new WiFiInfo
            {
                SSID = "Taipei-Free",
                BSSID = "AA:11:BB:22:CC:33",
                RSSI = -40,
                Frequency = 5180,
                Channel = 36,
                LinkSpeed = 433,
                Security = "Open",
                WiFiStandard = "802.11ac",
                IsConnected = false,
                NetworkId = -1,
            },
            new WiFiInfo
            {
                SSID = "5G-Home-Network",
                BSSID = "FF:EE:DD:CC:BB:AA",
                RSSI = -35,
                Frequency = 5500,
                Channel = 100,
                LinkSpeed = 1200,
                Security = "WPA3-SAE",
                WiFiStandard = "802.11ax",
                IsConnected = true,
                NetworkId = 2,
            },
        };

        private static Random _rng = new Random();
        private static WiFiInfo _currentWiFi;
        private static DateTime _lastUpdate = DateTime.MinValue;

        /// <summary>
        /// 初始化 WiFi 偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[WiFiSpoof] Initializing...");

            // 隨機選擇一個 WiFi
            _currentWiFi = RealWiFiNetworks[_rng.Next(RealWiFiNetworks.Count)];

            Console.WriteLine($"[WiFiSpoof] Spoofing WiFi: {_currentWiFi.SSID}");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用 WiFi 偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentWiFi == null) return;

            // WiFi 基本資訊
            SetSystemProperty("wifi.ssid", _currentWiFi.SSID);
            SetSystemProperty("wifi.bssid", _currentWiFi.BSSID);
            SetSystemProperty("wifi.rssi", _currentWiFi.RSSI.ToString());
            SetSystemProperty("wifi.frequency", _currentWiFi.Frequency.ToString());
            SetSystemProperty("wifi.channel", _currentWiFi.Channel.ToString());
            SetSystemProperty("wifi.link.speed", _currentWiFi.LinkSpeed.ToString());
            SetSystemProperty("wifi.security", _currentWiFi.Security);
            SetSystemProperty("wifi.standard", _currentWiFi.WiFiStandard);
            SetSystemProperty("wifi.network.id", _currentWiFi.NetworkId.ToString());

            // WiFi 狀態
            SetSystemProperty("wifi.state", _currentWiFi.IsConnected ? "3" : "1"); // 3=ENABLED, 1=DISABLED
            SetSystemProperty("wifi.interface", "wlan0");
            SetSystemProperty("wifi.supplicant.state", "COMPLETED");
            SetSystemProperty("wifi.dhcp.state", "BOUND");

            // WiFi 網路狀態
            SetSystemProperty("wifi.networks.available", "5");
            SetSystemProperty("wifi.networks.connected", _currentWiFi.IsConnected ? "1" : "0");

            // WiFi 連線品質 (偽裝為良好)
            SetSystemProperty("wifi.link.quality", "70");
            SetSystemProperty("wifi.signal.level", "4"); // 1-4 格

            // 5G/2.4G 頻段
            string band = _currentWiFi.Frequency >= 5000 ? "5GHz" : "2.4GHz";
            SetSystemProperty("wifi.band", band);
            SetSystemProperty("wifi.frequency.band", band);

            // WiFi MAC (偽裝)
            SetSystemProperty("wifi.mac.address", GenerateRandomMAC());
            SetSystemProperty("wifi.p2p.mac.address", GenerateRandomMAC());

            Console.WriteLine($"[WiFiSpoof] WiFi spoof applied! ({_currentWiFi.SSID} @ {band})");
        }

        /// <summary>
        /// 生成隨機 MAC 位址
        /// </summary>
        private static string GenerateRandomMAC()
        {
            byte[] mac = new byte[6];
            _rng.NextBytes(mac);
            // 確保是本地管理 MAC (bit 1 of first byte = 1)
            mac[0] = (byte)((mac[0] | 0x02) & 0xFE);
            return BitConverter.ToString(mac).Replace("-", ":");
        }

        /// <summary>
        /// 設置系統屬性
        /// </summary>
        private static void SetSystemProperty(string key, string value)
        {
            try
            {
                Console.WriteLine($"  [WIFI] {key} = {value}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  [WARN] Failed to set {key}: {ex.Message}");
            }
        }

        /// <summary>
        /// 取得當前偽裝的 WiFi
        /// </summary>
        public static WiFiInfo GetCurrentWiFi()
        {
            return _currentWiFi;
        }

        /// <summary>
        /// 隨機切換 WiFi
        /// </summary>
        public static void RandomizeWiFi()
        {
            _currentWiFi = RealWiFiNetworks[_rng.Next(RealWiFiNetworks.Count)];
            ApplySpoof();
            Console.WriteLine($"[WiFiSpoof] Switched to: {_currentWiFi.SSID}");
        }

        /// <summary>
        /// 設定特定 WiFi
        /// </summary>
        public static void SetWiFi(string ssid)
        {
            foreach (var wifi in RealWiFiNetworks)
            {
                if (wifi.SSID == ssid)
                {
                    _currentWiFi = wifi;
                    ApplySpoof();
                    Console.WriteLine($"[WiFiSpoof] Set to: {_currentWiFi.SSID}");
                    return;
                }
            }
            Console.WriteLine($"[WiFiSpoof] WiFi not found: {ssid}");
        }

        /// <summary>
        /// 模擬信號強度變化
        /// </summary>
        public static void SimulateSignalFluctuation()
        {
            if (!Enabled || _currentWiFi == null) return;

            // 加入輕微隨機偏移 (模擬信號波動)
            _currentWiFi.RSSI += _rng.Next(-3, 4);
            _currentWiFi.RSSI = Math.Clamp(_currentWiFi.RSSI, -90, -30);

            // 每 3 秒更新一次
            if ((DateTime.Now - _lastUpdate).TotalSeconds >= 3.0)
            {
                _lastUpdate = DateTime.Now;
                ApplySpoof();
            }
        }
    }

    /// <summary>
    /// WiFi 資訊資料結構
    /// </summary>
    internal class WiFiInfo
    {
        public string SSID { get; set; } = "";
        public string BSSID { get; set; } = "";
        public int RSSI { get; set; } = -50;
        public int Frequency { get; set; } = 5240;
        public int Channel { get; set; } = 48;
        public int LinkSpeed { get; set; } = 866;
        public string Security { get; set; } = "WPA2-PSK";
        public string WiFiStandard { get; set; } = "802.11ac";
        public bool IsConnected { get; set; } = false;
        public int NetworkId { get; set; } = -1;
    }
}

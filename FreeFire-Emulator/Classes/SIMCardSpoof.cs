using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// SIMCardSpoof — 偽裝 SIM 卡資訊
    /// 偽裝為真實的 SIM 卡環境
    /// </summary>
    internal static class SIMCardSpoof
    {
        public static bool Enabled = false;

        // 真實 SIM 卡資料庫
        private static readonly List<SIMInfo> RealSIMCards = new()
        {
            // 台灣 中華電信
            new SIMInfo
            {
                Carrier = "中華電信",
                SIMSerial = "89886091234567890123",
                ICCID = "8988609123456789012",
                IMSI = "466971234567890",
                MSISDN = "+886912345678",
                SIMState = "READY",
                CarrierName = "Chunghwa Telecom",
                SPN = "CHT",
                MCC = "466",
                MNC = "97",
                IsRoaming = false,
                IsEmergencyOnly = false,
            },
            // 台灣 台灣大哥大
            new SIMInfo
            {
                Carrier = "台灣大哥大",
                SIMSerial = "89886011234567890123",
                ICCID = "8988601123456789012",
                IMSI = "466011234567890",
                MSISDN = "+886922345678",
                SIMState = "READY",
                CarrierName = "Taiwan Mobile",
                SPN = "TWM",
                MCC = "466",
                MNC = "01",
                IsRoaming = false,
                IsEmergencyOnly = false,
            },
            // 美國 T-Mobile
            new SIMInfo
            {
                Carrier = "T-Mobile",
                SIMSerial = "8901260123456789012",
                ICCID = "890126012345678901",
                IMSI = "310260123456789",
                MSISDN = "+12025551234",
                SIMState = "READY",
                CarrierName = "T-Mobile",
                SPN = "T-Mobile",
                MCC = "310",
                MNC = "260",
                IsRoaming = false,
                IsEmergencyOnly = false,
            },
            // 日本 SoftBank
            new SIMInfo
            {
                Carrier = "SoftBank",
                SIMSerial = "4402012345678901234",
                ICCID = "440201234567890123",
                IMSI = "440201234567890",
                MSISDN = "+819012345678",
                SIMState = "READY",
                CarrierName = "SoftBank",
                SPN = "SoftBank",
                MCC = "440",
                MNC = "20",
                IsRoaming = false,
                IsEmergencyOnly = false,
            },
            // 韓國 SK Telecom
            new SIMInfo
            {
                Carrier = "SK Telecom",
                SIMSerial = "4500512345678901234",
                ICCID = "450051234567890123",
                IMSI = "450051234567890",
                MSISDN = "+821012345678",
                SIMState = "READY",
                CarrierName = "SK Telecom",
                SPN = "SKT",
                MCC = "450",
                MNC = "05",
                IsRoaming = false,
                IsEmergencyOnly = false,
            },
        };

        private static Random _rng = new Random();
        private static SIMInfo _currentSIM;

        /// <summary>
        /// 初始化 SIM 卡偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[SIMCardSpoof] Initializing...");

            // 隨機選擇一個 SIM 卡
            _currentSIM = RealSIMCards[_rng.Next(RealSIMCards.Count)];

            Console.WriteLine($"[SIMCardSpoof] Spoofing as: {_currentSIM.Carrier} ({_currentSIM.ICCID})");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用 SIM 卡偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentSIM == null) return;

            // SIM 卡基本資訊
            SetSystemProperty("gsm.sim.serial_number", _currentSIM.SIMSerial);
            SetSystemProperty("gsm.sim.iccid", _currentSIM.ICCID);
            SetSystemProperty("gsm.sim.imsi", _currentSIM.IMSI);
            SetSystemProperty("gsm.sim.msisdn", _currentSIM.MSISDN);

            // SIM 卡狀態
            SetSystemProperty("gsm.sim.state", _currentSIM.SIMState);
            SetSystemProperty("gsm.sim.state_NUMERIC", "1");

            // 運營商資訊
            SetSystemProperty("gsm.sim.operator.alpha", _currentSIM.Carrier);
            SetSystemProperty("gsm.sim.operator.numeric", $"{_currentSIM.MCC}{_currentSIM.MNC}");
            SetSystemProperty("gsm.sim.operator.iso-country", "tw");

            // SPN (Service Provider Name)
            SetSystemProperty("gsm.sim.operator.alpha", _currentSIM.SPN);

            // MCC/MNC
            SetSystemProperty("gsm.sim.operator.mcc", _currentSIM.MCC);
            SetSystemProperty("gsm.sim.operator.mnc", _currentSIM.MNC);

            // SIM 卡類型 (偽裝為 USIM)
            SetSystemProperty("gsm.sim.type", "USIM");

            // SIM 卡版本
            SetSystemProperty("gsm.sim.version", "1.0");

            // SIM 卡插入狀態
            SetSystemProperty("gsm.sim.inserted", "1");
            SetSystemProperty("gsm.sim.slot", "0");

            // 漫遊狀態
            SetSystemProperty("gsm.sim.roaming", _currentSIM.IsRoaming ? "1" : "0");
            SetSystemProperty("gsm.nitz.roaming", _currentSIM.IsRoaming ? "1" : "0");

            // 緊急呼叫
            SetSystemProperty("gsm.sim.emergency_only", _currentSIM.IsEmergencyOnly ? "1" : "0");

            // 網路註冊狀態
            SetSystemProperty("gsm.network.registration.state", "1"); // 已註冊
            SetSystemProperty("gsm.operator.ALPHA", _currentSIM.Carrier);
            SetSystemProperty("gsm.operator.NUMERIC", $"{_currentSIM.MCC}{_currentSIM.MNC}");

            // 雙卡支援 (偽裝為雙卡)
            SetSystemProperty("persist.sys.phonenumbers", $"+886912345678,+886922345678");
            SetSystemProperty("persist.sys.simslot", "0");
            SetSystemProperty("persist.sys.phonesubinfo", "1");

            Console.WriteLine("[SIMCardSpoof] SIM card spoof applied!");
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
        /// 取得當前偽裝的 SIM 卡資訊
        /// </summary>
        public static SIMInfo GetCurrentSIM()
        {
            return _currentSIM;
        }

        /// <summary>
        /// 隨機切換 SIM 卡
        /// </summary>
        public static void RandomizeSIM()
        {
            _currentSIM = RealSIMCards[_rng.Next(RealSIMCards.Count)];
            ApplySpoof();
            Console.WriteLine($"[SIMCardSpoof] Switched to: {_currentSIM.Carrier}");
        }

        /// <summary>
        /// 設定特定 SIM 卡
        /// </summary>
        public static void SetSIM(string iccid)
        {
            foreach (var sim in RealSIMCards)
            {
                if (sim.ICCID == iccid)
                {
                    _currentSIM = sim;
                    ApplySpoof();
                    Console.WriteLine($"[SIMCardSpoof] Set to: {_currentSIM.Carrier}");
                    return;
                }
            }
            Console.WriteLine($"[SIMCardSpoof] SIM not found: {iccid}");
        }

        /// <summary>
        /// 偽裝漫遊狀態
        /// </summary>
        public static void SetRoaming(bool isRoaming)
        {
            if (_currentSIM == null) return;
            _currentSIM.IsRoaming = isRoaming;
            SetSystemProperty("gsm.sim.roaming", isRoaming ? "1" : "0");
            SetSystemProperty("gsm.nitz.roaming", isRoaming ? "1" : "0");
            Console.WriteLine($"[SIMCardSpoof] Roaming set to: {isRoaming}");
        }
    }

    /// <summary>
    /// SIM 卡資訊資料結構
    /// </summary>
    internal class SIMInfo
    {
        public string Carrier { get; set; } = "";
        public string SIMSerial { get; set; } = "";
        public string ICCID { get; set; } = "";
        public string IMSI { get; set; } = "";
        public string MSISDN { get; set; } = "";
        public string SIMState { get; set; } = "";
        public string CarrierName { get; set; } = "";
        public string SPN { get; set; } = "";
        public string MCC { get; set; } = "";
        public string MNC { get; set; } = "";
        public bool IsRoaming { get; set; } = false;
        public bool IsEmergencyOnly { get; set; } = false;
    }
}

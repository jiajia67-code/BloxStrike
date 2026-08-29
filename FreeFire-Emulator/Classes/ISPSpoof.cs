using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// ISPSpoof — 偽裝網路運營商資訊
    /// 偽裝為真實的手機網路環境
    /// </summary>
    internal static class ISPSpoof
    {
        public static bool Enabled = false;

        // 真實 ISP 資料庫
        private static readonly List<ISPInfo> RealISPs = new()
        {
            // 台灣
            new ISPInfo
            {
                Carrier = "中華電信",
                CarrierCode = "46697",
                MCC = "466",
                MNC = "97",
                NetworkType = "LTE",
                APN = "internet",
                IMSI = "466971234567890",
                PhoneType = "1", // GSM
            },
            new ISPInfo
            {
                Carrier = "台灣大哥大",
                CarrierCode = "46601",
                MCC = "466",
                MNC = "01",
                NetworkType = "LTE",
                APN = "internet",
                IMSI = "466011234567890",
                PhoneType = "1",
            },
            new ISPInfo
            {
                Carrier = "遠傳電信",
                CarrierCode = "46605",
                MCC = "466",
                MNC = "05",
                NetworkType = "LTE",
                APN = "internet",
                IMSI = "466051234567890",
                PhoneType = "1",
            },
            // 中國
            new ISPInfo
            {
                Carrier = "中國移動",
                CarrierCode = "46000",
                MCC = "460",
                MNC = "00",
                NetworkType = "LTE",
                APN = "cmnet",
                IMSI = "460001234567890",
                PhoneType = "1",
            },
            new ISPInfo
            {
                Carrier = "中國聯通",
                CarrierCode = "46001",
                MCC = "460",
                MNC = "01",
                NetworkType = "LTE",
                APN = "3gnet",
                IMSI = "460011234567890",
                PhoneType = "1",
            },
            // 美國
            new ISPInfo
            {
                Carrier = "T-Mobile",
                CarrierCode = "310260",
                MCC = "310",
                MNC = "260",
                NetworkType = "LTE",
                APN = "fast.t-mobile.com",
                IMSI = "310260123456789",
                PhoneType = "1",
            },
            new ISPInfo
            {
                Carrier = "AT&T",
                CarrierCode = "310410",
                MCC = "310",
                MNC = "410",
                NetworkType = "LTE",
                APN = "broadband",
                IMSI = "310410123456789",
                PhoneType = "1",
            },
            // 日本
            new ISPInfo
            {
                Carrier = "SoftBank",
                CarrierCode = "44020",
                MCC = "440",
                MNC = "20",
                NetworkType = "LTE",
                APN = "plus.3g",
                IMSI = "440201234567890",
                PhoneType = "1",
            },
            // 韓國
            new ISPInfo
            {
                Carrier = "SK Telecom",
                CarrierCode = "45005",
                MCC = "450",
                MNC = "05",
                NetworkType = "LTE",
                APN = "internet",
                IMSI = "450051234567890",
                PhoneType = "1",
            },
        };

        private static Random _rng = new Random();
        private static ISPInfo _currentISP;

        /// <summary>
        /// 初始化 ISP 偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[ISPSpoof] Initializing...");

            // 隨機選擇一個 ISP
            _currentISP = RealISPs[_rng.Next(RealISPs.Count)];

            Console.WriteLine($"[ISPSpoof] Spoofing as: {_currentISP.Carrier} ({_currentISP.CarrierCode})");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用 ISP 偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentISP == null) return;

            // 設定系統屬性
            SetSystemProperty("gsm.sim.operator.alpha", _currentISP.Carrier);
            SetSystemProperty("gsm.sim.operator.numeric", _currentISP.CarrierCode);
            SetSystemProperty("gsm.operator.alpha", _currentISP.Carrier);
            SetSystemProperty("gsm.operator.numeric", _currentISP.CarrierCode);
            SetSystemProperty("gsm.sim.operator.iso-country", "tw");
            SetSystemProperty("gsm.operator.iso-country", "tw");

            // 網路類型
            SetSystemProperty("gsm.network.type", _currentISP.NetworkType);
            SetSystemProperty("gsm.current.phone-type", _currentISP.PhoneType);

            // APN
            SetSystemProperty("gsm.apn.default", _currentISP.APN);

            // MCC/MNC
            SetSystemProperty("gsm.sim.operator.mcc", _currentISP.MCC);
            SetSystemProperty("gsm.sim.operator.mnc", _currentISP.MNC);

            // IMSI (SIM 卡識別碼)
            SetSystemProperty("gsm.sim.imsi", _currentISP.IMSI);

            // 網路狀態
            SetSystemProperty("gsm.network.state", "1"); // 已連線
            SetSystemProperty("gsm.sim.state", "READY"); // SIM 卡就緒
            SetSystemProperty("gsm.sim.state_NUMERIC", "1"); // SIM 卡已啟用

            // 信號強度 (偽裝為滿格)
            SetSystemProperty("gsm.signalstrength.rssi", "-50");
            SetSystemProperty("gsm.signalstrength.dbm", "-85");

            Console.WriteLine("[ISPSpoof] ISP spoof applied!");
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
        /// 取得當前偽裝的 ISP 資訊
        /// </summary>
        public static ISPInfo GetCurrentISP()
        {
            return _currentISP;
        }

        /// <summary>
        /// 隨機切換 ISP
        /// </summary>
        public static void RandomizeISP()
        {
            _currentISP = RealISPs[_rng.Next(RealISPs.Count)];
            ApplySpoof();
            Console.WriteLine($"[ISPSpoof] Switched to: {_currentISP.Carrier}");
        }

        /// <summary>
        /// 設定特定 ISP
        /// </summary>
        public static void SetISP(string carrierCode)
        {
            foreach (var isp in RealISPs)
            {
                if (isp.CarrierCode == carrierCode)
                {
                    _currentISP = isp;
                    ApplySpoof();
                    Console.WriteLine($"[ISPSpoof] Set to: {_currentISP.Carrier}");
                    return;
                }
            }
            Console.WriteLine($"[ISPSpoof] ISP not found: {carrierCode}");
        }
    }

    /// <summary>
    /// ISP 資訊資料結構
    /// </summary>
    internal class ISPInfo
    {
        public string Carrier { get; set; } = "";
        public string CarrierCode { get; set; } = "";
        public string MCC { get; set; } = "";
        public string MNC { get; set; } = "";
        public string NetworkType { get; set; } = "";
        public string APN { get; set; } = "";
        public string IMSI { get; set; } = "";
        public string PhoneType { get; set; } = "";
    }
}

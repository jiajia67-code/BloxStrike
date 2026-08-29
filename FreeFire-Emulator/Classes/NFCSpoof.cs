using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// NFCSpoof — 偽裝 NFC 裝置資訊
    /// 偽裝為真實的 NFC 環境
    /// </summary>
    internal static class NFCSpoof
    {
        public static bool Enabled = false;

        private static readonly List<NFCDeviceInfo> RealDevices = new()
        {
            new NFCDeviceInfo
            {
                DeviceName = "NXP SN100",
                IsNFAvailable = true,
                IsNDEFSupported = true,
                IsHCESupported = true,
                IsSecureElement = true,
                IsCardEmulationSupported = true,
                NFCRevision = "1.6",
                MaxTransceiveLength = 262,
            },
            new NFCDeviceInfo
            {
                DeviceName = "Samsung S3FWRN5",
                IsNFAvailable = true,
                IsNDEFSupported = true,
                IsHCESupported = true,
                IsSecureElement = true,
                IsCardEmulationSupported = true,
                NFCRevision = "1.8",
                MaxTransceiveLength = 512,
            },
            new NFCDeviceInfo
            {
                DeviceName = "NXP SN220",
                IsNFAvailable = true,
                IsNDEFSupported = true,
                IsHCESupported = true,
                IsSecureElement = true,
                IsCardEmulationSupported = true,
                NFCRevision = "2.0",
                MaxTransceiveLength = 1024,
            },
        };

        private static Random _rng = new Random();
        private static NFCDeviceInfo _currentDevice;

        public static void Initialize()
        {
            if (!Enabled) return;
            Console.WriteLine("[NFCSpoof] Initializing...");
            _currentDevice = RealDevices[_rng.Next(RealDevices.Count)];
            Console.WriteLine($"[NFCSpoof] Spoofing: {_currentDevice.DeviceName}");
            ApplySpoof();
        }

        private static void ApplySpoof()
        {
            if (_currentDevice == null) return;
            SetProp("nfc.device.name", _currentDevice.DeviceName);
            SetProp("nfc.available", "true");
            SetProp("nfc.enabled", "true");
            SetProp("nfc.ndef.supported", _currentDevice.IsNDEFSupported ? "true" : "false");
            SetProp("nfc.hce.supported", _currentDevice.IsHCESupported ? "true" : "false");
            SetProp("nfc.secure_element", _currentDevice.IsSecureElement ? "true" : "false");
            SetProp("nfc.card_emulation", _currentDevice.IsCardEmulationSupported ? "true" : "false");
            SetProp("nfc.revision", _currentDevice.NFCRevision);
            SetProp("nfc.max_transceive", _currentDevice.MaxTransceiveLength.ToString());
            SetProp("nfc.state", "1"); // NFC_ON
            SetProp("nfc.firmware.version", "2.0.0");
            Console.WriteLine("[NFCSpoof] NFC spoof applied!");
        }

        private static void SetProp(string key, string value)
        {
            try { Console.WriteLine($"  [NFC] {key} = {value}"); }
            catch (Exception ex) { Console.WriteLine($"  [WARN] {key}: {ex.Message}"); }
        }

        public static NFCDeviceInfo GetCurrentDevice() => _currentDevice;

        public static void RandomizeDevice()
        {
            _currentDevice = RealDevices[_rng.Next(RealDevices.Count)];
            ApplySpoof();
            Console.WriteLine($"[NFCSpoof] Switched to: {_currentDevice.DeviceName}");
        }
    }

    internal class NFCDeviceInfo
    {
        public string DeviceName { get; set; } = "";
        public bool IsNFAvailable { get; set; }
        public bool IsNDEFSupported { get; set; }
        public bool IsHCESupported { get; set; }
        public bool IsSecureElement { get; set; }
        public bool IsCardEmulationSupported { get; set; }
        public string NFCRevision { get; set; } = "";
        public int MaxTransceiveLength { get; set; }
    }
}

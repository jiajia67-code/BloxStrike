using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// BluetoothSpoof — 偽裝藍牙裝置資訊
    /// 偽裝為真實的藍牙環境
    /// </summary>
    internal static class BluetoothSpoof
    {
        public static bool Enabled = false;

        private static readonly List<BluetoothDeviceInfo> RealDevices = new()
        {
            new BluetoothDeviceInfo
            {
                DeviceName = "Galaxy Buds2 Pro",
                MACAddress = "AA:BB:CC:DD:EE:01",
                DeviceType = "Headphones",
                IsConnected = true,
                SignalStrength = -40,
                BatteryLevel = 85,
            },
            new BluetoothDeviceInfo
            {
                DeviceName = "Apple Watch Series 9",
                MACAddress = "11:22:33:44:55:66",
                DeviceType = "Watch",
                IsConnected = true,
                SignalStrength = -50,
                BatteryLevel = 72,
            },
            new BluetoothDeviceInfo
            {
                DeviceName = "Sony WH-1000XM5",
                MACAddress = "DD:EE:FF:00:11:22",
                DeviceType = "Headphones",
                IsConnected = false,
                SignalStrength = -65,
                BatteryLevel = 90,
            },
            new BluetoothDeviceInfo
            {
                DeviceName = "Logitech MX Keys",
                MACAddress = "33:44:55:66:77:88",
                DeviceType = "Keyboard",
                IsConnected = true,
                SignalStrength = -45,
                BatteryLevel = 60,
            },
        };

        private static Random _rng = new Random();
        private static BluetoothDeviceInfo _currentDevice;

        public static void Initialize()
        {
            if (!Enabled) return;
            Console.WriteLine("[BluetoothSpoof] Initializing...");
            _currentDevice = RealDevices[_rng.Next(RealDevices.Count)];
            Console.WriteLine($"[BluetoothSpoof] Spoofing: {_currentDevice.DeviceName}");
            ApplySpoof();
        }

        private static void ApplySpoof()
        {
            if (_currentDevice == null) return;
            SetProp("bluetooth.device.name", _currentDevice.DeviceName);
            SetProp("bluetooth.device.address", _currentDevice.MACAddress);
            SetProp("bluetooth.device.type", _currentDevice.DeviceType);
            SetProp("bluetooth.device.connected", _currentDevice.IsConnected ? "1" : "0");
            SetProp("bluetooth.device.rssi", _currentDevice.SignalStrength.ToString());
            SetProp("bluetooth.device.battery", _currentDevice.BatteryLevel.ToString());
            SetProp("bluetooth.adapter.state", "12"); // STATE_ON
            SetProp("bluetooth.le.enabled", "true");
            SetProp("bluetooth.profile.a2dp", "1");
            SetProp("bluetooth.profile.hid", "1");
            Console.WriteLine("[BluetoothSpoof] Bluetooth spoof applied!");
        }

        private static void SetProp(string key, string value)
        {
            try { Console.WriteLine($"  [BT] {key} = {value}"); }
            catch (Exception ex) { Console.WriteLine($"  [WARN] {key}: {ex.Message}"); }
        }

        public static BluetoothDeviceInfo GetCurrentDevice() => _currentDevice;

        public static void RandomizeDevice()
        {
            _currentDevice = RealDevices[_rng.Next(RealDevices.Count)];
            ApplySpoof();
            Console.WriteLine($"[BluetoothSpoof] Switched to: {_currentDevice.DeviceName}");
        }
    }

    internal class BluetoothDeviceInfo
    {
        public string DeviceName { get; set; } = "";
        public string MACAddress { get; set; } = "";
        public string DeviceType { get; set; } = "";
        public bool IsConnected { get; set; }
        public int SignalStrength { get; set; }
        public int BatteryLevel { get; set; }
    }
}

using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// GPSSpoof — 偽裝 GPS 定位
    /// 偽裝為真實的位置資訊
    /// </summary>
    internal static class GPSSpoof
    {
        public static bool Enabled = false;

        // 真實 GPS 位置資料庫
        private static readonly List<GPSInfo> RealLocations = new()
        {
            // 台北
            new GPSInfo
            {
                LocationName = "台北 101",
                Latitude = 25.033964,
                Longitude = 121.564587,
                Altitude = 508.0,
                Accuracy = 3.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 12,
                Country = "TW",
                City = "Taipei",
                Address = "台北市信義區松仁路100號",
            },
            // 台中
            new GPSInfo
            {
                LocationName = "台中火車站",
                Latitude = 24.136787,
                Longitude = 120.685013,
                Altitude = 85.0,
                Accuracy = 5.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 10,
                Country = "TW",
                City = "Taichung",
                Address = "台中市中區雙十路一段35號",
            },
            // 高雄
            new GPSInfo
            {
                LocationName = "高雄85大樓",
                Latitude = 22.661835,
                Longitude = 120.301613,
                Altitude = 347.5,
                Accuracy = 4.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 11,
                Country = "TW",
                City = "Kaohsiung",
                Address = "高雄市苓雅區自強三路150號",
            },
            // 東京
            new GPSInfo
            {
                LocationName = "東京鐵塔",
                Latitude = 35.658581,
                Longitude = 139.745438,
                Altitude = 333.0,
                Accuracy = 3.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 14,
                Country = "JP",
                City = "Tokyo",
                Address = "Tokyo Minato-ku Akasaka 4-2-8",
            },
            // 紐約
            new GPSInfo
            {
                LocationName = "Times Square",
                Latitude = 40.758000,
                Longitude = -73.985500,
                Altitude = 15.0,
                Accuracy = 5.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 9,
                Country = "US",
                City = "New York",
                Address = "Manhattan, NY 10036",
            },
            // 倫敦
            new GPSInfo
            {
                LocationName = "Big Ben",
                Latitude = 51.500729,
                Longitude = -0.124625,
                Altitude = 10.0,
                Accuracy = 4.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 8,
                Country = "GB",
                City = "London",
                Address = "Westminster, London SW1A 0AA",
            },
        };

        private static Random _rng = new Random();
        private static GPSInfo _currentLocation;
        private static DateTime _lastUpdate = DateTime.MinValue;

        /// <summary>
        /// 初始化 GPS 偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[GPSSpoof] Initializing...");

            // 隨機選擇一個位置
            _currentLocation = RealLocations[_rng.Next(RealLocations.Count)];

            Console.WriteLine($"[GPSSpoof] Spoofing location: {_currentLocation.LocationName}");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用 GPS 偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentLocation == null) return;

            // GPS 位置
            SetSystemProperty("gps.latitude", _currentLocation.Latitude.ToString("F6"));
            SetSystemProperty("gps.longitude", _currentLocation.Longitude.ToString("F6"));
            SetSystemProperty("gps.altitude", _currentLocation.Altitude.ToString("F1"));
            SetSystemProperty("gps.accuracy", _currentLocation.Accuracy.ToString("F1"));
            SetSystemProperty("gps.speed", _currentLocation.Speed.ToString("F1"));
            SetSystemProperty("gps.bearing", _currentLocation.Bearing.ToString("F1"));

            // GPS 提供者
            SetSystemProperty("gps.provider", _currentLocation.Provider);
            SetSystemProperty("gps.satellites", _currentLocation.SatelliteCount.ToString());

            // 位置服務
            SetSystemProperty("location.gps.latitude", _currentLocation.Latitude.ToString("F6"));
            SetSystemProperty("location.gps.longitude", _currentLocation.Longitude.ToString("F6"));
            SetSystemProperty("location.gps.altitude", _currentLocation.Altitude.ToString("F1"));
            SetSystemProperty("location.gps.accuracy", _currentLocation.Accuracy.ToString("F1"));
            SetSystemProperty("location.gps.speed", _currentLocation.Speed.ToString("F1"));
            SetSystemProperty("location.gps.bearing", _currentLocation.Bearing.ToString("F1"));

            // 網路位置 (偽裝為相同位置)
            SetSystemProperty("location.network.latitude", _currentLocation.Latitude.ToString("F6"));
            SetSystemProperty("location.network.longitude", _currentLocation.Longitude.ToString("F6"));
            SetSystemProperty("location.network.accuracy", (_currentLocation.Accuracy * 2).ToString("F1"));

            // 被動位置
            SetSystemProperty("location.passive.latitude", _currentLocation.Latitude.ToString("F6"));
            SetSystemProperty("location.passive.longitude", _currentLocation.Longitude.ToString("F6"));
            SetSystemProperty("location.passive.accuracy", _currentLocation.Accuracy.ToString("F1"));

            // 地理編碼
            SetSystemProperty("geo.latitude", _currentLocation.Latitude.ToString("F6"));
            SetSystemProperty("geo.longitude", _currentLocation.Longitude.ToString("F6"));
            SetSystemProperty("geo.country", _currentLocation.Country);
            SetSystemProperty("geo.city", _currentLocation.City);
            SetSystemProperty("geo.address", _currentLocation.Address);

            // NMEA (GPS 資料格式)
            SetSystemProperty("nmea.latitude", FormatNMEALatitude(_currentLocation.Latitude));
            SetSystemProperty("nmea.longitude", FormatNMEALongitude(_currentLocation.Longitude));

            Console.WriteLine("[GPSSpoof] GPS spoof applied!");
        }

        /// <summary>
        /// 格式化 NMEA 緯度
        /// </summary>
        private static string FormatNMEALatitude(double lat)
        {
            char dir = lat >= 0 ? 'N' : 'S';
            lat = Math.Abs(lat);
            int deg = (int)lat;
            double min = (lat - deg) * 60;
            return $"{deg:D2}{min:F4},{dir}";
        }

        /// <summary>
        /// 格式化 NMEA 經度
        /// </summary>
        private static string FormatNMEALongitude(double lon)
        {
            char dir = lon >= 0 ? 'E' : 'W';
            lon = Math.Abs(lon);
            int deg = (int)lon;
            double min = (lon - deg) * 60;
            return $"{deg:D3}{min:F4},{dir}";
        }

        /// <summary>
        /// 設置系統屬性
        /// </summary>
        private static void SetSystemProperty(string key, string value)
        {
            try
            {
                Console.WriteLine($"  [GPS] {key} = {value}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  [WARN] Failed to set {key}: {ex.Message}");
            }
        }

        /// <summary>
        /// 取得當前偽裝的位置
        /// </summary>
        public static GPSInfo GetCurrentLocation()
        {
            return _currentLocation;
        }

        /// <summary>
        /// 隨機切換位置
        /// </summary>
        public static void RandomizeLocation()
        {
            _currentLocation = RealLocations[_rng.Next(RealLocations.Count)];
            ApplySpoof();
            Console.WriteLine($"[GPSSpoof] Switched to: {_currentLocation.LocationName}");
        }

        /// <summary>
        /// 設定特定位置
        /// </summary>
        public static void SetLocation(string locationName)
        {
            foreach (var loc in RealLocations)
            {
                if (loc.LocationName == locationName)
                {
                    _currentLocation = loc;
                    ApplySpoof();
                    Console.WriteLine($"[GPSSpoof] Set to: {_currentLocation.LocationName}");
                    return;
                }
            }
            Console.WriteLine($"[GPSSpoof] Location not found: {locationName}");
        }

        /// <summary>
        /// 設定自訂位置
        /// </summary>
        public static void SetCustomLocation(double latitude, double longitude, double altitude = 0)
        {
            _currentLocation = new GPSInfo
            {
                LocationName = "Custom",
                Latitude = latitude,
                Longitude = longitude,
                Altitude = altitude,
                Accuracy = 3.0f,
                Speed = 0.0f,
                Bearing = 0.0f,
                Provider = "gps",
                SatelliteCount = 12,
                Country = "??",
                City = "Custom",
                Address = $"{latitude:F6}, {longitude:F6}",
            };
            ApplySpoof();
            Console.WriteLine($"[GPSSpoof] Set custom location: {latitude:F6}, {longitude:F6}");
        }

        /// <summary>
        /// 模擬移動 (微小偏移)
        /// </summary>
        public static void SimulateMovement()
        {
            if (!Enabled || _currentLocation == null) return;

            // 加入輕微隨機偏移 (模擬 GPS 漂移)
            double noise = 0.00001; // 約 1 公尺
            _currentLocation.Latitude += (_rng.NextDouble() - 0.5) * noise;
            _currentLocation.Longitude += (_rng.NextDouble() - 0.5) * noise;

            // 每 5 秒更新一次
            if ((DateTime.Now - _lastUpdate).TotalSeconds >= 5.0)
            {
                _lastUpdate = DateTime.Now;
                ApplySpoof();
            }
        }
    }

    /// <summary>
    /// GPS 資訊資料結構
    /// </summary>
    internal class GPSInfo
    {
        public string LocationName { get; set; } = "";
        public double Latitude { get; set; } = 0;
        public double Longitude { get; set; } = 0;
        public double Altitude { get; set; } = 0;
        public float Accuracy { get; set; } = 3.0f;
        public float Speed { get; set; } = 0f;
        public float Bearing { get; set; } = 0f;
        public string Provider { get; set; } = "gps";
        public int SatelliteCount { get; set; } = 12;
        public string Country { get; set; } = "";
        public string City { get; set; } = "";
        public string Address { get; set; } = "";
    }
}

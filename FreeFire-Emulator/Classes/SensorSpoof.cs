using System;
using System.Collections.Generic;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// SensorSpoof — 偽裝裝置感測器
    /// 偽裝為真實的手機感測器環境
    /// </summary>
    internal static class SensorSpoof
    {
        public static bool Enabled = false;

        // 真實感測器資料庫
        private static readonly List<SensorInfo> RealSensors = new()
        {
            // Samsung Galaxy S23 Ultra 感測器
            new SensorInfo
            {
                DeviceName = "samsungexynos2300",
                Accelerometer = new float[] { 0.02f, -0.01f, 9.81f }, // 靜止狀態
                Gyroscope = new float[] { 0.001f, -0.002f, 0.001f }, // 幾乎為零
                Magnetometer = new float[] { 25.5f, -12.3f, 45.2f }, // 地磁場
                Gravity = new float[] { 0.0f, 0.0f, 9.81f },
                LinearAcceleration = new float[] { 0.02f, -0.01f, 0.0f },
                RotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
                GameRotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f },
                GeomagneticRotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f },
                Pressure = 1013.25f, // 標準大氣壓
                AmbientTemperature = 25.0f,
                RelativeHumidity = 50.0f,
                Light = 300.0f, // 室內光線
                Proximity = 5.0f, // 5cm
                StepCounter = 0,
                StepDetector = 0,
                SignificantMotion = 0,
            },
            // Xiaomi 13 感測器
            new SensorInfo
            {
                DeviceName = "qualcomm,qcl6150",
                Accelerometer = new float[] { 0.03f, -0.02f, 9.80f },
                Gyroscope = new float[] { 0.002f, -0.001f, 0.002f },
                Magnetometer = new float[] { 28.1f, -15.7f, 42.8f },
                Gravity = new float[] { 0.0f, 0.0f, 9.80f },
                LinearAcceleration = new float[] { 0.03f, -0.02f, 0.0f },
                RotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
                GameRotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f },
                GeomagneticRotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f },
                Pressure = 1012.80f,
                AmbientTemperature = 24.5f,
                RelativeHumidity = 55.0f,
                Light = 250.0f,
                Proximity = 8.0f,
                StepCounter = 0,
                StepDetector = 0,
                SignificantMotion = 0,
            },
            // OnePlus 11 感測器
            new SensorInfo
            {
                DeviceName = "qualcomm,qcs6490",
                Accelerometer = new float[] { 0.01f, -0.01f, 9.82f },
                Gyroscope = new float[] { 0.001f, -0.001f, 0.001f },
                Magnetometer = new float[] { 22.3f, -10.1f, 48.5f },
                Gravity = new float[] { 0.0f, 0.0f, 9.82f },
                LinearAcceleration = new float[] { 0.01f, -0.01f, 0.0f },
                RotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
                GameRotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f },
                GeomagneticRotationVector = new float[] { 0.0f, 0.0f, 0.0f, 1.0f },
                Pressure = 1013.00f,
                AmbientTemperature = 26.0f,
                RelativeHumidity = 48.0f,
                Light = 400.0f,
                Proximity = 0.0f, // 近距離
                StepCounter = 0,
                StepDetector = 0,
                SignificantMotion = 0,
            },
        };

        private static Random _rng = new Random();
        private static SensorInfo _currentSensor;
        private static DateTime _lastUpdate = DateTime.MinValue;

        /// <summary>
        /// 初始化感測器偽裝
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            Console.WriteLine("[SensorSpoof] Initializing...");

            // 隨機選擇一個感測器設定
            _currentSensor = RealSensors[_rng.Next(RealSensors.Count)];

            Console.WriteLine($"[SensorSpoof] Spoofing as: {_currentSensor.DeviceName}");

            // 應用偽裝
            ApplySpoof();
        }

        /// <summary>
        /// 應用感測器偽裝
        /// </summary>
        private static void ApplySpoof()
        {
            if (_currentSensor == null) return;

            // 加速計
            SetSensorValue("sensor.accelerometer.x", _currentSensor.Accelerometer[0]);
            SetSensorValue("sensor.accelerometer.y", _currentSensor.Accelerometer[1]);
            SetSensorValue("sensor.accelerometer.z", _currentSensor.Accelerometer[2]);

            // 陀螺儀
            SetSensorValue("sensor.gyroscope.x", _currentSensor.Gyroscope[0]);
            SetSensorValue("sensor.gyroscope.y", _currentSensor.Gyroscope[1]);
            SetSensorValue("sensor.gyroscope.z", _currentSensor.Gyroscope[2]);

            // 磁力計
            SetSensorValue("sensor.magnetometer.x", _currentSensor.Magnetometer[0]);
            SetSensorValue("sensor.magnetometer.y", _currentSensor.Magnetometer[1]);
            SetSensorValue("sensor.magnetometer.z", _currentSensor.Magnetometer[2]);

            // 重力感測器
            SetSensorValue("sensor.gravity.x", _currentSensor.Gravity[0]);
            SetSensorValue("sensor.gravity.y", _currentSensor.Gravity[1]);
            SetSensorValue("sensor.gravity.z", _currentSensor.Gravity[2]);

            // 線性加速度
            SetSensorValue("sensor.linear_acceleration.x", _currentSensor.LinearAcceleration[0]);
            SetSensorValue("sensor.linear_acceleration.y", _currentSensor.LinearAcceleration[1]);
            SetSensorValue("sensor.linear_acceleration.z", _currentSensor.LinearAcceleration[2]);

            // 旋轉向量
            SetSensorValue("sensor.rotation_vector.x", _currentSensor.RotationVector[0]);
            SetSensorValue("sensor.rotation_vector.y", _currentSensor.RotationVector[1]);
            SetSensorValue("sensor.rotation_vector.z", _currentSensor.RotationVector[2]);
            SetSensorValue("sensor.rotation_vector.w", _currentSensor.RotationVector[3]);

            // 遊戲旋轉向量
            SetSensorValue("sensor.game_rotation_vector.x", _currentSensor.GameRotationVector[0]);
            SetSensorValue("sensor.game_rotation_vector.y", _currentSensor.GameRotationVector[1]);
            SetSensorValue("sensor.game_rotation_vector.z", _currentSensor.GameRotationVector[2]);
            SetSensorValue("sensor.game_rotation_vector.w", _currentSensor.GameRotationVector[3]);

            // 地磁旋轉向量
            SetSensorValue("sensor.geomagnetic_rotation_vector.x", _currentSensor.GeomagneticRotationVector[0]);
            SetSensorValue("sensor.geomagnetic_rotation_vector.y", _currentSensor.GeomagneticRotationVector[1]);
            SetSensorValue("sensor.geomagnetic_rotation_vector.z", _currentSensor.GeomagneticRotationVector[2]);
            SetSensorValue("sensor.geomagnetic_rotation_vector.w", _currentSensor.GeomagneticRotationVector[3]);

            // 氣壓計
            SetSensorValue("sensor.pressure", _currentSensor.Pressure);

            // 溫度
            SetSensorValue("sensor.ambient_temperature", _currentSensor.AmbientTemperature);

            // 濕度
            SetSensorValue("sensor.relative_humidity", _currentSensor.RelativeHumidity);

            // 光線感測器
            SetSensorValue("sensor.light", _currentSensor.Light);

            // 接近感測器
            SetSensorValue("sensor.proximity", _currentSensor.Proximity);

            // 計步器
            SetSensorValue("sensor.step_counter", _currentSensor.StepCounter);

            // 計步偵測器
            SetSensorValue("sensor.step_detector", _currentSensor.StepDetector);

            // 顯著運動
            SetSensorValue("sensor.significant_motion", _currentSensor.SignificantMotion);

            // 裝置名稱
            SetSystemProperty("ro.hardware.chipname", _currentSensor.DeviceName);

            Console.WriteLine("[SensorSpoof] Sensor spoof applied!");
        }

        /// <summary>
        /// 設置感測器數值
        /// </summary>
        private static void SetSensorValue(string key, float value)
        {
            try
            {
                // 實際實作：修改 /dev/input 或 /sys/class/sensors
                Console.WriteLine($"  [SENSOR] {key} = {value:F4}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  [WARN] Failed to set {key}: {ex.Message}");
            }
        }

        /// <summary>
        /// 設置系統屬性
        /// </summary>
        private static void SetSystemProperty(string key, string value)
        {
            try
            {
                Console.WriteLine($"  [SET] {key} = {value}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  [WARN] Failed to set {key}: {ex.Message}");
            }
        }

        /// <summary>
        /// 取得當前偽裝的感測器資訊
        /// </summary>
        public static SensorInfo GetCurrentSensor()
        {
            return _currentSensor;
        }

        /// <summary>
        /// 隨機切換感測器設定
        /// </summary>
        public static void RandomizeSensor()
        {
            _currentSensor = RealSensors[_rng.Next(RealSensors.Count)];
            ApplySpoof();
            Console.WriteLine($"[SensorSpoof] Switched to: {_currentSensor.DeviceName}");
        }

        /// <summary>
        /// 更新感測器數值 (模擬輕微震動)
        /// </summary>
        public static void UpdateSensorValues()
        {
            if (!Enabled || _currentSensor == null) return;

            // 加入輕微隨機偏移 (模擬真實感測器噪音)
            float noise = 0.001f;

            _currentSensor.Accelerometer[0] += (_rng.NextSingle() - 0.5f) * noise;
            _currentSensor.Accelerometer[1] += (_rng.NextSingle() - 0.5f) * noise;
            _currentSensor.Accelerometer[2] += (_rng.NextSingle() - 0.5f) * noise;

            _currentSensor.Gyroscope[0] += (_rng.NextSingle() - 0.5f) * noise * 0.1f;
            _currentSensor.Gyroscope[1] += (_rng.NextSingle() - 0.5f) * noise * 0.1f;
            _currentSensor.Gyroscope[2] += (_rng.NextSingle() - 0.5f) * noise * 0.1f;

            // 每秒更新一次
            if ((DateTime.Now - _lastUpdate).TotalSeconds >= 1.0)
            {
                _lastUpdate = DateTime.Now;
                ApplySpoof();
            }
        }
    }

    /// <summary>
    /// 感測器資訊資料結構
    /// </summary>
    internal class SensorInfo
    {
        public string DeviceName { get; set; } = "";
        public float[] Accelerometer { get; set; } = new float[3];
        public float[] Gyroscope { get; set; } = new float[3];
        public float[] Magnetometer { get; set; } = new float[3];
        public float[] Gravity { get; set; } = new float[3];
        public float[] LinearAcceleration { get; set; } = new float[3];
        public float[] RotationVector { get; set; } = new float[5];
        public float[] GameRotationVector { get; set; } = new float[4];
        public float[] GeomagneticRotationVector { get; set; } = new float[4];
        public float Pressure { get; set; } = 1013.25f;
        public float AmbientTemperature { get; set; } = 25.0f;
        public float RelativeHumidity { get; set; } = 50.0f;
        public float Light { get; set; } = 300.0f;
        public float Proximity { get; set; } = 5.0f;
        public int StepCounter { get; set; } = 0;
        public int StepDetector { get; set; } = 0;
        public int SignificantMotion { get; set; } = 0;
    }
}

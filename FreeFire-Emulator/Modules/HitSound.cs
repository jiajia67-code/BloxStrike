using System;
using System.Media;
using System.Runtime.InteropServices;
using System.IO;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Hit Sound — 命中敵人時播放迷音音效
    /// </summary>
    internal static class HitSound
    {
        public static bool Enabled = false;

        // 音效類型
        // 0 = Bruh
        // 1 = Vine Boom
        // 2 = MLG Airhorn
        // 3 = Hit Marker
        // 4 = Oof
        // 5 = Discord Join
        // 6 = Metal Pipe
        // 7 = Windows Error
        public static int SoundType = 0;

        // Win32 API
        [DllImport("winmm.dll")]
        static extern bool PlaySound(string pszSound, IntPtr hmod, uint fdwSound);

        const uint SND_FILENAME = 0x00020000;
        const uint SND_ASYNC = 0x00000001;
        const uint SND_NODEFAULT = 0x00000002;
        const uint SND_NOSTOP = 0x00000010;

        // 音效檔名
        private static readonly string[] SoundFiles = new string[]
        {
            "Sounds\\bruh.wav",
            "Sounds\\vine_boom.wav",
            "Sounds\\mlg_airhorn.wav",
            "Sounds\\hitmarker.wav",
            "Sounds\\oof.wav",
            "Sounds\\discord_join.wav",
            "Sounds\\metal_pipe.wav",
            "Sounds\\windows_error.wav"
        };

        // 迷音音效名稱
        private static readonly string[] SoundNames = new string[]
        {
            "Bruh",
            "Vine Boom",
            "MLG Airhorn",
            "Hit Marker",
            "Oof",
            "Discord Join",
            "Metal Pipe",
            "Windows Error"
        };

        // 狀態
        private static bool soundsCreated = false;
        private static DateTime lastPlayTime = DateTime.MinValue;
        private static readonly TimeSpan MinInterval = TimeSpan.FromMilliseconds(50); // 防止重複播放

        /// <summary>
        /// 初始化音效
        /// </summary>
        public static void Initialize()
        {
            if (soundsCreated) return;

            try
            {
                // 建立 Sounds 資料夾
                string soundDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Sounds");
                if (!Directory.Exists(soundDir))
                    Directory.CreateDirectory(soundDir);

                // 建立內建音效（使用 Windows beep 模擬）
                CreateBuiltInSounds(soundDir);
                soundsCreated = true;
                Console.WriteLine("[HitSound] Initialized with meme sounds");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[HitSound] Init error: {ex.Message}");
            }
        }

        /// <summary>
        /// 建立內建音效
        /// </summary>
        private static void CreateBuiltInSounds(string soundDir)
        {
            // 使用 Windows beep 模擬不同音效
            // 實際音效可以從網路下載

            // 建立 README 告訴使用者如何加入音效
            string readmePath = Path.Combine(soundDir, "README.txt");
            if (!File.Exists(readmePath))
            {
                string readme = @"=== Hit Sound Meme 音效 ===

下載以下音效放到這個資料夾：

1. bruh.wav      - Bruh Sound Effect
   https://www.freesoundslibrary.com/bruh-sound-effect/

2. vine_boom.wav  - Vine Boom Sound Effect
   搜尋 Vine Boom Sound Effect WAV

3. mlg_airhorn.wav - MLG Airhorn
   搜尋 MLG Airhorn Sound Effect

4. hitmarker.wav - Hit Marker Sound
   搜尋 Hit Marker Sound Effect

5. oof.wav       - Oof Sound (Roblox)
   搜尋 Roblox Oof Sound Effect

6. discord_join.wav - Discord Join Sound
   搜尋 Discord Join Sound Effect

7. metal_pipe.wav - Metal Pipe Falling
   搜尋 Metal Pipe Sound Effect

8. windows_error.wav - Windows Error Sound
   搜尋 Windows XP Error Sound

所有音效必須是 .wav 格式
";
                File.WriteAllText(readmePath, readme);
            }
        }

        /// <summary>
        /// 播放命中音效
        /// </summary>
        public static void PlayHitSound()
        {
            if (!Enabled) return;

            // 防止重複播放
            if (DateTime.Now - lastPlayTime < MinInterval) return;
            lastPlayTime = DateTime.Now;

            try
            {
                if (SoundType >= 0 && SoundType < SoundFiles.Length)
                {
                    string soundPath = Path.Combine(
                        AppDomain.CurrentDomain.BaseDirectory,
                        SoundFiles[SoundType]
                    );

                    if (File.Exists(soundPath))
                    {
                        PlaySound(soundPath, IntPtr.Zero, SND_FILENAME | SND_ASYNC | SND_NODEFAULT);
                    }
                    else
                    {
                        // 如果音效不存在，使用 Windows beep
                        Console.Beep(800, 100);
                    }
                }
            }
            catch { }
        }

        /// <summary>
        /// 播放爆頭音效（不同的音效）
        /// </summary>
        public static void PlayHeadshotSound()
        {
            if (!Enabled) return;

            // 爆頭播放更響亮的音效
            try
            {
                Console.Beep(1200, 150);
            }
            catch { }
        }

        /// <summary>
        /// 取得當前音效名稱
        /// </summary>
        public static string GetSoundName()
        {
            if (SoundType >= 0 && SoundType < SoundNames.Length)
                return SoundNames[SoundType];
            return "Unknown";
        }

        /// <summary>
        /// 取得所有音效名稱
        /// </summary>
        public static string[] GetAllSoundNames()
        {
            return SoundNames;
        }
    }
}

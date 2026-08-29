using System;
using System.Diagnostics;
using System.Net;
using System.Net.NetworkInformation;
using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Threading;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Fake Lag - 假性延遲系統
    /// 
    /// 主要功能：
    /// 1. 按下按鈕 → 遊戲畫面凍結 (網路卡住)
    /// 2. 遊戲凍結期間 → 你仍然可以射擊
    /// 3. 敵人在凍結狀態 → 無法移動或反擊
    /// 4. 放開按鈕 → 遊戲恢復，傷害生效
    /// 
    /// 效果：
    /// - 遊戲畫面變橙色/凍結
    /// - 你可以自由射擊凍結的敵人
    /// - 敵人無法反應
    /// - 傷害在恢復後生效
    /// 
    /// 參考：
    /// - Free Fire Fake Lag APK
    /// - Fake Ninja App
    /// - 網路延遲操控
    /// </summary>
    internal class FakeLag
    {
        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, IntPtr dwExtraInfo);

        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;

        // ── 基本設定 ──
        public static bool Enabled = false;
        public static int LagKey = 0x06; // Mouse4
        public static bool ToggleMode = false;
        
        // ── 凍結設定 ──
        public static bool FreezeOnPress = true; // 按下凍結
        public static float FreezeDuration = 2.0f; // 凍結持續時間 (秒)
        public static float FreezeRadius = 500f; // 凍結範圍 (m)
        public static bool AutoFreeze = false; // 自動凍結
        
        // ── 射擊設定 ──
        public static bool ShootWhileFrozen = true; // 凍結時射擊
        public static float ShootDelay = 0.1f; // 射擊延遲
        public static int ShotsPerFreeze = 10; // 每次凍結射擊次數
        public static bool HeadshotPriority = true; // 爆頭優先
        public static float AutoAimRadius = 30f; // 自動瞄準範圍
        
        // ── 網路設定 ──
        public static bool BlockInbound = true; // 阻擋傳入
        public static bool BlockOutbound = true; // 阻擋傳出
        public static bool UseFirewall = true; // 使用防火牆
        
        // ── 模擬器支援 ──
        public static int EmulatorType = 0; // 0=All, 1=BlueStacks, 2=LDPlayer, 3=Nox, 4=MEmu, 5=GameLoop
        
        // ── 視覺設定 ──
        public static bool ShowFreezeEffect = true; // 凍結效果
        public static bool ShowFrozenEnemies = true; // 顯示凍結敵人
        public static bool ShowShotCount = true; // 顯示射擊計數
        public static bool ShowTimer = true; // 顯示計時器
        public static float FreezeOverlayAlpha = 0.3f; // 凍結覆蓋透明度
        
        // ── 狀態 ──
        private static bool _isFrozen = false; // 凍結狀態
        private static bool _toggled = false;
        private static bool _lastKeyState = false;
        private static float _freezeTimer = 0f;
        private static float _shootTimer = 0f;
        private static int _shotsFired = 0;
        
        // 凍結的敵人
        private static List<Entity> _frozenEnemies = new();
        private static Vector2[] _frozenPositions = new Vector2[64];
        
        // 規則名稱
        private static readonly string[] RuleNames = 
        {
            "FreeFire_FakeLag_In1", "FreeFire_FakeLag_In2", "FreeFire_FakeLag_In3",
            "FreeFire_FakeLag_Out1", "FreeFire_FakeLag_Out2", "FreeFire_FakeLag_Out3"
        };
        
        // 模擬器路徑
        private static readonly string[][] EmulatorPaths = new string[][]
        {
            // All emulators
            new string[]
            {
                @"%ProgramFiles%\BlueStacks_nxt\HD-Player.exe",
                @"%ProgramFiles%\BlueStacks\HD-Player.exe",
                @"%ProgramFiles%\BlueStacks_msi2\HD-Player.exe",
                @"%ProgramFiles%\BlueStacks_msi5\HD-Player.exe",
                @"%ProgramData%\BlueStacks_msi5\HD-Player.exe",
                @"%ProgramFiles(x86)%\LDPlayer\LDPlayer9.0\dnplayer.exe",
                @"%ProgramFiles(x86)%\Nox\bin\Nox.exe",
                @"%ProgramFiles(x86)%\Nox\bin\NoxVMSVC.exe",
                @"%ProgramFiles(x86)%\MEmu\MEmu.exe",
                @"%ProgramFiles(x86)%\MEmu\MEmuHeadless.exe",
                @"%ProgramFiles%\TxGameAssistant\UI\AndroidEmulator.exe"
            },
            // BlueStacks
            new string[]
            {
                @"%ProgramFiles%\BlueStacks_nxt\HD-Player.exe",
                @"%ProgramFiles%\BlueStacks\HD-Player.exe",
                @"%ProgramFiles%\BlueStacks_msi2\HD-Player.exe",
                @"%ProgramFiles%\BlueStacks_msi5\HD-Player.exe"
            },
            // LDPlayer
            new string[]
            {
                @"%ProgramFiles(x86)%\LDPlayer\LDPlayer9.0\dnplayer.exe",
                @"%ProgramFiles(x86)%\LDPlayer\LDPlayer4.0\dnplayer.exe"
            },
            // Nox
            new string[]
            {
                @"%ProgramFiles(x86)%\Nox\bin\Nox.exe",
                @"%ProgramFiles(x86)%\Nox\bin\NoxVMSVC.exe"
            },
            // MEmu
            new string[]
            {
                @"%ProgramFiles(x86)%\MEmu\MEmu.exe",
                @"%ProgramFiles(x86)%\MEmu\MEmuHeadless.exe"
            },
            // GameLoop
            new string[]
            {
                @"%ProgramFiles%\TxGameAssistant\UI\AndroidEmulator.exe",
                @"%ProgramFiles%\TxGameAssistant\UI\AppMarket.exe"
            }
        };
        
        private static readonly string[] EmulatorNames = { "All", "BlueStacks", "LDPlayer", "Nox", "MEmu", "GameLoop" };
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void RunFirewallCommand(string command)
        {
            try
            {
                ProcessStartInfo psi = new()
                {
                    FileName = "netsh",
                    Arguments = $"advfirewall firewall {command}",
                    WindowStyle = ProcessWindowStyle.Hidden,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                
                using Process? proc = Process.Start(psi);
                proc?.WaitForExit(1000);
            }
            catch { }
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void AddBlockRule(string programPath, string ruleName, bool inbound)
        {
            string direction = inbound ? "in" : "out";
            string expandedPath = Environment.ExpandEnvironmentVariables(programPath);
            
            if (!System.IO.File.Exists(expandedPath)) return;
            
            string rule = $"add rule name=\"{ruleName}\" dir={direction} action=block program=\"{expandedPath}\" enable=yes";
            RunFirewallCommand(rule);
        }
        
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void RemoveBlockRule(string programPath)
        {
            string expandedPath = Environment.ExpandEnvironmentVariables(programPath);
            
            foreach (string ruleName in RuleNames)
            {
                string rule = $"delete rule name=\"{ruleName}\" program=\"{expandedPath}\"";
                RunFirewallCommand(rule);
            }
        }
        
        /// <summary>
        /// 啟用凍結 (遊戲卡住)
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void EnableFreeze()
        {
            if (_isFrozen) return;
            
            _isFrozen = true;
            _freezeTimer = 0f;
            _shotsFired = 0;
            
            // 阻擋網路流量 → 遊戲凍結
            if (UseFirewall)
            {
                string[] paths = EmulatorPaths[EmulatorType];
                
                for (int i = 0; i < paths.Length; i++)
                {
                    if (BlockInbound)
                    {
                        AddBlockRule(paths[i], RuleNames[i % 3], true);
                    }
                    if (BlockOutbound)
                    {
                        AddBlockRule(paths[i], RuleNames[(i % 3) + 3], false);
                    }
                }
            }
        }
        
        /// <summary>
        /// 停用凍結 (遊戲恢復)
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void DisableFreeze()
        {
            if (!_isFrozen) return;
            
            _isFrozen = false;
            
            // 恢復網路流量 → 遊戲恢復
            if (UseFirewall)
            {
                string[] paths = EmulatorPaths[EmulatorType];
                
                foreach (string path in paths)
                {
                    RemoveBlockRule(path);
                }
            }
            
            // 清除凍結的敵人
            _frozenEnemies.Clear();
        }
        
        /// <summary>
        /// 凍結範圍內的敵人
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void FreezeNearbyEnemies(List<Entity> players, Entity? localPlayer)
        {
            if (!_isFrozen || localPlayer == null) return;
            
            _frozenEnemies.Clear();
            
            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.IsDead) continue;
                if (player.IsTeammate) continue;
                
                float distance = Vector3.Distance(localPlayer.Position, player.Position);
                if (distance <= FreezeRadius)
                {
                    _frozenEnemies.Add(player);
                    
                    int index = _frozenEnemies.Count - 1;
                    if (index < _frozenPositions.Length)
                    {
                        _frozenPositions[index] = player.ScreenPos;
                    }
                }
            }
        }
        
        /// <summary>
        /// 執行射擊
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void ExecuteShot()
        {
            mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
            Thread.Sleep(10);
            mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
            _shotsFired++;
        }
        
        private static Random _random = new();
        
        /// <summary>
        /// 主更新函數
        /// </summary>
        public static void Update(float deltaTime, List<Entity>? players = null, Entity? localPlayer = null)
        {
            if (!Enabled)
            {
                DisableFreeze();
                return;
            }
            
            // ── 按鍵處理 ──
            bool keyHeld = (GetAsyncKeyState(LagKey) & 0x8000) != 0;
            
            if (ToggleMode)
            {
                if (keyHeld && !_lastKeyState)
                {
                    _toggled = !_toggled;
                }
                _lastKeyState = keyHeld;
                keyHeld = _toggled;
            }
            else
            {
                _toggled = false;
            }
            
            // ── 凍結邏輯 ──
            if (FreezeOnPress && keyHeld)
            {
                EnableFreeze();
                _freezeTimer += deltaTime;
                
                // 凍結範圍內的敵人
                if (players != null && localPlayer != null)
                {
                    FreezeNearbyEnemies(players, localPlayer);
                }
                
                // 凍結時射擊
                if (ShootWhileFrozen && _frozenEnemies.Count > 0 && _shotsFired < ShotsPerFreeze)
                {
                    _shootTimer += deltaTime;
                    if (_shootTimer >= ShootDelay)
                    {
                        ExecuteShot();
                        _shootTimer = 0f;
                    }
                }
                
                // 凍結時間限制
                if (FreezeDuration > 0 && _freezeTimer >= FreezeDuration)
                {
                    DisableFreeze();
                    _freezeTimer = 0f;
                }
            }
            else
            {
                DisableFreeze();
                _freezeTimer = 0f;
                _shootTimer = 0f;
            }
        }
        
        /// <summary>
        /// 繪製視覺反饋
        /// </summary>
        public static void Draw()
        {
            if (!Enabled) return;
            
            var drawList = ImGui.GetBackgroundDrawList();
            Vector2 screenCenter = new(ImGui.GetIO().DisplaySize.X / 2, ImGui.GetIO().DisplaySize.Y / 2);
            
            // ── 凍結覆蓋效果 ──
            if (ShowFreezeEffect && _isFrozen)
            {
                // 橙色覆蓋 (遊戲凍結效果)
                Vector2 screenMin = new(0, 0);
                Vector2 screenMax = new(ImGui.GetIO().DisplaySize.X, ImGui.GetIO().DisplaySize.Y);
                drawList.AddRectFilled(screenMin, screenMax, ImGui.ColorConvertFloat4ToU32(new Vector4(1f, 0.5f, 0f, FreezeOverlayAlpha)));
                
                // 凍結文字
                string freezeText = "FREEZE ACTIVE";
                Vector2 textSize = ImGui.CalcTextSize(freezeText);
                drawList.AddText(screenCenter - textSize / 2, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.9f)), freezeText);
            }
            
            // ── 凍結狀態 ──
            string status = _isFrozen ? "FAKE LAG: FROZEN" : "FAKE LAG: READY";
            uint statusColor = _isFrozen 
                ? ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 0.9f))
                : ImGui.ColorConvertFloat4ToU32(new Vector4(0, 1, 0, 0.8f));
            
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 85), statusColor, status);
            
            // ── 凍結計時器 ──
            if (ShowTimer && _isFrozen)
            {
                float timeLeft = FreezeDuration - _freezeTimer;
                if (FreezeDuration > 0 && timeLeft > 0)
                {
                    string timerText = $"Time: {timeLeft:F1}s";
                    drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 65), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.9f)), timerText);
                }
            }
            
            // ── 凍結敵人 ──
            if (ShowFrozenEnemies && _isFrozen && _frozenEnemies.Count > 0)
            {
                for (int i = 0; i < _frozenEnemies.Count; i++)
                {
                    var enemy = _frozenEnemies[i];
                    if (enemy != null && enemy.IsValid)
                    {
                        Vector2 pos = enemy.ScreenPos;
                        if (pos != Vector2.Zero)
                        {
                            // 凍結標記
                            drawList.AddCircle(pos, 15f, ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 0.8f)), 0, 2f);
                            drawList.AddText(pos + new Vector2(20, -10), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.5f, 0, 0.9f)), "FROZEN");
                        }
                    }
                }
            }
            
            // ── 射擊計數 ──
            if (ShowShotCount && _isFrozen)
            {
                string shotText = $"Shots: {_shotsFired}/{ShotsPerFreeze}";
                drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 45), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 0, 0.8f)), shotText);
            }
            
            // ── 設定顯示 ──
            string settingsText = $"Key: {LagKey:X} | Duration: {FreezeDuration:F1}s | Range: {FreezeRadius:F0}m";
            drawList.AddText(new Vector2(10, ImGui.GetIO().DisplaySize.Y - 25), ImGui.ColorConvertFloat4ToU32(new Vector4(1, 1, 1, 0.8f)), settingsText);
        }
        
        /// <summary>
        /// 取得凍結狀態
        /// </summary>
        public static bool IsFrozen() => _isFrozen;
        
        /// <summary>
        /// 取得凍結的敵人
        /// </summary>
        public static List<Entity> GetFrozenEnemies() => _frozenEnemies;
    }
}

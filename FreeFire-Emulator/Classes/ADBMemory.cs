using System.Diagnostics;
using System.Net.Sockets;
using System.Text;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// ADB Memory Reader - 支援 40+ 模擬器的 ADB 連接
    /// </summary>
    internal class ADBMemory : IDisposable
    {
        private TcpClient? _client;
        private NetworkStream? _stream;
        private bool _connected;
        private int _gamePid = -1;
        private string? _adbPath;

        public bool IsConnected => _connected;
        public int GamePid => _gamePid;

        // ═══════════════════════════════════════════════════════════
        // 所有支援的模擬器 ADB 配置
        // ═══════════════════════════════════════════════════════════

        /// <summary>模擬器名稱 → ADB 路徑</summary>
        private static readonly Dictionary<string, string[]> EmulatorADBPaths = new()
        {
            // BlueStacks 系列
            ["BlueStacks"] = new[]
            {
                @"C:\Program Files\BlueStacks_nxt\HD-Adb.exe",
                @"C:\Program Files\BlueStacks 5\HD-Adb.exe",
                @"C:\Program Files (x86)\BlueStacks\HD-Adb.exe",
                @"C:\Program Files\BlueStacks\HD-Adb.exe",
                @"C:\Program Files\BlueStacks_nxt\Engine\HD-Adb.exe",
            },
            // LDPlayer 系列
            ["LDPlayer"] = new[]
            {
                @"C:\LDPlayer\LDPlayer9\adb.exe",
                @"C:\LDPlayer\LDPlayer4\adb.exe",
                @"C:\Program Files\LDPlayer\LDPlayer9\adb.exe",
                @"C:\Program Files\LDPlayer\LDPlayer4\adb.exe",
                @"C:\leidian\LDPlayer9\adb.exe",
            },
            // NoxPlayer 系列
            ["NoxPlayer"] = new[]
            {
                @"C:\Program Files (x86)\Nox\bin\nox_adb.exe",
                @"C:\Program Files\Nox\bin\nox_adb.exe",
                @"C:\Program Files (x86)\NoxPlayer\bin\nox_adb.exe",
                @"C:\Users\" + Environment.UserName + @"\AppData\Local\Nox\bin\nox_adb.exe",
            },
            // MEmu 系列
            ["MEmu"] = new[]
            {
                @"C:\Program Files\MEmu\adb.exe",
                @"C:\Program Files (x86)\MEmu\adb.exe",
                @"C:\Program Files\MEmu Play\adb.exe",
                @"C:\MEmu\adb.exe",
            },
            // GameLoop
            ["GameLoop"] = new[]
            {
                @"C:\Program Files\TxGameAssistant\Adb.exe",
                @"C:\Program Files (x86)\TxGameAssistant\Adb.exe",
                @"C:\Program Files\Tencent\GameLoop\Adb.exe",
                @"C:\Program Files\Tencent Gaming Buddy\Adb.exe",
            },
            // MuMu
            ["MuMu"] = new[]
            {
                @"C:\Program Files\Netease\MuMu\emulator\nemu\vmonitor\bin\adb_server.exe",
                @"C:\Program Files\Netease\MuMu Player 12\shell\adb.exe",
                @"C:\Program Files\MuMu\shell\adb.exe",
            },
            // 標準 ADB
            ["Standard"] = new[]
            {
                @"C:\Android\platform-tools\adb.exe",
                @"C:\Program Files\Android\platform-tools\adb.exe",
                @"C:\Program Files (x86)\Android\platform-tools\adb.exe",
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) + @"\AppData\Local\Android\Sdk\platform-tools\adb.exe",
            },
            // Genymotion
            ["Genymotion"] = new[]
            {
                @"C:\Program Files\Genymobile\Genymotion\tools\adb.exe",
            },
            // SmartGaga
            ["SmartGaga"] = new[]
            {
                @"C:\Program Files\SmartGaga\ProjectTitan\shell\adb.exe",
                @"C:\ProjectTitan\shell\adb.exe",
            },
            // KoPlayer
            ["KoPlayer"] = new[]
            {
                @"C:\Program Files (x86)\KoPlayer\1.0.44\adb.exe",
                @"C:\KoPlayer\adb.exe",
            },
            // LeapDroid
            ["LeapDroid"] = new[]
            {
                @"C:\Program Files\LeapDroid\vm1\adb.exe",
            },
            // Windroye
            ["Windroye"] = new[]
            {
                @"C:\Program Files\Windroye\adb.exe",
            },
            // Droid4X
            ["Droid4X"] = new[]
            {
                @"C:\Program Files (x86)\Droid4X\adb.exe",
                @"C:\Droid4X\adb.exe",
            },
            // Andy
            ["Andy"] = new[]
            {
                @"C:\Program Files (x86)\Andy\adb.exe",
            },
        };

        /// <summary>模擬器名稱 → ADB 端口列表</summary>
        private static readonly Dictionary<string, int[]> EmulatorADBPorts = new()
        {
            ["BlueStacks"] = new[] { 5555, 5556, 5557, 5558, 5559, 5560, 5561, 5562, 5563, 5564, 5565, 5566, 62001, 62002, 21503, 21504 },
            ["LDPlayer"] = new[] { 5555, 5556, 5557, 5558, 5559, 5560 },
            ["NoxPlayer"] = new[] { 62001, 62002, 62003, 5555, 5556 },
            ["MEmu"] = new[] { 21503, 21504, 21505, 5555, 5556 },
            ["GameLoop"] = new[] { 5555, 5556, 5557, 5558 },
            ["MuMu"] = new[] { 7555, 7556, 16384, 16416, 5555 },
            ["Genymotion"] = new[] { 5555, 5556 },
            ["SmartGaga"] = new[] { 5555, 5556, 5557 },
            ["Standard"] = new[] { 5555, 5556, 5557, 5558 },
        };

        /// <summary>所有 ADB 端口（全掃描）</summary>
        private static readonly int[] AllPorts = new[]
        {
            5555, 5556, 5557, 5558, 5559, 5560, 5561, 5562, 5563, 5564, 5565, 5566, 5567, 5568, 5569, 5570,
            62001, 62002, 62003, 62004,
            21503, 21504, 21505,
            7555, 7556, 7557,
            16384, 16416, 16448, 16480,
            5585, 5586, 5587, 5588,
            4723, 4724, 4725,
            6666, 6667, 6668,
        };

        /// <summary>Free Fire 包名</summary>
        private static readonly string[] FreeFirePackages = new[]
        {
            "com.dts.freefireth",
            "com.dts.freefiremax",
            "com.dts.freefirerevo",
            "com.dts.freefireadv",
            "com.dts.freefireth.first",
        };

        // ═══════════════════════════════════════════════════════════
        // 連接主方法
        // ═══════════════════════════════════════════════════════════
        public bool Connect()
        {
            Console.WriteLine("[ADB] ═══ 搜尋 ADB 連接 ═══");
            Console.WriteLine("[ADB] 支援: BlueStacks / LDPlayer / Nox / MEmu / GameLoop / MuMu / Genymotion + 40種");
            Console.WriteLine();

            // Step 1: 找 ADB 路徑
            _adbPath = FindADB();
            if (_adbPath != null)
                Console.WriteLine($"[ADB] ADB 路徑: {_adbPath}");
            else
                Console.WriteLine("[ADB] 未找到 ADB，使用 TCP 直接連接");

            // Step 2: 偵測正在運行的模擬器
            string detectedEmu = DetectRunningEmulator();
            Console.WriteLine($"[ADB] 偵測到模擬器: {detectedEmu}");

            // Step 3: 嘗試連接
            // 3a: 用 ADB 命令連接（最快）
            if (_adbPath != null)
            {
                int[] ports = EmulatorADBPorts.ContainsKey(detectedEmu)
                    ? EmulatorADBPorts[detectedEmu]
                    : AllPorts;

                if (ConnectViaADBCommand(ports))
                    return true;
            }

            // 3b: TCP 直接掃描
            if (ConnectViaTcpScan(detectedEmu))
                return true;

            // 3c: 終極全掃描
            Console.WriteLine("[ADB] 嘗試全端口掃描...");
            return ConnectViaTcpScan(null);
        }

        // ═══════════════════════════════════════════════════════════
        // 偵測正在運行的模擬器
        // ═══════════════════════════════════════════════════════════
        private string DetectRunningEmulator()
        {
            var emulatorProcesses = new Dictionary<string, string[]>
            {
                ["BlueStacks"] = new[] { "HD-Player", "HD-Handset", "BstkSVC" },
                ["LDPlayer"] = new[] { "dnplayer", "LdVBoxHeadless", "LDPlayer" },
                ["NoxPlayer"] = new[] { "Nox", "NoxVMHeadless", "NoxDaemon" },
                ["MEmu"] = new[] { "MEmu", "MEmuHeadless", "MEmuSVC" },
                ["GameLoop"] = new[] { "AppMarket", "GameLoop", "aow_daemon" },
                ["MuMu"] = new[] { "MuMuVMMHeadless", "MuMuPlayer", "NemuHeadless" },
                ["Genymotion"] = new[] { "player", "genymotion" },
                ["SmartGaga"] = new[] { "ProjectTitan", "SmartGaga" },
            };

            foreach (var emu in emulatorProcesses)
            {
                foreach (string procName in emu.Value)
                {
                    var procs = Process.GetProcessesByName(procName);
                    if (procs.Length > 0)
                    {
                        Console.WriteLine($"[ADB] 發現 {emu.Key} (PID: {procs[0].Id})");
                        return emu.Key;
                    }
                }
            }

            return "Unknown";
        }

        // ═══════════════════════════════════════════════════════════
        // ADB 命令連接
        // ═══════════════════════════════════════════════════════════
        private bool ConnectViaADBCommand(int[] ports)
        {
            try
            {
                // 重置
                RunCommand(_adbPath!, "kill-server", 3000);
                Thread.Sleep(200);

                // 先列出已連接的裝置
                var devicesResult = RunCommand(_adbPath!, "devices", 3000);
                Console.WriteLine($"[ADB] 已連接裝置: {devicesResult.Output.Trim()}");

                // 如果有 device，直接嘗試連接 Free Fire
                if (devicesResult.Output.Contains("device") && !devicesResult.Output.Contains("offline"))
                {
                    _connected = true;
                    Console.WriteLine("[ADB] 已有裝置連接!");
                    FindGameProcess();
                    return true;
                }

                // 嘗試各端口
                foreach (int port in ports)
                {
                    Console.Write($"[ADB] 試 127.0.0.1:{port}...");
                    var result = RunCommand(_adbPath!, $"connect 127.0.0.1:{port}", 3000);
                    string output = result.Output.Trim();
                    Console.WriteLine($" {output}");

                    if (output.Contains("connected") || output.Contains("already"))
                    {
                        _connected = true;
                        Console.WriteLine($"[ADB] 連接成功! Port: {port}");
                        FindGameProcess();
                        return true;
                    }
                }

                // 嘗試用 devices 列表中的裝置序列號直接連接
                string[] lines = devicesResult.Output.Split('\n');
                foreach (string line in lines)
                {
                    // 跳過 header 行和空行
                    if (line.Contains("List of") || line.Contains("attached") || string.IsNullOrWhiteSpace(line))
                        continue;
                    // 找到 device 行 (格式: "emulator-5564\tdevice")
                    string trimmed = line.Trim();
                    if (string.IsNullOrEmpty(trimmed)) continue;
                    var parts = trimmed.Split(new[] { '\t', ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length >= 2 && parts[1] == "device")
                    {
                        string serial = parts[0];
                        Console.Write($"[ADB] 使用已有裝置 {serial}...");
                        var result = RunCommand(_adbPath!, $"-s {serial} shell echo ok", 3000);
                        if (result.Output.Contains("ok"))
                        {
                            _connected = true;
                            Console.WriteLine($" 連接成功!");
                            FindGameProcess();
                            return true;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ADB] 命令錯誤: {ex.Message}");
            }
            return false;
        }

        // ═══════════════════════════════════════════════════════════
        // TCP 直接掃描
        // ═══════════════════════════════════════════════════════════
        private bool ConnectViaTcpScan(string? emulatorType)
        {
            int[] ports;

            if (emulatorType != null && EmulatorADBPorts.ContainsKey(emulatorType))
            {
                ports = EmulatorADBPorts[emulatorType];
                Console.WriteLine($"[ADB] TCP 掃描 {emulatorType} 端口: [{string.Join(", ", ports)}]");
            }
            else
            {
                ports = AllPorts;
                Console.WriteLine($"[ADB] TCP 全掃描 {ports.Length} 個端口...");
            }

            // 並行掃描（更快）
            var tasks = new List<Task<(int port, bool connected, TcpClient? client)>>();
            var cts = new CancellationTokenSource(10000); // 10秒總超時

            foreach (int port in ports)
            {
                int p = port; // 捕獲變數
                tasks.Add(Task.Run(() =>
                {
                    try
                    {
                        var client = new TcpClient();
                        var ar = client.BeginConnect("127.0.0.1", p, null, null);
                        bool ok = ar.AsyncWaitHandle.WaitOne(500); // 500ms/端口
                        if (ok && client.Connected)
                        {
                            client.EndConnect(ar);
                            return (p, true, client);
                        }
                        client.Close();
                    }
                    catch { }
                    return (p, false, null);
                }, cts.Token));
            }

            Task.WaitAll(tasks.ToArray());

            foreach (var task in tasks)
            {
                if (task.Result.connected && task.Result.client != null)
                {
                    _client = task.Result.client;
                    _stream = _client.GetStream();
                    _connected = true;
                    Console.WriteLine($"[ADB] TCP 連接成功! Port: {task.Result.port}");
                    FindGameProcess();
                    return true;
                }
            }

            return false;
        }

        // ═══════════════════════════════════════════════════════════
        // 找 Free Fire
        // ═══════════════════════════════════════════════════════════
        private void FindGameProcess()
        {
            Console.WriteLine("[ADB] 搜尋 Free Fire...");

            foreach (string pkg in FreeFirePackages)
            {
                var result = Shell($"pidof {pkg}");
                if (result.ExitCode == 0 && int.TryParse(result.Output.Trim(), out int pid) && pid > 0)
                {
                    _gamePid = pid;
                    Console.WriteLine($"[ADB] Free Fire ({pkg}) PID: {pid}");
                    return;
                }
            }

            // 備用: grep 搜尋
            var allProcs = Shell("ps -A 2>/dev/null | grep -iE 'free|garena'");
            if (!string.IsNullOrEmpty(allProcs.Output))
            {
                Console.WriteLine($"[ADB] 進程搜尋結果:\n{allProcs.Output.Trim()}");
                // 嘗試提取 PID
                foreach (string line in allProcs.Output.Split('\n'))
                {
                    string[] parts = line.Trim().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length > 1 && int.TryParse(parts[1], out int pid))
                    {
                        _gamePid = pid;
                        Console.WriteLine($"[ADB] Free Fire PID: {pid}");
                        return;
                    }
                }
            }

            Console.WriteLine("[ADB] Free Fire 未找到! 請確認遊戲已啟動");
        }

        // ═══════════════════════════════════════════════════════════
        // 找 libil2cpp.so
        // ═══════════════════════════════════════════════════════════
        public long FindLibIl2CppBase()
        {
            if (_gamePid <= 0) return 0;

            Console.WriteLine("[ADB] 搜尋 libil2cpp.so...");

            // 方法1: /proc/pid/maps
            var result = Shell($"cat /proc/{_gamePid}/maps 2>/dev/null | grep -i 'libil2cpp' | head -5");
            if (result.ExitCode == 0 && !string.IsNullOrEmpty(result.Output))
            {
                Console.WriteLine($"[ADB] Maps:\n{result.Output.Trim()}");
                foreach (string line in result.Output.Split('\n'))
                {
                    if (line.Contains("r-xp") || line.Contains("r--p"))
                    {
                        string addr = line.Split('-')[0];
                        if (long.TryParse(addr, System.Globalization.NumberStyles.HexNumber, null, out long baseAddr) && baseAddr > 0)
                        {
                            Console.WriteLine($"[ADB] libil2cpp.so base: 0x{baseAddr:X}");
                            return baseAddr;
                        }
                    }
                }
            }

            // 嘗試用 grep 替代
            var grepResult = Shell($"grep -i 'libil2cpp' /proc/{_gamePid}/maps 2>/dev/null | head -5");
            if (grepResult.ExitCode == 0 && !string.IsNullOrEmpty(grepResult.Output))
            {
                Console.WriteLine($"[ADB] Grep maps:\n{grepResult.Output.Trim()}");
                foreach (string line in grepResult.Output.Split('\n'))
                {
                    string addr = line.Split('-')[0].Trim();
                    if (long.TryParse(addr, System.Globalization.NumberStyles.HexNumber, null, out long baseAddr) && baseAddr > 0)
                    {
                        Console.WriteLine($"[ADB] libil2cpp.so base: 0x{baseAddr:X}");
                        return baseAddr;
                    }
                }
            }

            return 0;
        }

        // ═══════════════════════════════════════════════════════════
        // 備用搜尋 libil2cpp.so（更進階的方式）
        // ═══════════════════════════════════════════════════════════
        public long FindLibIl2CppAlt()
        {
            if (_gamePid <= 0) return 0;

            Console.WriteLine("[ADB] 嘗試備用搜尋 libil2cpp.so...");

            // 方法2: /proc/pid/smaps
            var smaps = Shell($"cat /proc/{_gamePid}/smaps 2>/dev/null | grep -i 'libil2cpp' | head -10");
            if (smaps.ExitCode == 0 && !string.IsNullOrEmpty(smaps.Output))
            {
                Console.WriteLine($"[ADB] SMaps:\n{smaps.Output.Trim()}");
                foreach (string line in smaps.Output.Split('\n'))
                {
                    if (line.Contains("-"))
                    {
                        string addr = line.Split('-')[0].Trim();
                        if (long.TryParse(addr, System.Globalization.NumberStyles.HexNumber, null, out long baseAddr) && baseAddr > 0)
                        {
                            Console.WriteLine($"[ADB] libil2cpp.so (smaps): 0x{baseAddr:X}");
                            return baseAddr;
                        }
                    }
                }
            }

            // 方法3: find 搜尋 APK 目錄
            var find = Shell($"find /data/app -name 'libil2cpp*' 2>/dev/null | head -5");
            if (find.ExitCode == 0 && !string.IsNullOrEmpty(find.Output))
            {
                Console.WriteLine($"[ADB] Found: {find.Output.Trim()}");
                // 取得 APK 路徑中的 lib 目錄
                string apkDir = find.Output.Trim().Split('\n')[0];
                string libDir = System.IO.Path.GetDirectoryName(apkDir) ?? "/data/app";
                var loadAddr = Shell($"cat /proc/{_gamePid}/maps 2>/dev/null | grep '{libDir}' | head -3");
                if (loadAddr.ExitCode == 0 && !string.IsNullOrEmpty(loadAddr.Output))
                {
                    Console.WriteLine($"[ADB] Lib dir maps:\n{loadAddr.Output.Trim()}");
                }
            }

            // 方法4: 讀取 /proc/pid/auxv
            var auxv = Shell($"cat /proc/{_gamePid}/auxv 2>/dev/null | head -20");
            if (auxv.ExitCode == 0 && !string.IsNullOrEmpty(auxv.Output))
            {
                Console.WriteLine($"[ADB] Auxv:\n{auxv.Output.Trim()}");
            }

            // 方法5: 直接掃描 ELF header
            Console.WriteLine("[ADB] 使用 ELF header 掃描...");
            return ScanForElfModule();
        }

        // ═══════════════════════════════════════════════════════════
        // ELF 掃描（透過 /proc/pid/maps 找 r-xp 區段）
        // ═══════════════════════════════════════════════════════════
        private long ScanForElfModule()
        {
            if (_gamePid <= 0) return 0;

            // 取得所有記憶體區段
            var maps = Shell($"cat /proc/{_gamePid}/maps 2>/dev/null | head -50");
            if (maps.ExitCode != 0 || string.IsNullOrEmpty(maps.Output)) return 0;

            Console.WriteLine($"[ADB] 掃描記憶體區段 ({maps.Output.Split('\n').Length} 個)...");

            // 讀取每個 r-xp 區段的開頭 4 bytes 檢查 ELF magic
            foreach (string line in maps.Output.Split('\n'))
            {
                if (!line.Contains("r-xp")) continue;

                string[] parts = line.Split('-');
                if (parts.Length < 2) continue;

                if (long.TryParse(parts[0].Trim(), System.Globalization.NumberStyles.HexNumber, null, out long startAddr) &&
                    long.TryParse(parts[1].Split(' ')[0].Trim(), System.Globalization.NumberStyles.HexNumber, null, out long endAddr))
                {
                    // 讀取 ELF magic bytes
                    byte[] header = ReadMemory(startAddr, 16);
                    if (header.Length >= 4 && header[0] == 0x7f && header[1] == 0x45 && header[2] == 0x4c && header[3] == 0x46)
                    {
                        Console.WriteLine($"[ADB] ELF 區段: 0x{startAddr:X} - 0x{endAddr:X}");
                        // 嘗試讀取 libil2cpp 路徑
                        var path = Shell($"cat /proc/{_gamePid}/maps 2>/dev/null | grep '0x{startAddr:X}' | head -1");
                        Console.WriteLine($"[ADB] 詳情: {path.Output.Trim()}");
                        return startAddr;
                    }
                }
            }

            return 0;
        }

        // ═══════════════════════════════════════════════════════════
        // 記憶體讀寫
        // ═══════════════════════════════════════════════════════════
        public byte[] ReadMemory(long address, int size)
        {
            if (_gamePid <= 0) return Array.Empty<byte>();

            // 使用 dd 讀取
            var result = Shell($"dd if=/proc/{_gamePid}/mem bs=1 skip={address} count={size} 2>/dev/null | od -A n -t x1 | tr -d ' \\n'");
            if (result.ExitCode == 0 && !string.IsNullOrEmpty(result.Output) && result.Output.Trim().Length >= 2)
            {
                return HexToBytes(result.Output.Trim());
            }

            // 回退到 xxd
            var xxd = Shell($"xxd -p -s {address} -l {size} /proc/{_gamePid}/mem 2>/dev/null");
            if (xxd.ExitCode == 0 && !string.IsNullOrEmpty(xxd.Output))
            {
                return HexToBytes(xxd.Output.Trim().Replace("\n", ""));
            }

            return Array.Empty<byte>();
        }

        public byte[] ReadMemoryFast(long address, int size) => ReadMemory(address, size);

        public bool WriteMemory(long address, byte[] data)
        {
            if (_gamePid <= 0) return false;

            string hex = BitConverter.ToString(data).Replace("-", "").ToLower();
            var result = Shell($"printf '\\x{hex}' | dd of=/proc/{_gamePid}/mem bs=1 seek={address} conv=notrunc 2>/dev/null");
            return result.ExitCode == 0;
        }

        // ═══════════════════════════════════════════════════════════
        // Shell 執行
        // ═══════════════════════════════════════════════════════════
        public (string Output, int ExitCode) Shell(string command)
        {
            if (_adbPath != null)
                return RunCommand(_adbPath, $"shell {command}", 5000);
            return ("", 1);
        }

        // ═══════════════════════════════════════════════════════════
        // 找 ADB 路徑
        // ═══════════════════════════════════════════════════════════
        private string? FindADB()
        {
            // 1. 搜尋已知路徑
            foreach (var paths in EmulatorADBPaths.Values)
            {
                foreach (string path in paths)
                {
                    if (File.Exists(path))
                    {
                        Console.WriteLine($"[ADB] 找到: {path}");
                        return path;
                    }
                }
            }

            // 2. 搜尋 PATH 中的 adb.exe
            try
            {
                var r = RunCommand("where", "adb.exe", 3000);
                if (r.ExitCode == 0 && !string.IsNullOrEmpty(r.Output))
                {
                    string first = r.Output.Split('\n')[0].Trim();
                    if (File.Exists(first))
                    {
                        Console.WriteLine($"[ADB] PATH 中找到: {first}");
                        return first;
                    }
                }
            }
            catch { }

            // 3. 搜尋常見 Android SDK 路徑
            string[] sdkPaths =
            {
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) + @"\AppData\Local\Android\Sdk\platform-tools\adb.exe",
                @"C:\Android\sdk\platform-tools\adb.exe",
                @"C:\Android\platform-tools\adb.exe",
                @"D:\Android\platform-tools\adb.exe",
                @"D:\Android\sdk\platform-tools\adb.exe",
            };
            foreach (string path in sdkPaths)
            {
                if (File.Exists(path))
                {
                    Console.WriteLine($"[ADB] SDK 找到: {path}");
                    return path;
                }
            }

            return null;
        }

        // ═══════════════════════════════════════════════════════════
        // 執行命令（帶超時）
        // ═══════════════════════════════════════════════════════════
        private static (string Output, int ExitCode) RunCommand(string fileName, string arguments, int timeoutMs = 5000)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = fileName,
                    Arguments = arguments,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                };
                using var proc = Process.Start(psi);
                if (proc == null) return ("", 1);
                string output = proc.StandardOutput.ReadToEnd();
                string error = proc.StandardError.ReadToEnd();
                proc.WaitForExit(timeoutMs);
                return (output + error, proc.ExitCode);
            }
            catch (Exception ex)
            {
                return (ex.Message, 1);
            }
        }

        private static byte[] HexToBytes(string hex)
        {
            hex = hex.Replace(" ", "").Replace("\n", "").Replace("\r", "").Replace("0x", "");
            if (hex.Length % 2 != 0) hex = "0" + hex;
            byte[] bytes = new byte[hex.Length / 2];
            for (int i = 0; i < bytes.Length; i++)
            {
                try { bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16); }
                catch { bytes[i] = 0; }
            }
            return bytes;
        }

        public void Dispose()
        {
            _stream?.Close();
            _client?.Close();
        }
    }
}

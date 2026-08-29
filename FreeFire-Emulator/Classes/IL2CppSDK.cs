using System.Diagnostics;
using System.Numerics;
using System.Runtime.InteropServices;
using FreeFire_Emulator.Data;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// IL2CPP SDK for Free Fire
    /// 支援 Windows 直接掃描 + ADB 備用方案
    /// </summary>
    internal class IL2CppSDK
    {
        // ═══════════════════════════════════════════════════════════
        // Windows API
        // ═══════════════════════════════════════════════════════════
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool Module32First(IntPtr hSnapshot, ref MODULEENTRY32 lpme);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool Module32Next(IntPtr hSnapshot, ref MODULEENTRY32 lpme);
        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr hObject);
        [DllImport("kernel32.dll")]
        static extern int VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);
        [DllImport("kernel32.dll")]
        static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int nSize, out int lpNumberOfBytesRead);

        [StructLayout(LayoutKind.Sequential)]
        struct MEMORY_BASIC_INFORMATION
        {
            public IntPtr BaseAddress;
            public IntPtr AllocationBase;
            public uint AllocationProtect;
            public IntPtr RegionSize;
            public uint State;
            public uint Protect;
            public uint Type;
        }

        const uint TH32CS_SNAPMODULE = 0x00000008;
        const uint TH32CS_SNAPMODULE32 = 0x00000010;
        const uint MEM_COMMIT = 0x1000;
        const uint PAGE_READWRITE = 0x04;
        const uint PAGE_EXECUTE_READWRITE = 0x40;
        const uint PAGE_READONLY = 0x02;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
        struct MODULEENTRY32
        {
            public uint dwSize;
            public uint th32ModuleID;
            public uint th32ProcessID;
            public uint GlblcntUsage;
            public uint ProccntUsage;
            public IntPtr modBaseAddr;
            public uint modBaseSize;
            public IntPtr hModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string szModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szExePath;
        }

        private Memory? memory;
        private Process? emulatorProcess;
        private ADBMemory? adbMemory;
        private bool useADB;

        public IntPtr ModuleBase { get; private set; }

        // ═══════════════════════════════════════════════════════════
        // 建構函式
        // ═══════════════════════════════════════════════════════════
        public IL2CppSDK(Memory mem, Process process)
        {
            memory = mem;
            emulatorProcess = process;
        }

        public IL2CppSDK(ADBMemory adb)
        {
            adbMemory = adb;
            useADB = true;
        }

        // ═══════════════════════════════════════════════════════════
        // 初始化
        // ═══════════════════════════════════════════════════════════
        public bool Initialize()
        {
            Console.WriteLine("[IL2CPP] Searching for libil2cpp.so...");

            if (useADB && adbMemory != null)
                return InitADB();

            if (memory != null && emulatorProcess != null)
                return InitDirect();

            return false;
        }

        // ═══════════════════════════════════════════════════════════
        // Windows 直接模式：掃描 HD-Player.exe 記憶體
        // ═══════════════════════════════════════════════════════════
        private bool InitDirect()
        {
            if (emulatorProcess == null) return false;

            // 方法1: Toolhelp32 找模組
            ModuleBase = FindModule("libil2cpp");
            if (ModuleBase != IntPtr.Zero)
            {
                Console.WriteLine($"[IL2CPP] Direct base (Toolhelp32): 0x{ModuleBase:X}");
                return true;
            }

            // 方法2: VirtualQueryEx 掃描 ELF headers
            Console.WriteLine("[IL2CPP] Toolhelp32 failed, scanning virtual memory...");
            ModuleBase = ScanForELFHeaders();
            if (ModuleBase != IntPtr.Zero)
            {
                Console.WriteLine($"[IL2CPP] Direct base (ELF scan): 0x{ModuleBase:X}");
                return true;
            }

            // 方法3: 用 ReadProcessMemory 掃描大型記憶體區段找 ELF magic
            Console.WriteLine("[IL2CPP] ELF scan failed, trying large memory scan...");
            ModuleBase = ScanLargeMemoryRegions();
            if (ModuleBase != IntPtr.Zero)
            {
                Console.WriteLine($"[IL2CPP] Direct base (large scan): 0x{ModuleBase:X}");
                return true;
            }

            Console.WriteLine("[IL2CPP] Direct: all methods failed");
            return false;
        }

        private IntPtr FindModule(string moduleName)
        {
            try
            {
                IntPtr snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, (uint)emulatorProcess!.Id);
                if (snap != IntPtr.Zero && snap != new IntPtr(-1))
                {
                    MODULEENTRY32 me = new();
                    me.dwSize = (uint)Marshal.SizeOf<MODULEENTRY32>();
                    if (Module32First(snap, ref me))
                    {
                        do
                        {
                            Console.WriteLine($"  Module: {me.szModule} @ 0x{me.modBaseAddr:X} size=0x{me.modBaseSize:X}");
                            if (me.szModule != null && me.szModule.Contains(moduleName, StringComparison.OrdinalIgnoreCase))
                            {
                                CloseHandle(snap);
                                return me.modBaseAddr;
                            }
                        } while (Module32Next(snap, ref me));
                    }
                    CloseHandle(snap);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[IL2CPP] Toolhelp32 error: {ex.Message}");
            }
            return IntPtr.Zero;
        }

        private IntPtr ScanForELFHeaders()
        {
            if (emulatorProcess == null) return IntPtr.Zero;
            IntPtr handle = emulatorProcess.Handle;
            IntPtr addr = IntPtr.Zero;
            int found = 0;

            Console.WriteLine("[IL2CPP] Scanning for ELF headers...");

            while (true)
            {
                if (VirtualQueryEx(handle, addr, out MEMORY_BASIC_INFORMATION mbi,
                    (uint)Marshal.SizeOf<MEMORY_BASIC_INFORMATION>()) == 0)
                    break;

                long sz = mbi.RegionSize.ToInt64();
                uint protect = mbi.Protect;
                bool readable = (protect & (PAGE_READWRITE | PAGE_READONLY | PAGE_EXECUTE_READWRITE)) != 0 ||
                                (protect == 0x02 || protect == 0x04 || protect == 0x40 || protect == 0x20);

                if (sz > 0 && sz < 0x10000000 && (mbi.State & MEM_COMMIT) != 0 && readable)
                {
                    try
                    {
                        byte[] header = new byte[4];
                        int bytesRead;
                        if (ReadProcessMemory(handle, mbi.BaseAddress, header, 4, out bytesRead) && bytesRead == 4)
                        {
                            // ELF magic: 7f 45 4c 46
                            if (header[0] == 0x7f && header[1] == 0x45 && header[2] == 0x4c && header[3] == 0x46)
                            {
                                found++;
                                Console.WriteLine($"  ELF found @ 0x{mbi.BaseAddress:X} size=0x{sz:X}");

                                // 讀取更多 header 資訊
                                byte[] fullHeader = new byte[52];
                                if (ReadProcessMemory(handle, mbi.BaseAddress, fullHeader, 52, out bytesRead) && bytesRead == 52)
                                {
                                    uint phoff = BitConverter.ToUInt32(fullHeader, 28);
                                    ushort phnum = BitConverter.ToUInt16(fullHeader, 44);
                                    ushort phentsize = BitConverter.ToUInt16(fullHeader, 42);
                                    Console.WriteLine($"  ELF: phoff=0x{phoff:X} phnum={phnum} phentsize={phentsize}");

                                    // 讀取第一個 program header 確認是 shared object
                                    if (phnum > 0 && phoff > 0)
                                    {
                                        byte[] phdr = new byte[32];
                                        long phdrAddr = mbi.BaseAddress.ToInt64() + phoff;
                                        if (ReadProcessMemory(handle, (IntPtr)phdrAddr, phdr, 32, out bytesRead) && bytesRead == 32)
                                        {
                                            uint p_type = BitConverter.ToUInt32(phdr, 0);
                                            Console.WriteLine($"  First phdr type={p_type}");
                                            // PT_LOAD = 1, PT_DYNAMIC = 2
                                            // 這很可能是 libil2cpp.so
                                            if (p_type == 1 || p_type == 2)
                                            {
                                                return mbi.BaseAddress;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch { }
                }

                long next = mbi.BaseAddress.ToInt64() + sz;
                if (next <= addr.ToInt64()) break;
                addr = (IntPtr)next;
            }

            Console.WriteLine($"[IL2CPP] Found {found} ELF files total");
            return IntPtr.Zero;
        }

        private IntPtr ScanLargeMemoryRegions()
        {
            if (emulatorProcess == null) return IntPtr.Zero;
            IntPtr handle = emulatorProcess.Handle;
            IntPtr addr = IntPtr.Zero;

            Console.WriteLine("[IL2CPP] Scanning large committed regions...");

            // 收集所有 committed + readable 的大區段
            var candidates = new List<(IntPtr addr, long size)>();

            while (true)
            {
                if (VirtualQueryEx(handle, addr, out MEMORY_BASIC_INFORMATION mbi,
                    (uint)Marshal.SizeOf<MEMORY_BASIC_INFORMATION>()) == 0)
                    break;

                long sz = mbi.RegionSize.ToInt64();
                if (sz > 0x100000 && (mbi.State & MEM_COMMIT) != 0) // > 1MB
                {
                    candidates.Add((mbi.BaseAddress, sz));
                }

                long next = mbi.BaseAddress.ToInt64() + sz;
                if (next <= addr.ToInt64()) break;
                addr = (IntPtr)next;
            }

            Console.WriteLine($"[IL2CPP] Found {candidates.Count} large regions (>1MB)");

            foreach (var (regionAddr, regionSize) in candidates)
            {
                try
                {
                    // 在每個大區段中搜尋 ELF magic
                    int readSize = (int)Math.Min(regionSize, 4096);
                    byte[] buffer = new byte[readSize];
                    int bytesRead;
                    if (ReadProcessMemory(handle, regionAddr, buffer, readSize, out bytesRead) && bytesRead >= 4)
                    {
                        // 在 buffer 中搜尋 ELF magic
                        for (int i = 0; i <= bytesRead - 4; i += 4) // 4-byte aligned
                        {
                            if (buffer[i] == 0x7f && buffer[i + 1] == 0x45 &&
                                buffer[i + 2] == 0x4c && buffer[i + 3] == 0x46)
                            {
                                IntPtr elfAddr = (IntPtr)(regionAddr.ToInt64() + i);
                                Console.WriteLine($"[IL2CPP] ELF in large region @ 0x{elfAddr:X}");
                                return elfAddr;
                            }
                        }
                    }
                }
                catch { }
            }

            return IntPtr.Zero;
        }

        // ═══════════════════════════════════════════════════════════
        // ADB 模式：用 ADB shell 取得記憶體映射
        // ═══════════════════════════════════════════════════════════
        private bool InitADB()
        {
            if (adbMemory == null) return false;

            // 方法1: /proc/pid/maps
            long baseAddr = adbMemory.FindLibIl2CppBase();
            if (baseAddr > 0)
            {
                ModuleBase = (IntPtr)baseAddr;
                Console.WriteLine($"[IL2CPP] ADB base (maps): 0x{ModuleBase:X}");
                return true;
            }

            // 方法2: 備用搜尋
            baseAddr = adbMemory.FindLibIl2CppAlt();
            if (baseAddr > 0)
            {
                ModuleBase = (IntPtr)baseAddr;
                Console.WriteLine($"[IL2CPP] ADB base (alt): 0x{ModuleBase:X}");
                return true;
            }

            // 方法3: 從 Windows 側掃描 HD-Player.exe
            Console.WriteLine("[IL2CPP] ADB methods failed, trying Windows scan...");
            if (emulatorProcess != null)
            {
                ModuleBase = ScanForELFHeaders();
                if (ModuleBase != IntPtr.Zero)
                {
                    Console.WriteLine($"[IL2CPP] ADB+Windows base: 0x{ModuleBase:X}");
                    return true;
                }
            }

            Console.WriteLine("[IL2CPP] All methods failed");
            return false;
        }

        // ═══════════════════════════════════════════════════════════
        // 輔助方法
        // ═══════════════════════════════════════════════════════════
        private IntPtr ReadPtr(long addr)
        {
            if (useADB && adbMemory != null)
            {
                byte[] d = adbMemory.ReadMemoryFast(addr, 8);
                return d.Length >= 8 ? (IntPtr)BitConverter.ToInt64(d, 0) : IntPtr.Zero;
            }
            if (memory != null) return memory.ReadPointer((IntPtr)addr);
            return IntPtr.Zero;
        }

        private float ReadF(long addr)
        {
            if (useADB && adbMemory != null)
            {
                byte[] d = adbMemory.ReadMemoryFast(addr, 4);
                return d.Length >= 4 ? BitConverter.ToSingle(d, 0) : 0;
            }
            if (memory != null) return memory.ReadFloat((IntPtr)addr);
            return 0;
        }

        private int ReadI(long addr)
        {
            if (useADB && adbMemory != null)
            {
                byte[] d = adbMemory.ReadMemoryFast(addr, 4);
                return d.Length >= 4 ? BitConverter.ToInt32(d, 0) : 0;
            }
            if (memory != null) return memory.ReadInt((IntPtr)addr);
            return 0;
        }

        private bool ReadB(long addr)
        {
            if (useADB && adbMemory != null)
            {
                byte[] d = adbMemory.ReadMemoryFast(addr, 1);
                return d.Length >= 1 && d[0] != 0;
            }
            if (memory != null) return memory.ReadBool((IntPtr)addr);
            return false;
        }

        private string ReadStr(long addr, int max = 32)
        {
            if (useADB && adbMemory != null)
            {
                byte[] d = adbMemory.ReadMemoryFast(addr, max);
                if (d.Length == 0) return "";
                int len = Array.IndexOf(d, (byte)0);
                return System.Text.Encoding.UTF8.GetString(d, 0, len < 0 ? max : len);
            }
            if (memory != null) return memory.ReadString((IntPtr)addr, max);
            return "";
        }

        private Vector3 ReadVec3(long addr)
        {
            float x = ReadF(addr);
            float y = ReadF(addr + 4);
            float z = ReadF(addr + 8);
            return new Vector3(x, y, z);
        }

        private long Ptr(IntPtr p) => p.ToInt64();

        // ═══════════════════════════════════════════════════════════
        // Game Facade
        // ═══════════════════════════════════════════════════════════
        public IntPtr GetGameFacade()
        {
            try
            {
                long ib = Ptr(ModuleBase) + Offsets.InitBase;
                long initBase = Ptr(ReadPtr(ib));
                return ReadPtr(initBase + Offsets.StaticClass);
            }
            catch { return IntPtr.Zero; }
        }

        public IntPtr GetCurrentMatch()
        {
            long f = Ptr(GetGameFacade());
            return f == 0 ? IntPtr.Zero : ReadPtr(f + Offsets.CurrentMatch);
        }

        public IntPtr GetLocalPlayer()
        {
            long m = Ptr(GetCurrentMatch());
            return m == 0 ? IntPtr.Zero : ReadPtr(m + Offsets.LocalPlayer);
        }

        // ═══════════════════════════════════════════════════════════
        // Player Data
        // ═══════════════════════════════════════════════════════════
        public string GetPlayerName(IntPtr p) => ReadStr(Ptr(p) + Offsets.Player_Name);
        public float GetHealth(IntPtr p) => ReadF(Ptr(p) + Offsets.Vida);
        public float GetMaxHealth(IntPtr p) => 100f;
        public bool IsPlayerDead(IntPtr p) => ReadB(Ptr(p) + Offsets.Player_IsDead);
        public bool IsVisible(IntPtr p) => ReadB(Ptr(p) + Offsets.Avatar_IsVisible);
        public bool IsTeammate(IntPtr p) => ReadB(Ptr(p) + Offsets.Avatar_Data_IsTeam);
        public bool IsBot(IntPtr p) => ReadB(Ptr(p) + Offsets.IsClientBot);

        // ═══════════════════════════════════════════════════════════
        // Positions & Bones
        // ═══════════════════════════════════════════════════════════
        public Vector3 GetHipPosition(IntPtr p)
        {
            long shadow = ReadPtr(Ptr(p) + Offsets.Player_ShadowBase).ToInt64();
            return shadow == 0 ? Vector3.Zero : ReadVec3(shadow);
        }

        public Vector3 GetHeadPosition(IntPtr p)
        {
            long shadow = ReadPtr(Ptr(p) + Offsets.Player_ShadowBase).ToInt64();
            return shadow == 0 ? Vector3.Zero : ReadVec3(shadow + 0x10);
        }

        public Vector3 GetSpinePosition(IntPtr p)
        {
            long shadow = ReadPtr(Ptr(p) + Offsets.Player_ShadowBase).ToInt64();
            return shadow == 0 ? Vector3.Zero : ReadVec3(shadow + 0x08);
        }

        public Vector3 GetLocalPlayerPosition()
        {
            IntPtr lp = GetLocalPlayer();
            return lp == IntPtr.Zero ? Vector3.Zero : GetHipPosition(lp);
        }

        // ═══════════════════════════════════════════════════════════
        // Camera / View
        // ═══════════════════════════════════════════════════════════
        public Vector3 GetViewAngles()
        {
            long lp = Ptr(GetLocalPlayer());
            if (lp == 0) return Vector3.Zero;
            long followCam = ReadPtr(lp + Offsets.FollowCamera).ToInt64();
            if (followCam == 0) return Vector3.Zero;
            return ReadVec3(followCam + Offsets.AimRotation);
        }

        public void SetAimRotation(Vector3 angles)
        {
            long lp = Ptr(GetLocalPlayer());
            if (lp == 0) return;
            long followCam = ReadPtr(lp + Offsets.FollowCamera).ToInt64();
            if (followCam == 0) return;
            if (useADB && adbMemory != null)
            {
                byte[] data = new byte[12];
                Buffer.BlockCopy(BitConverter.GetBytes(angles.X), 0, data, 0, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(angles.Y), 0, data, 4, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(angles.Z), 0, data, 8, 4);
                adbMemory.WriteMemory(followCam + Offsets.AimRotation, data);
            }
        }

        public void SetAimRotation(IntPtr player, float pitch, float yaw)
        {
            long lp = Ptr(player);
            if (lp == 0) return;
            long followCam = ReadPtr(lp + Offsets.FollowCamera).ToInt64();
            if (followCam == 0) return;
            if (useADB && adbMemory != null)
            {
                byte[] data = new byte[12];
                Buffer.BlockCopy(BitConverter.GetBytes(pitch), 0, data, 0, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(yaw), 0, data, 4, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(0f), 0, data, 8, 4);
                adbMemory.WriteMemory(followCam + Offsets.AimRotation, data);
            }
        }

        public Vector2 WorldToScreen(Vector3 worldPos)
        {
            return new Vector2(worldPos.X, worldPos.Y);
        }

        public void Dispose()
        {
            adbMemory?.Dispose();
        }
    }
}

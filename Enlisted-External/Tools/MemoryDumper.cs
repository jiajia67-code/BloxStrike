using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace Enlisted_External.Tools
{
    internal class MemoryDumper
    {
        [DllImport("kernel32.dll")]
        static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll")]
        static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesRead);

        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll")]
        static extern bool VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);

        [DllImport("kernel32.dll")]
        static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);

        [DllImport("kernel32.dll")]
        static extern bool Module32First(IntPtr hSnapshot, ref MODULEENTRY32 lpme);

        [DllImport("kernel32.dll")]
        static extern bool Module32Next(IntPtr hSnapshot, ref MODULEENTRY32 lpme);

        const int PROCESS_ALL_ACCESS = 0x1F0FFF;
        const uint TH32CS_SNAPMODULE = 0x00000008;
        const uint TH32CS_SNAPMODULE32 = 0x00000010;

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
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string szModule;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string szExePath;
        }

        static IntPtr processHandle;

        static StreamWriter? fileWriter;

        static void Log(string msg)
        {
            Console.WriteLine(msg);
            fileWriter?.WriteLine(msg);
        }

        public static void Run()
        {
            string dumpPath = Path.Combine(Path.GetDirectoryName(typeof(MemoryDumper).Assembly.Location) ?? ".", "..", "..", "..", "..", "enlisted_dump.txt");
            try { fileWriter = new StreamWriter(dumpPath); } catch { }
            Console.Title = "Enlisted Memory Dumper";
            Log("═══════════════════════════════════════════════════════");
            Log("     Enlisted Memory Dumper — Finding Real Offsets");
            Log("═══════════════════════════════════════════════════════");
            Log("");

            var proc = Process.GetProcessesByName("enlisted").FirstOrDefault();
            if (proc == null)
            {
                Log("[-] Enlisted not found!");
                return;
            }

            Log($"[+] Found Enlisted: PID {proc.Id}");
            processHandle = OpenProcess(PROCESS_ALL_ACCESS, false, proc.Id);

            if (processHandle == IntPtr.Zero)
            {
                Log($"[-] Cannot open process (error: {Marshal.GetLastWin32Error()})");
                return;
            }
            Log("[+] Process handle opened");

            // Find module using Toolhelp32 instead of Process.MainModule
            IntPtr baseAddr = FindMainModule(proc.Id);
            if (baseAddr == IntPtr.Zero)
            {
                Log("[-] Cannot find enlisted.exe module via Toolhelp32!");
                Log("[*] Trying PE header scan...");
                baseAddr = ScanForPEHeader();
            }

            if (baseAddr == IntPtr.Zero)
            {
                Log("[-] Cannot find module base via any method!");
                Log("[*] Trying direct RVA reads with known offsets...");
                TryDirectRVAs();
                CloseHandle(processHandle);
                return;
            }

            int moduleSize = GetModuleSize(baseAddr);
            Log($"[+] Base: 0x{baseAddr:X}");
            Log($"[+] Size: 0x{moduleSize:X} ({moduleSize / 1024 / 1024}MB)");
            Log("");

            // ── Scan 1: Find "globtm_psf_0" string ──
            Log("═══ SCAN 1: Finding View Matrix (globtm_psf_0) ═══");
            IntPtr globtmPtr = FindStringInModule(baseAddr, moduleSize, "globtm_psf_0");
            if (globtmPtr != IntPtr.Zero)
            {
                long rva = globtmPtr.ToInt64() - baseAddr.ToInt64();
                Log($"  [+] String found at RVA 0x{rva:X} (abs: 0x{globtmPtr:X})");
                // Try to read nearby pointers
                for (int off = 0; off < 0x100; off += 8)
                {
                    IntPtr candidate = ReadPointer(globtmPtr + off);
                    if (candidate.ToInt64() > 0x10000 && candidate.ToInt64() < 0x7FFFFFFFFFFF)
                    {
                        Log($"  [+] Pointer at +0x{off:X}: 0x{candidate:X}");
                    }
                }
            }
            else
            {
                Log("  [-] String NOT found in module");
            }
            Log("");

            // ── Scan 2: Find "ecs::EntityManager" string ──
            Log("═══ SCAN 2: Finding ECS EntityManager ═══");
            IntPtr emStr = FindStringInModule(baseAddr, moduleSize, "ecs::EntityManager");
            if (emStr != IntPtr.Zero)
            {
                long rva = emStr.ToInt64() - baseAddr.ToInt64();
                Log($"  [+] String found at RVA 0x{rva:X}");
            }
            Log("");

            // ── Scan 3: Find "camera__look_at" string ──
            Log("═══ SCAN 3: Finding Camera Position ═══");
            IntPtr camStr = FindStringInModule(baseAddr, moduleSize, "camera__look_at");
            if (camStr != IntPtr.Zero)
            {
                long rva = camStr.ToInt64() - baseAddr.ToInt64();
                Log($"  [+] String found at RVA 0x{rva:X}");
            }
            Log("");

            // ── Scan 4: Find Component Strings ──
            Log("═══ SCAN 4: Finding ECS Component Strings ═══");
            string[] componentStrings = {
                "isAlive", "transform", "human_net_phys", "team",
                "hitpoints", "animchar", "velocity", "squad", "stamina",
                "gun", "vehicle", "binded_camera", "is_visible",
                "is_reloading", "is_downed", "gun_total_ammo"
            };
            foreach (var str in componentStrings)
            {
                IntPtr addr = FindStringInModule(baseAddr, moduleSize, str);
                if (addr != IntPtr.Zero)
                {
                    long rva = addr.ToInt64() - baseAddr.ToInt64();
                    Log($"  [+] \"{str}\" at RVA 0x{rva:X}");
                }
            }
            Log("");

            // ── Scan 5: Read current memory around known RVAs ──
            Log("═══ SCAN 5: Testing Known RVAs ═══");
            uint[] knownRvas = {
                0x5F8D820, // globtm_psf_0
                0x5F8D840, // globtm_psf_1
                0x5F8D860, // globtm_psf_2
                0x5F8D880, // globtm_psf_3
                0x5E45AD0, // camera_pos
                0x5DA1B68, // entity_manager
                0x5DA1BE8, // entity_array
                0x5DA1BF0, // max_entities
                // Newer build offsets (R3bornX)
                0x05FFB2E0, // globtm_psf_0 (newer)
                0x05FFB300, // globtm_psf_1 (newer)
                0x05FFB320, // globtm_psf_2 (newer)
                0x05FFB340, // globtm_psf_3 (newer)
                0x05EA3D48, // camera_pos (newer)
                0x05DFF258, // entity_manager (newer)
            };

            foreach (uint rva in knownRvas)
            {
                IntPtr addr = baseAddr + (int)rva;
                try
                {
                    IntPtr val = ReadPointer(addr);
                    bool looksValid = val.ToInt64() > 0x10000 && val.ToInt64() < 0x7FFFFFFFFFFF;
                    Log($"  [RVA 0x{rva:X}] = 0x{val:X} {(looksValid ? "✓ VALID" : "— invalid")}");
                }
                catch
                {
                    Log($"  [RVA 0x{rva:X}] = ??? (read failed)");
                }
            }
            Log("");

            // ── Scan 6: Search for float patterns ──
            Log("═══ SCAN 6: Scanning for View Matrix Candidates ═══");
            ScanForFloatPointers(baseAddr, moduleSize);

            Log("");
            Log("═══ SCAN COMPLETE ═══");
            CloseHandle(processHandle);
            fileWriter?.Flush();
            fileWriter?.Close();
        }

        // ============================================================
        // Module Enumeration via Toolhelp32
        // ============================================================

        static IntPtr FindMainModule(int processId)
        {
            // Method 1: Try Toolhelp32
            IntPtr snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, (uint)processId);
            if (snap != IntPtr.Zero && snap.ToInt64() != -1)
            {
                MODULEENTRY32 me = new();
                me.dwSize = (uint)Marshal.SizeOf<MODULEENTRY32>();

                IntPtr mainModule = IntPtr.Zero;
                Log("[+] Enumerating modules via Toolhelp32...");

                if (Module32First(snap, ref me))
                {
                    do
                    {
                        Log($"    {me.szModule} @ 0x{me.modBaseAddr:X} (size: 0x{me.modBaseSize:X})");
                        if (me.szModule != null && me.szModule.Contains("enlisted", StringComparison.OrdinalIgnoreCase))
                            mainModule = me.modBaseAddr;
                        if (mainModule == IntPtr.Zero && me.modBaseAddr != IntPtr.Zero)
                            mainModule = me.modBaseAddr;
                    }
                    while (Module32Next(snap, ref me));
                }
                CloseHandle(snap);
                if (mainModule != IntPtr.Zero) return mainModule;
            }

            Log("  [-] Toolhelp32 blocked by BattlEye, trying memory scan...");

            // Method 2: Scan memory for MZ header (PE executable)
            return ScanForPEHeader();
        }

        static IntPtr ScanForPEHeader()
        {
            Log("  [+] Scanning virtual memory for PE headers...");
            IntPtr addr = IntPtr.Zero;
            int found = 0;
            
            while (addr.ToInt64() < 0x7FFFFFFFFFFF)
            {
                if (!VirtualQueryEx(processHandle, addr, out MEMORY_BASIC_INFORMATION mbi, (uint)Marshal.SizeOf<MEMORY_BASIC_INFORMATION>()))
                    break;

                if (mbi.State == 0x1000) // MEM_COMMIT
                {
                    try
                    {
                        byte[] header = ReadBytes(mbi.BaseAddress, 2);
                        if (header[0] == 0x4D && header[1] == 0x5A) // MZ
                        {
                            // Verify PE signature
                            byte[] peCheck = ReadBytes(mbi.BaseAddress, 0x200);
                            int peOffset = BitConverter.ToInt32(peCheck, 0x3C);
                            if (peOffset > 0 && peOffset < 0x200)
                            {
                                byte[] peSig = ReadBytes(mbi.BaseAddress + peOffset, 4);
                                if (peSig[0] == 0x50 && peSig[1] == 0x45) // PE\0\0
                                {
                                    int sizeOfImage = BitConverter.ToInt32(peCheck, peOffset + 80);
                                    Log($"  [+] Found PE @ 0x{mbi.BaseAddress:X} (sizeOfImage: 0x{sizeOfImage:X})");
                                    found++;
                                    
                                    // Check if this is the main EXE (large module)
                                    if (sizeOfImage > 0x1000000) // > 16MB
                                    {
                                        Log($"  [+] This looks like enlisted.exe!");
                                        return mbi.BaseAddress;
                                    }
                                }
                            }
                        }
                    }
                    catch { }
                }

                addr = (IntPtr)(mbi.BaseAddress.ToInt64() + mbi.RegionSize.ToInt64());
                if (found > 50) break; // safety limit
            }
            
            Log($"  [-] Found {found} PE headers, none matched enlisted.exe size");
            return IntPtr.Zero;
        }

        // ============================================================
        // String Scanning
        // ============================================================

        static IntPtr FindStringInModule(IntPtr baseAddr, int moduleSize, string searchString)
        {
            byte[] target = Encoding.ASCII.GetBytes(searchString);
            int readSize = Math.Min(moduleSize, 0x2000000); // up to 32MB
            byte[] moduleBytes = ReadBytes(baseAddr, readSize);

            for (int i = 0; i < moduleBytes.Length - target.Length; i++)
            {
                bool match = true;
                for (int j = 0; j < target.Length; j++)
                {
                    if (moduleBytes[i + j] != target[j]) { match = false; break; }
                }
                if (match)
                    return baseAddr + i;
            }

            return IntPtr.Zero;
        }

        // ============================================================
        // View Matrix Candidate Search
        // ============================================================

        static void ScanForFloatPointers(IntPtr baseAddr, int moduleSize)
        {
            int readSize = Math.Min(moduleSize, 0x800000);
            byte[] data = ReadBytes(baseAddr, readSize);

            int found = 0;
            for (int i = 0; i < data.Length - 32; i += 8)
            {
                long p0 = BitConverter.ToInt64(data, i);
                long p1 = BitConverter.ToInt64(data, i + 8);
                long p2 = BitConverter.ToInt64(data, i + 16);
                long p3 = BitConverter.ToInt64(data, i + 24);

                if (p0 > 0x10000 && p0 < 0x7FFFFFFFFFFF &&
                    p1 > 0x10000 && p1 < 0x7FFFFFFFFFFF &&
                    p2 > 0x10000 && p2 < 0x7FFFFFFFFFFF &&
                    p3 > 0x10000 && p3 < 0x7FFFFFFFFFFF &&
                    Math.Abs(p1 - p0) < 0x1000 &&
                    Math.Abs(p2 - p1) < 0x1000 &&
                    Math.Abs(p3 - p2) < 0x1000)
                {
                    try
                    {
                        float[] f0 = ReadFloat4((IntPtr)p0);
                        float[] f1 = ReadFloat4((IntPtr)p1);
                        float[] f2 = ReadFloat4((IntPtr)p2);
                        float[] f3 = ReadFloat4((IntPtr)p3);

                        float[] all = f0.Concat(f1).Concat(f2).Concat(f3).ToArray();
                        int nonZero = all.Count(f => Math.Abs(f) > 0.001f);
                        int inRange = all.Count(f => Math.Abs(f) < 1000f && !float.IsNaN(f) && !float.IsInfinity(f));

                        if (nonZero >= 8 && inRange >= 12)
                        {
                            long rva = (baseAddr + i).ToInt64() - baseAddr.ToInt64();
                            Log($"  [+] Candidate at RVA 0x{rva:X}");
                            Log($"      Row0: [{f0[0]:F4}, {f0[1]:F4}, {f0[2]:F4}, {f0[3]:F4}]");
                            Log($"      Row1: [{f1[0]:F4}, {f1[1]:F4}, {f1[2]:F4}, {f1[3]:F4}]");
                            Log($"      Row2: [{f2[0]:F4}, {f2[1]:F4}, {f2[2]:F4}, {f2[3]:F4}]");
                            Log($"      Row3: [{f3[0]:F4}, {f3[1]:F4}, {f3[2]:F4}, {f3[3]:F4}]");
                            found++;
                            if (found >= 5) break;
                        }
                    }
                    catch { }
                }
            }

            if (found == 0)
                Log("  [-] No view matrix candidates found");
        }

        // ============================================================
        // Read Helpers
        // ============================================================

        static float[] ReadFloat4(IntPtr addr)
        {
            byte[] buf = ReadBytes(addr, 16);
            float[] result = new float[4];
            Buffer.BlockCopy(buf, 0, result, 0, 16);
            return result;
        }

        static IntPtr ReadPointer(IntPtr addr) => Read<IntPtr>(addr);

        static T Read<T>(IntPtr addr) where T : struct
        {
            int size = Marshal.SizeOf<T>();
            byte[] buf = new byte[size];
            ReadProcessMemory(processHandle, addr, buf, size, out _);
            GCHandle h = GCHandle.Alloc(buf, GCHandleType.Pinned);
            T result = Marshal.PtrToStructure<T>(h.AddrOfPinnedObject());
            h.Free();
            return result;
        }

        static byte[] ReadBytes(IntPtr addr, int size)
        {
            byte[] buf = new byte[size];
            ReadProcessMemory(processHandle, addr, buf, size, out _);
            return buf;
        }

        static void TryDirectRVAs()
        {
            // Scan ALL readable memory for key strings
            Log("");
            Log("═══ SCAN: Scanning ALL memory for key strings ═══");
            
            string[] targets = { "globtm_psf_0", "ecs::EntityManager", "camera__look_at", "isAlive", "transform", "human_net_phys" };
            
            IntPtr addr = IntPtr.Zero;
            int regionCount = 0;
            
            while (addr.ToInt64() < 0x7FFFFFFFFFFF)
            {
                if (!VirtualQueryEx(processHandle, addr, out MEMORY_BASIC_INFORMATION mbi, (uint)Marshal.SizeOf<MEMORY_BASIC_INFORMATION>()))
                    break;

                if (mbi.State == 0x1000 && (mbi.Protect & 0x04) != 0) // MEM_COMMIT, PAGE_READABLE
                {
                    int regionSize = (int)mbi.RegionSize;
                    if (regionSize > 0 && regionSize < 0x1000000) // max 16MB per read
                    {
                        try
                        {
                            byte[] data = ReadBytes(mbi.BaseAddress, regionSize);
                            foreach (var target in targets)
                            {
                                byte[] pattern = Encoding.ASCII.GetBytes(target);
                                for (int i = 0; i < data.Length - pattern.Length; i++)
                                {
                                    bool match = true;
                                    for (int j = 0; j < pattern.Length; j++)
                                    {
                                        if (data[i + j] != pattern[j]) { match = false; break; }
                                    }
                                    if (match)
                                    {
                                        IntPtr foundAddr = mbi.BaseAddress + i;
                                        Log($"  [+] \"{target}\" found at 0x{foundAddr:X}");
                                        
                                        // If we found globtm_psf_0, this region might be .rdata
                                        if (target == "globtm_psf_0")
                                        {
                                            // Read nearby to find pointer table
                                            for (int off = 0; off < Math.Min(0x200, regionSize - i - 32); off += 8)
                                            {
                                                long ptr = BitConverter.ToInt64(data, i + off);
                                                if (ptr > 0x10000 && ptr < 0x7FFFFFFFFFFF)
                                                {
                                                    Log($"    Nearby pointer at +0x{off:X}: 0x{ptr:X}");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        catch { }
                    }
                }

                addr = (IntPtr)(mbi.BaseAddress.ToInt64() + mbi.RegionSize.ToInt64());
                regionCount++;
                if (regionCount > 50000) break; // safety
            }
            
            Log($"  Scanned {regionCount} memory regions");
            
            // Also try reading from known absolute addresses
            Log("");
            Log("═══ SCAN: Trying absolute addresses ═══");
            // Some games load at predictable addresses due to ASLR disabled
            long[] candidates = { 0x140000000, 0x7FF600000000, 0x7FF700000000 };
            foreach (long cand in candidates)
            {
                try
                {
                    byte[] header = ReadBytes((IntPtr)cand, 2);
                    if (header[0] == 0x4D && header[1] == 0x5A)
                    {
                        Log($"  [+] PE found at 0x{cand:X}");
                    }
                }
                catch { }
            }
        }

        static int GetModuleSize(IntPtr baseAddr)
        {
            try
            {
                byte[] header = ReadBytes(baseAddr, 0x200);
                int peOffset = BitConverter.ToInt32(header, 0x3C);
                return BitConverter.ToInt32(header, peOffset + 80);
            }
            catch { return 0x1000000; }
        }
    }
}

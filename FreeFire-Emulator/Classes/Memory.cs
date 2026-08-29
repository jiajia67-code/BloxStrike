using System.Diagnostics;
using System.Runtime.InteropServices;

namespace FreeFire_Emulator.Classes
{
    internal class Memory
    {
        [DllImport("kernel32.dll")]
        static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll")]
        static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesRead);

        [DllImport("kernel32.dll")]
        static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesWritten);

        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr hObject);

        const int PROCESS_ALL_ACCESS = 0x1F0FFF;

        IntPtr processHandle;
        Process gameProcess;

        public bool IsValid => processHandle != IntPtr.Zero;

        public Memory(Process process)
        {
            gameProcess = process;
            processHandle = OpenProcess(PROCESS_ALL_ACCESS, false, process.Id);
        }

        public T Read<T>(IntPtr address) where T : struct
        {
            int size = Marshal.SizeOf<T>();
            byte[] buffer = new byte[size];
            ReadProcessMemory(processHandle, address, buffer, size, out _);
            GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);
            T result = Marshal.PtrToStructure<T>(handle.AddrOfPinnedObject());
            handle.Free();
            return result;
        }

        public byte[] ReadBytes(IntPtr address, int size)
        {
            byte[] buffer = new byte[size];
            ReadProcessMemory(processHandle, address, buffer, size, out _);
            return buffer;
        }

        public string ReadString(IntPtr address, int maxLength = 128)
        {
            byte[] buffer = ReadBytes(address, maxLength);
            int length = Array.IndexOf(buffer, (byte)0);
            if (length < 0) length = maxLength;
            return System.Text.Encoding.UTF8.GetString(buffer, 0, length);
        }

        public IntPtr ReadPointer(IntPtr address) => Read<IntPtr>(address);
        public float ReadFloat(IntPtr address) => Read<float>(address);
        public int ReadInt(IntPtr address) => Read<int>(address);
        public bool ReadBool(IntPtr address) => Read<byte>(address) != 0;

        public void Write<T>(IntPtr address, T value) where T : struct
        {
            int size = Marshal.SizeOf<T>();
            byte[] buffer = new byte[size];
            GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);
            Marshal.StructureToPtr(value, handle.AddrOfPinnedObject(), false);
            handle.Free();
            WriteProcessMemory(processHandle, address, buffer, size, out _);
        }

        public bool WriteBytes(IntPtr address, byte[] bytes)
        {
            return WriteProcessMemory(processHandle, address, bytes, bytes.Length, out _);
        }

        public bool WriteBytes(long address, byte[] bytes)
        {
            return WriteProcessMemory(processHandle, new IntPtr(address), bytes, bytes.Length, out _);
        }

        public IntPtr GetModuleBase(string moduleName)
        {
            foreach (ProcessModule module in gameProcess.Modules)
            {
                if (module.ModuleName.Contains(moduleName, StringComparison.OrdinalIgnoreCase))
                    return module.BaseAddress;
            }
            return IntPtr.Zero;
        }

        /// <summary>
        /// 在模組記憶體中搜尋 pattern，回傳所有匹配位置
        /// </summary>
        public long[] FindPatternAll(byte[] pattern, string moduleName = null)
        {
            IntPtr startAddr = IntPtr.Zero;
            long scanSize = 0;

            if (moduleName != null)
            {
                startAddr = GetModuleBase(moduleName);
                foreach (ProcessModule module in gameProcess.Modules)
                {
                    if (module.ModuleName.Contains(moduleName, StringComparison.OrdinalIgnoreCase))
                    {
                        scanSize = module.ModuleMemorySize;
                        break;
                    }
                }
            }
            else
            {
                // 掃描整個模擬器記憶體空間
                startAddr = gameProcess.MainModule.BaseAddress;
                scanSize = gameProcess.MainModule.ModuleMemorySize;
            }

            if (startAddr == IntPtr.Zero || scanSize == 0) return null;

            List<long> results = new List<long>();
            const int CHUNK_SIZE = 65536; // 64KB chunks
            int overlap = pattern.Length - 1;
            byte[] prevChunk = null;

            for (long offset = 0; offset < scanSize; offset += CHUNK_SIZE - overlap)
            {
                int readSize = (int)Math.Min(CHUNK_SIZE, scanSize - offset);
                byte[] chunk = ReadBytes(IntPtr.Add(startAddr, (int)offset), readSize);

                if (chunk == null || chunk.Length == 0) continue;

                // 合併前一個 chunk 的尾巴以避免跨 chunk 遺漏
                byte[] searchBuffer = chunk;
                if (prevChunk != null)
                {
                    searchBuffer = new byte[prevChunk.Length + chunk.Length];
                    Buffer.BlockCopy(prevChunk, 0, searchBuffer, 0, prevChunk.Length);
                    Buffer.BlockCopy(chunk, 0, searchBuffer, prevChunk.Length, chunk.Length);
                }

                // 搜尋 pattern
                for (int i = 0; i < searchBuffer.Length - pattern.Length + 1; i++)
                {
                    bool found = true;
                    for (int j = 0; j < pattern.Length; j++)
                    {
                        if (searchBuffer[i + j] != pattern[j])
                        {
                            found = false;
                            break;
                        }
                    }
                    if (found)
                    {
                        long addr = (long)startAddr + offset + i;
                        if (prevChunk != null) addr -= prevChunk.Length;
                        if (addr >= (long)startAddr && addr < (long)startAddr + scanSize)
                        {
                            results.Add(addr);
                        }
                    }
                }

                prevChunk = chunk;
            }

            return results.Count > 0 ? results.ToArray() : null;
        }

        /// <summary>
        /// 單一 pattern 搜尋，回傳第一個匹配位置
        /// </summary>
        public long FindPattern(byte[] pattern, string moduleName = null)
        {
            long[] results = FindPatternAll(pattern, moduleName);
            return results != null && results.Length > 0 ? results[0] : 0;
        }

        public void Dispose()
        {
            if (processHandle != IntPtr.Zero)
            {
                CloseHandle(processHandle);
                processHandle = IntPtr.Zero;
            }
        }
    }
}

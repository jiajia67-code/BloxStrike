using System.Diagnostics;
using System.Runtime.InteropServices;

namespace DeltaForce_External.Classes
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

        [DllImport("kernel32.dll")]
        static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, int dwSize, uint flAllocationType, uint flProtect);

        [DllImport("kernel32.dll")]
        static extern bool VirtualFreeEx(IntPtr hProcess, IntPtr lpAddress, int dwSize, uint dwFreeType);

        const int PROCESS_VM_READ = 0x0010;
        const int PROCESS_VM_WRITE = 0x0020;
        const int PROCESS_VM_OPERATION = 0x0008;
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

        public IntPtr ReadPointer(IntPtr address)
        {
            return Read<IntPtr>(address);
        }

        public float ReadFloat(IntPtr address)
        {
            return Read<float>(address);
        }

        public int ReadInt(IntPtr address)
        {
            return Read<int>(address);
        }

        public bool ReadBool(IntPtr address)
        {
            return Read<byte>(address) != 0;
        }

        public void Write<T>(IntPtr address, T value) where T : struct
        {
            int size = Marshal.SizeOf<T>();
            byte[] buffer = new byte[size];
            GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);
            Marshal.StructureToPtr(value, handle.AddrOfPinnedObject(), false);
            handle.Free();
            WriteProcessMemory(processHandle, address, buffer, size, out _);
        }

        public void WriteBytes(IntPtr address, byte[] bytes)
        {
            WriteProcessMemory(processHandle, address, bytes, bytes.Length, out _);
        }

        public IntPtr Allocate(int size)
        {
            return VirtualAllocEx(processHandle, IntPtr.Zero, size, 0x1000, 0x40);
        }

        public void Free(IntPtr address, int size)
        {
            VirtualFreeEx(processHandle, address, size, 0x8000);
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

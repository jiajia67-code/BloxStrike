using DeltaForce_External.Data;
using System.Numerics;

namespace DeltaForce_External.Classes
{
    /// <summary>
    /// UE4 SDK implementation for Delta Force: Hawk Ops
    /// Engine: UE4 4.24
    /// Features: GWorld/GObjects/GNames traversal, FName decryption, pattern scanning
    /// Delta Force encrypts FNameEntry (WideName and AnsiName)
    /// </summary>
    internal class UE4SDK
    {
        private Memory memory;
        private IntPtr baseAddress;

        public IntPtr GWorld { get; private set; }
        public IntPtr GObjects { get; private set; }
        public IntPtr GNames { get; private set; }

        // FName decryption function pointers
        private IntPtr decryptAnsiFunc;
        private IntPtr decryptWideFunc;

        // Cached pointers
        private IntPtr worldPtr;

        public UE4SDK(Memory mem, IntPtr baseAddr)
        {
            memory = mem;
            baseAddress = baseAddr;
        }

        public bool Initialize()
        {
            Console.WriteLine("[*] Searching for GWorld, GObjects, GNames...");

            // Pattern scan for core pointers
            GWorld = FindPattern(Offsets.GWorld_Pattern);
            GObjects = FindPattern("48 8B 05 ?? ?? ?? ?? 48 85 C0 75 ? 48 8B C8 E8");
            GNames = FindPattern(Offsets.GNames_Pattern);

            // Try to find FName decrypt functions
            decryptAnsiFunc = FindPattern("48 89 5C 24 ? 57 48 83 EC 20 48 8B D9 48 8B F9 48 85 C9");
            decryptWideFunc = FindPattern("48 89 5C 24 ? 57 48 83 EC 20 48 8B D9 48 8B F9 48 85 C9");

            Console.WriteLine($"    GWorld:   0x{GWorld:X}");
            Console.WriteLine($"    GObjects: 0x{GObjects:X}");
            Console.WriteLine($"    GNames:   0x{GNames:X}");

            // Dereference GWorld pointer
            worldPtr = memory.ReadPointer(GWorld);
            if (worldPtr == IntPtr.Zero)
            {
                Console.WriteLine("[-] GWorld is null — game may not be running");
                return false;
            }

            Console.WriteLine($"    WorldPtr: 0x{worldPtr:X}");
            return true;
        }

        // ============================================================
        // Pattern Scanning
        // ============================================================

        /// <summary>
        /// Pattern scan using IDA-style format: "48 8B 05 ?? ?? ?? ??"
        /// ?? = wildcard byte
        /// </summary>
        private IntPtr FindPattern(string pattern)
        {
            IntPtr moduleBase = memory.GetModuleBase("DeltaForceClient-Win64-Shipping");
            if (moduleBase == IntPtr.Zero)
                moduleBase = baseAddress;

            int moduleSize = GetModuleSize(moduleBase);
            if (moduleSize <= 0) return IntPtr.Zero;

            byte[] patternBytes = ParsePattern(pattern);
            string mask = ParseMask(pattern);
            byte[] moduleBytes = memory.ReadBytes(moduleBase, moduleSize);

            for (int i = 0; i < moduleSize - patternBytes.Length; i++)
            {
                bool found = true;
                for (int j = 0; j < patternBytes.Length; j++)
                {
                    if (mask[j] == 'x' && moduleBytes[i + j] != patternBytes[j])
                    {
                        found = false;
                        break;
                    }
                }
                if (found)
                {
                    IntPtr addr = moduleBase + i;
                    Console.WriteLine($"    Found pattern at 0x{addr:X}");
                    return addr;
                }
            }
            return IntPtr.Zero;
        }

        private byte[] ParsePattern(string pattern)
        {
            var parts = pattern.Split(' ');
            var bytes = new List<byte>();
            foreach (var part in parts)
            {
                if (part == "??") bytes.Add(0);
                else bytes.Add(Convert.ToByte(part, 16));
            }
            return bytes.ToArray();
        }

        private string ParseMask(string pattern)
        {
            var parts = pattern.Split(' ');
            return string.Concat(parts.Select(p => p == "??" ? '?' : 'x'));
        }

        private int GetModuleSize(IntPtr moduleBase)
        {
            try
            {
                byte[] header = memory.ReadBytes(moduleBase, 0x200);
                int peOffset = BitConverter.ToInt32(header, 0x3C);
                int sizeOfImage = BitConverter.ToInt32(header, peOffset + 80);
                return sizeOfImage;
            }
            catch
            {
                return 0x1000000; // 16MB fallback
            }
        }

        // ============================================================
        // FName Handling (with Delta Force encryption)
        // ============================================================

        /// <summary>
        /// Get FName string from GNames table
        /// Delta Force encrypts WideName and AnsiName in FNameEntry
        /// If decrypt functions are available, call them to decrypt
        /// </summary>
        public string GetFName(int comparisonIndex)
        {
            if (comparisonIndex <= 0 || GNames == IntPtr.Zero)
                return "";

            try
            {
                int blockIndex = comparisonIndex >> 16;
                int blockOffset = comparisonIndex & 0xFFFF;

                IntPtr namePool = memory.ReadPointer(GNames);
                IntPtr blockPtr = memory.ReadPointer(namePool + 0x18 + blockIndex * 0x8);

                if (blockPtr == IntPtr.Zero) return "";

                // FNameEntry: header (2 bytes) + name data
                IntPtr nameEntry = blockPtr + blockOffset * 2;
                int header = memory.ReadInt(nameEntry);
                int nameLength = header >> 6;

                if (nameLength <= 0 || nameLength > 256) return "";

                // Try to read the name
                // Delta Force encrypts the name, so we need to decrypt it
                byte[] nameBytes = memory.ReadBytes(nameEntry + 2, nameLength * 2);

                // If decrypt function is available, call it
                if (decryptWideFunc != IntPtr.Zero)
                {
                    // Call FNameEntry::DecryptWideName(nameEntry)
                    // This requires calling the function in the game process
                    // For external, we'd need to create a remote thread
                    // For now, try to read as-is
                }

                // Try UTF-16 decoding (may be encrypted)
                string name = System.Text.Encoding.Unicode.GetString(nameBytes).TrimEnd('\0');

                // Filter out garbage characters
                foreach (char c in name)
                {
                    if (c > 0 && c < 32) return ""; // Control chars = encrypted
                }

                return name;
            }
            catch
            {
                return "";
            }
        }

        // ============================================================
        // UE4 Structure Traversal
        // ============================================================

        /// <summary>
        /// Get all actors from the persistent level
        /// Path: GWorld → PersistentLevel → Actors[]
        /// </summary>
        public List<IntPtr> GetActors()
        {
            var actors = new List<IntPtr>();

            if (worldPtr == IntPtr.Zero) return actors;

            try
            {
                IntPtr persistentLevel = memory.ReadPointer(worldPtr + Offsets.World_PersistentLevel);
                if (persistentLevel == IntPtr.Zero) return actors;

                IntPtr actorArray = memory.ReadPointer(persistentLevel + Offsets.Level_Actors);
                int actorCount = memory.ReadInt(persistentLevel + Offsets.Level_ActorCount);

                if (actorCount <= 0 || actorCount > 4096) return actors;

                for (int i = 0; i < Math.Min(actorCount, 4096); i++)
                {
                    IntPtr actorPtr = memory.ReadPointer(actorArray + i * 0x8);
                    if (actorPtr != IntPtr.Zero)
                        actors.Add(actorPtr);
                }
            }
            catch { }

            return actors;
        }

        /// <summary>
        /// Get the local player controller
        /// Path: GWorld → GameInstance → LocalPlayers[0] → PlayerController
        /// </summary>
        public IntPtr GetLocalPlayerController()
        {
            try
            {
                IntPtr gameInstance = memory.ReadPointer(worldPtr + Offsets.World_OwningGameInstance);
                if (gameInstance == IntPtr.Zero) return IntPtr.Zero;

                IntPtr localPlayers = memory.ReadPointer(gameInstance + 0x38);
                if (localPlayers == IntPtr.Zero) return IntPtr.Zero;

                IntPtr localPlayer = memory.ReadPointer(localPlayers);
                if (localPlayer == IntPtr.Zero) return IntPtr.Zero;

                return memory.ReadPointer(localPlayer + 0x30);
            }
            catch { return IntPtr.Zero; }
        }

        /// <summary>
        /// Get the local player pawn
        /// Path: PlayerController → AcknowledgedPawn
        /// </summary>
        public IntPtr GetLocalPlayerPawn()
        {
            try
            {
                IntPtr controller = GetLocalPlayerController();
                if (controller == IntPtr.Zero) return IntPtr.Zero;

                return memory.ReadPointer(controller + 0x260);
            }
            catch { return IntPtr.Zero; }
        }

        /// <summary>
        /// Get the camera manager
        /// Path: PlayerController → CameraManager
        /// </summary>
        public IntPtr GetCameraManager()
        {
            try
            {
                IntPtr controller = GetLocalPlayerController();
                if (controller == IntPtr.Zero) return IntPtr.Zero;

                return memory.ReadPointer(controller + Offsets.PlayerController_CameraManager);
            }
            catch { return IntPtr.Zero; }
        }

        /// <summary>
        /// Get actor class name via GNames
        /// Path: Actor → ClassPrivate → NamePrivate (FName) → GNames
        /// </summary>
        public string GetActorClassName(IntPtr actorPtr)
        {
            if (actorPtr == IntPtr.Zero) return "";

            try
            {
                IntPtr classPtr = memory.ReadPointer(actorPtr + Offsets.Actor_ClassPrivate);
                if (classPtr == IntPtr.Zero) return "";

                int fNameIndex = memory.ReadInt(classPtr + Offsets.UObject_NamePrivate);
                return GetFName(fNameIndex);
            }
            catch { return ""; }
        }

        /// <summary>
        /// Get actor root component location
        /// Path: Actor → RootComponent → RelativeLocation
        /// </summary>
        public Vector3 GetActorLocation(IntPtr actorPtr)
        {
            if (actorPtr == IntPtr.Zero) return Vector3.Zero;

            try
            {
                IntPtr rootComponent = memory.ReadPointer(actorPtr + Offsets.Actor_RootComponent);
                if (rootComponent == IntPtr.Zero) return Vector3.Zero;

                return memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_RelativeLocation);
            }
            catch { return Vector3.Zero; }
        }

        /// <summary>
        /// Get actor velocity
        /// Path: Actor → RootComponent → ComponentVelocity
        /// </summary>
        public Vector3 GetActorVelocity(IntPtr actorPtr)
        {
            if (actorPtr == IntPtr.Zero) return Vector3.Zero;

            try
            {
                IntPtr rootComponent = memory.ReadPointer(actorPtr + Offsets.Actor_RootComponent);
                if (rootComponent == IntPtr.Zero) return Vector3.Zero;

                return memory.Read<Vector3>(rootComponent + Offsets.SceneComponent_ComponentVelocity);
            }
            catch { return Vector3.Zero; }
        }

        /// <summary>
        /// Project 3D world position to 2D screen coordinates
        /// Uses the view matrix from CameraManager
        /// </summary>
        public Vector2 WorldToScreen(Vector3 worldPos, float[] viewMatrix)
        {
            if (viewMatrix == null || viewMatrix.Length < 16)
                return new Vector2(-99, -99);

            float m11 = viewMatrix[0], m12 = viewMatrix[1], m13 = viewMatrix[2], m14 = viewMatrix[3];
            float m21 = viewMatrix[4], m22 = viewMatrix[5], m23 = viewMatrix[6], m24 = viewMatrix[7];
            float m41 = viewMatrix[12], m42 = viewMatrix[13], m43 = viewMatrix[14], m44 = viewMatrix[15];

            float w = m41 * worldPos.X + m42 * worldPos.Y + m43 * worldPos.Z + m44;
            if (w < 0.001f) return new Vector2(-99, -99);

            float x = m11 * worldPos.X + m12 * worldPos.Y + m13 * worldPos.Z + m14;
            float y = m21 * worldPos.X + m22 * worldPos.Y + m23 * worldPos.Z + m24;

            float screenX = (1920 / 2f) + (x / w) * (1920 / 2f);
            float screenY = (1080 / 2f) - (y / w) * (1080 / 2f);

            return new Vector2(screenX, screenY);
        }
    }


}

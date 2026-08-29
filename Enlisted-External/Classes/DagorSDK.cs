using Enlisted_External.Data;
using System.Numerics;
using System.Runtime.InteropServices;

namespace Enlisted_External.Classes
{
    /// <summary>
    /// Dagor Engine 6.x / daECS SDK for Enlisted
    /// 
    /// Entity system: Component-based (daECS)
    /// - Entities are identified by EntityId (uint64)
    /// - Components are looked up by FNV1a hash of the name string
    /// - Entity descriptors store archetype/chunk/generation info
    /// - View matrix: column-major via globtm_psf_0..3 pointers
    /// 
    /// Offsets are resolved via string pattern scanning in the binary.
    /// Falls back to hardcoded RVAs if scan fails.
    /// </summary>
    internal class DagorSDK
    {
        private Memory memory;
        private IntPtr baseAddress;

        // ── Global pointer RVAs (resolved at runtime) ──
        private IntPtr entityManagerAddr;
        private IntPtr viewMatrixRowAddrs = IntPtr.Zero; // 4 consecutive QWORD pointers
        private IntPtr cameraPosAddr;

        // ── Resolved pointers ──
        private IntPtr entityManagerPtr;
        private IntPtr entityArrayPtr;
        private int maxEntities;

        // ── Matrices ──
        private float[,] viewMatrix = new float[4, 4]; // [col][row] — column-major
        private bool matrixValid;

        public bool IsValid { get; private set; }

        // ── ECS Component Hashes (FNV1a-32) ──
        public static class CompHash
        {
            public const uint Transform = 0xE1AD931B;      // TMatrix 48B, pos @ float[9..11]
            public const uint IsAlive = 0xA63D3EB6;         // bool
            public const uint Team = 0xA2FD7D0C;            // int (faction)
            public const uint NetTeam = 0x2DD21A07;         // int (network replicated)
            public const uint HitPointsHP = 0x8ECE3E1B;     // float
            public const uint HitPointsMaxHP = 0x84053363;  // float
            public const uint Animchar = 0xB6AF512C;        // AnimcharBaseComponent (0x1A0)
            public const uint AnimcharRender = 0x44D29531;  // ptr
            public const uint AnimcharVisBits = 0xB669CED1; // uint8
            public const uint AnimcharNodeWTM = 0xBF868FAC; // ptr (GeomNodeTree)
            public const uint HumanNetPhys = 0x0417D5DB;    // ptr — soldier marker
            public const uint BindedCamera = 0x22390F00;    // EntityId — local player marker
            public const uint PosessedByPlr = 0x388A6B2B;   // EntityId
            public const uint Name = 0x8D39BDE6;            // ecs::string (24B)
            public const uint Velocity = 0x32741C32;        // Point3 (12B)
            public const uint IsInVehicle = 0xF8D31912;     // bool
            public const uint IsDowned = 0xB5F3E6AC;        // bool
            public const uint IsVisible = 0x9FCD7E71;       // bool
            public const uint IsReloading = 0x5A3DEADC;     // bool
            public const uint GunOwner = 0xD113E2B6;        // EntityId
            public const uint GunTotalAmmo = 0x114338C1;    // int
            public const uint VehicleHP = 0xDEC0790D;       // float
            public const uint SquadID = 0x3DDF9BE2;         // int
            public const uint Stamina = 0xE6F7DD36;         // float
        }

        // ── Entity descriptor bit packing ──
        private const ushort INVALID_ARCHETYPE = 0xFFFF;

        // ── Hardcoded fallback RVAs (Dec10 2025 build) ──
        private static readonly Dictionary<string, uint> FallbackRva = new()
        {
            ["globtm_psf_0"] = 0x5F8D820,
            ["globtm_psf_1"] = 0x5F8D840,
            ["globtm_psf_2"] = 0x5F8D860,
            ["globtm_psf_3"] = 0x5F8D880,
            ["camera_pos"]   = 0x5E45AD0,
            ["entity_manager"] = 0x5DA1B68,
            ["entity_array"]   = 0x5DA1BE8,
            ["max_entities"]   = 0x5DA1BF0,
        };

        public DagorSDK(Memory mem, IntPtr baseAddr)
        {
            memory = mem;
            baseAddress = baseAddr;
        }

        // ============================================================
        // Initialization
        // ============================================================

        public bool Initialize()
        {
            Console.WriteLine("[*] Initializing Dagor Engine SDK...");

            // 1) Resolve Global Pointers via string scanning
            ResolveGlobalPointers();

            // 2) Read entity manager pointer
            if (entityManagerAddr != IntPtr.Zero)
            {
                entityManagerPtr = memory.ReadPointer(entityManagerAddr);
                Console.WriteLine($"[+] EntityManager: 0x{entityManagerPtr:X}");
            }
            else
            {
                Console.WriteLine("[-] EntityManager RVA not found");
                IsValid = false;
                return false;
            }

            if (entityManagerPtr == IntPtr.Zero)
            {
                Console.WriteLine("[-] EntityManager pointer is NULL");
                IsValid = false;
                return false;
            }

            // 3) Resolve entity array and count
            ResolveEntityArray();

            IsValid = entityArrayPtr != IntPtr.Zero && maxEntities > 0;

            if (IsValid)
                Console.WriteLine($"[+] ECS ready: {maxEntities} max entities");
            else
                Console.WriteLine("[-] ECS initialization failed");

            return IsValid;
        }

        private void ResolveGlobalPointers()
        {
            var moduleBytes = memory.ReadBytes(baseAddress, GetModuleSize());

            // Scan for string "globtm_psf_0" to find view matrix pointers
            entityManagerAddr = ScanForRva(moduleBytes, "ecs::EntityManager", "entity_manager");
            viewMatrixRowAddrs = ScanForRva(moduleBytes, "globtm_psf_0", "globtm_psf_0");
            cameraPosAddr = ScanForRva(moduleBytes, "camera__look_at", "camera_pos");

            // If globtm scan failed, try each row individually
            if (viewMatrixRowAddrs == IntPtr.Zero)
            {
                var r0 = ScanForRva(moduleBytes, "globtm_psf_0", "globtm_psf_0");
                if (r0 != IntPtr.Zero) viewMatrixRowAddrs = r0;
            }

            // Fallback to hardcoded
            if (entityManagerAddr == IntPtr.Zero && FallbackRva.ContainsKey("entity_manager"))
            {
                Console.WriteLine("[*] Using fallback RVAs");
                entityManagerAddr = baseAddress + (int)FallbackRva["entity_manager"];
                viewMatrixRowAddrs = baseAddress + (int)FallbackRva["globtm_psf_0"];
                cameraPosAddr = baseAddress + (int)FallbackRva["camera_pos"];
            }
        }

        private IntPtr ScanForRva(byte[] moduleBytes, string searchString, string fallbackKey)
        {
            // Method 1: Find the string in .rdata, then find its xref in .text
            byte[] strBytes = System.Text.Encoding.ASCII.GetBytes(searchString);
            for (int i = 0; i < moduleBytes.Length - strBytes.Length; i++)
            {
                bool match = true;
                for (int j = 0; j < strBytes.Length; j++)
                {
                    if (moduleBytes[i + j] != strBytes[j]) { match = false; break; }
                }
                if (match)
                {
                    long strRva = i;
                    Console.WriteLine($"  [{searchString}] string found at RVA 0x{strRva:X}");

                    // Find LEA/MOV reference to this string address in code
                    long strVA = baseAddress + i;
                    IntPtr refAddr = FindXrefToAddress(moduleBytes, strVA);
                    if (refAddr != IntPtr.Zero)
                    {
                        // The pointer is typically at a fixed offset from the xref
                        // Read the global pointer from the .data section
                        long globalPtrOffset = FindAdjacentPointer(moduleBytes, strRva);
                        if (globalPtrOffset > 0)
                        {
                            Console.WriteLine($"  [{searchString}] global pointer at RVA 0x{globalPtrOffset:X}");
                            return baseAddress + (int)globalPtrOffset;
                        }
                    }

                    // If xref not found, the string might be used directly
                    // Scan nearby for pointer patterns
                    return FindGlobalPtrNear(moduleBytes, strRva);
                }
            }

            // Fallback
            if (FallbackRva.ContainsKey(fallbackKey))
            {
                Console.WriteLine($"  [{searchString}] using fallback RVA 0x{FallbackRva[fallbackKey]:X}");
                return baseAddress + (int)FallbackRva[fallbackKey];
            }

            Console.WriteLine($"  [{searchString}] NOT FOUND");
            return IntPtr.Zero;
        }

        private IntPtr FindXrefToAddress(byte[] moduleBytes, long targetVA)
        {
            // Scan .text for LEA R, [rip+disp32] or MOV R, [rip+disp32] referencing targetVA
            // x64: LEA/MOV reg, [rip + disp32] — the instruction is typically 7 bytes
            for (int i = 0; i < moduleBytes.Length - 7; i++)
            {
                // LEA reg, [rip+disp32]: 48 8D xx xx xx xx xx or 4C 8D xx xx xx xx xx
                if ((moduleBytes[i] == 0x48 || moduleBytes[i] == 0x4C) && moduleBytes[i + 1] == 0x8D)
                {
                    byte modrm = moduleBytes[i + 2];
                    if ((modrm & 0xC7) == 0x05) // mod=00, rm=101 (RIP-relative)
                    {
                        int disp = BitConverter.ToInt32(moduleBytes, i + 3);
                        long instrEnd = baseAddress + i + 7;
                        long target = instrEnd + disp;
                        if (Math.Abs(target - targetVA) < 0x1000)
                            return baseAddress + i;
                    }
                }

                // MOV reg, [rip+disp32]: 48 8B xx xx xx xx xx
                if ((moduleBytes[i] == 0x48 || moduleBytes[i] == 0x4C) && moduleBytes[i + 1] == 0x8B)
                {
                    byte modrm = moduleBytes[i + 2];
                    if ((modrm & 0xC7) == 0x05)
                    {
                        int disp = BitConverter.ToInt32(moduleBytes, i + 3);
                        long instrEnd = baseAddress + i + 7;
                        long target = instrEnd + disp;
                        if (Math.Abs(target - targetVA) < 0x1000)
                            return baseAddress + i;
                    }
                }
            }

            return IntPtr.Zero;
        }

        private long FindAdjacentPointer(byte[] moduleBytes, long strRva)
        {
            // After the string, there's often padding then a pointer array
            // Scan forward from the string end for 4 consecutive aligned pointers
            long endOfStr = strRva + System.Text.Encoding.ASCII.GetBytes("globtm_psf_0").Length + 1;
            long align = (endOfStr + 15) & ~15; // align to 16 bytes

            for (long off = align; off < Math.Min(moduleBytes.Length - 32, align + 0x1000); off += 8)
            {
                // Check if 4 consecutive QWORDs look like plausible pointers
                bool valid = true;
                for (int p = 0; p < 4; p++)
                {
                    long ptr = BitConverter.ToInt64(moduleBytes, (int)(off + p * 8));
                    // Valid user-mode pointer: 0x10000 < ptr < 0x7FFFFFFFFFFF
                    if (ptr < 0x10000 || ptr > 0x7FFFFFFFFFFF)
                    {
                        valid = false;
                        break;
                    }
                }
                if (valid)
                {
                    // Verify they're close together (within same page range)
                    long first = BitConverter.ToInt64(moduleBytes, (int)off);
                    long last = BitConverter.ToInt64(moduleBytes, (int)(off + 24));
                    if (Math.Abs(last - first) < 0x100)
                        return off;
                }
            }

            return strRva + 0x20; // guess after string
        }

        private IntPtr FindGlobalPtrNear(byte[] moduleBytes, long strRva)
        {
            // Simple approach: look for aligned QWORDs after the string
            long start = (strRva + 64) & ~7;
            for (long off = start; off < Math.Min(moduleBytes.Length - 8, start + 0x2000); off += 8)
            {
                long val = BitConverter.ToInt64(moduleBytes, (int)off);
                if (val > 0x10000 && val < 0x7FFFFFFFFFFF)
                    return baseAddress + (int)off;
            }
            return baseAddress + (int)(strRva + 0x40);
        }

        private void ResolveEntityArray()
        {
            // EntityManager → entity_descriptors_ptr and entity_descriptors_count
            // Entity descriptor entry is 8 bytes: [archetype_idx:2][comp_off:1][gen:1][pad:2][chunk:2]
            if (entityManagerPtr == IntPtr.Zero) return;

            try
            {
                // Scan nearby memory for the entity count (reasonable range)
                // The entity array pointer is typically within 0x100 bytes of the EM pointer
                entityArrayPtr = FindEntityArrayInManager();
                maxEntities = FindMaxEntities();

                Console.WriteLine($"[+] EntityArray: 0x{entityArrayPtr:X}, Max: {maxEntities}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[-] Entity resolution failed: {ex.Message}");
            }
        }

        private IntPtr FindEntityArrayInManager()
        {
            // Try to find the entity array by scanning the entity manager memory
            // The array is a QWORD pointer followed by a DWORD count
            for (int offset = 0; offset < 0x200; offset += 8)
            {
                IntPtr candidate = memory.ReadPointer(entityManagerPtr + offset);
                if (candidate == IntPtr.Zero || candidate.ToInt64() < 0x10000) continue;

                // Check if there's a reasonable count nearby
                int count = memory.ReadInt(entityManagerPtr + offset + 8);
                if (count > 0 && count < 4096)
                {
                    // Verify: try to read the first entry as an entity descriptor
                    try
                    {
                        ulong firstEntry = memory.Read<ulong>(candidate);
                        ushort archIdx = (ushort)(firstEntry & 0xFFFF);
                        // A valid descriptor won't be 0xFFFF and won't be all zeros
                        if (firstEntry != 0 && archIdx != INVALID_ARCHETYPE)
                        {
                            Console.WriteLine($"  Found entity array at EM+0x{offset:X}, count={count}");
                            return candidate;
                        }
                    }
                    catch { }
                }
            }

            // If scan failed, try known offset patterns
            IntPtr fallback = memory.ReadPointer(entityManagerPtr + 0x80);
            if (fallback != IntPtr.Zero && fallback.ToInt64() > 0x10000)
                return fallback;

            return IntPtr.Zero;
        }

        private int FindMaxEntities()
        {
            // Scan entity manager for a reasonable entity count
            for (int offset = 0; offset < 0x200; offset += 4)
            {
                int val = memory.ReadInt(entityManagerPtr + offset);
                if (val > 0 && val < 4096 && val > 10)
                {
                    // Check if nearby memory has entity array pointers
                    IntPtr arrayCandidate = memory.ReadPointer(entityManagerPtr + offset - 8);
                    if (arrayCandidate != IntPtr.Zero && arrayCandidate.ToInt64() > 0x10000)
                        return val;
                }
            }
            return 512; // default
        }

        // ============================================================
        // Entity Walker
        // ============================================================

        public List<EntityInfo> GetAllEntities()
        {
            var result = new List<EntityInfo>();
            if (entityArrayPtr == IntPtr.Zero || maxEntities <= 0) return result;

            for (int i = 0; i < maxEntities; i++)
            {
                try
                {
                    ulong desc = memory.Read<ulong>(entityArrayPtr + i * 8);
                    if (desc == 0) continue;

                    ushort archIdx = (ushort)(desc & 0xFFFF);
                    if (archIdx == INVALID_ARCHETYPE) continue;

                    byte compOffIdx = (byte)((desc >> 16) & 0xFF);
                    byte generation = (byte)((desc >> 8) & 0xFF);
                    ushort chunkIdx = (ushort)((desc >> 48) & 0xFFFF);

                    result.Add(new EntityInfo
                    {
                        Index = i,
                        ArchetypeIndex = archIdx,
                        ChunkIndex = chunkIdx,
                        ComponentOffsetIndex = compOffIdx,
                        Generation = generation,
                    });
                }
                catch { }
            }

            return result;
        }

        /// <summary>
        /// Get component data pointer for an entity using FNV1a hash lookup
        /// Uses the archetype chunk system to find the actual data
        /// </summary>
        public IntPtr GetComponentData(EntityInfo entity, uint componentHash)
        {
            if (entityManagerPtr == IntPtr.Zero) return IntPtr.Zero;

            try
            {
                // Walk the archetype → chunk → component data chain
                // This is a simplified version; real implementation would
                // use the component lookup table at em + comp_lookup_offset
                IntPtr archetypeBase = memory.ReadPointer(entityManagerPtr + 0xD8);
                if (archetypeBase == IntPtr.Zero) return IntPtr.Zero;

                // Read archetype descriptor for this entity
                int archStride = 0x40; // typical stride per archetype
                IntPtr archDesc = archetypeBase + entity.ArchetypeIndex * archStride;

                // Read chunk base for this archetype
                IntPtr chunkArray = memory.ReadPointer(archDesc + 0x10);
                if (chunkArray == IntPtr.Zero) return IntPtr.Zero;

                int chunkStride = 0x1000; // typical chunk size
                IntPtr chunk = chunkArray + entity.ChunkIndex * chunkStride;

                // Read component data from chunk
                IntPtr compData = memory.ReadPointer(chunk + 0x18);
                if (compData == IntPtr.Zero) return IntPtr.Zero;

                // Simple lookup: scan for matching hash in the component list
                int compCount = memory.ReadInt(chunk + 0x20);
                for (int c = 0; c < Math.Min(compCount, 64); c++)
                {
                    IntPtr compEntry = memory.ReadPointer(compData + c * 0x10);
                    if (compEntry == IntPtr.Zero) continue;

                    uint hash = (uint)memory.ReadInt(compEntry + 0x04);
                    if (hash == componentHash)
                        return memory.ReadPointer(compEntry + 0x08);
                }
            }
            catch { }

            return IntPtr.Zero;
        }

        // ============================================================
        // View Matrix (Dagor column-vector convention)
        // ============================================================

        public bool UpdateViewMatrix()
        {
            if (viewMatrixRowAddrs == IntPtr.Zero) return false;

            try
            {
                float[] row0 = ReadFloat4(viewMatrixRowAddrs);
                float[] row1 = ReadFloat4(viewMatrixRowAddrs + 8);
                float[] row2 = ReadFloat4(viewMatrixRowAddrs + 16);
                float[] row3 = ReadFloat4(viewMatrixRowAddrs + 24);

                // Validate: reject torn reads
                float[] row0b = ReadFloat4(viewMatrixRowAddrs);
                if (!row0.SequenceEqual(row0b)) return false; // torn

                // Store as [col][row] for the W2S formula
                for (int r = 0; r < 4; r++)
                {
                    viewMatrix[0, r] = row0[r];
                    viewMatrix[1, r] = row1[r];
                    viewMatrix[2, r] = row2[r];
                    viewMatrix[3, r] = row3[r];
                }

                matrixValid = true;
                return true;
            }
            catch
            {
                matrixValid = false;
                return false;
            }
        }

        public Vector3 GetCameraPosition()
        {
            if (cameraPosAddr == IntPtr.Zero) return Vector3.Zero;
            try
            {
                return memory.Read<Vector3>(cameraPosAddr);
            }
            catch { return Vector3.Zero; }
        }

        /// <summary>
        /// Dagor Engine W2S — column-major convention
        /// clip.X = dot(worldPos4, psf_0) etc.
        /// </summary>
        public Vector2 WorldToScreen(Vector3 worldPos, float screenW, float screenH)
        {
            if (!matrixValid) return new Vector2(-99, -99);

            float cx = viewMatrix[0, 0] * worldPos.X + viewMatrix[1, 0] * worldPos.Y + viewMatrix[2, 0] * worldPos.Z + viewMatrix[3, 0];
            float cy = viewMatrix[0, 1] * worldPos.X + viewMatrix[1, 1] * worldPos.Y + viewMatrix[2, 1] * worldPos.Z + viewMatrix[3, 1];
            float cw = viewMatrix[0, 3] * worldPos.X + viewMatrix[1, 3] * worldPos.Y + viewMatrix[2, 3] * worldPos.Z + viewMatrix[3, 3];

            if (cw < 0.1f) return new Vector2(-99, -99);

            float inv = 1.0f / cw;
            float sx = screenW * 0.5f + (cx * inv) * screenW * 0.5f;
            float sy = screenH * 0.5f - (cy * inv) * screenH * 0.5f;

            return new Vector2(sx, sy);
        }

        // ============================================================
        // Bone System (AnimcharBaseComponent)
        // ============================================================

        /// <summary>
        /// Read skeleton bones from AnimcharBaseComponent
        /// Each bone WTM is 64 bytes, position at +0x30 (float[3])
        /// </summary>
        public Dictionary<int, Vector3> GetBonePositions(IntPtr animcharPtr)
        {
            var bones = new Dictionary<int, Vector3>();
            if (animcharPtr == IntPtr.Zero) return bones;

            try
            {
                IntPtr wtmArray = memory.ReadPointer(animcharPtr + 0x00);
                int nodeCount = memory.ReadInt(animcharPtr + 0x08);
                IntPtr parentPtr = memory.ReadPointer(animcharPtr + 0x20);

                // Base offset added to every bone position
                float baseX = memory.ReadFloat(animcharPtr + 0x50);
                float baseY = memory.ReadFloat(animcharPtr + 0x54);
                float baseZ = memory.ReadFloat(animcharPtr + 0x58);

                // Key bone indices
                const int HEAD = 53, NECK = 22, CHEST = 27, PELVIS = 1;
                const int LEFT_KNEE = 13, RIGHT_KNEE = 15;
                int[] importantBones = { HEAD, NECK, CHEST, PELVIS, LEFT_KNEE, RIGHT_KNEE };

                foreach (int boneIdx in importantBones)
                {
                    if (boneIdx >= nodeCount || wtmArray == IntPtr.Zero) continue;

                    long boneOffset = (long)boneIdx * 64 + 0x30; // position at +0x30
                    IntPtr boneAddr = wtmArray + (int)boneOffset;

                    float bx = memory.ReadFloat(boneAddr) + baseX;
                    float by = memory.ReadFloat(boneAddr + 4) + baseY;
                    float bz = memory.ReadFloat(boneAddr + 8) + baseZ;

                    bones[boneIdx] = new Vector3(bx, by, bz);
                }
            }
            catch { }

            return bones;
        }

        // ============================================================
        // Entity Info Helper
        // ============================================================

        public class EntityInfo
        {
            public int Index;
            public ushort ArchetypeIndex;
            public ushort ChunkIndex;
            public byte ComponentOffsetIndex;
            public byte Generation;
        }

        // ============================================================
        // Utilities
        // ============================================================

        private float[] ReadFloat4(IntPtr addr)
        {
            byte[] bytes = memory.ReadBytes(addr, 16);
            float[] result = new float[4];
            Buffer.BlockCopy(bytes, 0, result, 0, 16);
            return result;
        }

        private int GetModuleSize()
        {
            try
            {
                byte[] header = memory.ReadBytes(baseAddress, 0x200);
                int peOffset = BitConverter.ToInt32(header, 0x3C);
                int sizeOfImage = BitConverter.ToInt32(header, peOffset + 80);
                return Math.Min(sizeOfImage, 0x2000000); // cap at 32MB
            }
            catch { return 0x1000000; }
        }

        /// <summary>
        /// FNV1a-32 hash for ECS component name lookup
        /// </summary>
        public static uint HashString(string str)
        {
            uint hash = 0x811C9DC5;
            foreach (char c in str)
            {
                hash ^= (uint)c;
                hash *= 0x01000193;
            }
            return hash;
        }

        /// <summary>
        /// Create 3D box corners for ESP (0.3m half-width, 1.85m height)
        /// </summary>
        public static Vector3[] MakeBoxCorners(Vector3 pos)
        {
            float hw = 0.3f, hd = 0.3f, h = 1.85f;
            return new Vector3[]
            {
                new(pos.X - hw, pos.Y, pos.Z - hd),
                new(pos.X + hw, pos.Y, pos.Z - hd),
                new(pos.X + hw, pos.Y, pos.Z + hd),
                new(pos.X - hw, pos.Y, pos.Z + hd),
                new(pos.X - hw, pos.Y + h, pos.Z - hd),
                new(pos.X + hw, pos.Y + h, pos.Z - hd),
                new(pos.X + hw, pos.Y + h, pos.Z + hd),
                new(pos.X - hw, pos.Y + h, pos.Z + hd),
            };
        }

        /// <summary>
        /// Get AABB of projected box corners for 2D bounding box
        /// </summary>
        public static void GetBoxAABB(Vector3[] corners3D, float[] viewMatrix, float sw, float sh,
            out Vector2 min, out Vector2 max)
        {
            min = new Vector2(99999, 99999);
            max = new Vector2(-99999, -99999);
            int visCount = 0;

            foreach (var corner in corners3D)
            {
                float cx = viewMatrix[0] * corner.X + viewMatrix[4] * corner.Y + viewMatrix[8] * corner.Z + viewMatrix[12];
                float cy = viewMatrix[1] * corner.X + viewMatrix[5] * corner.Y + viewMatrix[9] * corner.Z + viewMatrix[13];
                float cw = viewMatrix[3] * corner.X + viewMatrix[7] * corner.Y + viewMatrix[11] * corner.Z + viewMatrix[15];

                if (cw < 0.1f) continue;
                visCount++;

                float inv = 1.0f / cw;
                float sx = sw * 0.5f + (cx * inv) * sw * 0.5f;
                float sy = sh * 0.5f - (cy * inv) * sh * 0.5f;

                if (sx < min.X) min.X = sx;
                if (sy < min.Y) min.Y = sy;
                if (sx > max.X) max.X = sx;
                if (sy > max.Y) max.Y = sy;
            }

            if (visCount < 4)
            {
                min = new Vector2(-99, -99);
                max = new Vector2(-99, -99);
            }
        }
    }
}

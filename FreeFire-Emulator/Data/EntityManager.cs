using System.Numerics;
using FreeFire_Emulator.Classes;

namespace FreeFire_Emulator.Data
{
    internal class EntityManager
    {
        private Memory memory;
        private IL2CppSDK il2cpp;

        public Entity? LocalPlayer { get; private set; }
        public List<Entity> Players { get; private set; } = new();

        public EntityManager(Memory mem, IL2CppSDK sdk)
        {
            memory = mem;
            il2cpp = sdk;
        }

        public void Update()
        {
            if (memory == null || il2cpp == null) return;
            Players.Clear();

            IntPtr localPlayer = il2cpp.GetLocalPlayer();
            if (localPlayer == IntPtr.Zero) return;

            LocalPlayer = ReadPlayer(localPlayer, 0);
            if (LocalPlayer == null) return;

            ReadPlayerList();
        }

        private void ReadPlayerList()
        {
            try
            {
                IntPtr dictBase = il2cpp.ModuleBase + 0x55333000;
                int count = memory.ReadInt(dictBase + 0x10);
                if (count <= 0 || count > 100) return;

                IntPtr entries = memory.ReadPointer(dictBase + 0x18);
                for (int i = 0; i < count; i++)
                {
                    IntPtr entry = entries + i * 0x18;
                    IntPtr playerPtr = memory.ReadPointer(entry + 0x10);
                    if (playerPtr == IntPtr.Zero) continue;

                    Entity? player = ReadPlayer(playerPtr, Players.Count + 1);
                    if (player != null && player.IsValid)
                        Players.Add(player);
                }
            }
            catch { }
        }

        private Entity? ReadPlayer(IntPtr playerPtr, int index)
        {
            try
            {
                Entity entity = new Entity
                {
                    Address = playerPtr,
                    PlayerIndex = index,
                    Name = il2cpp.GetPlayerName(playerPtr),
                    Health = il2cpp.GetHealth(playerPtr),
                    MaxHealth = il2cpp.GetMaxHealth(playerPtr),
                    IsDead = il2cpp.IsPlayerDead(playerPtr),
                    IsVisible = il2cpp.IsVisible(playerPtr),
                    IsTeam = il2cpp.IsTeammate(playerPtr),
                    IsBot = il2cpp.IsBot(playerPtr),
                };

                entity.Position = il2cpp.GetHipPosition(playerPtr);
                entity.HeadPosition = il2cpp.GetHeadPosition(playerPtr);

                entity.ScreenPos = il2cpp.WorldToScreen(entity.Position);
                entity.HeadScreen = il2cpp.WorldToScreen(entity.HeadPosition);

                if (LocalPlayer != null)
                    entity.Distance = Vector3.Distance(LocalPlayer.Position, entity.Position);

                return entity;
            }
            catch { return null; }
        }
    }
}

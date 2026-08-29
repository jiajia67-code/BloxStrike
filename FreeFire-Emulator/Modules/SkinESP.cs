using System.Numerics;
using FreeFire_Emulator.Data;
using ImGuiNET;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// Skin ESP for Free Fire (Unity IL2CPP)
    /// 
    /// Shows player skin information:
    /// - Skin name (outfit)
    /// - Weapon skin
    /// - Pet skin
    /// - Backpack skin
    /// - Rarity indicator
    /// 
    /// How it works:
    /// 1. Read player's equipped skin data from inventory
    /// 2. Map skin IDs to names using IL2CPP metadata
    /// 3. Display skin info near player ESP
    /// 
    /// Unity IL2CPP approach:
    /// - Player → Inventory → EquippedItems → SkinData
    /// - Each skin has an ID that maps to a name in the metadata
    /// </summary>
    internal class SkinESP
    {
        // Settings
        public static bool Enabled = false;
        public static bool ShowOutfit = true;
        public static bool ShowWeaponSkin = true;
        public static bool ShowPet = false;
        public static bool ShowRarity = true;

        // Rarity colors
        private static uint CommonColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0.6f, 0.6f, 0.6f, 1));
        private static uint RareColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0.2f, 0.6f, 1, 1));
        private static uint EpicColor = ImGui.ColorConvertFloat4ToU32(new Vector4(0.7f, 0.2f, 1, 1));
        private static uint LegendaryColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.8f, 0, 1));
        private static uint MythicColor = ImGui.ColorConvertFloat4ToU32(new Vector4(1, 0.2f, 0.2f, 1));

        // Skin ID to name mapping (from IL2CPP metadata)
        // These are example IDs - need to be dumped from the game
        private static readonly Dictionary<int, string> SkinNames = new()
        {
            { 1001, "Default" },
            { 1002, "Arctic Wolf" },
            { 1003, "Dragon Fire" },
            { 1004, "Shadow Blade" },
            { 1005, "Neon Storm" },
            { 2001, "AK47 - Blue Flame" },
            { 2002, "M4A1 - Red Dragon" },
            { 2003, "AWM - Gold Rush" },
            { 2004, "UMP - Cyber Punk" },
            { 3001, "Mechanical Cat" },
            { 3002, "Fire Fox" },
        };

        // Rarity mapping
        private static readonly Dictionary<int, int> SkinRarity = new()
        {
            { 1001, 0 }, // Common
            { 1002, 1 }, // Rare
            { 1003, 2 }, // Epic
            { 1004, 3 }, // Legendary
            { 1005, 4 }, // Mythic
        };

        /// <summary>
        /// Draw skin information near players
        /// </summary>
        public static void Draw(Entity? localPlayer, List<Entity> players)
        {
            if (!Enabled || localPlayer == null) return;

            var drawList = ImGui.GetBackgroundDrawList();

            foreach (var player in players)
            {
                if (player == null || !player.IsValid) continue;
                if (player.Position2D == new Vector2(-99, -99)) continue;
                if (player.IsTeammate) continue;

                // Get skin info from player object
                SkinInfo? skinInfo = GetPlayerSkinInfo(player);
                if (skinInfo == null) continue;

                float entityHeight = Math.Abs(player.Head2D.Y - player.Position2D.Y);
                float halfWidth = entityHeight / 3f;
                float centerX = (player.Head2D.X + player.Position2D.X) / 2f;
                float topY = Math.Min(player.Head2D.Y, player.Position2D.Y);

                float yOffset = -20f;

                // Draw outfit name
                if (ShowOutfit && !string.IsNullOrEmpty(skinInfo.OutfitName))
                {
                    Vector2 pos = new(centerX, topY + yOffset);
                    uint color = GetRarityColor(skinInfo.OutfitRarity);
                    Vector2 ts = ImGui.CalcTextSize(skinInfo.OutfitName);
                    drawList.AddText(new(pos.X - ts.X / 2, pos.Y - ts.Y), color, skinInfo.OutfitName);
                    yOffset -= ts.Y + 2;
                }

                // Draw weapon skin
                if (ShowWeaponSkin && !string.IsNullOrEmpty(skinInfo.WeaponSkinName))
                {
                    Vector2 pos = new(centerX, topY + yOffset);
                    uint color = GetRarityColor(skinInfo.WeaponSkinRarity);
                    Vector2 ts = ImGui.CalcTextSize(skinInfo.WeaponSkinName);
                    drawList.AddText(new(pos.X - ts.X / 2, pos.Y - ts.Y), color, skinInfo.WeaponSkinName);
                    yOffset -= ts.Y + 2;
                }

                // Draw pet
                if (ShowPet && !string.IsNullOrEmpty(skinInfo.PetName))
                {
                    Vector2 pos = new(centerX, topY + yOffset);
                    uint color = ImGui.ColorConvertFloat4ToU32(new Vector4(0.5f, 1, 0.5f, 1));
                    Vector2 ts = ImGui.CalcTextSize(skinInfo.PetName);
                    drawList.AddText(new(pos.X - ts.X / 2, pos.Y - ts.Y), color, skinInfo.PetName);
                    yOffset -= ts.Y + 2;
                }

                // Draw rarity stars
                if (ShowRarity && skinInfo.MaxRarity > 0)
                {
                    string stars = new string('★', skinInfo.MaxRarity);
                    Vector2 pos = new(centerX, topY + yOffset);
                    uint color = GetRarityColor(skinInfo.MaxRarity);
                    Vector2 ts = ImGui.CalcTextSize(stars);
                    drawList.AddText(new(pos.X - ts.X / 2, pos.Y - ts.Y), color, stars);
                }
            }
        }

        /// <summary>
        /// Get skin information for a player
        /// </summary>
        private static SkinInfo? GetPlayerSkinInfo(Entity player)
        {
            try
            {
                // Read from player's inventory/equipment data
                // This depends on the IL2CPP structure
                // For now, return a placeholder
                return new SkinInfo
                {
                    OutfitName = "Skin",
                    OutfitRarity = 2,
                    WeaponSkinName = "",
                    WeaponSkinRarity = 0,
                    PetName = "",
                    MaxRarity = 2,
                };
            }
            catch { return null; }
        }

        private static uint GetRarityColor(int rarity)
        {
            return rarity switch
            {
                0 => CommonColor,
                1 => RareColor,
                2 => EpicColor,
                3 => LegendaryColor,
                4 => MythicColor,
                _ => CommonColor,
            };
        }
    }

    /// <summary>
    /// Skin information for a player
    /// </summary>
    internal class SkinInfo
    {
        public string OutfitName { get; set; } = "";
        public int OutfitRarity { get; set; }
        public string WeaponSkinName { get; set; } = "";
        public int WeaponSkinRarity { get; set; }
        public string PetName { get; set; } = "";
        public int MaxRarity { get; set; }
    }
}

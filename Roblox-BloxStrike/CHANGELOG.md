# 📋 Changelog

All notable changes to BloxStrike will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.0] - 2026-09-04

### 🔧 Comprehensive Bug Fix + AI Enhancement Release

#### ⚡ Fixed
- Fixed critical `BS.enemies()` function syntax bug in core.lua (invalid Lua syntax)
- Fixed hud.lua duplicate function definitions (updateWatermark, updateSpectators, updateKillCounter)
- Fixed esp.lua missing `local Players`/`lplr` declarations
- Removed dead duplicate standalone functions in esp.lua (skeleton, snapline, headdot, barrel)
- Fixed combat.lua `Vector3.new()` empty args in humanize section (uncommented random deviation)
- Fixed stealth.lua `humanizeAim` `Vector3.new()` empty args (uncommented random deviation)
- Fixed esp.lua `draw3DBox` corners3D all commented out (uncommented 8 corners)
- Fixed pingadapt.lua all state assignments were commented out (Current, Average, Jitter, Min, Max, etc.)
- Fixed 8+ pingadapt API functions with missing/TODO implementations
- Fixed pingadapt.lua `getAdaptPrediction` undefined `pingBonus` variable
- Fixed pingadapt.lua `getAdaptResolverAccuracy` undefined `m` variable

#### ✨ Added
- AI-powered target selection engine (smartai.lua v4.0)
- Enemy profiling system (velocity tracking, movement pattern classification)
- AI prediction engine (linear, zigzag, aggressive, jump prediction)
- AI weapon matching optimization (bone selection per weapon type)
- Adaptive playstyle engine with self-limiting and mode rotation
- AI HUD display with real-time stats
- PingAdapt: Implemented getAdaptFOV, getAdaptAAJitter, getAdaptBhopInterval, getAdaptSilentRange, getAdaptHumanDelay

#### 🎨 Changed
- Updated all version references to v4.1
- Enhanced smartai.lua from simplified stubs to full AI system
- Improved pingadapt.lua from mostly TODO stubs to working implementations

---

## [3.0.0] - 2024-01-XX

### 🎉 Major Release

#### ⚡ Fixed
- Fixed all 16 failing modules (syntax errors resolved)
- Fixed empty tab name issue in utility module
- Fixed `continue` statement outside loop in combat module
- Fixed orphaned `end)` in multiple modules
- Fixed commented function definitions in compat module
- Fixed Colorpicker runtime error in ESP module
- Fixed ToggleVisibility method missing in UI module

#### ✨ Added
- One-click fixer script (`BloxStrike_Fixer.lua`)
- Standalone version (`BloxStrike_Standalone.lua`)
- Game restriction (BloxStrike only - PlaceId: 114234929420007)
- Comprehensive README with bilingual content
- Feature description document
- GitHub issue and PR templates
- Security policy
- Contributing guidelines
- MIT License

#### 🎨 Changed
- GUI tab reorganization (13 logical tabs)
- Renamed "Combat Assist" tab to "Comms"
- Removed duplicate settings buttons from Utility tab
- Improved error messages and logging

#### 🔧 Technical
- Updated module loading system
- Improved error handling in all modules
- Added pcall wrappers for safer execution

---

## [2.0.0] - 2024-01-XX

### 🎉 Major Release

#### ✨ Added
- Full device compatibility layer (25+ executors)
- UI v2.0 (mobile touch + adaptive screen)
- ESP compat layer (Drawing API safe wrapper)
- Settings compat layer (cross-executor file operations)
- Webhook compat layer (cross-executor HTTP)
- Auto error handling system
- Settings save system (5 presets)
- Weapon viewmodel changer (8 presets)
- Kill sounds+animations (30+ sounds, 15+ effects)
- Ragebot (Ragebot, Anti-Aim, Fake Lag, Resolver)
- Silent Aim for HVH
- Bunny hop (8 modes)
- Anti-detection system v2.0

#### ⚔️ Combat Features
- Aimbot v2.0 (30+ options)
- Triggerbot v2.0 (15+ options)
- Silent Aim with server-side modification
- Recoil control system
- Auto fire and quick switch
- Team and friend check

#### 🎯 HVH Features
- Advanced ragebot with multipoint
- Safe point system
- Damage override
- PSilent (pure silent aim)
- Rapid fire mode
- Auto wallbang

#### 👁️ ESP Features
- 60+ ESP options with zero delay
- Multiple box styles (2D, Corners, 3D, Filled)
- Health, armor, distance displays
- Skeleton and head ESP
- Radar and compass
- Kill feed and damage numbers

#### 🌍 World Features
- FOV changer
- Anti-flash
- Full bright
- Wallhack
- Smoke reveal and no smoke
- No fire and grenade trajectory

#### 🕵️ Stealth Features
- 28 protection blocks
- 30 advanced bypass systems
- Traffic masking and noise injection
- ML behavioral evasion

---

## [1.0.0] - 2024-01-XX

### 🎉 Initial Release

#### ✨ Added
- Basic aimbot functionality
- Simple ESP system
- Basic world modifications
- Settings system
- Modular architecture

---

## 📊 Version History

| Version | Date | Changes |
|---------|------|---------|
| 3.0.0 | 2024-01-XX | Major bug fixes, GUI optimization |
| 2.0.0 | 2024-01-XX | Full feature set, compatibility layer |
| 1.0.0 | 2024-01-XX | Initial release |

---

## 🔮 Future Plans

### v3.1.0 (Planned)
- [ ] AI-powered aimbot optimization
- [ ] Advanced recoil patterns
- [ ] More ESP styles
- [ ] Additional kill effects
- [ ] Performance improvements

### v3.2.0 (Planned)
- [ ] Team voice chat integration
- [ ] Advanced statistics tracking
- [ ] Custom theme support
- [ ] Plugin system

---

## 📝 Notes

- All versions are tested in BloxStrike game (PlaceId: 114234929420007)
- Supported on PC, Mobile, and Emulators
- Compatible with 25+ Roblox executors

---

*For more details, see the [README](README.md) and [DESCRIPTION](DESCRIPTION.md).*

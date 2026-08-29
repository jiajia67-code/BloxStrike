#!/system/bin/sh
# ═══ Free Fire Emulator Bypass - customize.sh ═══
# 安裝腳本

ui_print('')
ui_print('╔══════════════════════════════════════════════════════════════╗')
ui_print('║           Free Fire Emulator Bypass v1.0.0                  ║')
ui_print('║           by FreeFire Emulator                              ║')
ui_print('╚══════════════════════════════════════════════════════════════╝')
ui_print('')
ui_print('- Checking device...')
ui_print('- Android API: $(getprop ro.build.version.sdk)')
ui_print('- Magisk Version: $(magisk -v)')
ui_print('')

# ═══ 檢查 Magisk 版本 ═══
if [ "$(magisk -v)" = "not found" ]; then
    ui_print('[-] Error: Magisk not found!')
    ui_print('[-] Please install Magisk first.')
    exit 1
fi

ui_print('- Magisk detected!')
ui_print('')

# ═══ 安裝模組 ═══
ui_print('- Installing Free Fire Emulator Bypass...')
ui_print('')

# 複製 system.prop
if [ -f "$MODPATH/system.prop" ]; then
    cp -f "$MODPATH/system.prop" /system/system.prop
    ui_print('- system.prop installed')
fi

# 設定權限
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755

ui_print('')
ui_print('- ═══ Installation Complete! ═══')
ui_print('')
ui_print('- Features enabled:')
ui_print('  ✅ build.prop spoofing (Samsung Galaxy S23 Ultra)')
ui_print('  ✅ Emulator file hiding')
ui_print('  ✅ System property spoofing')
ui_print('  ✅ Magisk hiding')
ui_print('  ✅ Root file hiding')
ui_print('')
ui_print('- Please REBOOT your device!')
ui_print('')
ui_print('- After reboot:')
ui_print('  1. Open Free Fire')
ui_print('  2. Emulator detection should be bypassed')
ui_print('  3. Play without restrictions!')
ui_print('')

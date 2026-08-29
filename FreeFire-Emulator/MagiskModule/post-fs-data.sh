#!/system/bin/sh
# ═══ Free Fire Emulator Bypass - post-fs-data.sh ═══
# 早期啟動階段執行 (隱藏模擬器檔案)

MODDIR=${0%/*}

# ═══ 隱藏模擬器檔案 ═══
hide_emulator_files() {
    # QEMU
    mount -o bind /dev/null /system/bin/qemu-props 2>/dev/null
    mount -o bind /dev/null /system/bin/qemu.prop 2>/dev/null
    mount -o bind /dev/null /dev/socket/qemud 2>/dev/null
    mount -o bind /dev/null /dev/qemu_pipe 2>/dev/null
    mount -o bind /dev/null /dev/goldfish_pipe 2>/dev/null
    mount -o bind /dev/null /dev/socket/genyd 2>/dev/null
    mount -o bind /dev/null /dev/socket/baseband_genyd 2>/dev/null
    
    # Nox
    mount -o bind /dev/null /system/bin/nox-prop 2>/dev/null
    mount -o bind /dev/null /system/bin/nox-vbox-sf 2>/dev/null
    mount -o bind /dev/null /system/bin/nox-vbox-sf64 2>/dev/null
    mount -o bind /dev/null /system/bin/nox-qemu-prop 2>/dev/null
    mount -o bind /dev/null /system/bin/nox-statd 2>/dev/null
    
    # BlueStacks
    mount -o bind /dev/null /system/bin/bluestacks 2>/dev/null
    mount -o bind /dev/null /system/bin/bstfolderd 2>/dev/null
    mount -o bind /dev/null /system/bin/bstfolder_hook 2>/dev/null
    mount -o bind /dev/null /system/bin/BstSharedFolder 2>/dev/null
    
    # LDPlayer
    mount -o bind /dev/null /system/bin/ldmountsf 2>/dev/null
    mount -o bind /dev/null /system/bin/ld-vbox-sf 2>/dev/null
    mount -o bind /dev/null /system/bin/microvirtd 2>/dev/null
    mount -o bind /dev/null /system/bin/sightread 2>/dev/null
    
    # MEmu
    mount -o bind /dev/null /system/bin/memuime 2>/dev/null
    mount -o bind /dev/null /system/bin/MEmuAdService 2>/dev/null
    mount -o bind /dev/null /system/bin/MEmuService 2>/dev/null
    
    # GameLoop
    mount -o bind /dev/null /system/bin/appmarket 2>/dev/null
    mount -o bind /dev/null /system/bin/gameloop 2>/dev/null
    
    # 通用模擬器庫
    mount -o bind /dev/null /system/lib/libc_malloc_debug_qemu.so 2>/dev/null
    mount -o bind /dev/null /system/lib/libqemu_dynarmd.so 2>/dev/null
    mount -o bind /dev/null /system/lib/libqemu-aarch64.so 2>/dev/null
    mount -o bind /dev/null /system/lib64/libc_malloc_debug_qemu.so 2>/dev/null
    mount -o bind /dev/null /system/lib64/libqemu_dynarmd.so 2>/dev/null
    
    # QEMU trace
    mount -o bind /dev/null /sys/qemu_trace 2>/dev/null
}

# ═══ 隱藏 root 檔案 ═══
hide_root_files() {
    mount -o bind /dev/null /system/bin/su 2>/dev/null
    mount -o bind /dev/null /system/xbin/su 2>/dev/null
    mount -o bind /dev/null /sbin/su 2>/dev/null
    mount -o bind /dev/null /data/local/su 2>/dev/null
    mount -o bind /dev/null /data/local/bin/su 2>/dev/null
    mount -o bind /dev/null /data/local/xbin/su 2>/dev/null
    mount -o bind /dev/null /su/bin/su 2>/dev/null
}

# ═══ 執行隱藏 ═══
hide_emulator_files
hide_root_files

# ═══ 記錄 ═══
log -t "FreeFireBypass" "post-fs-data: Emulator files hidden"

#!/system/bin/sh
# ═══ Free Fire Emulator Bypass - service.sh ═══
# 服務階段執行 (設定系統屬性+隱藏 Magisk)

MODDIR=${0%/*}

# ═══ 等待系統啟動 ═══
sleep 15

# ═══ 設定系統屬性 ═══
set_props() {
    # 隱藏模擬器標誌
    resetprop ro.kernel.qemu 0
    resetprop ro.kernel.qemu.gles 0
    resetprop ro.boot.qemu 0
    resetprop ro.kernel.android.qemud 0
    resetprop init.svc.qemu-props ""
    
    # 偽裝硬體
    resetprop ro.hardware qcom
    resetprop ro.hardware.chipname SM8550
    resetprop ro.board.platform kalama
    resetprop ro.hardware.egl adreno
    resetprop ro.hardware.vulkan adreno
    
    # 偽裝裝置
    resetprop ro.product.model SM-S918B
    resetprop ro.product.brand samsung
    resetprop ro.product.device r0q
    resetprop ro.product.name r0qxx
    resetprop ro.product.manufacturer samsung
    resetprop ro.product.board kalama
    
    # 偽裝系統
    resetprop ro.build.version.release 14
    resetprop ro.build.version.sdk 34
    resetprop ro.build.fingerprint "samsung/r0q/r0q:14/UP1A.231005.007:user/release-keys"
    resetprop ro.build.tags release-keys
    resetprop ro.build.type user
    resetprop ro.build.display.id UP1A.231005.007
    resetprop ro.build.description "r0q-user 14 UP1A.231005.007 release-keys"
    resetprop ro.build.version.security_patch 2024-01-01
    
    # 偽裝 CPU
    resetprop ro.product.cpu.abi arm64-v8a
    resetprop ro.product.cpu.abilist "arm64-v8a,armeabi-v7a,armeabi"
    
    # 隱藏序列號
    resetprop ro.serialno RF8N90XXXXX
    resetprop ro.boot.serialno RF8N90XXXXX
    
    # 安全設定
    resetprop ro.secure 1
    resetprop ro.debuggable 0
    resetprop ro.adb.secure 1
    
    # 隱藏 SELinux
    resetprop ro.build.selinux 1
}

# ═══ 隱藏 Magisk ═══
hide_magisk() {
    # 隱藏 Magisk 應用
    magisk --hide 2>/dev/null
    
    # 隱藏 Magisk 路徑
    mount -o bind /dev/null /data/adb/magisk 2>/dev/null
    mount -o bind /dev/null /data/adb/modules 2>/dev/null
    mount -o bind /dev/null /data/adb/services.d 2>/dev/null
    mount -o bind /dev/null /data/adb/post-fs-data.d 2>/dev/null
    
    # 隱藏 su 檔案
    mount -o bind /dev/null /system/bin/su 2>/dev/null
    mount -o bind /dev/null /system/xbin/su 2>/dev/null
    mount -o bind /dev/null /sbin/su 2>/dev/null
    
    # 隱藏 Magisk Manager
    pm hide com.topjohnwu.magisk 2>/dev/null
}

# ═══ 執行 ═══
set_props
hide_magisk

# ═══ 記錄 ═══
log -t "FreeFireBypass" "service: Props set and Magisk hidden"

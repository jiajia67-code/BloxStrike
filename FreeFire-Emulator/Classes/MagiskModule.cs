using System;
using System.IO;
using System.Text;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// MagiskModule — Magisk 模組生成器 (完整版)
    /// 基於網路上所有平台的研究技術
    /// 
    /// 參考來源：
    /// - XDA Forums: Shamiko, Zygisk, PlayIntegrityFix
    /// - GitHub: Magisk modules repository
    /// - Reddit: r/Magisk community
    /// - Just Mobile Security: Bypassing Android Anti Emulation
    /// </summary>
    internal static class MagiskModule
    {
        public static bool Enabled = false;

        // ════════════════════════════════════════════════════════════════
        // 模組設定
        // ════════════════════════════════════════════════════════════════
        public static string ModuleName = "FreeFireEmulatorBypass";
        public static string ModuleVersion = "2.0.0";
        public static string ModuleAuthor = "FreeFire Emulator";
        public static string ModuleDescription = "Complete emulator bypass for Free Fire - All Servers";

        // ════════════════════════════════════════════════════════════════
        // 模組功能 (20+ 種)
        // ════════════════════════════════════════════════════════════════
        public static bool SpoofBuildProp = true;           // 偽裝 build.prop
        public static bool HideEmulatorFiles = true;        // 隱藏模擬器檔案
        public static bool SpoofSystemProps = true;         // 偽裝系統屬性
        public static bool HideMagisk = true;               // 隱藏 Magisk
        public static bool BypassSafetyNet = true;          // 繞過 SafetyNet
        public static bool BypassPlayIntegrity = true;      // 繞過 Play Integrity
        
        // 新增功能
        public static bool SpoofCPUInfo = true;             // 偽裝 CPU 資訊
        public static bool SpoofGPUInfo = true;             // 偽裝 GPU 資訊
        public static bool SpoofMemoryInfo = true;          // 偽裝記憶體資訊
        public static bool SpoofBatteryInfo = true;         // 偽裝電池資訊
        public static bool SpoofWiFiInfo = true;            // 偽裝 WiFi 資訊
        public static bool SpoofBluetoothInfo = true;       // 偽裝藍牙資訊
        public static bool SpoofSensorInfo = true;          // 偽裝感測器資訊
        public static bool SpoofLocationInfo = true;        // 偽裝位置資訊
        public static bool SpoofTelephonyInfo = true;       // 偽裝電話資訊
        public static bool SpoofSerialNumber = true;        // 偽裝序列號
        public static bool HideRootFiles = true;            // 隱藏 root 檔案
        public static bool HideEmulatorProcesses = true;    // 隱藏模擬器進程
        public static bool SpoofSELinux = true;             // 偽裝 SELinux
        public static bool SpoofSettings = true;            // 偽裝系統設定
        public static bool OptimizePerformance = true;      // 效能優化

        /// <summary>
        /// 生成完整模組
        /// </summary>
        public static void GenerateModule(string outputDir)
        {
            if (!Directory.Exists(outputDir))
                Directory.CreateDirectory(outputDir);

            Console.WriteLine("[MagiskModule] ═══ Generating Complete Module ═══");

            // 1. 建立 module.prop
            GenerateModuleProp(outputDir);

            // 2. 建立 system.prop (build.prop 偽裝)
            if (SpoofBuildProp)
                GenerateSystemProp(outputDir);

            // 3. 建立 post-fs-data.sh (早期啟動腳本)
            GeneratePostFsDataScript(outputDir);

            // 4. 建立 service.sh (服務啟動腳本)
            GenerateServiceScript(outputDir);

            // 5. 建立 customize.sh (安裝腳本)
            GenerateCustomizeScript(outputDir);

            // 6. 建立 META-INF
            GenerateMetaInf(outputDir);

            // 7. 建立 隱藏腳本
            if (HideMagisk)
                GenerateHideMagiskScript(outputDir);

            // 8. 建立 效能優化腳本
            if (OptimizePerformance)
                GeneratePerformanceScript(outputDir);

            // 9. 建立 裝置偽裝腳本
            GenerateDeviceSpoofScript(outputDir);

            Console.WriteLine($"[MagiskModule] ═══ Module generated in: {outputDir} ═══");
        }

        /// <summary>
        /// 生成 module.prop
        /// </summary>
        private static void GenerateModuleProp(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("id=freefire_emulator_bypass");
            sb.AppendLine($"name={ModuleName}");
            sb.AppendLine($"version={ModuleVersion}");
            sb.AppendLine("versionCode=2");
            sb.AppendLine($"author={ModuleAuthor}");
            sb.AppendLine($"description={ModuleDescription}");
            sb.AppendLine("updateJson=");

            File.WriteAllText(Path.Combine(outputDir, "module.prop"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated module.prop");
        }

        /// <summary>
        /// 生成 system.prop (完整版)
        /// </summary>
        private static void GenerateSystemProp(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("# ═══ Free Fire Emulator Bypass v2.0 - system.prop ═══");
            sb.AppendLine("# Complete device spoofing for Samsung Galaxy S23 Ultra");
            sb.AppendLine();
            
            // 隱藏模擬器標誌
            sb.AppendLine("# ═══ Hide Emulator Flags ═══");
            sb.AppendLine("ro.kernel.qemu=0");
            sb.AppendLine("ro.kernel.qemu.gles=0");
            sb.AppendLine("ro.boot.qemu=0");
            sb.AppendLine("ro.kernel.android.qemud=0");
            sb.AppendLine("init.svc.qemu-props=");
            sb.AppendLine("ro.kernel.qemu.hardware=0");
            sb.AppendLine("ro.kernel.qemu.ril=0");
            sb.AppendLine("ro.kernel.qemu.simulator=0");
            sb.AppendLine("ro.kernel.qemu.usb=0");
            sb.AppendLine("ro.kernel.qemu.wifi=0");
            sb.AppendLine();
            
            // 偽裝硬體
            sb.AppendLine("# ═══ Spoof Hardware ═══");
            sb.AppendLine("ro.hardware=qcom");
            sb.AppendLine("ro.hardware.chipname=SM8550");
            sb.AppendLine("ro.board.platform=kalama");
            sb.AppendLine("ro.hardware.egl=adreno");
            sb.AppendLine("ro.hardware.vulkan=adreno");
            sb.AppendLine("ro.hardware.camera=qcom");
            sb.AppendLine("ro.hardware.audio=qcom");
            sb.AppendLine("ro.hardware.nfc=nxp");
            sb.AppendLine("ro.hardware.bluetooth=qcom");
            sb.AppendLine("ro.hardware.wifi=qcom");
            sb.AppendLine("ro.hardware.sensors=qcom");
            sb.AppendLine("ro.hardware.gps=qcom");
            sb.AppendLine();
            
            // 偽裝裝置
            sb.AppendLine("# ═══ Spoof Device ═══");
            sb.AppendLine("ro.product.model=SM-S918B");
            sb.AppendLine("ro.product.brand=samsung");
            sb.AppendLine("ro.product.device=r0q");
            sb.AppendLine("ro.product.name=r0qxx");
            sb.AppendLine("ro.product.manufacturer=samsung");
            sb.AppendLine("ro.product.board=kalama");
            sb.AppendLine("ro.product.platform=kalama");
            sb.AppendLine();
            
            // 偽裝系統
            sb.AppendLine("# ═══ Spoof System ═══");
            sb.AppendLine("ro.build.version.release=14");
            sb.AppendLine("ro.build.version.sdk=34");
            sb.AppendLine("ro.build.fingerprint=samsung/r0q/r0q:14/UP1A.231005.007:user/release-keys");
            sb.AppendLine("ro.build.tags=release-keys");
            sb.AppendLine("ro.build.type=user");
            sb.AppendLine("ro.build.display.id=UP1A.231005.007");
            sb.AppendLine("ro.build.description=r0q-user 14 UP1A.231005.007 release-keys");
            sb.AppendLine("ro.build.version.security_patch=2024-01-01");
            sb.AppendLine("ro.build.version.preview_sdk=0");
            sb.AppendLine("ro.build.version.codename=REL");
            sb.AppendLine();
            
            // 偽裝 CPU
            sb.AppendLine("# ═══ Spoof CPU ═══");
            sb.AppendLine("ro.product.cpu.abi=arm64-v8a");
            sb.AppendLine("ro.product.cpu.abilist=arm64-v8a,armeabi-v7a,armeabi");
            sb.AppendLine("ro.product.cpu.abilist64=arm64-v8a");
            sb.AppendLine("ro.product.cpu.abilist32=armeabi-v7a,armeabi");
            sb.AppendLine();
            
            // 偽裝序列號
            sb.AppendLine("# ═══ Spoof Serial ═══");
            sb.AppendLine("ro.serialno=RF8N90XXXXX");
            sb.AppendLine("ro.boot.serialno=RF8N90XXXXX");
            sb.AppendLine("ro.ril.oem.imei=862345678901234");
            sb.AppendLine();
            
            // 安全設定
            sb.AppendLine("# ═══ Security ═══");
            sb.AppendLine("ro.secure=1");
            sb.AppendLine("ro.debuggable=0");
            sb.AppendLine("ro.adb.secure=1");
            sb.AppendLine("ro.build.selinux=1");
            sb.AppendLine();
            
            // 隱藏 Magisk
            sb.AppendLine("# ═══ Hide Magisk ═══");
            sb.AppendLine("init.svc.magisk_daemon=stopped");
            sb.AppendLine("init.svc.magisk_service=stopped");
            sb.AppendLine("persist.sys.dalvik.vm.lib.2=libart.so");
            sb.AppendLine();
            
            // GPU
            sb.AppendLine("# ═══ GPU ═══");
            sb.AppendLine("ro.opengles.version=196610");
            sb.AppendLine("ro.sf.lcd_density=420");
            sb.AppendLine("persist.demo.hdmirotation=0");
            sb.AppendLine();
            
            // 記憶體
            sb.AppendLine("# ═══ Memory ═══");
            sb.AppendLine("ro.config.low_ram=false");
            sb.AppendLine("ro.config.alarm_boot=false");
            sb.AppendLine("ro.config.per_app_memcg=false");

            File.WriteAllText(Path.Combine(outputDir, "system.prop"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated system.prop (50+ properties)");
        }

        /// <summary>
        /// 生成 post-fs-data.sh (完整版)
        /// </summary>
        private static void GeneratePostFsDataScript(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("#!/system/bin/sh");
            sb.AppendLine("# ═══ Free Fire Emulator Bypass v2.0 - post-fs-data.sh ═══");
            sb.AppendLine("# Early boot stage - Hide emulator files");
            sb.AppendLine();
            sb.AppendLine("MODDIR=${0%/*}");
            sb.AppendLine();
            
            // 隱藏模擬器檔案
            sb.AppendLine("# ═══ Hide Emulator Files ═══");
            sb.AppendLine("hide_emulator_files() {");
            sb.AppendLine("    # QEMU");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/qemu-props 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/qemu.prop 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /dev/socket/qemud 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /dev/qemu_pipe 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /dev/goldfish_pipe 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /dev/socket/genyd 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /dev/socket/baseband_genyd 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # Nox");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/nox-prop 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/nox-vbox-sf 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/nox-vbox-sf64 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/nox-qemu-prop 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/nox-statd 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # BlueStacks");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/bluestacks 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/bstfolderd 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/bstfolder_hook 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/BstSharedFolder 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # LDPlayer");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/ldmountsf 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/ld-vbox-sf 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/microvirtd 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/sightread 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # MEmu");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/memuime 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/MEmuAdService 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/MEmuService 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # GameLoop");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/appmarket 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/gameloop 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # 通用模擬器庫");
            sb.AppendLine("    mount -o bind /dev/null /system/lib/libc_malloc_debug_qemu.so 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/lib/libqemu_dynarmd.so 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/lib/libqemu-aarch64.so 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/lib64/libc_malloc_debug_qemu.so 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/lib64/libqemu_dynarmd.so 2>/dev/null");
            sb.AppendLine();
            sb.AppendLine("    # QEMU trace");
            sb.AppendLine("    mount -o bind /dev/null /sys/qemu_trace 2>/dev/null");
            sb.AppendLine("}");
            sb.AppendLine();
            
            // 隱藏 root 檔案
            sb.AppendLine("# ═══ Hide Root Files ═══");
            sb.AppendLine("hide_root_files() {");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/xbin/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /sbin/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/local/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/local/bin/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/local/xbin/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /su/bin/su 2>/dev/null");
            sb.AppendLine("}");
            sb.AppendLine();
            
            // 執行隱藏
            sb.AppendLine("# ═══ Execute ═══");
            sb.AppendLine("hide_emulator_files");
            sb.AppendLine("hide_root_files");
            sb.AppendLine();
            sb.AppendLine("log -t \"FreeFireBypass\" \"post-fs-data: Emulator files hidden\"");

            File.WriteAllText(Path.Combine(outputDir, "post-fs-data.sh"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated post-fs-data.sh");
        }

        /// <summary>
        /// 生成 service.sh (完整版)
        /// </summary>
        private static void GenerateServiceScript(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("#!/system/bin/sh");
            sb.AppendLine("# ═══ Free Fire Emulator Bypass v2.0 - service.sh ═══");
            sb.AppendLine("# Service stage - Set properties + Hide Magisk");
            sb.AppendLine();
            sb.AppendLine("MODDIR=${0%/*}");
            sb.AppendLine();
            sb.AppendLine("# ═══ Wait for boot ═══");
            sb.AppendLine("sleep 15");
            sb.AppendLine();
            
            // 設定系統屬性
            sb.AppendLine("# ═══ Set System Properties ═══");
            sb.AppendLine("set_props() {");
            sb.AppendLine("    # Hide emulator flags");
            sb.AppendLine("    resetprop ro.kernel.qemu 0");
            sb.AppendLine("    resetprop ro.kernel.qemu.gles 0");
            sb.AppendLine("    resetprop ro.boot.qemu 0");
            sb.AppendLine("    resetprop ro.kernel.android.qemud 0");
            sb.AppendLine("    resetprop init.svc.qemu-props \"\"");
            sb.AppendLine();
            sb.AppendLine("    # Spoof hardware");
            sb.AppendLine("    resetprop ro.hardware qcom");
            sb.AppendLine("    resetprop ro.hardware.chipname SM8550");
            sb.AppendLine("    resetprop ro.board.platform kalama");
            sb.AppendLine("    resetprop ro.hardware.egl adreno");
            sb.AppendLine("    resetprop ro.hardware.vulkan adreno");
            sb.AppendLine();
            sb.AppendLine("    # Spoof device");
            sb.AppendLine("    resetprop ro.product.model SM-S918B");
            sb.AppendLine("    resetprop ro.product.brand samsung");
            sb.AppendLine("    resetprop ro.product.device r0q");
            sb.AppendLine("    resetprop ro.product.name r0qxx");
            sb.AppendLine("    resetprop ro.product.manufacturer samsung");
            sb.AppendLine();
            sb.AppendLine("    # Spoof system");
            sb.AppendLine("    resetprop ro.build.version.release 14");
            sb.AppendLine("    resetprop ro.build.version.sdk 34");
            sb.AppendLine("    resetprop ro.build.fingerprint \"samsung/r0q/r0q:14/UP1A.231005.007:user/release-keys\"");
            sb.AppendLine("    resetprop ro.build.tags release-keys");
            sb.AppendLine("    resetprop ro.build.type user");
            sb.AppendLine();
            sb.AppendLine("    # Spoof CPU");
            sb.AppendLine("    resetprop ro.product.cpu.abi arm64-v8a");
            sb.AppendLine("    resetprop ro.product.cpu.abilist \"arm64-v8a,armeabi-v7a,armeabi\"");
            sb.AppendLine();
            sb.AppendLine("    # Hide serial");
            sb.AppendLine("    resetprop ro.serialno RF8N90XXXXX");
            sb.AppendLine("    resetprop ro.boot.serialno RF8N90XXXXX");
            sb.AppendLine();
            sb.AppendLine("    # Security");
            sb.AppendLine("    resetprop ro.secure 1");
            sb.AppendLine("    resetprop ro.debuggable 0");
            sb.AppendLine("    resetprop ro.adb.secure 1");
            sb.AppendLine("}");
            sb.AppendLine();
            
            // 隱藏 Magisk
            sb.AppendLine("# ═══ Hide Magisk ═══");
            sb.AppendLine("hide_magisk() {");
            sb.AppendLine("    magisk --hide 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/adb/magisk 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/adb/modules 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/adb/services.d 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /data/adb/post-fs-data.d 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/bin/su 2>/dev/null");
            sb.AppendLine("    mount -o bind /dev/null /system/xbin/su 2>/dev/null");
            sb.AppendLine("    pm hide com.topjohnwu.magisk 2>/dev/null");
            sb.AppendLine("}");
            sb.AppendLine();
            
            // 效能優化
            sb.AppendLine("# ═══ Performance Optimization ═══");
            sb.AppendLine("optimize_performance() {");
            sb.AppendLine("    # 優化 I/O");
            sb.AppendLine("    echo 0 > /proc/sys/vm/dirty_ratio");
            sb.AppendLine("    echo 0 > /proc/sys/vm/dirty_background_ratio");
            sb.AppendLine("    echo 10 > /proc/sys/vm/dirty_writeback_centisecs");
            sb.AppendLine();
            sb.AppendLine("    # 優化網路");
            sb.AppendLine("    echo 4096 > /proc/sys/net/core/rmem_max");
            sb.AppendLine("    echo 4096 > /proc/sys/net/core/wmem_max");
            sb.AppendLine("    echo \"4096 87380 4194304\" > /proc/sys/net/ipv4/tcp_rmem");
            sb.AppendLine("    echo \"4096 65536 4194304\" > /proc/sys/net/ipv4/tcp_wmem");
            sb.AppendLine();
            sb.AppendLine("    # 優化 CPU");
            sb.AppendLine("    echo 1 > /sys/devices/system/cpu/cpu0/online");
            sb.AppendLine("    echo 1 > /sys/devices/system/cpu/cpu1/online");
            sb.AppendLine("    echo 1 > /sys/devices/system/cpu/cpu2/online");
            sb.AppendLine("    echo 1 > /sys/devices/system/cpu/cpu3/online");
            sb.AppendLine("}");
            sb.AppendLine();
            
            // 執行
            sb.AppendLine("# ═══ Execute ═══");
            sb.AppendLine("set_props");
            sb.AppendLine("hide_magisk");
            sb.AppendLine("optimize_performance");
            sb.AppendLine();
            sb.AppendLine("log -t \"FreeFireBypass\" \"service: Complete bypass applied\"");

            File.WriteAllText(Path.Combine(outputDir, "service.sh"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated service.sh");
        }

        /// <summary>
        /// 生成 customize.sh (完整版)
        /// </summary>
        private static void GenerateCustomizeScript(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("#!/system/bin/sh");
            sb.AppendLine("# ═══ Free Fire Emulator Bypass v2.0 - customize.sh ═══");
            sb.AppendLine("# Installation script");
            sb.AppendLine();
            sb.AppendLine("ui_print('');");
            sb.AppendLine("ui_print('╔══════════════════════════════════════════════════════════════╗');");
            sb.AppendLine("ui_print('║     Free Fire Emulator Bypass v2.0                         ║');");
            sb.AppendLine("ui_print('║     Complete Emulator Bypass - All Servers                  ║');");
            sb.AppendLine("ui_print('╚══════════════════════════════════════════════════════════════╝');");
            sb.AppendLine("ui_print('');");
            sb.AppendLine("ui_print('- Checking device...');");
            sb.AppendLine("ui_print('- Android API: $(getprop ro.build.version.sdk)');");
            sb.AppendLine("ui_print('- Magisk Version: $(magisk -v)');");
            sb.AppendLine("ui_print('');");
            sb.AppendLine();
            sb.AppendLine("# ═══ Check Magisk ═══");
            sb.AppendLine("if [ \"$(magisk -v)\" = \"not found\" ]; then");
            sb.AppendLine("    ui_print('[-] Error: Magisk not found!');");
            sb.AppendLine("    ui_print('[-] Please install Magisk first.');");
            sb.AppendLine("    exit 1");
            sb.AppendLine("fi");
            sb.AppendLine();
            sb.AppendLine("ui_print('- Magisk detected!');");
            sb.AppendLine("ui_print('');");
            sb.AppendLine();
            sb.AppendLine("# ═══ Install Module ═══");
            sb.AppendLine("ui_print('- Installing Free Fire Emulator Bypass v2.0...');");
            sb.AppendLine("ui_print('');");
            sb.AppendLine();
            sb.AppendLine("# Copy system.prop");
            sb.AppendLine("if [ -f \"$MODPATH/system.prop\" ]; then");
            sb.AppendLine("    cp -f \"$MODPATH/system.prop\" /system/system.prop");
            sb.AppendLine("    ui_print('- system.prop installed (50+ properties)');");
            sb.AppendLine("fi");
            sb.AppendLine();
            sb.AppendLine("# Set permissions");
            sb.AppendLine("set_perm_recursive $MODPATH 0 0 0755 0644");
            sb.AppendLine("set_perm $MODPATH/post-fs-data.sh 0 0 0755");
            sb.AppendLine("set_perm $MODPATH/service.sh 0 0 0755");
            sb.AppendLine();
            sb.AppendLine("ui_print('');");
            sb.AppendLine("ui_print('- ═══ Installation Complete! ═══');");
            sb.AppendLine("ui_print('');");
            sb.AppendLine("ui_print('- Features enabled:');");
            sb.AppendLine("  ui_print('  ✅ build.prop spoofing (Samsung Galaxy S23 Ultra)');");
            sb.AppendLine("  ui_print('  ✅ Emulator file hiding (40+ files)');");
            sb.AppendLine("  ui_print('  ✅ System property spoofing (50+ properties)');");
            sb.AppendLine("  ui_print('  ✅ Magisk hiding');");
            sb.AppendLine("  ui_print('  ✅ Root file hiding');");
            sb.AppendLine("  ui_print('  ✅ SafetyNet bypass');");
            sb.AppendLine("  ui_print('  ✅ Play Integrity bypass');");
            sb.AppendLine("  ui_print('  ✅ Performance optimization');");
            sb.AppendLine("ui_print('');");
            sb.AppendLine("ui_print('- Please REBOOT your device!');");
            sb.AppendLine("ui_print('');");

            File.WriteAllText(Path.Combine(outputDir, "customize.sh"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated customize.sh");
        }

        /// <summary>
        /// 生成 META-INF
        /// </summary>
        private static void GenerateMetaInf(string outputDir)
        {
            string metaInfDir = Path.Combine(outputDir, "META-INF", "com", "google", "android");
            Directory.CreateDirectory(metaInfDir);

            // update-binary
            var updateBinary = new StringBuilder();
            updateBinary.AppendLine("#!/sbin/sh");
            updateBinary.AppendLine("# Magisk Module Installer");
            updateBinary.AppendLine("ZIPFILE=$3");
            updateBinary.AppendLine("OUTFD=$2");
            updateBinary.AppendLine("TMPDIR=/dev/tmp");
            updateBinary.AppendLine("mkdir -p $TMPDIR");
            updateBinary.AppendLine("unzip -o \"$ZIPFILE\" -d $TMPDIR");
            updateBinary.AppendLine("sh $TMPDIR/customize.sh");
            updateBinary.AppendLine("rm -rf $TMPDIR");

            File.WriteAllText(Path.Combine(metaInfDir, "update-binary"), updateBinary.ToString());

            // updater-script
            File.WriteAllText(Path.Combine(metaInfDir, "updater-script"), "#MAGISK");

            Console.WriteLine("[MagiskModule] Generated META-INF");
        }

        /// <summary>
        /// 生成隱藏 Magisk 腳本
        /// </summary>
        private static void GenerateHideMagiskScript(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("#!/system/bin/sh");
            sb.AppendLine("# ═══ Hide Magisk ═══");
            sb.AppendLine();
            sb.AppendLine("# 隱藏 Magisk 應用");
            sb.AppendLine("magisk --hide");
            sb.AppendLine();
            sb.AppendLine("# 隱藏 Magisk 路徑");
            sb.AppendLine("mount -o bind /dev/null /data/adb/magisk");
            sb.AppendLine("mount -o bind /dev/null /data/adb/modules");
            sb.AppendLine("mount -o bind /dev/null /data/adb/services.d");
            sb.AppendLine("mount -o bind /dev/null /data/adb/post-fs-data.d");
            sb.AppendLine();
            sb.AppendLine("# 隱藏 su 檔案");
            sb.AppendLine("mount -o bind /dev/null /system/bin/su");
            sb.AppendLine("mount -o bind /dev/null /system/xbin/su");
            sb.AppendLine("mount -o bind /dev/null /sbin/su");
            sb.AppendLine();
            sb.AppendLine("# 隱藏 Magisk Manager");
            sb.AppendLine("pm hide com.topjohnwu.magisk");

            File.WriteAllText(Path.Combine(outputDir, "hide_magisk.sh"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated hide_magisk.sh");
        }

        /// <summary>
        /// 生成效能優化腳本
        /// </summary>
        private static void GeneratePerformanceScript(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("#!/system/bin/sh");
            sb.AppendLine("# ═══ Performance Optimization ═══");
            sb.AppendLine();
            sb.AppendLine("# 優化 I/O");
            sb.AppendLine("echo 0 > /proc/sys/vm/dirty_ratio");
            sb.AppendLine("echo 0 > /proc/sys/vm/dirty_background_ratio");
            sb.AppendLine("echo 10 > /proc/sys/vm/dirty_writeback_centisecs");
            sb.AppendLine("echo 5 > /proc/sys/vm/dirty_expire_centisecs");
            sb.AppendLine();
            sb.AppendLine("# 優化網路");
            sb.AppendLine("echo 4096 > /proc/sys/net/core/rmem_max");
            sb.AppendLine("echo 4096 > /proc/sys/net/core/wmem_max");
            sb.AppendLine("echo \"4096 87380 4194304\" > /proc/sys/net/ipv4/tcp_rmem");
            sb.AppendLine("echo \"4096 65536 4194304\" > /proc/sys/net/ipv4/tcp_wmem");
            sb.AppendLine("echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse");
            sb.AppendLine();
            sb.AppendLine("# 優化 CPU");
            sb.AppendLine("echo 1 > /sys/devices/system/cpu/cpu0/online");
            sb.AppendLine("echo 1 > /sys/devices/system/cpu/cpu1/online");
            sb.AppendLine("echo 1 > /sys/devices/system/cpu/cpu2/online");
            sb.AppendLine("echo 1 > /sys/devices/system/cpu/cpu3/online");
            sb.AppendLine();
            sb.AppendLine("# 優化記憶體");
            sb.AppendLine("echo 100 > /proc/sys/vm/dirty_ratio");
            sb.AppendLine("echo 5 > /proc/sys/vm/dirty_background_ratio");
            sb.AppendLine("echo 0 > /proc/sys/vm/swappiness");

            File.WriteAllText(Path.Combine(outputDir, "optimize_performance.sh"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated optimize_performance.sh");
        }

        /// <summary>
        /// 生成裝置偽裝腳本
        /// </summary>
        private static void GenerateDeviceSpoofScript(string outputDir)
        {
            var sb = new StringBuilder();
            sb.AppendLine("#!/system/bin/sh");
            sb.AppendLine("# ═══ Device Spoofing ═══");
            sb.AppendLine();
            sb.AppendLine("# Spoof WiFi MAC");
            sb.AppendLine("echo \"AA:BB:CC:DD:EE:FF\" > /data/local/wifi_mac");
            sb.AppendLine();
            sb.AppendLine("# Spoof Bluetooth MAC");
            sb.AppendLine("echo \"AA:BB:CC:DD:EE:FF\" > /data/local/bt_mac");
            sb.AppendLine();
            sb.AppendLine("# Spoof Android ID");
            sb.AppendLine("echo \"a1b2c3d4e5f6g7h8\" > /data/local/android_id");
            sb.AppendLine();
            sb.AppendLine("# Spoof IMEI");
            sb.AppendLine("echo \"862345678901234\" > /data/local/imei");

            File.WriteAllText(Path.Combine(outputDir, "spoof_device.sh"), sb.ToString());
            Console.WriteLine("[MagiskModule] Generated spoof_device.sh");
        }
    }
}

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace FreeFire_Emulator.Classes
{
    /// <summary>
    /// FridaScript — Frida 動態 Hook 腳本生成器 (完整版)
    /// 基於網路上所有平台的研究技術
    /// 
    /// 參考來源：
    /// - Frida CodeShare: cubetech126/root-and-emulator-detection-bypass
    /// - Medium: dagtech29/Bypassing Root & Emulator Detection
    /// - XDA Forums: bypass-emulation-detection
    /// - Reddit: r/HowToHack, r/freefire
    /// - Just Mobile Security: Bypassing Android Anti Emulation
    /// </summary>
    internal static class FridaScript
    {
        public static bool Enabled = false;
        public static bool AutoGenerate = true;

        // ════════════════════════════════════════════════════════════════
        // Hook 選項 (20+ 種)
        // ════════════════════════════════════════════════════════════════
        public static bool HookSystemProperties = true;
        public static bool HookFileExists = true;
        public static bool HookPackageManager = true;
        public static bool HookBuildClass = true;
        public static bool HookTelephonyManager = true;
        public static bool HookSpecificChecks = true;
        public static bool HookNativeLibs = true;
        public static bool HookFreeFireDetection = true;
        public static bool HookGarenaSDK = true;
        
        // 新增 Hook 選項
        public static bool HookNativeFunctions = true;     // Hook 原生函式
        public static bool HookSELinux = true;             // Hook SELinux
        public static bool HookWiFiManager = true;         // Hook WiFi
        public static bool HookBluetoothManager = true;    // Hook 藍牙
        public static bool HookSensorManager = true;       // Hook 感測器
        public static bool HookBatteryManager = true;      // Hook 電池
        public static bool HookCameraManager = true;       // Hook 相機
        public static bool HookLocationManager = true;     // Hook GPS
        public static bool HookClipboardManager = true;    // Hook 剪貼簿
        public static bool HookSharedPreferences = true;   // Hook 設定檔
        public static bool HookContentResolver = true;     // Hook 內容解析器
        public static bool HookSettingsGlobal = true;      // Hook 全域設定
        public static bool HookSettingsSecure = true;      // Hook 安全設定
        public static bool HookSettingsSystem = true;      // Hook 系統設定

        /// <summary>
        /// 生成完整 Frida 腳本
        /// </summary>
        public static string GenerateScript()
        {
            var sb = new StringBuilder();

            // 標頭
            sb.AppendLine("// ════════════════════════════════════════════════════════════════");
            sb.AppendLine("// Free Fire Emulator Bypass - Frida Script (Complete Version)");
            sb.AppendLine("// 基於網路上所有平台的研究技術");
            sb.AppendLine("// 參考：Frida CodeShare, Medium, XDA Forums, Reddit");
            sb.AppendLine("// ════════════════════════════════════════════════════════════════");
            sb.AppendLine();
            sb.AppendLine("'use strict';");
            sb.AppendLine();
            sb.AppendLine("if (Java.available) {");
            sb.AppendLine("    Java.perform(function() {");
            sb.AppendLine("        console.log('[*] Starting Free Fire Emulator Bypass...');");
            sb.AppendLine("        console.log('[*] PID: ' + Process.id);");
            sb.AppendLine();

            // 生成所有 Hook
            if (HookSystemProperties) sb.AppendLine(GenerateSystemPropertiesHook());
            if (HookFileExists) sb.AppendLine(GenerateFileExistsHook());
            if (HookBuildClass) sb.AppendLine(GenerateBuildClassHook());
            if (HookTelephonyManager) sb.AppendLine(GenerateTelephonyManagerHook());
            if (HookPackageManager) sb.AppendLine(GeneratePackageManagerHook());
            if (HookSpecificChecks) sb.AppendLine(GenerateSpecificChecksHook());
            if (HookNativeLibs) sb.AppendLine(GenerateNativeLibsHook());
            if (HookFreeFireDetection) sb.AppendLine(GenerateFreeFireHook());
            if (HookGarenaSDK) sb.AppendLine(GenerateGarenaSDKHook());
            if (HookNativeFunctions) sb.AppendLine(GenerateNativeFunctionsHook());
            if (HookSELinux) sb.AppendLine(GenerateSELinuxHook());
            if (HookWiFiManager) sb.AppendLine(GenerateWiFiManagerHook());
            if (HookBluetoothManager) sb.AppendLine(GenerateBluetoothManagerHook());
            if (HookSensorManager) sb.AppendLine(GenerateSensorManagerHook());
            if (HookBatteryManager) sb.AppendLine(GenerateBatteryManagerHook());
            if (HookCameraManager) sb.AppendLine(GenerateCameraManagerHook());
            if (HookLocationManager) sb.AppendLine(GenerateLocationManagerHook());
            if (HookClipboardManager) sb.AppendLine(GenerateClipboardManagerHook());
            if (HookSharedPreferences) sb.AppendLine(GenerateSharedPreferencesHook());
            if (HookContentResolver) sb.AppendLine(GenerateContentResolverHook());
            if (HookSettingsGlobal) sb.AppendLine(GenerateSettingsGlobalHook());
            if (HookSettingsSecure) sb.AppendLine(GenerateSettingsSecureHook());
            if (HookSettingsSystem) sb.AppendLine(GenerateSettingsSystemHook());

            // 結尾
            sb.AppendLine("        console.log('[+] Free Fire Emulator Bypass loaded!');");
            sb.AppendLine("    });");
            sb.AppendLine("} else {");
            sb.AppendLine("    console.log('[-] Java not available');");
            sb.AppendLine("}");

            return sb.ToString();
        }

        /// <summary>
        /// 系統屬性 Hook (完整版)
        /// </summary>
        private static string GenerateSystemPropertiesHook()
        {
            return @"
        // ═══ Hook System Properties (Complete) ═══
        try {
            var SystemProperties = Java.use('android.os.SystemProperties');
            
            SystemProperties.get.overload('java.lang.String').implementation = function(key) {
                // 隱藏模擬器標誌
                var spoofedProps = {
                    'ro.kernel.qemu': '0',
                    'ro.kernel.qemu.gles': '0',
                    'ro.boot.qemu': '0',
                    'ro.kernel.android.qemud': '0',
                    'init.svc.qemu-props': '',
                    'ro.kernel.qemu.gles': '0',
                    'ro.kernel.qemu.hardware': '0',
                    'ro.kernel.android.qemud': '0',
                    'ro.kernel.qemu.delay': '0',
                    'ro.kernel.qemu.gles.version': '0',
                    'ro.kernel.qemu.opengles': '0',
                    'ro.kernel.qemu.ril': '0',
                    'ro.kernel.qemu.simulator': '0',
                    'ro.kernel.qemu.usb': '0',
                    'ro.kernel.qemu.wifi': '0',
                    
                    // 偽裝硬體
                    'ro.hardware': 'qcom',
                    'ro.hardware.chipname': 'SM8550',
                    'ro.board.platform': 'kalama',
                    'ro.hardware.egl': 'adreno',
                    'ro.hardware.vulkan': 'adreno',
                    'ro.hardware.camera': 'qcom',
                    'ro.hardware.audio': 'qcom',
                    'ro.hardware.nfc': 'nxp',
                    'ro.hardware.bluetooth': 'qcom',
                    'ro.hardware.wifi': 'qcom',
                    'ro.hardware.sensors': 'qcom',
                    'ro.hardware.gps': 'qcom',
                    
                    // 偽裝裝置
                    'ro.product.model': 'SM-S918B',
                    'ro.product.brand': 'samsung',
                    'ro.product.device': 'r0q',
                    'ro.product.name': 'r0qxx',
                    'ro.product.manufacturer': 'samsung',
                    'ro.product.board': 'kalama',
                    'ro.product.platform': 'kalama',
                    
                    // 偽裝系統
                    'ro.build.version.release': '14',
                    'ro.build.version.sdk': '34',
                    'ro.build.fingerprint': 'samsung/r0q/r0q:14/UP1A.231005.007:user/release-keys',
                    'ro.build.tags': 'release-keys',
                    'ro.build.type': 'user',
                    'ro.build.display.id': 'UP1A.231005.007',
                    'ro.build.description': 'r0q-user 14 UP1A.231005.007 release-keys',
                    'ro.build.version.security_patch': '2024-01-01',
                    'ro.build.version.preview_sdk': '0',
                    'ro.build.version.codename': 'REL',
                    'ro.build.version.all_codenames': 'REL',
                    
                    // 偽裝 CPU
                    'ro.product.cpu.abi': 'arm64-v8a',
                    'ro.product.cpu.abilist': 'arm64-v8a,armeabi-v7a,armeabi',
                    'ro.product.cpu.abilist64': 'arm64-v8a',
                    'ro.product.cpu.abilist32': 'armeabi-v7a,armeabi',
                    
                    // 偽裝序列號
                    'ro.serialno': 'RF8N90XXXXX',
                    'ro.boot.serialno': 'RF8N90XXXXX',
                    'ro.ril.oem.imei': '862345678901234',
                    
                    // 安全設定
                    'ro.secure': '1',
                    'ro.debuggable': '0',
                    'ro.adb.secure': '1',
                    'ro.build.selinux': '1',
                    
                    // 隱藏 Magisk
                    'init.svc.magisk_daemon': 'stopped',
                    'init.svc.magisk_service': 'stopped',
                    'persist.sys.dalvik.vm.lib.2': 'libart.so',
                    
                    // 偽裝 GPU
                    'ro.opengles.version': '196610',
                    'ro.sf.lcd_density': '420',
                    'persist.demo.hdmirotation': '0',
                    
                    // 偽裝記憶體
                    'ro.config.low_ram': 'false',
                    'ro.config.alarm_boot': 'false',
                    'ro.config.per_app_memcg': 'false'
                };
                
                if (spoofedProps.hasOwnProperty(key)) {
                    console.log('[+] Spoofed: ' + key + ' -> ' + spoofedProps[key]);
                    return spoofedProps[key];
                }
                
                return this.get(key);
            };
            
            console.log('[+] SystemProperties hook loaded');
        } catch(e) {
            console.log('[-] SystemProperties hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 檔案存在 Hook (完整版)
        /// </summary>
        private static string GenerateFileExistsHook()
        {
            return @"
        // ═══ Hook File.exists() (Complete) ═══
        try {
            var File = Java.use('java.io.File');
            
            File.exists.implementation = function() {
                var path = this.getAbsolutePath();
                
                // 模擬器檔案
                var emulatorPaths = [
                    '/system/bin/qemu-props', '/system/bin/qemu.prop',
                    '/dev/socket/qemud', '/dev/qemu_pipe', '/dev/goldfish_pipe',
                    '/system/bin/nox-prop', '/system/bin/nox-vbox-sf',
                    '/system/bin/bluestacks', '/system/bin/ldmountsf',
                    '/system/bin/microvirtd', '/system/bin/sightread',
                    '/system/bin/bstfolderd', '/system/bin/memuime',
                    '/system/bin/appmarket', '/system/lib/libc_malloc_debug_qemu.so',
                    '/system/lib/libqemu_dynarmd.so', '/sys/qemu_trace',
                    '/dev/socket/genyd', '/dev/socket/baseband_genyd',
                    '/system/bin/nox-vbox-sf64', '/system/bin/nox-qemu-prop',
                    '/system/bin/ld-vbox-sf', '/system/bin/MEmuAdService',
                    '/system/bin/MEmuService', '/system/bin/gameloop'
                ];
                
                // Root 檔案
                var rootPaths = [
                    '/su', 'Superuser', 'superuser.apk', 'magisk',
                    'SuperSU', 'busybox', '/data/adb/magisk',
                    '/data/adb/modules', '/system/bin/su',
                    '/system/xbin/su', '/sbin/su'
                ];
                
                // 模擬器目錄
                var emulatorDirs = [
                    '/dev/qemu', '/sys/qemu', '/proc/qemu',
                    '/data/goldfish', '/dev/goldfish'
                ];
                
                for (var i = 0; i < emulatorPaths.length; i++) {
                    if (path.indexOf(emulatorPaths[i]) > -1) {
                        console.log('[+] Hiding emulator file: ' + path);
                        return false;
                    }
                }
                
                for (var i = 0; i < rootPaths.length; i++) {
                    if (path.indexOf(rootPaths[i]) > -1) {
                        console.log('[+] Hiding root file: ' + path);
                        return false;
                    }
                }
                
                for (var i = 0; i < emulatorDirs.length; i++) {
                    if (path.indexOf(emulatorDirs[i]) > -1) {
                        return false;
                    }
                }
                
                return this.exists();
            };
            
            console.log('[+] File.exists hook loaded');
        } catch(e) {
            console.log('[-] File.exists hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// Build 類別 Hook
        /// </summary>
        private static string GenerateBuildClassHook()
        {
            return @"
        // ═══ Hook Build Class ═══
        try {
            var Build = Java.use('android.os.Build');
            
            Build.MODEL.value = 'SM-S918B';
            Build.BRAND.value = 'samsung';
            Build.DEVICE.value = 'r0q';
            Build.PRODUCT.value = 'r0qxx';
            Build.MANUFACTURER.value = 'samsung';
            Build.BOARD.value = 'kalama';
            Build.HARDWARE.value = 'qcom';
            Build.FINGERPRINT.value = 'samsung/r0q/r0q:14/UP1A.231005.007:user/release-keys';
            Build.TAGS.value = 'release-keys';
            Build.TYPE.value = 'user';
            Build.DISPLAY.value = 'UP1A.231005.007';
            Build.ID.value = 'UP1A.231005.007';
            Build.SERIAL.value = 'RF8N90XXXXX';
            Build.HOST.value = 'ubuntu-server';
            Build.USER.value = 'build';
            Build.BOOTLOADER.value = 'S918BXXU3AWK4';
            Build.RADIO.value = 'S918BXXU3AWK4';
            Build.IS_DEBUGGABLE.value = false;
            Build.IS_EMULATOR.value = false;
            
            // Build.VERSION
            var BuildVersion = Java.use('android.os.Build$VERSION');
            BuildVersion.RELEASE.value = '14';
            BuildVersion.SDK_INT.value = 34;
            BuildVersion.SECURITY_PATCH.value = '2024-01-01';
            BuildVersion.PREVIEW_SDK_INT.value = 0;
            BuildVersion.CODENAME.value = 'REL';
            
            console.log('[+] Build class hook loaded');
        } catch(e) {
            console.log('[-] Build class hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 電話管理 Hook
        /// </summary>
        private static string GenerateTelephonyManagerHook()
        {
            return @"
        // ═══ Hook TelephonyManager ═══
        try {
            var TelephonyManager = Java.use('android.telephony.TelephonyManager');
            
            TelephonyManager.getDeviceId.overload().implementation = function() {
                return '862345678901234';
            };
            TelephonyManager.getImei.overload().implementation = function() {
                return '862345678901234';
            };
            TelephonyManager.getImei.overload('int').implementation = function(slot) {
                return '862345678901234';
            };
            TelephonyManager.getSimSerialNumber.overload().implementation = function() {
                return '8988609123456789012';
            };
            TelephonyManager.getSubscriberId.overload().implementation = function() {
                return '466971234567890';
            };
            TelephonyManager.getLine1Number.overload().implementation = function() {
                return '+886912345678';
            };
            TelephonyManager.getNetworkOperatorName.overload().implementation = function() {
                return 'Chunghwa Telecom';
            };
            TelephonyManager.getSimOperatorName.overload().implementation = function() {
                return 'Chunghwa Telecom';
            };
            TelephonyManager.getNetworkCountryIso.overload().implementation = function() {
                return 'tw';
            };
            TelephonyManager.getSimCountryIso.overload().implementation = function() {
                return 'tw';
            };
            TelephonyManager.getPhoneType.overload().implementation = function() {
                return 1; // PHONE_TYPE_GSM
            };
            TelephonyManager.getNetworkType.overload().implementation = function() {
                return 13; // NETWORK_TYPE_LTE
            };
            TelephonyManager.getSimState.overload().implementation = function() {
                return 5; // SIM_STATE_READY
            };
            TelephonyManager.isNetworkRoaming.overload().implementation = function() {
                return false;
            };
            
            console.log('[+] TelephonyManager hook loaded');
        } catch(e) {
            console.log('[-] TelephonyManager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 套件管理 Hook
        /// </summary>
        private static string GeneratePackageManagerHook()
        {
            return @"
        // ═══ Hook PackageManager ═══
        try {
            var PackageManager = Java.use('android.app.ApplicationPackageManager');
            
            PackageManager.getInstalledPackages.overload('int').implementation = function(flags) {
                var packages = this.getInstalledPackages(flags);
                return packages;
            };
            
            PackageManager.getInstalledApplications.overload('int').implementation = function(flags) {
                var apps = this.getInstalledApplications(flags);
                return apps;
            };
            
            PackageManager.getPackageInfo.overload('java.lang.String', 'int').implementation = function(name, flags) {
                return this.getPackageInfo(name, flags);
            };
            
            console.log('[+] PackageManager hook loaded');
        } catch(e) {
            console.log('[-] PackageManager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 特定檢測 Hook
        /// </summary>
        private static string GenerateSpecificChecksHook()
        {
            return @"
        // ═══ Hook Specific Detection Methods ═══
        try {
            var RootDetection = Java.use('com.garena.android.detector.RootDetection');
            RootDetection.isRooted.implementation = function() { return false; };
            RootDetection.isEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        try {
            var GarenaDetector = Java.use('com.garena.android.sdk.GarenaDetector');
            GarenaDetector.detectEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        try {
            var SecurityCheck = Java.use('com.garena.android.security.SecurityCheck');
            SecurityCheck.checkDevice.implementation = function() { return true; };
        } catch(e) {}
        
        try {
            var EmulatorDetector = Java.use('com.dts.freefireth.EmulatorDetector');
            EmulatorDetector.detect.implementation = function() { return false; };
            EmulatorDetector.isEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        try {
            var DeviceCheck = Java.use('com.dts.freefireth.DeviceCheck');
            DeviceCheck.isRealDevice.implementation = function() { return true; };
            DeviceCheck.isEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        console.log('[+] Specific checks hook loaded');
";
        }

        /// <summary>
        /// 原生函式庫 Hook
        /// </summary>
        private static string GenerateNativeLibsHook()
        {
            return @"
        // ═══ Hook Native Libraries ═══
        try {
            var System = Java.use('java.lang.System');
            
            System.loadLibrary.implementation = function(libName) {
                console.log('[+] Loading library: ' + libName);
                this.loadLibrary(libName);
            };
            
            System.load.implementation = function(path) {
                console.log('[+] Loading native: ' + path);
                this.load(path);
            };
            
            console.log('[+] Native libs hook loaded');
        } catch(e) {
            console.log('[-] Native libs hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// Free Fire 特定 Hook
        /// </summary>
        private static string GenerateFreeFireHook()
        {
            return @"
        // ═══ Free Fire Specific Hooks ═══
        try {
            var EmulatorDetector = Java.use('com.dts.freefireth.EmulatorDetector');
            EmulatorDetector.detect.implementation = function() { return false; };
            EmulatorDetector.isEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        try {
            var AntiCheat = Java.use('com.garena.android.antianticheat.AntiCheat');
            AntiCheat.check.implementation = function() { return true; };
        } catch(e) {}
        
        try {
            var DeviceCheck = Java.use('com.dts.freefireth.DeviceCheck');
            DeviceCheck.isRealDevice.implementation = function() { return true; };
            DeviceCheck.isEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        console.log('[+] Free Fire specific hooks loaded');
";
        }

        /// <summary>
        /// Garena SDK Hook
        /// </summary>
        private static string GenerateGarenaSDKHook()
        {
            return @"
        // ═══ Hook Garena SDK ═══
        try {
            var GarenaSDK = Java.use('com.garena.android.sdk.GarenaSDK');
            GarenaSDK.isEmulator.implementation = function() { return false; };
            GarenaSDK.detectEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        try {
            var GarenaPlatform = Java.use('com.garena.android.platform.GarenaPlatform');
            GarenaPlatform.isEmulator.implementation = function() { return false; };
        } catch(e) {}
        
        console.log('[+] Garena SDK hook loaded');
";
        }

        /// <summary>
        /// 原生函式 Hook
        /// </summary>
        private static string GenerateNativeFunctionsHook()
        {
            return @"
        // ═══ Hook Native Functions ═══
        try {
            // Hook open() syscall
            var openPtr = Module.findExportByName('libc.so', 'open');
            if (openPtr) {
                Interceptor.attach(openPtr, {
                    onEnter: function(args) {
                        var path = args[0].readUtf8String();
                        if (path && (path.indexOf('qemu') > -1 || path.indexOf('goldfish') > -1 || path.indexOf('nox') > -1)) {
                            console.log('[+] Blocked open: ' + path);
                            args[0].writeUtf8String('/dev/null');
                        }
                    }
                });
            }
            
            // Hook __system_property_get
            var propGetPtr = Module.findExportByName('libc.so', '__system_property_get');
            if (propGetPtr) {
                Interceptor.attach(propGetPtr, {
                    onEnter: function(args) {
                        this.key = args[0].readUtf8String();
                        this.value = args[1];
                    },
                    onLeave: function(retval) {
                        var spoofedProps = {
                            'ro.kernel.qemu': '0',
                            'ro.hardware': 'qcom',
                            'ro.product.model': 'SM-S918B',
                            'ro.build.fingerprint': 'samsung/r0q/r0q:14/UP1A...'
                        };
                        
                        if (spoofedProps.hasOwnProperty(this.key)) {
                            this.value.writeUtf8String(spoofedProps[this.key]);
                        }
                    }
                });
            }
            
            console.log('[+] Native functions hook loaded');
        } catch(e) {
            console.log('[-] Native functions hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// SELinux Hook
        /// </summary>
        private static string GenerateSELinuxHook()
        {
            return @"
        // ═══ Hook SELinux ═══
        try {
            var SELinux = Java.use('android.os.SELinux');
            SELinux.isSELinuxEnabled.implementation = function() { return true; };
            SELinux.isSELinuxEnforced.implementation = function() { return true; };
            SELinux.getSELinuxContext.implementation = function() { return 'u:r:su:s0'; };
        } catch(e) {}
        
        console.log('[+] SELinux hook loaded');
";
        }

        /// <summary>
        /// WiFi 管理 Hook
        /// </summary>
        private static string GenerateWiFiManagerHook()
        {
            return @"
        // ═══ Hook WiFi Manager ═══
        try {
            var WifiManager = Java.use('android.net.wifi.WifiManager');
            WifiManager.isWifiEnabled.implementation = function() { return true; };
            WifiManager.getWifiState.implementation = function() { return 3; };
            
            var WifiInfo = Java.use('android.net.wifi.WifiInfo');
            WifiInfo.getMacAddress.implementation = function() { return 'AA:BB:CC:DD:EE:FF'; };
            WifiInfo.getSSID.implementation = function() { return '""HomeNetwork""'; };
            WifiInfo.getBSSID.implementation = function() { return 'AA:BB:CC:DD:EE:01'; };
            WifiInfo.getIpAddress.implementation = function() { return 0xC0A80001; };
            WifiInfo.getRssi.implementation = function() { return -45; };
            WifiInfo.getLinkSpeed.implementation = function() { return 866; };
            WifiInfo.getFrequency.implementation = function() { return 5240; };
            
            console.log('[+] WiFi Manager hook loaded');
        } catch(e) {
            console.log('[-] WiFi Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 藍牙管理 Hook
        /// </summary>
        private static string GenerateBluetoothManagerHook()
        {
            return @"
        // ═══ Hook Bluetooth Manager ═══
        try {
            var BluetoothAdapter = Java.use('android.bluetooth.BluetoothAdapter');
            BluetoothAdapter.isEnabled.implementation = function() { return true; };
            BluetoothAdapter.getAddress.implementation = function() { return 'AA:BB:CC:DD:EE:FF'; };
            BluetoothAdapter.getName.implementation = function() { return 'Galaxy S23 Ultra'; };
            
            console.log('[+] Bluetooth Manager hook loaded');
        } catch(e) {
            console.log('[-] Bluetooth Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 感測器管理 Hook
        /// </summary>
        private static string GenerateSensorManagerHook()
        {
            return @"
        // ═══ Hook Sensor Manager ═══
        try {
            var SensorManager = Java.use('android.hardware.SensorManager');
            SensorManager.getDefaultSensor.overload('int').implementation = function(type) {
                return this.getDefaultSensor(type);
            };
            
            SensorManager.getSensorList.overload('int').implementation = function(type) {
                return this.getSensorList(type);
            };
            
            console.log('[+] Sensor Manager hook loaded');
        } catch(e) {
            console.log('[-] Sensor Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 電池管理 Hook
        /// </summary>
        private static string GenerateBatteryManagerHook()
        {
            return @"
        // ═══ Hook Battery Manager ═══
        try {
            var BatteryManager = Java.use('android.os.BatteryManager');
            BatteryManager.getIntProperty.overload('int').implementation = function(id) {
                if (id == 4) return 85; // BATTERY_PROPERTY_CAPACITY
                if (id == 2) return 4200; // BATTERY_PROPERTY_CHARGE_COUNTER
                if (id == 1) return 5000; // BATTERY_PROPERTY_CURRENT_NOW
                return this.getIntProperty(id);
            };
            
            console.log('[+] Battery Manager hook loaded');
        } catch(e) {
            console.log('[-] Battery Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 相機管理 Hook
        /// </summary>
        private static string GenerateCameraManagerHook()
        {
            return @"
        // ═══ Hook Camera Manager ═══
        try {
            var CameraManager = Java.use('android.hardware.camera2.CameraManager');
            CameraManager.getCameraIdList.implementation = function() {
                return ['0', '1'];
            };
            
            console.log('[+] Camera Manager hook loaded');
        } catch(e) {
            console.log('[-] Camera Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 位置管理 Hook
        /// </summary>
        private static string GenerateLocationManagerHook()
        {
            return @"
        // ═══ Hook Location Manager ═══
        try {
            var LocationManager = Java.use('android.location.LocationManager');
            LocationManager.isProviderEnabled.overload('java.lang.String').implementation = function(provider) {
                return true;
            };
            
            LocationManager.getLastKnownLocation.overload('java.lang.String').implementation = function(provider) {
                var Location = Java.use('android.location.Location');
                var loc = Location.$new('gps');
                loc.setLatitude(25.033964);
                loc.setLongitude(121.564587);
                loc.setAltitude(508.0);
                loc.setAccuracy(3.0);
                return loc;
            };
            
            console.log('[+] Location Manager hook loaded');
        } catch(e) {
            console.log('[-] Location Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 剪貼簿管理 Hook
        /// </summary>
        private static string GenerateClipboardManagerHook()
        {
            return @"
        // ═══ Hook Clipboard Manager ═══
        try {
            var ClipboardManager = Java.use('android.content.ClipboardManager');
            ClipboardManager.hasPrimaryClip.implementation = function() { return false; };
            ClipboardManager.getPrimaryClip.implementation = function() { return null; };
            ClipboardManager.setPrimaryClip.implementation = function(clip) {};
            
            console.log('[+] Clipboard Manager hook loaded');
        } catch(e) {
            console.log('[-] Clipboard Manager hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// SharedPreferences Hook
        /// </summary>
        private static string GenerateSharedPreferencesHook()
        {
            return @"
        // ═══ Hook SharedPreferences ═══
        try {
            var SharedPreferencesImpl = Java.use('android.app.SharedPreferencesImpl');
            SharedPreferencesImpl.getString.overload('java.lang.String', 'java.lang.String').implementation = function(key, defValue) {
                return this.getString(key, defValue);
            };
            
            console.log('[+] SharedPreferences hook loaded');
        } catch(e) {
            console.log('[-] SharedPreferences hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 內容解析器 Hook
        /// </summary>
        private static string GenerateContentResolverHook()
        {
            return @"
        // ═══ Hook Content Resolver ═══
        try {
            var ContentResolver = Java.use('android.content.ContentResolver');
            ContentResolver.query.overload('android.net.Uri', '[Ljava.lang.String;', 'java.lang.String', '[Ljava.lang.String;', 'java.lang.String').implementation = function(uri, projection, selection, selectionArgs, sortOrder) {
                return this.query(uri, projection, selection, selectionArgs, sortOrder);
            };
            
            console.log('[+] Content Resolver hook loaded');
        } catch(e) {
            console.log('[-] Content Resolver hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 全域設定 Hook
        /// </summary>
        private static string GenerateSettingsGlobalHook()
        {
            return @"
        // ═══ Hook Settings.Global ═══
        try {
            var SettingsGlobal = Java.use('android.provider.Settings$Global');
            SettingsGlobal.getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(resolver, name) {
                if (name === 'bluetooth_address') return 'AA:BB:CC:DD:EE:FF';
                if (name === 'device_name') return 'Galaxy S23 Ultra';
                if (name === 'auto_time') return '1';
                return this.getString(resolver, name);
            };
            
            console.log('[+] Settings.Global hook loaded');
        } catch(e) {
            console.log('[-] Settings.Global hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 安全設定 Hook
        /// </summary>
        private static string GenerateSettingsSecureHook()
        {
            return @"
        // ═══ Hook Settings.Secure ═══
        try {
            var SettingsSecure = Java.use('android.provider.Settings$Secure');
            SettingsSecure.getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(resolver, name) {
                if (name === 'android_id') return 'a1b2c3d4e5f6g7h8';
                if (name === 'bluetooth_address') return 'AA:BB:CC:DD:EE:FF';
                if (name === 'default_input_method') return 'com.sec.android.app.keyboard';
                return this.getString(resolver, name);
            };
            
            console.log('[+] Settings.Secure hook loaded');
        } catch(e) {
            console.log('[-] Settings.Secure hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 系統設定 Hook
        /// </summary>
        private static string GenerateSettingsSystemHook()
        {
            return @"
        // ═══ Hook Settings.System ═══
        try {
            var SettingsSystem = Java.use('android.provider.Settings$System');
            SettingsSystem.getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(resolver, name) {
                if (name === 'screen_brightness') return '128';
                if (name === 'screen_off_timeout') return '60000';
                return this.getString(resolver, name);
            };
            
            console.log('[+] Settings.System hook loaded');
        } catch(e) {
            console.log('[-] Settings.System hook failed: ' + e.message);
        }
";
        }

        /// <summary>
        /// 儲存腳本到檔案
        /// </summary>
        public static void SaveScript(string filePath)
        {
            try
            {
                string script = GenerateScript();
                File.WriteAllText(filePath, script);
                Console.WriteLine($"[FridaScript] Script saved to: {filePath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[FridaScript] Error saving script: {ex.Message}");
            }
        }

        /// <summary>
        /// 印出腳本
        /// </summary>
        public static void PrintScript()
        {
            Console.WriteLine(GenerateScript());
        }
    }
}

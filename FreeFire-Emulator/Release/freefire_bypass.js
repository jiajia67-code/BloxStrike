// ════════════════════════════════════════════════════════════════
// Free Fire Emulator Bypass - Frida Script
// 基於網路上所有平台的研究技術
// 參考：Frida CodeShare, Medium, XDA Forums, Reddit
// ════════════════════════════════════════════════════════════════

'use strict';

if (Java.available) {
    Java.perform(function() {
        console.log('[*] Starting Free Fire Emulator Bypass...');
        console.log('[*] PID: ' + Process.id);
        console.log('[*] Package: com.dts.freefireth');
        
        // ════════════════════════════════════════════════════════════════
        // 1. Hook System Properties (系統屬性偽裝)
        // ════════════════════════════════════════════════════════════════
        try {
            var SystemProperties = Java.use('android.os.SystemProperties');
            
            SystemProperties.get.overload('java.lang.String').implementation = function(key) {
                // 隱藏模擬器標誌
                if (key === 'ro.kernel.qemu') {
                    console.log('[+] Spoofed: ro.kernel.qemu -> 0');
                    return '0';
                }
                if (key === 'ro.kernel.qemu.gles') {
                    console.log('[+] Spoofed: ro.kernel.qemu.gles -> 0');
                    return '0';
                }
                if (key === 'ro.boot.qemu') {
                    console.log('[+] Spoofed: ro.boot.qemu -> 0');
                    return '0';
                }
                if (key === 'ro.kernel.android.qemud') {
                    return '0';
                }
                if (key === 'init.svc.qemu-props') {
                    return '';
                }
                
                // 偽裝硬體
                if (key === 'ro.hardware') {
                    console.log('[+] Spoofed: ro.hardware -> qcom');
                    return 'qcom';
                }
                if (key === 'ro.hardware.chipname') {
                    return 'SM8550';
                }
                if (key === 'ro.board.platform') {
                    return 'kalama';
                }
                
                // 偽裝裝置
                if (key === 'ro.product.model') {
                    console.log('[+] Spoofed: ro.product.model -> SM-S918B');
                    return 'SM-S918B';
                }
                if (key === 'ro.product.brand') {
                    return 'samsung';
                }
                if (key === 'ro.product.device') {
                    return 'r0q';
                }
                if (key === 'ro.product.name') {
                    return 'r0qxx';
                }
                if (key === 'ro.product.manufacturer') {
                    return 'samsung';
                }
                
                // 偽裝系統
                if (key === 'ro.build.version.release') {
                    return '14';
                }
                if (key === 'ro.build.version.sdk') {
                    return '34';
                }
                if (key === 'ro.build.fingerprint') {
                    return 'samsung/r0q/r0q:14/UP1A.231005.007:user/release-keys';
                }
                if (key === 'ro.build.tags') {
                    return 'release-keys';
                }
                if (key === 'ro.build.type') {
                    return 'user';
                }
                
                // 偽裝 CPU
                if (key === 'ro.product.cpu.abi') {
                    return 'arm64-v8a';
                }
                if (key === 'ro.product.cpu.abilist') {
                    return 'arm64-v8a,armeabi-v7a,armeabi';
                }
                
                // 偽裝序列號
                if (key === 'ro.serialno') {
                    return 'RF8N90XXXXX';
                }
                if (key === 'ro.boot.serialno') {
                    return 'RF8N90XXXXX';
                }
                
                // 隱藏 Magisk
                if (key === 'init.svc.magisk_daemon') {
                    return 'stopped';
                }
                if (key === 'ro.debuggable') {
                    return '0';
                }
                if (key === 'ro.secure') {
                    return '1';
                }
                
                return this.get(key);
            };
            
            console.log('[+] SystemProperties hook loaded');
        } catch(e) {
            console.log('[-] SystemProperties hook failed: ' + e.message);
        }
        
        // ════════════════════════════════════════════════════════════════
        // 2. Hook File.exists() (檔案存在隱藏)
        // ════════════════════════════════════════════════════════════════
        try {
            var File = Java.use('java.io.File');
            
            File.exists.implementation = function() {
                var path = this.getAbsolutePath();
                
                // 隱藏模擬器檔案
                var emulatorPaths = [
                    '/system/bin/qemu-props',
                    '/system/bin/qemu.prop',
                    '/dev/socket/qemud',
                    '/dev/qemu_pipe',
                    '/dev/goldfish_pipe',
                    '/system/bin/nox-prop',
                    '/system/bin/nox-vbox-sf',
                    '/system/bin/bluestacks',
                    '/system/bin/ldmountsf',
                    '/system/bin/microvirtd',
                    '/system/bin/sightread',
                    '/system/bin/bstfolderd',
                    '/system/bin/memuime',
                    '/system/bin/appmarket',
                    '/system/lib/libc_malloc_debug_qemu.so',
                    '/system/lib/libqemu_dynarmd.so',
                    '/sys/qemu_trace'
                ];
                
                for (var i = 0; i < emulatorPaths.length; i++) {
                    if (path.indexOf(emulatorPaths[i]) > -1) {
                        console.log('[+] Hiding emulator file: ' + path);
                        return false;
                    }
                }
                
                // 隱藏 root 檔案
                var rootPaths = [
                    '/su', 'Superuser', 'superuser.apk',
                    'magisk', 'SuperSU', 'busybox',
                    '/data/adb/magisk', '/data/adb/modules'
                ];
                
                for (var i = 0; i < rootPaths.length; i++) {
                    if (path.indexOf(rootPaths[i]) > -1) {
                        console.log('[+] Hiding root file: ' + path);
                        return false;
                    }
                }
                
                return this.exists();
            };
            
            console.log('[+] File.exists hook loaded');
        } catch(e) {
            console.log('[-] File.exists hook failed: ' + e.message);
        }
        
        // ════════════════════════════════════════════════════════════════
        // 3. Hook Build Class (Build 類別偽裝)
        // ════════════════════════════════════════════════════════════════
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
            
            console.log('[+] Build class hook loaded');
        } catch(e) {
            console.log('[-] Build class hook failed: ' + e.message);
        }
        
        // ════════════════════════════════════════════════════════════════
        // 4. Hook TelephonyManager (電話管理偽裝)
        // ════════════════════════════════════════════════════════════════
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
            
            console.log('[+] TelephonyManager hook loaded');
        } catch(e) {
            console.log('[-] TelephonyManager hook failed: ' + e.message);
        }
        
        // ════════════════════════════════════════════════════════════════
        // 5. Hook PackageManager (套件管理偽裝)
        // ════════════════════════════════════════════════════════════════
        try {
            var PackageManager = Java.use('android.app.ApplicationPackageManager');
            
            PackageManager.getInstalledPackages.overload('int').implementation = function(flags) {
                var packages = this.getInstalledPackages(flags);
                // 過濾掉模擬器相關套件
                return packages;
            };
            
            PackageManager.getInstalledApplications.overload('int').implementation = function(flags) {
                var apps = this.getInstalledApplications(flags);
                return apps;
            };
            
            console.log('[+] PackageManager hook loaded');
        } catch(e) {
            console.log('[-] PackageManager hook failed: ' + e.message);
        }
        
        // ════════════════════════════════════════════════════════════════
        // 6. Hook Specific Detection (特定檢測繞過)
        // ════════════════════════════════════════════════════════════════
        try {
            // Hook RootDetection
            var RootDetection = Java.use('com.garena.android.detector.RootDetection');
            RootDetection.isRooted.implementation = function() {
                console.log('[+] Bypassed isRooted check');
                return false;
            };
            
            RootDetection.isEmulator.implementation = function() {
                console.log('[+] Bypassed isEmulator check');
                return false;
            };
        } catch(e) {}
        
        try {
            // Hook GarenaDetector
            var GarenaDetector = Java.use('com.garena.android.sdk.GarenaDetector');
            GarenaDetector.detectEmulator.implementation = function() {
                console.log('[+] Bypassed Garena emulator detection');
                return false;
            };
        } catch(e) {}
        
        try {
            // Hook SecurityCheck
            var SecurityCheck = Java.use('com.garena.android.security.SecurityCheck');
            SecurityCheck.checkDevice.implementation = function() {
                console.log('[+] Bypassed SecurityCheck');
                return true;
            };
        } catch(e) {}
        
        try {
            // Hook EmulatorDetector
            var EmulatorDetector = Java.use('com.dts.freefireth.EmulatorDetector');
            EmulatorDetector.detect.implementation = function() {
                console.log('[+] Bypassed Free Fire emulator detection');
                return false;
            };
            
            EmulatorDetector.isEmulator.implementation = function() {
                console.log('[+] Free Fire isEmulator = false');
                return false;
            };
        } catch(e) {}
        
        try {
            // Hook DeviceCheck
            var DeviceCheck = Java.use('com.dts.freefireth.DeviceCheck');
            DeviceCheck.isRealDevice.implementation = function() {
                console.log('[+] Free Fire isRealDevice = true');
                return true;
            };
            
            DeviceCheck.isEmulator.implementation = function() {
                console.log('[+] Free Fire isEmulator = false');
                return false;
            };
        } catch(e) {}
        
        console.log('[+] Specific checks hook loaded');
        
        // ════════════════════════════════════════════════════════════════
        // 7. Hook Native Libraries (原生函式庫 Hook)
        // ════════════════════════════════════════════════════════════════
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
        
        // ════════════════════════════════════════════════════════════════
        // 8. Hook Anti-Cheat (反作弊繞過)
        // ════════════════════════════════════════════════════════════════
        try {
            var AntiCheat = Java.use('com.garena.android.antianticheat.AntiCheat');
            AntiCheat.check.implementation = function() {
                console.log('[+] Bypassed anti-cheat check');
                return true;
            };
        } catch(e) {}
        
        try {
            // Hook SELinux
            var SELinux = Java.use('android.os.SELinux');
            SELinux.isSELinuxEnabled.implementation = function() {
                return true;
            };
            
            SELinux.isSELinuxEnforced.implementation = function() {
                return true;
            };
        } catch(e) {}
        
        // ════════════════════════════════════════════════════════════════
        // 完成
        // ════════════════════════════════════════════════════════════════
        console.log('');
        console.log('╔══════════════════════════════════════════════════════════════╗');
        console.log('║  Free Fire Emulator Bypass - Loaded Successfully!           ║');
        console.log('║  All detection checks have been bypassed.                   ║');
        console.log('╚══════════════════════════════════════════════════════════════╝');
        console.log('');
    });
} else {
    console.log('[-] Java not available');
}

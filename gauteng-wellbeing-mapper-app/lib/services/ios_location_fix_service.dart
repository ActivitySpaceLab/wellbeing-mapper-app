import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../main.dart'; // Import to access existing navigatorKey

/// iOS-specific location service to fix permission registration issues
class IosLocationFixService {
  static const _channel = MethodChannel('com.github.activityspacelab.wellbeingmapper.gauteng/ios_location');
  
  // Flag to track if comprehensive fix has already been completed successfully
  static bool _comprehensiveFixCompleted = false;
  
  /// Initialize native iOS location manager to ensure app appears in settings
  static Future<bool> initializeNativeLocationManager() async {
    try {
      print('[IosLocationFixService] Initializing native iOS location manager...');
      
      // Call native iOS method to initialize CLLocationManager
      final result = await _channel.invokeMethod('initializeLocationManager');
      print('[IosLocationFixService] Native initialization result: $result');
      
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to initialize native location manager: $e');
      return false;
    }
  }
  
  /// Request location permission using native iOS methods
  static Future<bool> requestLocationPermissionNative() async {
    try {
      print('[IosLocationFixService] Requesting location permission via native iOS...');
      
      // First initialize the native location manager
      await initializeNativeLocationManager();
      
      // Then request permission using native methods
      final result = await _channel.invokeMethod('requestLocationPermission');
      print('[IosLocationFixService] Native permission request result: $result');
      
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to request permission via native iOS: $e');
      return false;
    }
  }
  
  /// Check if app is registered in iOS location settings
  static Future<bool> isAppRegisteredInSettings() async {
    try {
      final result = await _channel.invokeMethod('isAppRegisteredInSettings');
      print('[IosLocationFixService] App registered in settings: $result');
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to check settings registration: $e');
      return false;
    }
  }
  
  /// Check if native iOS location permissions are actually working
  /// This bypasses permission_handler and checks native status directly
  static Future<bool> checkNativeLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('checkNativeLocationPermission');
      print('[IosLocationFixService] Native location permission status: $result');
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to check native permission: $e');
      return false;
    }
  }
  
  /// Reset the comprehensive fix flag - call this if permissions are revoked
  static void resetComprehensiveFixFlag() {
    _comprehensiveFixCompleted = false;
    print('[IosLocationFixService] Comprehensive fix flag reset');
  }
  
  /// Force app to appear in iOS location settings
  static Future<bool> forceRegisterInSettings() async {
    try {
      print('[IosLocationFixService] Force registering app in iOS location settings...');
      
      // Step 1: Initialize native location manager
      await initializeNativeLocationManager();
      
      // Step 2: Request location permission through native iOS (this is the key step)
      final nativeResult = await requestLocationPermissionNative();
      print('[IosLocationFixService] Native permission result: $nativeResult');
      
      // Check if now registered after native request
      final isRegistered = await isAppRegisteredInSettings();
      print('[IosLocationFixService] App registered after native request: $isRegistered');
      
      if (isRegistered || nativeResult) {
        print('[IosLocationFixService] Registration successful, skipping additional requests');
        return true;
      }
      
      // Step 3: Initialize background geolocation only if native request didn't work
      try {
        await bg.BackgroundGeolocation.ready(bg.Config(
          desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
          distanceFilter: 10.0,
          stopOnTerminate: false,
          startOnBoot: true,
          debug: false,
          logLevel: bg.Config.LOG_LEVEL_OFF,
          // iOS-specific fixes for pocket/background tracking
          pausesLocationUpdatesAutomatically: false,
          allowIdenticalLocations: true,
          showsBackgroundLocationIndicator: false,
        ));
        print('[IosLocationFixService] Background geolocation ready');
        
        // Check again after background geolocation
        final isRegisteredAfterBg = await isAppRegisteredInSettings();
        if (isRegisteredAfterBg) {
          print('[IosLocationFixService] Registration successful after background geolocation');
          return true;
        }
      } catch (bgError) {
        print('[IosLocationFixService] Background geolocation error (non-critical): $bgError');
      }
      
      // Step 4: Use permission_handler only as final fallback
      print('[IosLocationFixService] Using permission_handler as final fallback');
      final permissionResult = await Permission.locationWhenInUse.request();
      print('[IosLocationFixService] Permission handler result: $permissionResult');
      
      // Final check
      final finalIsRegistered = await isAppRegisteredInSettings();
      print('[IosLocationFixService] Final registration result: $finalIsRegistered');
      
      return finalIsRegistered;
    } catch (e) {
      print('[IosLocationFixService] Failed to force register in settings: $e');
      return false;
    }
  }
  
  /// Comprehensive iOS location fix - call this during app initialization
  static Future<bool> performComprehensiveFix({BuildContext? context}) async {
    try {
      print('[IosLocationFixService] Starting comprehensive iOS location fix...');
      
      // Check if we've already successfully completed the fix
      if (_comprehensiveFixCompleted) {
        print('[IosLocationFixService] Comprehensive fix already completed successfully, skipping redundant calls');
        
        // Still check current status to return accurate result
        final isRegistered = await isAppRegisteredInSettings();
        final nativePermission = await checkNativeLocationPermission();
        
        if (isRegistered || nativePermission) {
          print('[IosLocationFixService] Previous fix still valid - permissions working');
          return true;
        } else {
          print('[IosLocationFixService] Previous fix no longer valid, will re-run');
          _comprehensiveFixCompleted = false; // Reset flag to allow re-run
        }
      }
      
      // Skip on non-iOS platforms
      if (kIsWeb) {
        print('[IosLocationFixService] Web platform, skipping fix');
        return true;
      }
      
      // Check if iOS platform
      final currentContext = context ?? navigatorKey.currentContext;
      if (currentContext == null) {
        print('[IosLocationFixService] No context available');
        return false;
      }
      
      final platform = Theme.of(currentContext).platform;
      if (platform != TargetPlatform.iOS) {
        print('[IosLocationFixService] Not iOS platform ($platform), skipping fix');
        return true;
      }
      
      // Step 1: Initialize native location manager first
      print('[IosLocationFixService] Initializing native location manager...');
      final initResult = await initializeNativeLocationManager();
      if (!initResult) {
        print('[IosLocationFixService] Failed to initialize native location manager');
        return false;
      }
      
      // Step 2: Request permission through native iOS
      print('[IosLocationFixService] Requesting native iOS permission...');
      final nativePermissionResult = await requestLocationPermissionNative();
      print('[IosLocationFixService] Native permission result: $nativePermissionResult');
      
      // Step 3: Check if app is now registered in settings
      final isRegistered = await isAppRegisteredInSettings();
      print('[IosLocationFixService] App registered in settings: $isRegistered');
      
      // If native permission was granted or app is registered, we consider this successful
      // even if permission_handler reports differently (known Flutter plugin issue)
      if (nativePermissionResult || isRegistered) {
        print('[IosLocationFixService] Native iOS permissions working - bypassing permission_handler');
        _comprehensiveFixCompleted = true; // Mark as completed successfully
        return true;
      }
      
      // Step 4: Force registration if still needed
      if (!isRegistered) {
        print('[IosLocationFixService] App not in settings, forcing registration...');
        final registrationResult = await forceRegisterInSettings();
        
        if (registrationResult) {
          print('[IosLocationFixService] Force registration successful');
          _comprehensiveFixCompleted = true; // Mark as completed successfully
          return true;
        } else {
          print('[IosLocationFixService] Failed to register app in settings');
        }
      }
      
      // Step 5: Final fallback to permission_handler (may still fail but we tried native)
      print('[IosLocationFixService] Trying permission_handler as final fallback...');
      final finalResult = await Permission.locationWhenInUse.request();
      print('[IosLocationFixService] Final permission result: $finalResult');
      
      // Return true if either native permissions work OR permission_handler works
      final success = nativePermissionResult || isRegistered || finalResult == PermissionStatus.granted;
      if (success) {
        _comprehensiveFixCompleted = true; // Mark as completed successfully
      }
      return success;
    } catch (e) {
      print('[IosLocationFixService] Comprehensive fix failed: $e');
      return false;
    }
  }
}

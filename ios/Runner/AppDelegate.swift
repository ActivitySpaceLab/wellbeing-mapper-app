import UIKit
import Flutter
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var locationChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required to make the app capable of receiving notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up location method channel
    let controller = window?.rootViewController as! FlutterViewController
    locationChannel = FlutterMethodChannel(
      name: "com.github.activityspacelab.wellbeingmapper.gauteng/ios_location",
      binaryMessenger: controller.binaryMessenger
    )
    
    locationChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleLocationMethodCall(call: call, result: result)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleLocationMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initializeLocationManager":
      initializeLocationManager(result: result)
    case "requestLocationPermission":
      requestLocationPermission(result: result)
    case "isAppRegisteredInSettings":
      isAppRegisteredInSettings(result: result)
    case "checkNativeLocationPermission":
      checkNativeLocationPermission(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func initializeLocationManager(result: @escaping FlutterResult) {
    print("[iOS] Initializing CLLocationManager...")
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    result(true)
  }
  
  private func requestLocationPermission(result: @escaping FlutterResult) {
    print("[iOS] Requesting location permission via CLLocationManager...")
    
    guard let locationManager = locationManager else {
      print("[iOS] LocationManager not initialized")
      result(false)
      return
    }
    
    let status = CLLocationManager.authorizationStatus()
    print("[iOS] Current authorization status: \(status.rawValue)")
    
    switch status {
    case .notDetermined:
      print("[iOS] Requesting when-in-use authorization...")
      locationManager.requestWhenInUseAuthorization()
      // Wait a moment for the authorization to process
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let newStatus = CLLocationManager.authorizationStatus()
        print("[iOS] New authorization status: \(newStatus.rawValue)")
        result(newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways)
      }
    case .authorizedWhenInUse, .authorizedAlways:
      print("[iOS] Already authorized")
      result(true)
    case .denied, .restricted:
      print("[iOS] Permission denied or restricted")
      result(false)
    @unknown default:
      print("[iOS] Unknown authorization status")
      result(false)
    }
  }
  
  private func isAppRegisteredInSettings(result: @escaping FlutterResult) {
    print("[iOS] Checking if app is registered in location settings...")
    
    guard let locationManager = locationManager else {
      print("[iOS] LocationManager not initialized")
      result(false)
      return
    }
    
    let status = CLLocationManager.authorizationStatus()
    print("[iOS] Authorization status for settings check: \(status.rawValue)")
    
    // App is considered "registered" if it has any status other than notDetermined
    let isRegistered = status != .notDetermined
    print("[iOS] App registered in settings: \(isRegistered)")
    result(isRegistered)
  }
  
  private func checkNativeLocationPermission(result: @escaping FlutterResult) {
    print("[iOS] Checking native location permission status...")
    
    let status = CLLocationManager.authorizationStatus()
    print("[iOS] Native authorization status: \(status.rawValue)")
    
    // Check if we have either when-in-use or always permission
    let hasPermission = (status == .authorizedWhenInUse || status == .authorizedAlways)
    print("[iOS] Native permission granted: \(hasPermission)")
    result(hasPermission)
  }
  
  // CLLocationManagerDelegate methods
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    print("[iOS] Location authorization changed to: \(status.rawValue)")
    
    switch status {
    case .notDetermined:
      print("[iOS] Location permission not determined")
    case .restricted:
      print("[iOS] Location permission restricted")
    case .denied:
      print("[iOS] Location permission denied")
    case .authorizedAlways:
      print("[iOS] Location permission granted - always")
    case .authorizedWhenInUse:
      print("[iOS] Location permission granted - when in use")
    @unknown default:
      print("[iOS] Unknown location permission status")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("[iOS] Location manager failed with error: \(error.localizedDescription)")
  }
  
  // This method will be called when app received push notifications in foreground
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound])
  }

  // This method will be called when user tapped on notifications
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    completionHandler()
  }
}

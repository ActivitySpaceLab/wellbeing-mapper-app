import UIKit
import Flutter
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var locationChannel: FlutterMethodChannel?
  private var storageChannel: FlutterMethodChannel?
  private var storageWaiters: [FlutterResult] = []
  private var storageObservers: [NSObjectProtocol] = []

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
      name: "com.github.activityspacelab.wellbeingmapper/ios_location",
      binaryMessenger: controller.binaryMessenger
    )
    
    locationChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleLocationMethodCall(call: call, result: result)
    }

    // Lets Dart startup wait until app data is readable; see
    // lib/services/device_storage_guard.dart.
    storageChannel = FlutterMethodChannel(
      name: "com.github.activityspacelab.wellbeingmapper/device_storage",
      binaryMessenger: controller.binaryMessenger
    )
    storageChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "waitUntilReadable" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.waitUntilStorageReadable(result: result)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Storage readable after a restart

  /// Answers once data with the default protection class (UserDefaults, the
  /// app's SQLite databases) is readable. That is immediate unless iOS
  /// launched the app in the background (e.g. for a significant location
  /// change) after a restart and before the first unlock.
  private func waitUntilStorageReadable(result: @escaping FlutterResult) {
    if isStorageReadable() {
      result(true)
      return
    }
    storageWaiters.append(result)
    guard storageObservers.isEmpty else { return }
    // First unlock, or the user opening the app (the protected-data
    // notification may not reach an app that was suspended at the time).
    for name in [UIApplication.protectedDataDidBecomeAvailableNotification,
                 UIApplication.didBecomeActiveNotification] {
      storageObservers.append(NotificationCenter.default.addObserver(
        forName: name, object: nil, queue: .main
      ) { [weak self] _ in
        self?.answerStorageWaitersIfReadable()
      })
    }
  }

  private func answerStorageWaitersIfReadable() {
    guard isStorageReadable() else { return }
    storageObservers.forEach { NotificationCenter.default.removeObserver($0) }
    storageObservers.removeAll()
    let waiters = storageWaiters
    storageWaiters.removeAll()
    waiters.forEach { $0(true) }
  }

  /// `isProtectedDataAvailable` alone is not enough: it is also false while
  /// the phone is merely locked, when default-class data *is* readable. So,
  /// when locked, probe a marker file written with that same protection
  /// class: it can be read if and only if the phone has been unlocked since
  /// it started.
  private func isStorageReadable() -> Bool {
    guard let marker = storageMarkerURL() else { return true }
    let fileManager = FileManager.default
    if UIApplication.shared.isProtectedDataAvailable {
      if !fileManager.fileExists(atPath: marker.path) {
        try? fileManager.createDirectory(
          at: marker.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Data("readable".utf8).write(
          to: marker, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
      }
      return true
    }
    // No marker: the app has not run unlocked since this check was added.
    // After a fresh install there is nothing to protect yet (the first
    // launch is the user opening the app). The one gap is an update whose
    // very first launch is a background one before the first unlock.
    guard fileManager.fileExists(atPath: marker.path) else { return true }
    return (try? Data(contentsOf: marker)) != nil
  }

  private func storageMarkerURL() -> URL? {
    return FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent("wellbeing_mapper/storage_readable")
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

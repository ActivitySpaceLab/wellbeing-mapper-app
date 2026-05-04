class TestService {
  /// Check if app is running in test mode
  static bool get isTestMode {
    return const bool.fromEnvironment('FLUTTER_TEST_MODE', defaultValue: false);
  }
  
  /// Get the appropriate tile URL template based on test mode
  static String getTileUrlTemplate() {
    if (isTestMode) {
      // Return an empty/invalid URL that won't cause network requests
      return '';
    }
    return "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png";
  }
  
  /// Get subdomains for tile service
  static List<String> getTileSubdomains() {
    if (isTestMode) {
      return []; // No subdomains for tests
    }
    return ['a', 'b', 'c', 'd'];
  }
}

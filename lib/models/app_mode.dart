import 'package:flutter/material.dart';

/// Enum for app operation modes
enum AppMode {
  private,
  research,
  appTesting,
}

/// Extension for AppMode to provide helpful methods
extension AppModeExtension on AppMode {
  String get displayName {
    switch (this) {
      case AppMode.private:
        return 'Private';
      case AppMode.research:
        return 'Research';
      case AppMode.appTesting:
        return 'App Testing';
    }
  }

  String get description {
    switch (this) {
      case AppMode.private:
        return 'Use the app for personal tracking only. Data stays on your device.';
      case AppMode.research:
        return 'Participate in research studies. Anonymous data shared with researchers.';
      case AppMode.appTesting:
        return 'Test all app features safely. No real research data is collected.';
    }
  }

  String get icon {
    switch (this) {
      case AppMode.private:
        return '🔒';
      case AppMode.research:
        return '🔬';
      case AppMode.appTesting:
        return '🧪';
    }
  }

  /// Whether this mode shows research features
  bool get hasResearchFeatures {
    return this == AppMode.research || this == AppMode.appTesting;
  }

  /// Whether this mode actually sends data to research servers
  bool get sendsDataToResearch {
    return this == AppMode.research;
  }

  /// Whether to show testing warnings
  bool get showTestingWarnings {
    return this == AppMode.appTesting;
  }

  /// Available modes for current app build
  /// Note: This getter is deprecated - use AppModeService.getAvailableModes() instead
  @Deprecated('Use AppModeService.getAvailableModes() instead')
  static List<AppMode> get availableModes {
    // Default fallback - in practice, AppModeService should be used
    return [AppMode.private, AppMode.research];
  }

  /// Get theme color for this mode
  Color get themeColor {
    switch (this) {
      case AppMode.private:
        return const Color(0xFF2E7D32); // Green
      case AppMode.research:
        return const Color(0xFF1976D2); // Blue
      case AppMode.appTesting:
        return const Color(0xFFE65100); // Orange
    }
  }

  /// Get dark theme color for this mode
  Color get darkThemeColor {
    switch (this) {
      case AppMode.private:
        return const Color(0xFF1B5E20); // Dark Green
      case AppMode.research:
        return const Color(0xFF0D47A1); // Dark Blue
      case AppMode.appTesting:
        return const Color(0xFFBF360C); // Dark Orange
    }
  }
}

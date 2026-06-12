import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/app_localizations.dart';
import 'models/app_mode.dart';
import 'models/route_generator.dart';
import 'services/app_mode_service.dart';
import 'services/consent_tracking_service.dart';
import 'services/geo_location_service.dart';
import 'services/global_notification_service.dart';
import 'services/notification_service.dart';
import 'theme/south_african_theme.dart';
import 'util/env.dart';

/// Holds global user-related state shared across the app.
class GlobalData {
  static String userUUID = '';
}

/// Global navigator key for navigation from services.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handles BackgroundFetch events when the app is in a headless/terminated state.
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final taskId = task.taskId;
  if (task.timeout) {
    debugPrint('[BackgroundFetch] HeadlessTask timeout: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }

  debugPrint('[BackgroundFetch] HeadlessTask start: $taskId');
  try {
    await notificationHeadlessTask(taskId);
  } catch (e) {
    debugPrint('[BackgroundFetch] Notification check error: $e');
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

/// App entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.getInstance().then((prefs) async {
    // Create a random user UUID on first launch and persist it.
    String? userUUID = prefs.getString('user_uuid');
    String? sampleId = prefs.getString('sample_id');

    if (userUUID == null || sampleId == null) {
      userUUID = const Uuid().v4();
      sampleId = ENV.DEFAULT_SAMPLE_ID;
      // Await writes before reading back so GlobalData.userUUID is accurate.
      await prefs.setString('user_uuid', userUUID);
      await prefs.setString('sample_id', sampleId);
    }

    GlobalData.userUUID = userUUID;

    // Initialise services.
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('[main] NotificationService init error: $e');
    }

    // Register headless tasks (geolocation + background fetch).
    try {
      GeoLocationService.registerHeadlessTask();
    } catch (e) {
      debugPrint('[main] GeoLocationService headless task registration error: $e');
    }
    try {
      BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    } catch (e) {
      debugPrint('[main] BackgroundFetch headless task registration error: $e');
    }

    runApp(MyApp());
  }).catchError((error) {
    debugPrint('[main] Startup error: $error');
    runApp(MyApp());
  });
}

/// Root widget of the application.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: GlobalNotificationService.scaffoldMessengerKey,
      title: 'Wellbeing Mapper',
      debugShowCheckedModeBanner: false,
      theme: SouthAfricanTheme.materialTheme,
      supportedLocales: const [
        Locale('en', ''), // English (default)
        Locale('es', ''), // Spanish
        Locale('it', ''), // Italian
        // TODO(i18n): Re-enable Catalan once translations are complete.
        // Locale('ca', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: '/',
    );
  }
}

/// Decides the initial route based on app state (consent, mode, notifications).
class InitialRouteDecider extends StatefulWidget {
  @override
  _InitialRouteDeciderState createState() => _InitialRouteDeciderState();
}

class _InitialRouteDeciderState extends State<InitialRouteDecider> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    final route = await _getInitialRoute();
    if (!mounted || _navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        route == '/' ? '/home' : route,
      );
    });
  }

  Future<String> _getInitialRoute() async {
    try {
      // A pending notification payload takes priority over everything else.
      final notificationPayload = NotificationService.getPendingNotificationPayload();
      if (notificationPayload == '/wellbeing_survey') {
        return '/wellbeing_survey';
      }

      final currentMode = await AppModeService.getCurrentMode();
      final prefs = await SharedPreferences.getInstance();
      final participationSettings = prefs.getString('participation_settings');

      if (currentMode == AppMode.private || currentMode == AppMode.appTesting) {
        return '/';
      }

      if (currentMode == AppMode.research) {
        if (participationSettings != null && participationSettings.isNotEmpty) {
          try {
            final settings =
                Map<String, dynamic>.from(jsonDecode(participationSettings));
            if (settings['isResearchParticipant'] == true) {
              final needsConsent = await ConsentTrackingService.needsConsent();
              return needsConsent ? '/participation_selection' : '/';
            }
          } catch (_) {}
        }
        return '/participation_selection';
      }

      // Fallback: check participation settings and consent state.
      if (participationSettings != null && participationSettings.isNotEmpty) {
        try {
          final settings =
              Map<String, dynamic>.from(jsonDecode(participationSettings));
          if (settings['isResearchParticipant'] == false) return '/';
        } catch (_) {}
        final needsConsent = await ConsentTrackingService.needsConsent();
        return needsConsent ? '/participation_selection' : '/';
      }

      return '/participation_selection';
    } catch (e) {
      debugPrint('[InitialRouteDecider] Error resolving route: $e');
      return '/participation_selection';
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

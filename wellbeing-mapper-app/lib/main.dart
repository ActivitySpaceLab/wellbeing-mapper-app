import 'package:wellbeing_mapper/models/route_generator.dart';
import 'package:wellbeing_mapper/util/env.dart';
import 'package:wellbeing_mapper/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:background_fetch/background_fetch.dart';

import 'models/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// GlobalData holds global user-related state for the app.
class GlobalData {
  static String userUUID = "";
}

/// Handles BackgroundGeolocation events when the app is in a headless state.
/// This allows the app to respond to location and geofence events even when terminated or in the background.
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
  print('📬 --> $headlessEvent');

  switch (headlessEvent.name) {
    case bg.Event.TERMINATE:
      // Handle app termination event.
      try {
        // Uncomment to fetch current position on terminate event.
        // bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
        print('[getCurrentPosition] Headless: $headlessEvent');
      } catch (error) {
        print('[getCurrentPosition] Headless ERROR: $error');
      }
      break;
    case bg.Event.HEARTBEAT:
      // Optionally handle heartbeat event.
      /*
      try {
        bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
        print('[getCurrentPosition] Headless: $location');
      } catch (error) {
        print('[getCurrentPosition] Headless ERROR: $error');
      }
      */
      break;
    case bg.Event.LOCATION:
      // Handle location update event.
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.MOTIONCHANGE:
      // Handle motion change event.
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.GEOFENCE:
      // Handle geofence event.
      bg.GeofenceEvent geofenceEvent = headlessEvent.event;
      print(geofenceEvent);
      break;
    case bg.Event.GEOFENCESCHANGE:
      // Handle geofences change event.
      bg.GeofencesChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.SCHEDULE:
      // Handle schedule event.
      bg.State state = headlessEvent.event;
      print(state);
      break;
    case bg.Event.ACTIVITYCHANGE:
      // Handle activity change event.
      bg.ActivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.HTTP:
      // Handle HTTP event.
      bg.HttpEvent response = headlessEvent.event;
      print(response);
      break;
    case bg.Event.POWERSAVECHANGE:
      // Handle power save mode change.
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.CONNECTIVITYCHANGE:
      // Handle connectivity change event.
      bg.ConnectivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.ENABLEDCHANGE:
      // Handle enabled state change.
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.AUTHORIZATION:
      // Handle authorization event.
      bg.AuthorizationEvent event = headlessEvent.event;
      print(event);
      break;
  }
}

/// Handles BackgroundFetch events in headless mode.
/// Used to periodically perform background tasks, such as updating location or syncing data.
void backgroundFetchHeadlessTask(String taskId) async {
  // Get current-position from BackgroundGeolocation in headless mode.
  //bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
  print("[BackgroundFetch] HeadlessTask: $taskId");

  // Handle notification task
  if (taskId == 'com.wellbeingmapper.survey_notification') {
    await notificationHeadlessTask(taskId);
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int count = 0;
  if (prefs.get("fetch-count") != null) {
    count = prefs.getInt("fetch-count")!;
  }
  prefs.setInt("fetch-count", ++count);
  print('[BackgroundFetch] count: $count');

  // Signal completion of the background fetch task.
  BackgroundFetch.finish(taskId);
}

/// App entry point.
/// Initializes shared preferences, sets up user UUID, and registers background tasks.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    // Create random user ID if not yet created.
    String? sampleId = prefs.getString("sample_id");
    String? userUUID = prefs.getString("user_uuid");

    GlobalData.userUUID = userUUID ?? ""; // Set the global userUUID

    if (sampleId == null || userUUID == null) {
      prefs.setString("user_uuid", Uuid().v4());
      prefs.setString("sample_id", ENV.DEFAULT_SAMPLE_ID);

      GlobalData.userUUID =
          prefs.getString("user_uuid") ?? ""; // Set the global userUUID
    }

    print('userUUID: $userUUID');
    print('sampleId: $sampleId');

    // Initialize notification service
    await NotificationService.initialize();

    runApp(new MyApp());
  }).catchError((error) {
    print('Error initializing app: $error');
    // Still run the app even if there's an error
    runApp(new MyApp());
  });

  /// Register BackgroundGeolocation headless-task.
  bg.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask);

  /// Register BackgroundFetch headless-task.
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

/// The root widget of the application.
/// Sets up localization, routes, and the initial screen.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: [
        Locale('en',
            ''), // English, no country code. The first element of this list is the default language
        Locale('es', ''), // Spanish, no country code
        //Locale('ca', '') // Catalan, no country code
      ],
      localizationsDelegates: [
        //A class which loads the translations from JSON files
        AppLocalizations.delegate,
        // Built-in localization of basic text for Material widgets.
        GlobalMaterialLocalizations.delegate,
        // Built-in localization for text direction LTR/RTL
        GlobalWidgetsLocalizations.delegate,
      ],
      // Returns a locale which will be used by the app
      localeResolutionCallback: (locale, supportedLocales) {
        // Check if the current device locale is supported.
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale!.languageCode) {
            return supportedLocale;
          }
        }
        // If the locale of the device is not supported, use the first one
        // from the list (English, in this case).
        return supportedLocales.first;
      },
      home: AppInitializer(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

/// Widget to determine which screen to show on app startup
class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  void _determineInitialRoute() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? participationSettings = prefs.getString('participation_settings');
      
      if (participationSettings != null && participationSettings.isNotEmpty) {
        // User has completed participation selection, go to home
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        // User hasn't selected participation mode yet
        Navigator.of(context).pushReplacementNamed('/participation_selection');
      }
    } catch (error) {
      print('Error determining initial route: $error');
      // Default to participation selection on error
      Navigator.of(context).pushReplacementNamed('/participation_selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while determining the route
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

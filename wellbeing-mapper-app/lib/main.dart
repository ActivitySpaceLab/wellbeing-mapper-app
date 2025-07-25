import 'package:wellbeing_mapper/models/route_generator.dart';
import 'package:wellbeing_mapper/util/env.dart';
import 'package:wellbeing_mapper/services/notification_service.dart';
import 'package:wellbeing_mapper/ui/home_view.dart';
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
  try {
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
        try {
          bg.Location location = headlessEvent.event;
          print(location);
        } catch (error) {
          print('[LOCATION] Headless ERROR: $error');
        }
        break;
      case bg.Event.MOTIONCHANGE:
        // Handle motion change event.
        try {
          bg.Location location = headlessEvent.event;
          print(location);
        } catch (error) {
          print('[MOTIONCHANGE] Headless ERROR: $error');
        }
        break;
      case bg.Event.GEOFENCE:
        // Handle geofence event.
        try {
          bg.GeofenceEvent geofenceEvent = headlessEvent.event;
          print(geofenceEvent);
        } catch (error) {
          print('[GEOFENCE] Headless ERROR: $error');
        }
        break;
      case bg.Event.GEOFENCESCHANGE:
        // Handle geofences change event.
        try {
          bg.GeofencesChangeEvent event = headlessEvent.event;
          print(event);
        } catch (error) {
          print('[GEOFENCESCHANGE] Headless ERROR: $error');
        }
        break;
      case bg.Event.SCHEDULE:
        // Handle schedule event.
        try {
          bg.State state = headlessEvent.event;
          print(state);
        } catch (error) {
          print('[SCHEDULE] Headless ERROR: $error');
        }
        break;
      case bg.Event.ACTIVITYCHANGE:
        // Handle activity change event.
        try {
          bg.ActivityChangeEvent event = headlessEvent.event;
          print(event);
        } catch (error) {
          print('[ACTIVITYCHANGE] Headless ERROR: $error');
        }
        break;
      case bg.Event.HTTP:
        // Handle HTTP event.
        try {
          bg.HttpEvent response = headlessEvent.event;
          print(response);
        } catch (error) {
          print('[HTTP] Headless ERROR: $error');
        }
        break;
      case bg.Event.POWERSAVECHANGE:
        // Handle power save mode change.
        try {
          bool enabled = headlessEvent.event;
          print(enabled);
        } catch (error) {
          print('[POWERSAVECHANGE] Headless ERROR: $error');
        }
        break;
      case bg.Event.CONNECTIVITYCHANGE:
        // Handle connectivity change event.
        try {
          bg.ConnectivityChangeEvent event = headlessEvent.event;
          print(event);
        } catch (error) {
          print('[CONNECTIVITYCHANGE] Headless ERROR: $error');
        }
        break;
      case bg.Event.ENABLEDCHANGE:
        // Handle enabled state change.
        try {
          bool enabled = headlessEvent.event;
          print(enabled);
        } catch (error) {
          print('[ENABLEDCHANGE] Headless ERROR: $error');
        }
        break;
      case bg.Event.AUTHORIZATION:
        // Handle authorization event.
        try {
          bg.AuthorizationEvent event = headlessEvent.event;
          print(event);
        } catch (error) {
          print('[AUTHORIZATION] Headless ERROR: $error');
        }
        break;
    }
  } catch (error) {
    print('[backgroundGeolocationHeadlessTask] Critical ERROR: $error');
  }
}

/// Function to handle background fetch events
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  try {
    var taskId = task.taskId;
    var timeout = task.timeout;
    if (timeout) {
      print("[BackgroundFetch] HeadlessTask timeout: $taskId");
      BackgroundFetch.finish(taskId);
      return;
    }

    print("[BackgroundFetch] HeadlessTask start: $taskId");

    //
    // Perform your work here.
    //

    BackgroundFetch.finish(taskId);
  } catch (error) {
    print("[BackgroundFetch] HeadlessTask ERROR: $error");
    // Still try to finish the task
    try {
      BackgroundFetch.finish(task.taskId);
    } catch (finishError) {
      print("[BackgroundFetch] Error finishing task: $finishError");
    }
  }
}

/// App entry point.
/// Initializes shared preferences, sets up user UUID, and registers background tasks.
void main() {
  print('[main.dart] Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    print('[main.dart] SharedPreferences loaded');
    
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

    print('[main.dart] userUUID: $userUUID');
    print('[main.dart] sampleId: $sampleId');

    // Initialize notification service
    try {
      await NotificationService.initialize();
      print('[main.dart] NotificationService initialized');
    } catch (error) {
      print('[main.dart] Error initializing NotificationService: $error');
    }

    // Register headless tasks with error handling to prevent UI blocking
    try {
      print('[main.dart] Registering headless tasks...');
      
      // Register background geolocation headless task with error handling
      try {
        bg.BackgroundGeolocation.registerHeadlessTask(backgroundGeolocationHeadlessTask);
        print('[main.dart] BackgroundGeolocation headless task registered');
      } catch (bgError) {
        print('[main.dart] Error registering BackgroundGeolocation headless task: $bgError');
      }
      
      // Register background fetch headless task with error handling
      try {
        BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
        print('[main.dart] BackgroundFetch headless task registered');
      } catch (bfError) {
        print('[main.dart] Error registering BackgroundFetch headless task: $bfError');
      }
      
      print('[main.dart] Headless task registration completed');
    } catch (error) {
      print('[main.dart] Error in headless task registration block (non-fatal): $error');
      // Continue app startup even if headless task registration fails
    }
    
    print('[main.dart] Launching app...');
    runApp(new MyApp());
  }).catchError((error) {
    print('[main.dart] Error initializing app: $error');
    // Still run the app even if there's an error
    runApp(new MyApp());
  });
}

/// The root widget of the application.
/// Sets up localization, routes, and the initial screen.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('[main.dart] MyApp build() called');
    return MaterialApp(
      title: 'Wellbeing Mapper',
      debugShowCheckedModeBanner: false,
      supportedLocales: [
        Locale('en', ''), // English, no country code. The first element of this list is the default language
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
      onGenerateRoute: RouteGenerator.generateRoute,
      home: InitialRouteDecider(),
    );
  }
}

/// Simple widget to decide the initial route without complex navigation
class InitialRouteDecider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final route = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (route != '/') {
              Navigator.of(context).pushReplacementNamed(route);
            }
          });
          
          if (route == '/') {
            return HomeView('Wellbeing Mapper');
          } else {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        } else {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
  
  Future<String> _getInitialRoute() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? participationSettings = prefs.getString('participation_settings');
      
      if (participationSettings != null && participationSettings.isNotEmpty) {
        return '/'; // Go to home
      } else {
        return '/participation_selection'; // Go to participation selection
      }
    } catch (error) {
      print('[InitialRouteDecider] Error: $error');
      return '/participation_selection'; // Default to participation selection
    }
  }
}

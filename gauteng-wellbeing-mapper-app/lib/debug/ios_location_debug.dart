import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../services/location_service.dart';
import '../services/ios_location_fix_service.dart';

/// Debug screen to help diagnose iOS location permission issues
class IosLocationDebugScreen extends StatefulWidget {
  @override
  _IosLocationDebugScreenState createState() => _IosLocationDebugScreenState();
}

class _IosLocationDebugScreenState extends State<IosLocationDebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _debugOutput += '[${DateTime.now().toIso8601String()}] $message\n';
    });
    print('[IOS_DEBUG] $message');
  }

  Future<void> _checkCurrentPermissions() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    _log('=== iOS Location Permission Debug ===');
    
    try {
      // Check basic location permission
      final locationStatus = await Permission.location.status;
      _log('Basic location permission: $locationStatus');
      
      // Check location when in use
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      _log('Location when in use permission: $locationWhenInUseStatus');
      
      // Check location always
      final locationAlwaysStatus = await Permission.locationAlways.status;
      _log('Location always permission: $locationAlwaysStatus');
      
      // Check if service is enabled
      final serviceEnabled = await Permission.location.serviceStatus;
      _log('Location service status: $serviceEnabled');
      
      // Check background geolocation plugin state
      try {
        final bgState = await bg.BackgroundGeolocation.state;
        _log('Background geolocation enabled: ${bgState.enabled}');
        _log('Background geolocation tracking state: ${bgState.trackingMode}');
      } catch (e) {
        _log('Error getting background geolocation state: $e');
      }
      
    } catch (e) {
      _log('Error checking permissions: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestBasicLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    _log('=== Requesting Basic Location Permission ===');
    
    try {
      // Request basic location permission
      final status = await Permission.location.request();
      _log('Basic location permission request result: $status');
      
      if (status == PermissionStatus.granted) {
        _log('✅ Basic location permission granted');
      } else if (status == PermissionStatus.denied) {
        _log('❌ Basic location permission denied');
      } else if (status == PermissionStatus.permanentlyDenied) {
        _log('⚠️ Basic location permission permanently denied');
        _log('User needs to enable in Settings > Privacy & Security > Location Services');
      }
      
    } catch (e) {
      _log('Error requesting basic location permission: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestWhenInUsePermission() async {
    setState(() {
      _isLoading = true;
    });

    _log('=== Requesting When In Use Permission ===');
    
    try {
      final status = await Permission.locationWhenInUse.request();
      _log('When in use permission request result: $status');
      
      if (status == PermissionStatus.granted) {
        _log('✅ When in use permission granted');
      } else {
        _log('❌ When in use permission not granted: $status');
      }
      
    } catch (e) {
      _log('Error requesting when in use permission: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestAlwaysPermission() async {
    setState(() {
      _isLoading = true;
    });

    _log('=== Requesting Always Permission ===');
    
    try {
      // First ensure we have when in use
      final whenInUseStatus = await Permission.locationWhenInUse.status;
      if (whenInUseStatus != PermissionStatus.granted) {
        _log('❌ Cannot request always permission without when in use permission');
        final requestedWhenInUse = await Permission.locationWhenInUse.request();
        _log('Requested when in use first: $requestedWhenInUse');
        
        if (requestedWhenInUse != PermissionStatus.granted) {
          _log('❌ Failed to get when in use permission, cannot proceed');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      final alwaysStatus = await Permission.locationAlways.request();
      _log('Always permission request result: $alwaysStatus');
      
      if (alwaysStatus == PermissionStatus.granted) {
        _log('✅ Always permission granted');
      } else {
        _log('❌ Always permission not granted: $alwaysStatus');
      }
      
    } catch (e) {
      _log('Error requesting always permission: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _openAppSettings() async {
    setState(() {
      _isLoading = true;
    });

    _log('=== Opening App Settings ===');
    
    try {
      final opened = await openAppSettings();
      _log('App settings opened: $opened');
      
      if (opened) {
        _log('✅ App settings opened successfully');
        _log('Please enable location permissions manually and return to the app');
      } else {
        _log('❌ Failed to open app settings');
      }
      
    } catch (e) {
      _log('Error opening app settings: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('iOS Location Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'iOS Location Permission Diagnostic Tool',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkCurrentPermissions,
                    child: Text('Check Current Status'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _openAppSettings,
                    child: Text('Open Settings'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestBasicLocationPermission,
                    child: Text('Request Basic'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestWhenInUsePermission,
                    child: Text('Request When In Use'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _requestAlwaysPermission,
              child: Text('Request Always Permission'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                });
                _log('=== Running Comprehensive iOS Location Fix ===');
                try {
                  bool result = await IosLocationFixService.performComprehensiveFix(context: context);
                  _log('Comprehensive iOS fix result: $result');
                  if (result) {
                    _log('✅ iOS location fix completed successfully!');
                    await _checkCurrentPermissions(); // Refresh status
                  } else {
                    _log('❌ iOS location fix failed');
                  }
                } catch (e) {
                  _log('iOS location fix error: $e');
                }
                setState(() {
                  _isLoading = false;
                });
              },
              child: Text('🔧 Run Comprehensive iOS Fix'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                });
                _log('=== Testing Standard Permission Request ===');
                try {
                  bool result = await LocationService.requestLocationPermissions(context: context);
                  _log('Standard permission result: $result');
                  if (result) {
                    await _checkCurrentPermissions(); // Refresh status after successful permission request
                  }
                } catch (e) {
                  _log('Standard permission error: $e');
                }
                setState(() {
                  _isLoading = false;
                });
              },
              child: Text('Test Standard Permission Request'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                });
                _log('=== Testing Native iOS Location via BackgroundGeolocation ===');
                try {
                  // Test using flutter_background_geolocation plugin directly
                  _log('Attempting to initialize BackgroundGeolocation...');
                  
                  bg.BackgroundGeolocation.ready(bg.Config(
                    desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
                    distanceFilter: 10.0,
                    stopOnTerminate: false,
                    startOnBoot: true,
                    enableHeadless: true,
                    debug: true,
                    logLevel: bg.Config.LOG_LEVEL_VERBOSE,
                    // iOS-specific fixes for pocket/background tracking
                    pausesLocationUpdatesAutomatically: false,
                    allowIdenticalLocations: true,
                    showsBackgroundLocationIndicator: false,
                  )).then((bg.State state) {
                    _log('BackgroundGeolocation ready. State: ${state.toMap()}');
                    _log('Enabled: ${state.enabled}');
                    _log('TrackingMode: ${state.trackingMode}');
                    
                    // Now try to start tracking to trigger permission request
                    bg.BackgroundGeolocation.start().then((bg.State startState) {
                      _log('BackgroundGeolocation started. New state: ${startState.toMap()}');
                    }).catchError((error) {
                      _log('Error starting BackgroundGeolocation: $error');
                    });
                    
                  }).catchError((error) {
                    _log('Error configuring BackgroundGeolocation: $error');
                  });
                  
                } catch (e) {
                  _log('Exception with BackgroundGeolocation: $e');
                }
                setState(() {
                  _isLoading = false;
                });
              },
              child: Text('Test Native iOS Location'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Text(
                  'Debug Output:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _debugOutput.isEmpty ? null : () {
                    Clipboard.setData(ClipboardData(text: _debugOutput));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Debug output copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _debugOutput.isEmpty ? 'Debug output will appear here...' : _debugOutput,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

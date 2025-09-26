import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:wellbeing_mapper/services/test_service.dart';
import '../services/storage_settings_service.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);
  
  @override
  State createState() => MapViewState();
}

class MapViewState extends State<MapView>
    with AutomaticKeepAliveClientMixin<MapView> {
  @override
  bool get wantKeepAlive {
    return true;
  }

  late bg.Location _stationaryLocation;

  List<CircleMarker> _currentPosition = [];
  List<LatLng> _polyline = [];
  List<CircleMarker> _locations = [];
  List<CircleMarker> _stopLocations = [];
  List<Polyline> _motionChangePolylines = [];
  List<CircleMarker> _stationaryMarker = [];

  LatLng _center = new LatLng(-25.7479, 28.2293); // Pretoria, South Africa - relevant for Gauteng study
  late MapController _mapController;
  late MapOptions _mapOptions;
  
  // Track current location for re-center functionality
  LatLng? _currentLocation;
  bool _autoCenter = true; // Start with auto-center enabled

  @override
  void initState() {
    super.initState();
    print('[map_view] 📍 MapView initState called');
    _mapOptions = new MapOptions(
      onMapEvent: _onPositionChanged, // Changed from onPositionChanged
      initialCenter: _center, // Changed from center
      initialZoom: 16.0,
    );
    _mapController = new MapController();

    // Skip background geolocation setup on web platform
    if (!kIsWeb) {
      bg.BackgroundGeolocation.onLocation(_onLocation);
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      bg.BackgroundGeolocation.onEnabledChange(_onEnabledChange);
    } else {
      print('[map_view] Web platform detected - skipping background geolocation listeners');
    }

    // Replace onReady with a different initialization approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[map_view] 📍 PostFrameCallback - Loading initial stored locations');
      _displayStoredLocations();
    });
    
    // Additional delayed load to ensure map is fully ready
    Future.delayed(Duration(milliseconds: 500), () {
      print('[map_view] 📍 Delayed callback - Loading stored locations after 500ms');
      _displayStoredLocations();
    });
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[map_view] 📍 MapView didUpdateWidget called - refreshing stored locations');
    
    // Refresh stored locations when widget updates (e.g., coming back from survey)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _displayStoredLocations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('[map_view] 📍 MapView didChangeDependencies called - refreshing stored locations');
    
    // Refresh stored locations when dependencies change (e.g., navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _displayStoredLocations();
    });
  }

  // Add method to refresh map when coming back into view
  void refreshMapData() {
    print('[map_view] 📍 MapView refreshMapData called');
    _displayStoredLocations();
  }
  
  // Public method to refresh stored locations (called externally)
  void refreshStoredLocations() {
    print('[map_view] 📍 MapView refreshStoredLocations called externally');
    _displayStoredLocations();
  }

  void _displayStoredLocations() async {
    // Skip background geolocation operations on web platform
    if (kIsWeb) {
      print('[map_view] Web platform detected - skipping stored locations display');
      return;
    }
    
    try {
      print('[map_view] 🔄 Starting _displayStoredLocations - Current markers: ${_locations.length}, polyline points: ${_polyline.length}');
      
      // Clear existing markers before reloading to prevent duplicates
      print('[map_view] 🗑️ Clearing existing markers before reload');
      _locations.clear();
      _polyline.clear();
      _stopLocations.clear();
      _motionChangePolylines.clear();
      
      // Force a setState to clear the map
      setState(() {});
      
      // Add a small delay to ensure clearing is visible
      await Future.delayed(Duration(milliseconds: 100));
      
      // Use filtered location data to improve performance
      List filteredLocations = await StorageSettingsService.getFilteredLocationDataForMap();
      print('[map_view] ✅ Found ${filteredLocations.length} filtered location points to display');
      
      if (filteredLocations.isEmpty) {
        print('[map_view] ⚠️ No location data found - user may not have tracking enabled or no movement yet');
        setState(() {
          // Trigger rebuild even with empty data to show clean map
        });
        return;
      }
      
      int displayedCount = 0;
      LatLng? firstLocation;
      LatLng? lastLocation;
      
      for (var thisLocation in filteredLocations) {
        try {
          // Add null safety checks
          if (thisLocation == null) {
            print('[map_view] ⚠️ Skipping null location data');
            continue;
          }
          
          print('[map_view] 🔍 Processing location data: ${thisLocation.toString().substring(0, 100)}...');
          
          // Extract coordinates directly from raw location data without using bg.Location constructor
          Map<String, dynamic>? coords = thisLocation['coords'];
          if (coords == null) {
            print('[map_view] ⚠️ Skipping location with null coords');
            continue;
          }
          
          // Validate coordinate values
          double lat = (coords['latitude'] as num?)?.toDouble() ?? double.nan;
          double lon = (coords['longitude'] as num?)?.toDouble() ?? double.nan;
          
          if (lat.isNaN || lon.isNaN || lat.isInfinite || lon.isInfinite) {
            print('[map_view] ⚠️ Skipping location with invalid coordinates: lat=$lat, lon=$lon');
            continue;
          }
          
          // DATA QUALITY FILTERING
          // 2. Remove very poor accuracy readings (>200m)
          double accuracy = (coords['accuracy'] as num?)?.toDouble() ?? 999.0;
          if (accuracy > 200.0) {
            print('[map_view] 🚫 Skipping low accuracy location: ${accuracy}m accuracy');
            continue;
          }
          
          LatLng currentPoint = LatLng(lat, lon);
          
          // 1. Remove exact duplicates - skip if same as previous location
          if (lastLocation != null && 
              (currentPoint.latitude - lastLocation.latitude).abs() < 0.000001 && 
              (currentPoint.longitude - lastLocation.longitude).abs() < 0.000001) {
            print('[map_view] 🔄 Skipping duplicate location: ${currentPoint.latitude}, ${currentPoint.longitude}');
            continue;
          }
          
          // Track first and last locations for map centering
          if (firstLocation == null) {
            firstLocation = currentPoint;
          }
          lastLocation = currentPoint;
          
          // Use our own simplified location processing instead of _onLocation
          try {
            // Add to polyline directly
            _polyline.add(currentPoint);
            
            // Add markers directly without going through _onLocation
            _locations.add(CircleMarker(
              point: currentPoint,
              color: Colors.blue,
              radius: 4.0,
              useRadiusInMeter: false,
            ));
            
            print('[map_view] ✅ Successfully added location point: ${currentPoint.latitude}, ${currentPoint.longitude}');
            displayedCount++;
            
          } catch (directError) {
            print('[map_view] ❌ Error in direct location processing: $directError');
            // Still count it as processed to avoid infinite loops
            displayedCount++;
          }
          
        } catch (e) {
          print('[map_view] ❌ Error processing individual location: $e');
          print('[map_view] 📊 Location data: $thisLocation');
          continue;
        }
      }
      
      print('[map_view] ✅ Successfully displayed ${displayedCount} location points on map');
      
      // Center map on the most recent location if available
      if (lastLocation != null && _autoCenter) {
        try {
          print('[map_view] 📍 Centering map on most recent location: ${lastLocation.latitude}, ${lastLocation.longitude}');
          double zoom = _mapOptions.initialZoom;
          _mapController.move(lastLocation, zoom);
          _currentLocation = lastLocation;
        } catch (e) {
          print('[map_view] ❌ Error centering map on last location: $e');
        }
      } else if (firstLocation != null) {
        try {
          print('[map_view] 📍 Centering map on first available location: ${firstLocation.latitude}, ${firstLocation.longitude}');
          double zoom = _mapOptions.initialZoom;
          _mapController.move(firstLocation, zoom);
          _currentLocation = firstLocation;
        } catch (e) {
          print('[map_view] ❌ Error centering map on first location: $e');
        }
      }
      
      // Force a map refresh to ensure polylines and markers are visible
      setState(() {
        // Trigger rebuild to ensure map elements are displayed
      });
      
      print('[map_view] 🎯 Map refresh complete with ${_locations.length} location markers and ${_polyline.length} polyline points');
      
    } catch (error) {
      print('[map_view] ❌ Error loading stored locations: $error');
    }
  }

  void _onEnabledChange(bool enabled) {
    if (!enabled) {
//      _locations.clear();
//      _polyline.clear();
//      _stopLocations.clear();
//      _motionChangePolylines.clear();
      //     _stationaryMarker.clear();
    }
  }

  void _onMotionChange(bg.Location location) async {
    print('[MapView] 🚶 Motion change detected: ${location.isMoving ? 'moving' : 'stationary'}');
    
    try {
      // Process motion changes safely without complex flutter_map operations
      if (location.isMoving) {
        print('[MapView] 🚶 User started moving');
        // Could add motion-specific markers here if needed
      } else {
        print('[MapView] 🛑 User became stationary');
        // Could add stationary markers here if needed
      }
      
      // Update the current location regardless of motion state
      _onLocation(location);
      
    } catch (error) {
      print('[MapView] ❌ Error processing motion change: $error');
      // Don't crash the app, just log and continue
    }
  }

  void _onLocation(bg.Location location) {
    print('[MapView] 📍 Real-time location received: ${location.coords.latitude}, ${location.coords.longitude}');
    
    try {
      // Create location point safely
      LatLng currentPoint = LatLng(location.coords.latitude, location.coords.longitude);
      
      // Apply data quality filtering (same as in stored location display)
      if (location.coords.accuracy > 200.0) {
        print('[MapView] ⚠️ Rejecting real-time location with poor accuracy: ${location.coords.accuracy}m');
        return;
      }
      
      // Check for exact duplicates
      if (_locations.isNotEmpty) {
        LatLng lastPoint = _locations.last.point;
        double latDiff = (currentPoint.latitude - lastPoint.latitude).abs();
        double lngDiff = (currentPoint.longitude - lastPoint.longitude).abs();
        
        if (latDiff < 0.000001 && lngDiff < 0.000001) {
          print('[MapView] ⚠️ Skipping exact duplicate real-time location');
          return;
        }
      }
      
      // Add to polyline and markers safely
      _polyline.add(currentPoint);
      _locations.add(CircleMarker(
        point: currentPoint,
        color: Colors.blue,
        radius: 4.0,
        useRadiusInMeter: false,
      ));
      
      // Update current position marker safely
      _currentPosition.clear();
      _currentPosition.add(CircleMarker(
        point: currentPoint,
        color: Colors.red,
        radius: 8.0,
        useRadiusInMeter: false,
      ));
      
      // Auto-center map if enabled (with protection against null errors)
      if (_autoCenter) {
        try {
          double zoom = _mapOptions.initialZoom;
          _mapController.move(currentPoint, zoom);
          _currentLocation = currentPoint;
        } catch (e) {
          print('[MapView] ❌ Error moving map to new location (flutter_map compatibility issue): $e');
          // Continue without map centering to avoid crashes
        }
      }
      
      // Update the UI safely
      if (mounted) {
        setState(() {
          // Trigger rebuild to show new location
        });
      }
      
      print('[MapView] ✅ Successfully added real-time location point, total: ${_locations.length}');
      
    } catch (error) {
      print('[MapView] ❌ Error processing real-time location: $error');
      // Don't crash the app, just log and continue
    }
  }

  /// Update Big Blue current position dot.
  void _updateCurrentPositionMarker(LatLng ll) {
    // TEMPORARY: Disable current position markers to isolate error
    print('[MapView] Would update current position marker at: ${ll.latitude}, ${ll.longitude}');
    _currentPosition.clear();
    // All CircleMarker creation disabled
  }

  /*CircleMarker _buildStationaryCircleMarker(
      bg.Location location, bg.State state) {
    return new CircleMarker(
        point: LatLng(location.coords.latitude, location.coords.longitude),
        color: Color.fromRGBO(255, 0, 0, 0.5),
        useRadiusInMeter: true,
        radius: (state.trackingMode == 1)
            ? 200
            : (state.geofenceProximityRadius! / 2));
  }*/

  Polyline _buildMotionChangePolyline(bg.Location from, bg.Location to) {
    return new Polyline(points: [
      LatLng(from.coords.latitude, from.coords.longitude),
      LatLng(to.coords.latitude, to.coords.longitude)
    ], strokeWidth: 10.0, color: Color.fromRGBO(22, 190, 66, 0.7));
  }

  CircleMarker _buildStopCircleMarker(bg.Location location) {
    // TEMPORARY: Return a dummy marker to avoid null errors
    return CircleMarker(
        point: LatLng(0, 0), // Dummy coordinates  
        color: Colors.transparent, 
        useRadiusInMeter: false,
        radius: 0.0); // Zero radius
  }

  //void _onPositionChanged(MapPosition pos, bool hasGesture) {
  //   _mapOptions.crs.scale(_mapController.zoom);
  // }

  void _onPositionChanged(MapEvent event) {
    if (event is MapEventMove) {
      _mapOptions.crs
          .scale(event.camera.zoom); // Use camera.zoom instead of zoom
          
      // If user manually moves the map, disable auto-centering
      if (event.source == MapEventSource.onDrag || event.source == MapEventSource.flingAnimationController) {
        setState(() {
          _autoCenter = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        // Main map
        FlutterMap(
          mapController: _mapController,
          options: _mapOptions,
          children: [
            if (!TestService.isTestMode)
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.github.activityspacelab.wellbeingmapper.gauteng',
                maxZoom: 20,
                retinaMode: RetinaMode.isHighDensity(context),
              ),
            if (TestService.isTestMode)
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    'Test Mode - Map Disabled',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            if (_polyline.isNotEmpty)
              PolylineLayer(
                polylines: [
                  new Polyline(
                    points: _polyline,
                    strokeWidth: 10.0,
                    color: Color.fromRGBO(0, 179, 253, 0.8),
                  ),
                ],
              ),
            // Remove confusing big red stationary radius circles
            // if (_stationaryMarker.isNotEmpty)
            //   CircleLayer(circles: _stationaryMarker),
            // Polyline joining last stationary location to motionchange:true location.
            if (_motionChangePolylines.isNotEmpty)
              PolylineLayer(polylines: _motionChangePolylines),
            // Recorded locations.
            if (_locations.isNotEmpty) CircleLayer(circles: _locations),
            // Simplified stop locations (smaller, less confusing)
            if (_stopLocations.isNotEmpty) CircleLayer(circles: _stopLocations),
            if (_currentPosition.isNotEmpty) CircleLayer(circles: _currentPosition),
          ],
        ),
        
        // Map control buttons
        Positioned(
          right: 16,
          bottom: 100, // Position above typical FAB location
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Auto-center toggle
              FloatingActionButton(
                mini: true,
                heroTag: "auto_center_toggle",
                onPressed: () {
                  setState(() {
                    _autoCenter = !_autoCenter;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_autoCenter 
                        ? 'Auto-center enabled - map will follow your location' 
                        : 'Auto-center disabled - explore freely!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                backgroundColor: _autoCenter ? Colors.blue : Colors.grey[600],
                foregroundColor: Colors.white,
                child: Icon(_autoCenter ? Icons.gps_fixed : Icons.gps_not_fixed),
              ),
              SizedBox(height: 8),
              // Manual re-center button
              FloatingActionButton(
                mini: true,
                heroTag: "recenter",
                onPressed: _currentLocation != null ? () {
                  _mapController.move(_currentLocation!, _mapOptions.initialZoom);
                  setState(() {
                    _autoCenter = true; // Re-enable auto-center when manually centering
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Centered on current location'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } : null,
                backgroundColor: _currentLocation != null ? Colors.green : Colors.grey[400],
                foregroundColor: Colors.white,
                child: Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

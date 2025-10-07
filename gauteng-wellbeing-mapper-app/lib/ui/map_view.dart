import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map/plugin_api.dart';
import 'dart:async';
import 'dart:math' as math;

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

  List<CircleMarker> _currentPosition = [];
  List<LatLng> _polyline = [];
  List<CircleMarker> _locations = [];
  
  List<CircleMarker> _accuracyCircles = [];

  // NEW: Separate layers for improved performance and UX
  // Historical points loaded when map opens (before current session)
  List<CircleMarker> _historicalPoints = [];
  List<LatLng> _historicalPolyline = [];
  
  // Points collected during current session (since map opened)
  List<CircleMarker> _sessionPoints = [];
  List<LatLng> _sessionPolyline = [];

  // Stream controller for current position updates to avoid setState() on location changes
  final StreamController<List<CircleMarker>> _currentPositionStream = StreamController<List<CircleMarker>>.broadcast();
  
  // Stream controller for session points to avoid setState() when adding session points
  final StreamController<List<CircleMarker>> _sessionPointsStream = StreamController<List<CircleMarker>>.broadcast();
  
  // Stream controller for historical points to avoid setState() rebuilds when loading historical data
  final StreamController<List<CircleMarker>> _historicalPointsStream = StreamController<List<CircleMarker>>.broadcast();

  LatLng _center = new LatLng(-25.7479, 28.2293); // Pretoria, South Africa - relevant for Gauteng study
  late MapController _mapController;
  late MapOptions _mapOptions;
  
  // Track current location for re-center functionality (stored in _currentPosition)
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
      _historicalPoints.clear();
      _historicalPolyline.clear();
      _locations.clear();
      _polyline.clear();
      _accuracyCircles.clear();
      
      // Clear session points and notify stream
      _sessionPoints.clear();
      _sessionPointsStream.add(List.from(_sessionPoints));
      
      // Clear historical points and notify stream (no setState needed!)
      _historicalPointsStream.add(List.from(_historicalPoints));
      
      // Add a small delay to ensure clearing is visible
      await Future.delayed(Duration(milliseconds: 100));
      
      // Use filtered location data to improve performance
      List filteredLocations = await StorageSettingsService.getFilteredLocationDataForMap();
      print('[map_view] ✅ Found ${filteredLocations.length} filtered location points to display');
      
      if (filteredLocations.isEmpty) {
        print('[map_view] ⚠️ No location data found - user may not have tracking enabled or no movement yet');
        // No setState needed - streams handle empty data
        return;
      }
      
      int displayedCount = 0;
      LatLng? firstLocation;
      LatLng? lastLocation;
      
      for (var thisLocation in filteredLocations) {
        try {
          if (thisLocation == null) {
            print('[map_view] ⚠️ Skipping null location data');
            continue;
          }
          print('[map_view] 🔍 Processing location data: ${thisLocation.toString().substring(0, 100)}...');
          Map<String, dynamic>? coords = thisLocation['coords'];
          if (coords == null) {
            print('[map_view] ⚠️ Skipping location with null coords');
            continue;
          }
          double lat = (coords['latitude'] as num?)?.toDouble() ?? double.nan;
          double lon = (coords['longitude'] as num?)?.toDouble() ?? double.nan;
          if (lat.isNaN || lon.isNaN || lat.isInfinite || lon.isInfinite) {
            print('[map_view] ⚠️ Skipping location with invalid coordinates: lat=$lat, lon=$lon');
            continue;
          }
          double accuracy = (coords['accuracy'] as num?)?.toDouble() ?? 999.0;
          // IMPROVED: More lenient accuracy filtering to reduce gaps (was 200m, now 500m)
          if (accuracy > 500.0) {
            print('[map_view] 🚫 Skipping extremely poor accuracy location: ${accuracy}m accuracy');
            continue;
          }
          LatLng currentPoint = LatLng(lat, lon);
          if (lastLocation != null &&
              (currentPoint.latitude - lastLocation.latitude).abs() < 0.000001 &&
              (currentPoint.longitude - lastLocation.longitude).abs() < 0.000001) {
            print('[map_view] 🔄 Skipping duplicate location: ${currentPoint.latitude}, ${currentPoint.longitude}');
            continue;
          }
          if (firstLocation == null) {
            firstLocation = currentPoint;
          }
          lastLocation = currentPoint;
          
          // Create CircleMarker for historical location (semitransparent blue with accuracy radius)
          double radius = accuracy.clamp(10.0, 200.0);
          _historicalPoints.add(CircleMarker(
            point: currentPoint,
            color: Colors.blue.withValues(alpha: 0.3),
            borderColor: Colors.blue.withValues(alpha: 0.5),
            borderStrokeWidth: 1.0,
            radius: radius,
            useRadiusInMeter: true,
          ));
          
          // Add to polylines (legacy compatibility only - no visual polyline)
          _historicalPolyline.add(currentPoint);
          _polyline.add(currentPoint);
          
          print('[map_view] ✅ Successfully added location point: ${currentPoint.latitude}, ${currentPoint.longitude}');
          displayedCount++;
        } catch (e) {
          print('[map_view] ❌ Error processing individual location: $e');
          print('[map_view] 📊 Location data: $thisLocation');
          continue;
        }
      }
      
      print('[map_view] ✅ Successfully displayed ${displayedCount} location points on map');
      
      // Update historical points via stream (no setState needed!)
      _historicalPointsStream.add(List.from(_historicalPoints));
      
      // Center map on the most recent location if auto-center is enabled
      if (_autoCenter && lastLocation != null) {
        try {
          print('[map_view] 📍 Auto-centering map on most recent location: ${lastLocation.latitude}, ${lastLocation.longitude}');
          double zoom = _mapOptions.initialZoom;
          _mapController.move(lastLocation, zoom);
        } catch (e) {
          print('[map_view] ❌ Error centering map on last location: $e');
        }
      } else if (_autoCenter && firstLocation != null) {
        try {
          print('[map_view] 📍 Auto-centering map on first available location: ${firstLocation.latitude}, ${firstLocation.longitude}');
          double zoom = _mapOptions.initialZoom;
          _mapController.move(firstLocation, zoom);
        } catch (e) {
          print('[map_view] ❌ Error centering map on first location: $e');
        }
      } else if (!_autoCenter) {
        print('[map_view] 📍 Auto-center disabled - keeping current map position');
      }
      
      print('[map_view] 🎯 Map refresh complete with ${_locations.length} location markers and ${_polyline.length} polyline points');
      
    } catch (error) {
      print('[map_view] ❌ Error loading stored locations: $error');
    }
  }

  void _onEnabledChange(bool enabled) {
    if (!enabled) {
//      _locations.clear();
//      _polyline.clear();
      //     _stationaryMarker.clear();
    }
  }

  void _onLocation(bg.Location location) {
    print('[MapView] 📍 Real-time location received: ${location.coords.latitude}, ${location.coords.longitude}');
    
    try {
      // Create location point safely
      LatLng currentPoint = LatLng(location.coords.latitude, location.coords.longitude);
      
      // IMPROVED: More lenient accuracy filtering for real-time display (was 200m, now 500m)
      if (location.coords.accuracy > 500.0) {
        print('[MapView] ⚠️ Rejecting real-time location with extremely poor accuracy: ${location.coords.accuracy}m');
        return;
      }
      
      // FIXED: Enhanced duplicate and stationary filtering to reduce flashing
      if (_currentPosition.isNotEmpty) {
        LatLng lastPoint = _currentPosition.first.point;
        double distance = _calculateDistance(currentPoint.latitude, currentPoint.longitude, 
                                            lastPoint.latitude, lastPoint.longitude);
        
        // If stationary and very close to last position, skip update more aggressively
        if (!location.isMoving && distance < 15.0) {
          print('[MapView] ⚠️ Skipping stationary location update (${distance.toStringAsFixed(1)}m from last)');
          return;
        }
        
        // For moving locations, still filter exact duplicates
        if (distance < 0.5) {
          print('[MapView] ⚠️ Skipping very close duplicate location (${distance.toStringAsFixed(1)}m)');
          return;
        }
      }
      
      // If we have a previous current position, move it to session points with accuracy-based styling
      if (_currentPosition.isNotEmpty) {
        LatLng previousPoint = _currentPosition.first.point;
        // Get accuracy from location data for radius
        double radius = location.coords.accuracy.clamp(10.0, 200.0);
        _sessionPoints.add(CircleMarker(
          point: previousPoint,
          color: Colors.blue.withValues(alpha: 0.3),
          borderColor: Colors.blue.withValues(alpha: 0.5),
          borderStrokeWidth: 1.0,
          radius: radius,
          useRadiusInMeter: true,
        ));
        _sessionPolyline.add(previousPoint);
        
        // Update session points via stream (no setState!)
        _sessionPointsStream.add(List.from(_sessionPoints));
      }
      
      // Add to polyline for continuity (only if moving or significant distance)
      if (location.isMoving || _polyline.isEmpty) {
        _polyline.add(currentPoint);
      }
      
      // Update current position marker safely (most recent, prominent styling)
      _currentPosition.clear();
      
      // Google Maps style blue marker with white perimeter
      _currentPosition.add(
        CircleMarker(
          point: currentPoint,
          color: Colors.blue,
          borderColor: Colors.white,
          borderStrokeWidth: 3.0,
          radius: 8.0,
          useRadiusInMeter: false,
        ),
      );
      
      // Send current position update through stream (no setState needed!)
      _currentPositionStream.add(List.from(_currentPosition));
      
      // Auto-center map if enabled (without setState to avoid full rebuild)
      if (_autoCenter) {
        try {
          double zoom = _mapOptions.initialZoom;
          _mapController.move(currentPoint, zoom);
          print('[MapView] 🎯 Auto-centered map on real-time location: ${currentPoint.latitude}, ${currentPoint.longitude}');
        } catch (e) {
          print('[MapView] ❌ Error moving map to new location (flutter_map compatibility issue): $e');
          // Continue without map centering to avoid crashes
        }
      } else {
        print('[MapView] 📍 Auto-center disabled - not centering on real-time location');
      }
      
      print('[MapView] ✅ Successfully added real-time location point via stream, total: ${_locations.length}');
      
    } catch (error) {
      print('[MapView] ❌ Error processing real-time location: $error');
      // Don't crash the app, just log and continue
    }
  }

  // FIXED: Add distance calculation helper for location filtering
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLon = (lon2 - lon1) * (math.pi / 180);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
  
  @override
  void dispose() {
    _currentPositionStream.close();
    _sessionPointsStream.close();
    _historicalPointsStream.close();
    super.dispose();
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
            // Historical points with StreamBuilder (completely independent updates)
            StreamBuilder<List<CircleMarker>>(
              stream: _historicalPointsStream.stream,
              initialData: _historicalPoints,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return CircleLayer(circles: snapshot.data!);
                }
                return SizedBox.shrink();
              },
            ),
            
            // Session points with StreamBuilder (updates independently when session points are added)
            StreamBuilder<List<CircleMarker>>(
              stream: _sessionPointsStream.stream,
              initialData: _sessionPoints,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return CircleLayer(circles: snapshot.data!);
                }
                return SizedBox.shrink();
              },
            ),
            
            // Current position with StreamBuilder (updates independently without rebuilding other layers)
            StreamBuilder<List<CircleMarker>>(
              stream: _currentPositionStream.stream,
              initialData: _currentPosition,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return CircleLayer(circles: snapshot.data!);
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
        
        // Map control buttons
        Positioned(
          right: 16,
          bottom: 100, // Position above typical FAB location
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Auto-center toggle (green when enabled)
              FloatingActionButton(
                mini: true,
                heroTag: "auto_center_toggle",
                onPressed: () {
                  final newAutoCenter = !_autoCenter;
                  
                  // Do the centering first if enabling (before setState to avoid rebuild during centering)
                  if (newAutoCenter) {
                    LatLng? centerPoint;
                    
                    // Try current position first
                    if (_currentPosition.isNotEmpty) {
                      centerPoint = _currentPosition.first.point;
                    } 
                    // Fall back to last session point
                    else if (_sessionPoints.isNotEmpty) {
                      centerPoint = _sessionPoints.last.point;
                    }
                    // Fall back to last historical point
                    else if (_historicalPoints.isNotEmpty) {
                      centerPoint = _historicalPoints.last.point;
                    }
                    
                    if (centerPoint != null) {
                      try {
                        _mapController.move(centerPoint, _mapOptions.initialZoom);
                        print('[MapView] 🎯 Immediate centering on enabling auto-center');
                      } catch (e) {
                        print('[MapView] Error centering map: $e');
                      }
                    }
                  }
                  
                  // Then update the state for the button color (minimal setState)
                  setState(() {
                    _autoCenter = newAutoCenter;
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
            ],
          ),
        ),
      ],
    );
  }
}

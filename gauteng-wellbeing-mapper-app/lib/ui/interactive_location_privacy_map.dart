import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/south_african_theme.dart';
import '../models/data_sharing_consent.dart';
import '../models/survey_models.dart';
import '../db/survey_database.dart';

/// Interactive map widget that allows users to selectively erase location points 
/// they don't want to share, providing granular privacy control
class InteractiveLocationPrivacyMap extends StatefulWidget {
  final List<LocationTrack> locationTracks;
  final VoidCallback onConfirmSelection;
  final VoidCallback onCancel;
  final String participantUuid;
  final VoidCallback onUploadProceed;
  final bool isSelectionMode; // If true, just returns selection instead of uploading
  final Function(Set<int>)? onSelectionChanged; // Callback for selection mode

  const InteractiveLocationPrivacyMap({
    Key? key,
    required this.locationTracks,
    required this.onConfirmSelection,
    required this.onCancel,
    required this.participantUuid,
    required this.onUploadProceed,
    this.isSelectionMode = false,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  _InteractiveLocationPrivacyMapState createState() => _InteractiveLocationPrivacyMapState();
}

class _InteractiveLocationPrivacyMapState extends State<InteractiveLocationPrivacyMap> {
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey(); // Key to reference the map widget specifically
  final double _eraserRadius = 100.0; // 100 meter radius (200m diameter)
  
  // Track which points are erased (hidden from sharing)
  Set<int> _erasedPointIndices = <int>{};
  
  // Current tool mode
  bool _isEraserMode = true; // true = eraser, false = uneraser
  bool _isNavigationMode = true; // true = map navigation, false = eraser/restore - start in navigation mode
  
  // For gesture detection
  bool _isDragging = false;
  LatLng? _currentEraserLatLng; // Actual lat/lng position of eraser circle
  DateTime _lastUpdateTime = DateTime.now(); // For throttling updates

  @override
  void initState() {
    super.initState();
    _centerMapOnData();
  }

  void _centerMapOnData() {
    if (widget.locationTracks.isEmpty) return;
    
    // Calculate bounds of all location points
    double minLat = widget.locationTracks.first.latitude;
    double maxLat = widget.locationTracks.first.latitude;
    double minLng = widget.locationTracks.first.longitude;
    double maxLng = widget.locationTracks.first.longitude;
    
    for (final track in widget.locationTracks) {
      if (track.latitude < minLat) minLat = track.latitude;
      if (track.latitude > maxLat) maxLat = track.latitude;
      if (track.longitude < minLng) minLng = track.longitude;
      if (track.longitude > maxLng) maxLng = track.longitude;
    }
    
    // Center point
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // Add some padding and zoom to show all points
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(centerLat, centerLng), 14.0);
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;
    _processEraserAction(details.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      // Throttle updates to improve performance
      final now = DateTime.now();
      if (now.difference(_lastUpdateTime).inMilliseconds > 50) { // Update at most every 50ms
        _processEraserAction(details.globalPosition);
        _lastUpdateTime = now;
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDragging = false;
    _currentEraserLatLng = null;
  }

  void _processEraserAction(Offset globalPosition) {
    // Get the map widget's render box using the key
    final RenderBox? mapRenderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (mapRenderBox == null) return;

    // Convert global position to local position relative to the map widget specifically
    final localPosition = mapRenderBox.globalToLocal(globalPosition);
    final mapSize = mapRenderBox.size;
    
    // Get current map bounds from the camera
    final camera = _mapController.camera;
    final bounds = camera.visibleBounds;
    
    // Convert screen coordinates to lat/lng with proper bounds calculation
    final relativeX = localPosition.dx / mapSize.width;
    final relativeY = localPosition.dy / mapSize.height;
    
    // Ensure coordinates are within valid range [0,1]
    final clampedX = relativeX.clamp(0.0, 1.0);
    final clampedY = relativeY.clamp(0.0, 1.0);
    
    final tapLat = bounds.north - (clampedY * (bounds.north - bounds.south));
    final tapLng = bounds.west + (clampedX * (bounds.east - bounds.west));
    
    // Always store the current eraser position for visual feedback (show circle everywhere)
    _currentEraserLatLng = LatLng(tapLat, tapLng);
    
    print('[InteractiveMap] Touch at map-local: ${localPosition.dx.toStringAsFixed(1)}, ${localPosition.dy.toStringAsFixed(1)} -> lat/lng: ${tapLat.toStringAsFixed(6)}, ${tapLng.toStringAsFixed(6)}');
    print('[InteractiveMap] Map size: ${mapSize.width.toStringAsFixed(1)} x ${mapSize.height.toStringAsFixed(1)}');
    
    _findAndToggleNearbyPoints(LatLng(tapLat, tapLng));
  }

  void _findAndToggleNearbyPoints(LatLng centerPoint) {
    // Find points within eraser radius
    final Distance distance = Distance();
    
    bool foundPoints = false;
    for (int i = 0; i < widget.locationTracks.length; i++) {
      final track = widget.locationTracks[i];
      final trackPoint = LatLng(track.latitude, track.longitude);
      final pointDistance = distance.as(LengthUnit.Meter, centerPoint, trackPoint);
      
      if (pointDistance <= _eraserRadius) {
        foundPoints = true;
        setState(() {
          if (_isEraserMode) {
            _erasedPointIndices.add(i);
            print('[InteractiveMap] Erased point $i at distance ${pointDistance.toStringAsFixed(1)}m');
          } else {
            _erasedPointIndices.remove(i);
            print('[InteractiveMap] Restored point $i at distance ${pointDistance.toStringAsFixed(1)}m');
          }
        });
      }
    }
    
    if (!foundPoints) {
      print('[InteractiveMap] No points found within ${_eraserRadius}m of position');
    }
  }

  void _resetAllPoints() {
    setState(() {
      _erasedPointIndices.clear();
    });
  }

  Future<void> _submitLocationSelection() async {
    try {
      if (widget.isSelectionMode) {
        // Selection mode: just return the erased indices to the calling widget
        if (widget.onSelectionChanged != null) {
          widget.onSelectionChanged!(_erasedPointIndices);
        }
        Navigator.of(context).pop(_erasedPointIndices); // Return the erased indices
        return;
      }

      // Original consent dialog mode: save consent and trigger upload
      // Create dummy location cluster IDs based on selected points
      // For partial data sharing, we'll use the indices of the selected location tracks
      List<String> customLocationIds = [];
      
      // Get the selected location tracks (those not erased)
      final selectedTracks = getSelectedLocationTracks();
      
      // Create cluster IDs based on the selected tracks
      for (int i = 0; i < selectedTracks.length; i++) {
        customLocationIds.add('track_${i}');
      }

      // Save user's consent decision with partial data selection
      final consent = DataSharingConsent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationSharingOption: LocationSharingOption.partialData,
        decisionTimestamp: DateTime.now(),
        participantUuid: widget.participantUuid,
        customLocationIds: customLocationIds,
      );

      // Store consent in database
      final db = SurveyDatabase();
      await db.insertDataSharingConsent(consent);

      // Signal completion to consent dialog and trigger upload
      widget.onConfirmSelection(); // This will close the map and signal to consent dialog
      widget.onUploadProceed(); // This will trigger the actual upload process
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving selection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<LocationTrack> getSelectedLocationTracks() {
    return widget.locationTracks
        .asMap()
        .entries
        .where((entry) => !_erasedPointIndices.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location Data to Share'),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Column(
        children: [
          // Map with gesture detection
          Expanded(
            child: Stack(
              children: [
                // Use a GestureDetector that only handles eraser actions when not in navigation mode
                GestureDetector(
                  onTapUp: (details) {
                    if (!_isNavigationMode) {
                      _processEraserAction(details.globalPosition);
                    }
                  },
                  onPanStart: (details) {
                    if (!_isNavigationMode) {
                      _handlePanStart(details);
                    }
                  },
                  onPanUpdate: (details) {
                    if (!_isNavigationMode) {
                      _handlePanUpdate(details);
                    }
                  },
                  onPanEnd: (details) {
                    if (!_isNavigationMode) {
                      _handlePanEnd(details);
                    }
                  },
                  child: FlutterMap(
                    key: _mapKey, // Add key to reference this widget
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(-26.2041, 28.0473), // Johannesburg
                      initialZoom: 14.0,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      // Enable full map interactions only in navigation mode
                      interactionOptions: InteractionOptions(
                        flags: _isNavigationMode 
                          ? InteractiveFlag.all // All interactions in navigation mode
                          : InteractiveFlag.none, // No built-in interactions in eraser/restore mode
                      ),
                    ),
                    children: [
                      // Base map tiles
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      
                      // Location points
                      CircleLayer(
                        circles: widget.locationTracks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final track = entry.value;
                          final isErased = _erasedPointIndices.contains(index);
                          
                          return CircleMarker(
                            point: LatLng(track.latitude, track.longitude),
                            radius: 8,
                            color: isErased 
                              ? Colors.red.withValues(alpha: 0.3)  // Erased points are faded red
                              : SouthAfricanTheme.primaryBlue.withValues(alpha: 0.8), // Active points are blue
                            borderStrokeWidth: 2,
                            borderColor: isErased 
                              ? Colors.red 
                              : SouthAfricanTheme.primaryBlue,
                          );
                        }).toList(),
                      ),
                      
                      // Eraser circle visualization (when dragging)
                      if (_isDragging && _currentEraserLatLng != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _currentEraserLatLng!,
                              radius: _eraserRadius, // Use meter radius directly
                              color: (_isEraserMode ? Colors.red : Colors.green).withValues(alpha: 0.2),
                              borderStrokeWidth: 3,
                              borderColor: _isEraserMode ? Colors.red : Colors.green,
                              useRadiusInMeter: true, // Important: use actual meter radius
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Manual zoom controls
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        heroTag: "zoom_in",
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            (currentZoom + 1).clamp(10.0, 18.0),
                          );
                        },
                        child: Icon(Icons.add),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: "zoom_out",
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            (currentZoom - 1).clamp(10.0, 18.0),
                          );
                        },
                        child: Icon(Icons.remove),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tool controls
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Tool selection
                // Mode selection buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEraserMode = true;
                            _isNavigationMode = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_isEraserMode && !_isNavigationMode)
                            ? Colors.red[600] 
                            : Colors.grey[300],
                          foregroundColor: (_isEraserMode && !_isNavigationMode)
                            ? Colors.white 
                            : Colors.grey[700],
                        ),
                        child: Icon(Icons.remove, size: 24),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEraserMode = false;
                            _isNavigationMode = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (!_isEraserMode && !_isNavigationMode)
                            ? Colors.green[600] 
                            : Colors.grey[300],
                          foregroundColor: (!_isEraserMode && !_isNavigationMode)
                            ? Colors.white 
                            : Colors.grey[700],
                        ),
                        child: Icon(Icons.add, size: 24),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isNavigationMode = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isNavigationMode
                            ? Colors.blue[600] 
                            : Colors.grey[300],
                          foregroundColor: _isNavigationMode
                            ? Colors.white 
                            : Colors.grey[700],
                        ),
                        child: Icon(Icons.navigation, size: 24),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Action buttons - evenly spaced
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resetAllPoints,
                        icon: Icon(Icons.refresh, size: 20),
                        label: Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.orange[700],
                          backgroundColor: Colors.orange[50],
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onCancel,
                        icon: Icon(Icons.close, size: 20),
                        label: Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          backgroundColor: Colors.grey[100],
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitLocationSelection,
                        icon: Icon(Icons.check, size: 20, color: Colors.white),
                        label: Text('Confirm Selection', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SouthAfricanTheme.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

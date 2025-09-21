import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../models/data_sharing_consent.dart';
import '../models/survey_models.dart';
import '../db/survey_database.dart';
import '../theme/south_african_theme.dart';
import 'interactive_location_privacy_map.dart';

/// Dialog that prompts research participants for their consent before uploading data
class DataSharingConsentDialog extends StatefulWidget {
  final String participantUuid;
  final String researchSite;
  final VoidCallback onUploadProceed;
  final VoidCallback onUploadCancelled;

  const DataSharingConsentDialog({
    Key? key,
    required this.participantUuid,
    required this.researchSite,
    required this.onUploadProceed,
    required this.onUploadCancelled,
  }) : super(key: key);

  @override
  _DataSharingConsentDialogState createState() => _DataSharingConsentDialogState();
}

class _DataSharingConsentDialogState extends State<DataSharingConsentDialog> {
  LocationSharingOption _selectedOption = LocationSharingOption.fullData;
  bool _isLoading = true;
  DataUploadSummary? _dataSummary;
  Set<String> _selectedClusterIds = Set<String>(); // Track selected location clusters
  List<LocationTrack> _recentLocationTracks = []; // Store the location tracks for map interaction

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
  }

  Future<void> _loadDataSummary() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Debug: Check what's in the database directly
      final db = SurveyDatabase();
      final allLocationTracks = await db.getAllLocationTracks();
      print('[DataSharingConsentDialog] Found ${allLocationTracks.length} total location tracks in database');

      // Get location data from background geolocation plugin (same as map uses)
      List<LocationTrack> locationTracks = [];
      
      if (!kIsWeb) {
        try {
          // Get location data from background geolocation plugin
          final bgLocations = await bg.BackgroundGeolocation.locations;
          print('[DataSharingConsentDialog] Found ${bgLocations.length} background geolocation records');
          
          // Convert to LocationTrack objects and filter for last 2 weeks
          final twoWeeksAgo = DateTime.now().subtract(Duration(days: 14));
          for (var bgLocation in bgLocations) {
            try {
              final locationMap = bgLocation as Map<Object?, Object?>;
              
              // Handle timestamp - could be int or string
              DateTime locationTime;
              final timestamp = locationMap['timestamp'];
              if (timestamp is int) {
                locationTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              } else if (timestamp is String) {
                locationTime = DateTime.parse(timestamp);
              } else {
                print('[DataSharingConsentDialog] Unknown timestamp format: ${timestamp.runtimeType}');
                continue;
              }
              
              if (locationTime.isAfter(twoWeeksAgo)) {
                final coords = locationMap['coords'] as Map<Object?, Object?>?;
                if (coords != null) {
                  locationTracks.add(LocationTrack(
                    timestamp: locationTime,
                    latitude: coords['latitude'] as double,
                    longitude: coords['longitude'] as double,
                    accuracy: coords['accuracy'] as double?,
                    altitude: coords['altitude'] as double?,
                    speed: coords['speed'] as double?,
                    activity: (locationMap['activity'] as Map<Object?, Object?>?)?['type'] as String?,
                  ));
                }
              }
            } catch (e) {
              print('[DataSharingConsentDialog] Error processing location record: $e');
              continue;
            }
          }
        } catch (e) {
          print('[DataSharingConsentDialog] Error getting background locations: $e');
        }
      }
      
      print('[DataSharingConsentDialog] Retrieved ${locationTracks.length} recent location tracks (last 2 weeks)');

      // Store location tracks for interactive map
      _recentLocationTracks = locationTracks;

      // Get survey count
      final initialSurveys = await db.getInitialSurveys();
      final recurringSurveys = await db.getRecurringSurveys();
      final totalSurveys = initialSurveys.length + recurringSurveys.length;

      // Create clusters for location preview
      final clusters = _createLocationClusters(locationTracks);
      print('[DataSharingConsentDialog] Created ${clusters.length} location clusters');

      if (locationTracks.isNotEmpty) {
        final dates = locationTracks.map((track) => track.timestamp).toList()..sort();
        final accuracies = locationTracks.map((track) => track.accuracy ?? 0.0).where((acc) => acc > 0);
        final avgAccuracy = accuracies.isNotEmpty 
            ? accuracies.reduce((a, b) => a + b) / accuracies.length 
            : 0.0;

        setState(() {
          _dataSummary = DataUploadSummary(
            surveyResponseCount: totalSurveys,
            locationTrackCount: locationTracks.length,
            oldestLocationDate: dates.first,
            newestLocationDate: dates.last,
            locationAccuracyStats: avgAccuracy,
            locationClusters: clusters,
          );
          
          // Initialize all clusters as selected for partial sharing
          _selectedClusterIds.clear();
          for (int i = 0; i < clusters.length; i++) {
            _selectedClusterIds.add('cluster_$i');
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _dataSummary = DataUploadSummary(
            surveyResponseCount: totalSurveys,
            locationTrackCount: 0,
            oldestLocationDate: DateTime.now().subtract(Duration(days: 14)),
            newestLocationDate: DateTime.now(),
            locationAccuracyStats: 0.0,
            locationClusters: [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data summary: $e');
    }
  }

  List<LocationCluster> _createLocationClusters(List<LocationTrack> tracks) {
    if (tracks.isEmpty) return [];
    
    // Create individual clusters for each location point to give users granular control
    // This allows users to exclude specific locations even if they only have one point there
    final clusters = <LocationCluster>[];
    const double clusterRadius = 0.005; // Reduced radius (roughly 500m) for finer granularity
    
    for (final track in tracks) {
      bool addedToCluster = false;
      
      for (int i = 0; i < clusters.length; i++) {
        final cluster = clusters[i];
        final distance = _calculateDistance(
          track.latitude, track.longitude,
          cluster.centerLatitude, cluster.centerLongitude,
        );
        
        if (distance <= clusterRadius) {
          // Add to existing cluster and update centroid
          final newTrackCount = cluster.trackCount + 1;
          final newCenterLat = (cluster.centerLatitude * cluster.trackCount + track.latitude) / newTrackCount;
          final newCenterLon = (cluster.centerLongitude * cluster.trackCount + track.longitude) / newTrackCount;
          
          clusters[i] = LocationCluster(
            areaName: cluster.areaName,
            trackCount: newTrackCount,
            centerLatitude: newCenterLat,
            centerLongitude: newCenterLon,
            firstVisit: track.timestamp.isBefore(cluster.firstVisit) ? track.timestamp : cluster.firstVisit,
            lastVisit: track.timestamp.isAfter(cluster.lastVisit) ? track.timestamp : cluster.lastVisit,
          );
          addedToCluster = true;
          break;
        }
      }
      
      if (!addedToCluster) {
        // Create a new cluster for this location - even single points get their own cluster
        clusters.add(LocationCluster(
          areaName: _getAreaName(track.latitude, track.longitude),
          trackCount: 1,
          centerLatitude: track.latitude,
          centerLongitude: track.longitude,
          firstVisit: track.timestamp,
          lastVisit: track.timestamp,
        ));
      }
    }
    
    return clusters;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple Euclidean distance approximation for clustering
    return ((lat1 - lat2).abs() + (lon1 - lon2).abs());
  }

  String _getAreaName(double latitude, double longitude) {
    // Create more user-friendly area names
    // Use a simple grid-based naming system that's more readable
    final latInt = (latitude * 100).round();
    final lonInt = (longitude * 100).round();
    return "Location Area ${latInt.abs()}.${lonInt.abs()}";
  }

  void _handleOptionChanged(LocationSharingOption? option) {
    if (option != null) {
      setState(() {
        _selectedOption = option;
        // Clear any previous selections when switching options
        if (option != LocationSharingOption.partialData) {
          _selectedClusterIds.clear();
        }
      });
      
      // Open interactive map for partial data selection
      if (option == LocationSharingOption.partialData) {
        _openInteractiveMap();
      }
    }
  }

  void _openInteractiveMap() async {
    if (_recentLocationTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No location data available for selection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show help dialog first
    final shouldProceed = await _showMapHelpDialog();
    if (!shouldProceed) {
      // User cancelled, switch back to full data mode
      setState(() {
        _selectedOption = LocationSharingOption.fullData;
      });
      return;
    }

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => InteractiveLocationPrivacyMap(
          locationTracks: _recentLocationTracks,
          onConfirmSelection: () {
            Navigator.of(context).pop('submitted'); // Signal that data was submitted
          },
          onCancel: () {
            Navigator.of(context).pop('cancelled');
          },
          participantUuid: widget.participantUuid,
          onUploadProceed: widget.onUploadProceed,
        ),
      ),
    );

    // Handle the result
    if (result == 'submitted') {
      // Data was submitted from the map, close this dialog too
      Navigator.of(context).pop();
    } else if (result == 'cancelled') {
      // User cancelled, switch back to full data mode
      setState(() {
        _selectedOption = LocationSharingOption.fullData;
      });
    }
  }

  Future<bool> _showMapHelpDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Location Sharing Choices Guide',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can choose exactly which locations to share:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                
                // Remove/Restore/Navigate buttons explanation
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.remove, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remove Mode: Tap or drag to exclude locations from sharing',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Restore Mode: Tap or drag to restore locations for sharing',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.navigation, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Navigate Mode: Pan, zoom, and explore the map freely',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Control buttons explanation
                Text(
                  'Bottom Controls:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange[700], size: 20),
                    SizedBox(width: 12),
                    Text('Reset - Restore all locations', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.close, color: Colors.grey[700], size: 20),
                    SizedBox(width: 12),
                    Text('Cancel - Exit without choosing', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.check, color: SouthAfricanTheme.primaryBlue, size: 20),
                    SizedBox(width: 12),
                    Text('Submit - Save your selection and continue', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SouthAfricanTheme.primaryBlue,
              ),
              child: Text(
                'Got It!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _proceedWithUpload() async {
    try {
      // Prepare custom location IDs for partial sharing
      List<String>? customLocationIds;
      if (_selectedOption == LocationSharingOption.partialData) {
        customLocationIds = _selectedClusterIds.toList();
      }

      // Save user's consent decision
      final consent = DataSharingConsent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationSharingOption: _selectedOption,
        decisionTimestamp: DateTime.now(),
        participantUuid: widget.participantUuid,
        customLocationIds: customLocationIds,
      );

      // Store consent in database
      final db = SurveyDatabase();
      await db.insertDataSharingConsent(consent);

      Navigator.of(context).pop();
      widget.onUploadProceed();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving consent: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Location Sharing Choices',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: _isLoading ? _buildLoadingContent() : _buildConsentContent(),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onUploadCancelled();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_canProceedWithUpload() ? null : _proceedWithUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: SouthAfricanTheme.primaryBlue,
          ),
          child: Text(
            'Continue Upload',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      width: double.maxFinite,
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: SouthAfricanTheme.primaryBlue,
            ),
            SizedBox(height: 16),
            Text('Analyzing your data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentContent() {
    return Container(
      width: double.maxFinite,
      constraints: BoxConstraints(maxHeight: 500),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You are about to upload your research data. Please choose how much location data you\'d like to share:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            _buildDataSummary(),
            SizedBox(height: 20),
            _buildSharingOptions(),
            SizedBox(height: 16),
            _buildPrivacyNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    if (_dataSummary == null) return SizedBox.shrink();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Survey Responses: ${_dataSummary!.surveyResponseCount}'),
            Text('Location Records: ${_dataSummary!.locationTrackCount}'),
            if (_dataSummary!.locationTrackCount > 0) ...[
              Text('Date Range: ${_formatDate(_dataSummary!.oldestLocationDate)} - ${_formatDate(_dataSummary!.newestLocationDate)}'),
              Text('Location Areas: ${_dataSummary!.locationClusters.length} different areas'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSharingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Data Sharing Options:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        
        RadioListTile<LocationSharingOption>(
          title: Text('Share Full Location Data'),
          subtitle: Text('Upload complete 2-week location history (${_dataSummary?.locationTrackCount ?? 0} records)'),
          value: LocationSharingOption.fullData,
          groupValue: _selectedOption,
          onChanged: _handleOptionChanged,
          activeColor: SouthAfricanTheme.primaryBlue,
        ),
        
        RadioListTile<LocationSharingOption>(
          title: Text('Share Partial Location Data'),
          subtitle: Text('Open interactive map to select specific locations to share'),
          value: LocationSharingOption.partialData,
          groupValue: _selectedOption,
          onChanged: _handleOptionChanged,
          activeColor: SouthAfricanTheme.primaryBlue,
        ),
        
        RadioListTile<LocationSharingOption>(
          title: Text('Survey Responses Only'),
          subtitle: Text('Upload only survey answers, no location data'),
          value: LocationSharingOption.surveyOnly,
          groupValue: _selectedOption,
          onChanged: _handleOptionChanged,
          activeColor: SouthAfricanTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Privacy Protection',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• All data is encrypted before upload\n'
            '• No personal identifiers are included\n'
            '• You can change this preference anytime\n'
            '• You can withdraw from the study at any point',
            style: TextStyle(fontSize: 13, color: Colors.green[800]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _canProceedWithUpload() {
    // Always allow full data or survey-only options
    if (_selectedOption == LocationSharingOption.fullData || 
        _selectedOption == LocationSharingOption.surveyOnly) {
      return true;
    }
    
    // For partial data, always allow (even if no clusters selected - equivalent to survey-only)
    if (_selectedOption == LocationSharingOption.partialData) {
      return true;
    }
    
    return false;
  }
}

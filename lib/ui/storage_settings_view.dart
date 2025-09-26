import 'package:flutter/material.dart';
import '../services/storage_settings_service.dart';

class StorageSettingsView extends StatefulWidget {
  @override
  _StorageSettingsViewState createState() => _StorageSettingsViewState();
}

class _StorageSettingsViewState extends State<StorageSettingsView> {
  // Current settings
  int _locationRetentionDays = StorageSettingsService.DEFAULT_LOCATION_RETENTION_DAYS;
  int _mapDisplayDays = StorageSettingsService.DEFAULT_MAP_DISPLAY_DAYS;
  int _maxMapMarkers = StorageSettingsService.DEFAULT_MAX_MAP_MARKERS;
  bool _autoCleanupEnabled = StorageSettingsService.DEFAULT_AUTO_CLEANUP_ENABLED;
  bool _locationRetentionLimited = true;
  bool _mapDisplayLimited = true;
  
  // Loading states
  bool _isLoading = true;
  bool _isPerformingCleanup = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final locationRetention = await StorageSettingsService.getLocationRetentionDays();
      final mapDisplay = await StorageSettingsService.getMapDisplayDays();
      final maxMarkers = await StorageSettingsService.getMaxMapMarkers();
      final autoCleanup = await StorageSettingsService.getAutoCleanupEnabled();
      final locationLimited = await StorageSettingsService.getLocationRetentionLimited();
      final mapLimited = await StorageSettingsService.getMapDisplayLimited();

      setState(() {
        _locationRetentionDays = locationRetention == StorageSettingsService.UNLIMITED_VALUE 
            ? StorageSettingsService.DEFAULT_LOCATION_RETENTION_DAYS : locationRetention;
        _mapDisplayDays = mapDisplay == StorageSettingsService.UNLIMITED_VALUE 
            ? StorageSettingsService.DEFAULT_MAP_DISPLAY_DAYS : mapDisplay;
        _maxMapMarkers = maxMarkers;
        _autoCleanupEnabled = autoCleanup;
        _locationRetentionLimited = locationLimited;
        _mapDisplayLimited = mapLimited;
        _isLoading = false;
      });
    } catch (e) {
      print('[StorageSettingsView] Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocationRetentionDays(double value) async {
    final days = value.toInt();
    setState(() {
      _locationRetentionDays = days;
    });
    await StorageSettingsService.setLocationRetentionDays(days);
  }

  Future<void> _updateLocationRetentionLimited(bool limited) async {
    setState(() {
      _locationRetentionLimited = limited;
    });
    await StorageSettingsService.setLocationRetentionLimited(limited);
  }

  Future<void> _updateMapDisplayDays(double value) async {
    final days = value.toInt();
    setState(() {
      _mapDisplayDays = days;
    });
    await StorageSettingsService.setMapDisplayDays(days);
  }

  Future<void> _updateMapDisplayLimited(bool limited) async {
    setState(() {
      _mapDisplayLimited = limited;
    });
    await StorageSettingsService.setMapDisplayLimited(limited);
  }

  Future<void> _updateMaxMapMarkers(double value) async {
    final markers = value.toInt();
    setState(() {
      _maxMapMarkers = markers;
    });
    await StorageSettingsService.setMaxMapMarkers(markers);
  }

  Future<void> _updateAutoCleanup(bool value) async {
    setState(() {
      _autoCleanupEnabled = value;
    });
    await StorageSettingsService.setAutoCleanupEnabled(value);
  }

  Future<void> _performManualCleanup() async {
    setState(() {
      _isPerformingCleanup = true;
    });

    try {
      await StorageSettingsService.performCleanup();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Manual cleanup completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Cleanup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPerformingCleanup = false;
      });
    }
  }

  Widget _buildSwitchSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderSetting(String title, String subtitle, double value, double min, double max, Function(double) onChanged, String unit, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
          subtitle: Text(subtitle, style: TextStyle(color: enabled ? null : Colors.grey)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text('${min.toInt()}', style: TextStyle(color: enabled ? null : Colors.grey)),
              Expanded(
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: (max - min).toInt(),
                  label: '${value.toInt()} $unit',
                  onChanged: enabled ? onChanged : null,
                ),
              ),
              Text('${max.toInt()}', style: TextStyle(color: enabled ? null : Colors.grey)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Current: ${value.toInt()} $unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: enabled ? null : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLimitedSetting({
    required String title,
    required String subtitle,
    required bool isLimited,
    required Function(bool) onLimitedChanged,
    required double sliderValue,
    required double sliderMin,
    required double sliderMax,
    required Function(double) onSliderChanged,
    required String unit,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Checkbox(
                  value: isLimited,
                  onChanged: (bool? value) => onLimitedChanged(value ?? false),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              isLimited ? 'Set limit:' : 'No limit - all data will be kept',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isLimited ? null : Colors.blue[700],
              ),
            ),
            if (isLimited) ...[
              SizedBox(height: 8),
              _buildSliderSetting(
                '',
                '',
                sliderValue,
                sliderMin,
                sliderMax,
                onSliderChanged,
                unit,
                enabled: isLimited,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Storage Settings'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Storage Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Configure how long location data is stored and displayed in the app.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Location Retention Setting
            _buildLimitedSetting(
              title: 'Location Data Retention',
              subtitle: 'How long to keep location data on device',
              isLimited: _locationRetentionLimited,
              onLimitedChanged: _updateLocationRetentionLimited,
              sliderValue: _locationRetentionDays.toDouble(),
              sliderMin: StorageSettingsService.MINIMUM_LOCATION_RETENTION_DAYS.toDouble(),
              sliderMax: 90.0,
              onSliderChanged: _updateLocationRetentionDays,
              unit: 'days',
            ),

            SizedBox(height: 16),

            // Map Display Setting
            _buildLimitedSetting(
              title: 'Map Display Period',
              subtitle: 'How many days of data to show on the map',
              isLimited: _mapDisplayLimited,
              onLimitedChanged: _updateMapDisplayLimited,
              sliderValue: _mapDisplayDays.toDouble(),
              sliderMin: 1.0,
              sliderMax: 30.0,
              onSliderChanged: _updateMapDisplayDays,
              unit: 'days',
            ),

            SizedBox(height: 16),

            // Max Map Markers Setting
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: _buildSliderSetting(
                  'Maximum Map Markers',
                  'Limit markers displayed to improve performance',
                  _maxMapMarkers.toDouble(),
                  100.0,
                  2000.0,
                  _updateMaxMapMarkers,
                  'markers',
                ),
              ),
            ),

            SizedBox(height: 16),

            // Automatic Cleanup Setting
            Card(
              child: _buildSwitchSetting(
                'Automatic Cleanup',
                'Automatically remove old data daily',
                _autoCleanupEnabled,
                _updateAutoCleanup,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Manual cleanup button moved to bottom with explanation
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cleaning_services, color: Colors.orange[700]),
                        SizedBox(width: 8),
                        Text(
                          'Manual Cleanup',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _locationRetentionLimited 
                          ? 'Remove location data older than your retention period ($_locationRetentionDays days). This will delete old data from both device storage and the app database.'
                          : 'Manual cleanup is disabled because unlimited retention is enabled. Enable retention limits to use manual cleanup.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isPerformingCleanup || !_locationRetentionLimited) ? null : _performManualCleanup,
                        child: _isPerformingCleanup
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cleaning up...'),
                                ],
                              )
                            : Text(_locationRetentionLimited ? 'Clean Up Old Data Now' : 'Cleanup Disabled'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _locationRetentionLimited ? Colors.orange : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Important Notes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Survey data requires minimum ${StorageSettingsService.MINIMUM_LOCATION_RETENTION_DAYS} days retention\n'
                      '• Unlimited retention keeps all data until manually deleted\n'
                      '• Map performance may decrease with too many markers\n'
                      '• Automatic cleanup runs daily in the background',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/data_sharing_consent.dart';
import '../db/survey_database.dart';
import '../theme/south_african_theme.dart';

/// Screen for users to view and manage their data sharing consent preferences
class DataSharingPreferencesScreen extends StatefulWidget {
  @override
  _DataSharingPreferencesScreenState createState() => _DataSharingPreferencesScreenState();
}

class _DataSharingPreferencesScreenState extends State<DataSharingPreferencesScreen> {
  bool _isLoading = true;
  String? _participantUuid;
  DataSharingConsent? _currentConsent;
  List<DataSharingConsent> _consentHistory = [];

  @override
  void initState() {
    super.initState();
    _checkConsentAndLoad();
  }

  /// Check if user has consent before showing preferences, redirect if no consent
  Future<void> _checkConsentAndLoad() async {
    debugPrint('[DataSharingPreferences] Checking for existing consent...');
    
    // Import the consent tracking service
    try {
      final db = SurveyDatabase();
      final consent = await db.getConsent();
      
      if (consent == null) {
        debugPrint('[DataSharingPreferences] No consent found - redirecting to participation selection');
        
        if (mounted) {
          // No consent exists, redirect to participation selection
          Navigator.of(context).pushReplacementNamed('/participation_selection');
        }
        return;
      }
      
      debugPrint('[DataSharingPreferences] Consent found - loading data');
      await _loadConsentData();
    } catch (e) {
      debugPrint('[DataSharingPreferences] Error checking consent: $e');
      // If there's an error, still try to load data
      await _loadConsentData();
    }
  }

  Future<void> _loadConsentData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final db = SurveyDatabase();
      final consent = await db.getConsent();
      
      if (consent != null) {
        _participantUuid = consent.participantUuid;
        
        final currentConsent = await db.getLatestDataSharingConsent(_participantUuid!);
        final history = await db.getAllDataSharingConsents(_participantUuid!);
        
        setState(() {
          _currentConsent = currentConsent;
          _consentHistory = history;
        });
      }
    } catch (e) {
      debugPrint('Error loading consent data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateConsent(LocationSharingOption newOption) async {
    if (_participantUuid == null) return;

    try {
      final newConsent = DataSharingConsent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationSharingOption: newOption,
        decisionTimestamp: DateTime.now(),
        participantUuid: _participantUuid!,
      );

      final db = SurveyDatabase();
      await db.insertDataSharingConsent(newConsent);

      await _loadConsentData(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data sharing preference updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Sharing Preferences'),
        backgroundColor: SouthAfricanTheme.primaryBlue,
      ),
      body: _isLoading ? _buildLoadingView() : _buildContentView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(
        color: SouthAfricanTheme.primaryBlue,
      ),
    );
  }

  Widget _buildContentView() {
    if (_participantUuid == null) {
      return _buildNotParticipantView();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPreferenceCard(),
          SizedBox(height: 24),
          _buildUpdatePreferencesCard(),
          SizedBox(height: 24),
          _buildConsentHistoryCard(),
          SizedBox(height: 24),
          _buildPrivacyInfoCard(),
        ],
      ),
    );
  }

  Widget _buildNotParticipantView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Not a Research Participant',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Data sharing preferences are only available for research participants. You can still use the app in private mode.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPreferenceCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Preference',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (_currentConsent != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getOptionColor(_currentConsent!.locationSharingOption),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getOptionIcon(_currentConsent!.locationSharingOption),
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getOptionTitle(_currentConsent!.locationSharingOption),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getOptionDescription(_currentConsent!.locationSharingOption),
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Set on ${_formatDateTime(_currentConsent!.decisionTimestamp)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ] else ...[
              Text(
                'No preference set yet. You will be asked to choose when uploading data.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatePreferencesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'You can change your data sharing preference at any time. The new setting will apply to future uploads.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            
            // Option buttons
            for (final option in LocationSharingOption.values) ...[
              Container(
                margin: EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => _showConfirmationDialog(option),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _getOptionColor(option)),
                    backgroundColor: _currentConsent?.locationSharingOption == option 
                        ? _getOptionColor(option).withValues(alpha: 0.1) 
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          _getOptionIcon(option),
                          color: _getOptionColor(option),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getOptionTitle(option),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getOptionColor(option),
                                ),
                              ),
                              Text(
                                _getOptionDescription(option),
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        if (_currentConsent?.locationSharingOption == option)
                          Icon(Icons.check_circle, color: _getOptionColor(option)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsentHistoryCard() {
    if (_consentHistory.isEmpty) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            for (int i = 0; i < _consentHistory.length && i < 5; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _getOptionIcon(_consentHistory[i].locationSharingOption),
                  color: _getOptionColor(_consentHistory[i].locationSharingOption),
                ),
                title: Text(_getOptionTitle(_consentHistory[i].locationSharingOption)),
                subtitle: Text(_formatDateTime(_consentHistory[i].decisionTimestamp)),
                trailing: i == 0 
                    ? Chip(
                        label: Text('Current', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.green[100],
                      )
                    : null,
              ),
              if (i < _consentHistory.length - 1 && i < 4) Divider(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Privacy Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Your preferences are stored locally on your device\n'
              '• All uploaded data is encrypted before transmission\n'
              '• You can withdraw from the study at any time\n'
              '• No personal identifiers are included in research data\n'
              '• You can request deletion of your data from the study',
              style: TextStyle(color: Colors.blue[800], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(LocationSharingOption newOption) {
    if (_currentConsent?.locationSharingOption == newOption) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This is already your current preference')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Data Sharing Preference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to change your preference to:'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getOptionColor(newOption).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getOptionColor(newOption)),
              ),
              child: Row(
                children: [
                  Icon(_getOptionIcon(newOption), color: _getOptionColor(newOption)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getOptionTitle(newOption),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getOptionDescription(newOption),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This change will apply to future data uploads.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateConsent(newOption);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _getOptionColor(newOption)),
            child: Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(LocationSharingOption option) {
    switch (option) {
      case LocationSharingOption.fullData:
        return Colors.green;
      case LocationSharingOption.partialData:
        return Colors.orange;
      case LocationSharingOption.surveyOnly:
        return Colors.blue;
    }
  }

  IconData _getOptionIcon(LocationSharingOption option) {
    switch (option) {
      case LocationSharingOption.fullData:
        return Icons.share_location;
      case LocationSharingOption.partialData:
        return Icons.share_outlined;
      case LocationSharingOption.surveyOnly:
        return Icons.quiz;
    }
  }

  String _getOptionTitle(LocationSharingOption option) {
    switch (option) {
      case LocationSharingOption.fullData:
        return 'Share Full Location Data';
      case LocationSharingOption.partialData:
        return 'Share Partial Location Data';
      case LocationSharingOption.surveyOnly:
        return 'Survey Responses Only';
    }
  }

  String _getOptionDescription(LocationSharingOption option) {
    switch (option) {
      case LocationSharingOption.fullData:
        return 'Upload complete 2-week location history';
      case LocationSharingOption.partialData:
        return 'Select specific locations to share';
      case LocationSharingOption.surveyOnly:
        return 'No location data, surveys only';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

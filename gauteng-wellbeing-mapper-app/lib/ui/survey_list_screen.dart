import 'package:flutter/material.dart';
import '../db/survey_database.dart';
import '../models/survey_models.dart';
import '../services/survey_navigation_service.dart';
import '../services/encrypted_survey_service.dart';
import '../services/global_notification_service.dart';

class SurveyListScreen extends StatefulWidget {
  @override
  _SurveyListScreenState createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  final SurveyDatabase _db = SurveyDatabase();
  List<RecurringSurveyResponse> _surveys = [];
  bool _hasInitialSurvey = false;
  bool _initialSurveySynced = false;
  bool _consentFormSynced = false;
  bool _hasConsentForm = false;
  bool _isLoading = true;
  bool _isSyncing = false;
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    try {
      final surveys = await _db.getRecurringSurveys();
      final hasInitial = await _db.hasCompletedInitialSurvey();
      
      // Check initial survey sync status
      bool initialSynced = false;
      if (hasInitial) {
        final unsyncedInitial = await _db.getUnsyncedInitialSurveys();
        initialSynced = unsyncedInitial.isEmpty;
      }
      
      // Check consent form status
      final consentForm = await _db.getConsent();
      bool consentSynced = false;
      if (consentForm != null) {
        final unsyncedConsent = await _db.getUnsyncedConsentForms();
        consentSynced = unsyncedConsent.isEmpty;
      }
      
      final unsyncedSurveys = surveys.where((s) => !s.synced).length;
      int totalUnsynced = unsyncedSurveys;
      if (hasInitial && !initialSynced) totalUnsynced++;
      if (consentForm != null && !consentSynced) totalUnsynced++;
      
      setState(() {
        _surveys = surveys;
        _hasInitialSurvey = hasInitial;
        _initialSurveySynced = initialSynced;
        _hasConsentForm = consentForm != null;
        _consentFormSynced = consentSynced;
        _unsyncedCount = totalUnsynced;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load surveys: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Survey History',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.purple,
        actions: [
          if (_unsyncedCount > 0)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unsyncedCount unsynced',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSurveys,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  _buildConsentFormCard(),
                  SizedBox(height: 16),
                  _buildInitialSurveyCard(),
                  SizedBox(height: 16),
                  _buildRecurringSurveysSection(),
                  if (_unsyncedCount > 0) ...[
                    SizedBox(height: 20),
                    _buildSyncSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInitialSurveyCard() {
    return Card(
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasInitialSurvey ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _hasInitialSurvey ? Colors.green : Colors.grey,
            ),
            if (_hasInitialSurvey) ...[
              SizedBox(width: 4),
              Icon(
                _initialSurveySynced ? Icons.cloud_done : Icons.cloud_upload,
                color: _initialSurveySynced ? Colors.green : Colors.orange,
                size: 16,
              ),
            ],
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text('Initial Survey')),
            if (_hasInitialSurvey)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _initialSurveySynced ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _initialSurveySynced ? 'Synced' : 'Pending',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_hasInitialSurvey 
                ? 'Completed' 
                : 'Not completed - tap to complete'),
            // Photo indicators removed - photos no longer supported
          ],
        ),
        trailing: _hasInitialSurvey 
            ? null 
            : Icon(Icons.arrow_forward_ios),
        onTap: _hasInitialSurvey 
            ? null 
            : () => SurveyNavigationService.navigateToInitialSurvey(context),
      ),
    );
  }

  Widget _buildConsentFormCard() {
    return Card(
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasConsentForm ? Icons.verified_user : Icons.gpp_maybe,
              color: _hasConsentForm ? Colors.green : Colors.grey,
            ),
            if (_hasConsentForm) ...[
              SizedBox(width: 4),
              Icon(
                _consentFormSynced ? Icons.cloud_done : Icons.cloud_upload,
                color: _consentFormSynced ? Colors.green : Colors.orange,
                size: 16,
              ),
            ],
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text('Consent Form')),
            if (_hasConsentForm)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _consentFormSynced ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _consentFormSynced ? 'Synced' : 'Pending',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Text(_hasConsentForm 
            ? 'Informed consent provided' 
            : 'No consent record found'),
      ),
    );
  }

  Widget _buildRecurringSurveysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wellbeing Surveys (${_surveys.length})',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        if (_surveys.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No wellbeing surveys completed yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete your first bi-weekly survey to start tracking your wellbeing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_surveys.map((survey) => _buildSurveyCard(survey))),
        
        // New Survey button moved to bottom
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => SurveyNavigationService.navigateToBiweeklySurvey(context),
            icon: Icon(Icons.add),
            label: Text('Complete New Survey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurveyCard(RecurringSurveyResponse survey) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in, color: Colors.green),
            SizedBox(width: 4),
            Icon(
              survey.synced ? Icons.cloud_done : Icons.cloud_upload,
              color: survey.synced ? Colors.green : Colors.orange,
              size: 16,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text('Wellbeing Survey')),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: survey.synced ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                survey.synced ? 'Synced' : 'Pending',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(survey.submittedAt)),
            // Photo indicators removed - photos no longer supported
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSurveyDetail('Activities', survey.activities.join(', ')),
                _buildSurveyDetail('Living Arrangement', survey.livingArrangement ?? 'Not specified'),
                _buildSurveyDetail('Relationship Status', survey.relationshipStatus ?? 'Not specified'),
                SizedBox(height: 8),
                Text('Wellbeing Ratings (0-5):', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildRatingDetail('Good Spirits', survey.cheerfulSpirits),
                _buildRatingDetail('Calm & Relaxed', survey.calmRelaxed),
                _buildRatingDetail('Active & Vigorous', survey.activeVigorous),
                _buildRatingDetail('Woke Up Fresh', survey.wokeUpFresh),
                _buildRatingDetail('Daily Life Interesting', survey.dailyLifeInteresting),
                SizedBox(height: 8),
                if (survey.environmentalChallenges?.isNotEmpty == true) ...[
                  Text('Digital Diary:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildSurveyDetail('Environmental Challenges', survey.environmentalChallenges!),
                  if (survey.challengesStressLevel?.isNotEmpty == true)
                    _buildSurveyDetail('Stress Level', survey.challengesStressLevel!),
                  if (survey.copingHelp?.isNotEmpty == true)
                    _buildSurveyDetail('Coping Help', survey.copingHelp!),
                ],
                // TODO: MULTIMEDIA DISABLED - Uncomment to re-enable multimedia display
                // if (survey.imageUrls?.isNotEmpty == true) ...[
                //   SizedBox(height: 8),
                //   Text('Photos: ${survey.imageUrls!.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                // ],
                // if (survey.voiceNoteUrls?.isNotEmpty == true) ...[
                //   SizedBox(height: 8),
                //   Text('Voice Notes: ${survey.voiceNoteUrls!.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRatingDetail(String label, int? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(fontSize: 12)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getRatingColor(value),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int? value) {
    if (value == null) return Colors.grey;
    if (value <= 1) return Colors.red;
    if (value <= 2) return Colors.orange;
    if (value <= 3) return Colors.yellow[700]!;
    if (value <= 4) return Colors.lightGreen;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSyncSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Data Sync',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '$_unsyncedCount survey${_unsyncedCount == 1 ? '' : 's'} waiting to be uploaded to the research server.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _performManualSync,
                icon: _isSyncing 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.cloud_upload),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performManualSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      print('[SurveyListScreen] Starting manual sync...');
      
      await EncryptedSurveyService.syncPendingSurveys();
      
      print('[SurveyListScreen] Manual sync completed');
      
      // Show success notification
      GlobalNotificationService.showSuccess('✅ Surveys synced successfully!');
      
      // Reload surveys to update sync status
      await _loadSurveys();
      
    } catch (e) {
      print('[SurveyListScreen] Manual sync failed: $e');
      
      // Show error notification  
      GlobalNotificationService.showError('Sync failed: $e');
      
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

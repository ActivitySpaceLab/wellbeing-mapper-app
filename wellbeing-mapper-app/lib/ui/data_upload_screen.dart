import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_upload_service.dart';
import '../db/survey_database.dart';

class DataUploadScreen extends StatefulWidget {
  @override
  _DataUploadScreenState createState() => _DataUploadScreenState();
}

class _DataUploadScreenState extends State<DataUploadScreen> {
  bool _isLoading = false;
  String? _participantUuid;
  String? _researchSite;
  DateTime? _lastUpload;
  bool _canUpload = false;
  String? _lastUploadId;

  @override
  void initState() {
    super.initState();
    _loadParticipantInfo();
  }

  Future<void> _loadParticipantInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final participationJson = prefs.getString('participation_settings');
      
      if (participationJson != null) {
        // Parse participation settings to get research site
        // This is a simplified parsing - in production, use proper JSON parsing
        setState(() {
          _researchSite = 'barcelona'; // Default, should be parsed from JSON
        });
        
        // Get participant UUID from consent
        final db = SurveyDatabase();
        final consent = await db.getConsent();
        if (consent != null) {
          setState(() {
            _participantUuid = consent.participantUuid;
          });
        }
        
        // Check if we can upload
        final canUpload = await DataUploadService.shouldUploadData(_researchSite!);
        setState(() {
          _canUpload = canUpload;
        });
        
        // Get last upload info
        final lastUploadTimestamp = prefs.getInt('last_upload_$_researchSite');
        final lastUploadId = prefs.getString('last_upload_id_$_researchSite');
        
        if (lastUploadTimestamp != null) {
          setState(() {
            _lastUpload = DateTime.fromMillisecondsSinceEpoch(lastUploadTimestamp);
            _lastUploadId = lastUploadId;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Error loading participant info: $e');
    }
  }

  Future<void> _uploadData() async {
    if (_participantUuid == null || _researchSite == null) {
      _showErrorDialog('Missing participant information');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get survey data
      final db = SurveyDatabase();
      final initialSurveys = await db.getInitialSurveys();
      final recurringSurveys = await db.getRecurringSurveys();
      final locationTracks = await DataUploadService.getRecentLocationTracks();

      // Upload data
      final result = await DataUploadService.uploadParticipantData(
        researchSite: _researchSite!,
        initialSurveys: initialSurveys,
        recurringSurveys: recurringSurveys,
        locationTracks: locationTracks,
        participantUuid: _participantUuid!,
      );

      if (result.success) {
        // Mark upload as completed
        await DataUploadService.markUploadCompleted(_researchSite!, result.uploadId!);
        
        _showSuccessDialog(result.uploadId!);
        await _loadParticipantInfo(); // Refresh UI
      } else {
        _showErrorDialog('Upload failed: ${result.error}');
      }
    } catch (e) {
      _showErrorDialog('Upload error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Research Data Upload',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParticipantInfo(),
            SizedBox(height: 24),
            _buildUploadStatus(),
            SizedBox(height: 24),
            _buildDataSummary(),
            SizedBox(height: 32),
            _buildUploadButton(),
            SizedBox(height: 16),
            _buildPrivacyNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participant Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (_researchSite != null) ...[
              Text('Study Site: ${_researchSite == 'barcelona' ? 'Barcelona, Spain' : 'Gauteng, South Africa'}'),
              SizedBox(height: 8),
            ],
            if (_participantUuid != null) ...[
              Text('Participant ID: ${_participantUuid!.substring(0, 8)}...'),
              SizedBox(height: 8),
            ],
            if (_researchSite == null || _participantUuid == null)
              Text(
                'Unable to load participant information. Please ensure you have completed the consent process.',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStatus() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (_lastUpload != null) ...[
              Text('Last Upload: ${_formatDateTime(_lastUpload!)}'),
              SizedBox(height: 8),
              if (_lastUploadId != null) Text('Upload ID: ${_lastUploadId!.substring(0, 8)}...'),
              SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(
                  _canUpload ? Icons.cloud_upload : Icons.schedule,
                  color: _canUpload ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  _canUpload 
                    ? 'Ready to upload data'
                    : _lastUpload == null 
                      ? 'Initial data collection period'
                      : 'Next upload available in ${_getDaysUntilNextUpload()} days',
                  style: TextStyle(
                    color: _canUpload ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data to Upload',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Survey responses from the past 2 weeks'),
            Text('• Location data from the past 2 weeks'),
            Text('• All data is encrypted before transmission'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data is automatically encrypted with the research team\'s public key before upload.',
                      style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_canUpload && !_isLoading && _participantUuid != null) ? _uploadData : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Upload Research Data',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Security',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '• Your data is encrypted with military-grade encryption before upload\n'
            '• Only authorized researchers can decrypt your data\n'
            '• No personal identifying information is transmitted\n'
            '• You can withdraw from the study at any time',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  int _getDaysUntilNextUpload() {
    if (_lastUpload == null) return 0;
    final nextUpload = _lastUpload!.add(Duration(days: 14));
    final now = DateTime.now();
    return nextUpload.difference(now).inDays.clamp(0, 14);
  }

  void _showSuccessDialog(String uploadId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your research data has been successfully uploaded and encrypted.'),
            SizedBox(height: 16),
            Text('Upload ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(uploadId, style: TextStyle(fontFamily: 'monospace')),
            SizedBox(height: 8),
            Text(
              'Your next upload will be available in 2 weeks.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
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

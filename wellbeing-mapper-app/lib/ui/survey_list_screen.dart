import 'package:flutter/material.dart';
import '../db/survey_database.dart';
import '../models/survey_models.dart';

class SurveyListScreen extends StatefulWidget {
  @override
  _SurveyListScreenState createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  final SurveyDatabase _db = SurveyDatabase();
  List<RecurringSurveyResponse> _surveys = [];
  bool _hasInitialSurvey = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    try {
      final surveys = await _db.getRecurringSurveys();
      final hasInitial = await _db.hasCompletedInitialSurvey();
      
      setState(() {
        _surveys = surveys;
        _hasInitialSurvey = hasInitial;
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSurveys,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  _buildInitialSurveyCard(),
                  SizedBox(height: 16),
                  _buildRecurringSurveysSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInitialSurveyCard() {
    return Card(
      child: ListTile(
        leading: Icon(
          _hasInitialSurvey ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _hasInitialSurvey ? Colors.green : Colors.grey,
        ),
        title: Text('Initial Demographics Survey'),
        subtitle: Text(_hasInitialSurvey 
            ? 'Completed' 
            : 'Not completed - tap to complete'),
        trailing: _hasInitialSurvey 
            ? null 
            : Icon(Icons.arrow_forward_ios),
        onTap: _hasInitialSurvey 
            ? null 
            : () => Navigator.of(context).pushNamed('/initial_survey'),
      ),
    );
  }

  Widget _buildRecurringSurveysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wellbeing Surveys (${_surveys.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/recurring_survey'),
              icon: Icon(Icons.add),
              label: Text('New Survey'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
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
      ],
    );
  }

  Widget _buildSurveyCard(RecurringSurveyResponse survey) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: Icon(Icons.assignment_turned_in, color: Colors.green),
        title: Text('Wellbeing Survey'),
        subtitle: Text(_formatDate(survey.submittedAt)),
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
                if (survey.imageUrls?.isNotEmpty == true) ...[
                  SizedBox(height: 8),
                  Text('Photos: ${survey.imageUrls!.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
                if (survey.voiceNoteUrls?.isNotEmpty == true) ...[
                  SizedBox(height: 8),
                  Text('Voice Notes: ${survey.voiceNoteUrls!.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
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

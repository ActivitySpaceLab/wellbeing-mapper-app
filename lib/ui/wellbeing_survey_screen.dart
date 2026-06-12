import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../models/wellbeing_survey_models.dart';
import '../services/app_mode_service.dart';
import '../services/geo_location_service.dart';
import '../services/wellbeing_survey_service.dart';
import '../theme/south_african_theme.dart';

class WellbeingSurveyScreen extends StatefulWidget {
  @override
  _WellbeingSurveyScreenState createState() => _WellbeingSurveyScreenState();
}

class _WellbeingSurveyScreenState extends State<WellbeingSurveyScreen> {
  double? _happinessScore;
  bool _isSubmitting = false;
  bool _isCaptingLocation = false;
  AppLocation? _currentLocation;
  String? _locationError;

  // Shows Italian when the app locale is Italian; English otherwise.
  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';
  String _t(String en, String it) => _isItalian ? it : en;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCaptingLocation = true;
      _locationError = null;
    });

    try {
      if (kIsWeb) {
        setState(() {
          _locationError = 'Location capture not available on web platform';
          _isCaptingLocation = false;
        });
        return;
      }
      
      final location = await GeoLocationService.instance.getCurrentPosition(
        persist: false,
        desiredAccuracy: 40,
        maximumAge: 10000,
        timeout: 30,
        samples: 3,
      );
      
      setState(() {
        _currentLocation = location;
        _isCaptingLocation = false;
        if (location == null) {
          _locationError = 'Unable to determine current location. '
              'The survey can still be submitted without a location.';
        }
      });
      
      if (location != null) {
        debugPrint('[WellbeingSurveyScreen] Location captured: '
            '${location.coords.latitude}, ${location.coords.longitude}');
      }
    } catch (error) {
      setState(() {
        _locationError = error.toString();
        _isCaptingLocation = false;
      });
      debugPrint('[WellbeingSurveyScreen] Location capture error: $error');
    }
  }

  Future<void> _submitSurvey() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = WellbeingSurveyService.createResponse(
        happinessScore: _happinessScore,
        latitude: _currentLocation?.coords.latitude,
        longitude: _currentLocation?.coords.longitude,
        accuracy: _currentLocation?.coords.accuracy,
        locationTimestamp: _currentLocation?.timestamp,
      );

      await WellbeingSurveyService().insertWellbeingSurvey(response);

      // Check if we're in app testing mode
      final currentMode = await AppModeService.getCurrentMode();
      final hasAnswer = _happinessScore != null;
      
      if (currentMode == AppMode.appTesting) {
        // Show beta testing message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('🧪 Beta Testing Mode', '🧪 Modalità beta testing'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  hasAnswer 
                    ? _t('Your happiness rating of ${_happinessScore!.toStringAsFixed(1)} would have been submitted if this was research mode, but no data was transmitted since this is beta testing.',
                        'La tua valutazione di felicità di ${_happinessScore!.toStringAsFixed(1)} sarebbe stata inviata in modalità di ricerca, ma nessun dato è stato trasmesso trattandosi di beta testing.')
                    : _t('Your survey would have been submitted if this was research mode, but no data was transmitted since this is beta testing.',
                        'Il tuo questionario sarebbe stato inviato in modalità di ricerca, ma nessun dato è stato trasmesso trattandosi di beta testing.'),
                ),
                SizedBox(height: 8),
                Text(
                  _t('💙 Thank you for beta testing the Wellbeing Mapper!',
                      '💙 Grazie per aver partecipato al beta testing di Wellbeing Mapper!'),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: SouthAfricanTheme.primaryBlue,
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        // Show regular success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasAnswer 
                ? _t('Wellbeing survey submitted successfully! Happiness rating: ${_happinessScore!.toStringAsFixed(1)}/10',
                    'Questionario sul benessere inviato con successo! Valutazione di felicità: ${_happinessScore!.toStringAsFixed(1)}/10')
                : _t('Wellbeing survey submitted successfully!',
                    'Questionario sul benessere inviato con successo!'),
            ),
            backgroundColor: SouthAfricanTheme.success,
          ),
        );
      }

      // Close the screen
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[WellbeingSurveyScreen] Error submitting survey: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Error submitting survey. Please try again.',
              'Errore durante l\'invio del questionario. Riprova.')),
          backgroundColor: SouthAfricanTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildLocationStatus() {
    if (_isCaptingLocation) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(SouthAfricanTheme.primaryBlue),
            ),
          ),
          SizedBox(width: 8),
          Text(
            _t('Capturing location...', 'Acquisizione della posizione...'),
            style: TextStyle(
              fontSize: 12,
              color: SouthAfricanTheme.primaryBlue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (_currentLocation != null) {
      return Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Colors.green,
          ),
          SizedBox(width: 4),
          Text(
            _t('Location captured (±${_currentLocation!.coords.accuracy.round()}m)',
                'Posizione acquisita (±${_currentLocation!.coords.accuracy.round()} m)'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
            ),
          ),
        ],
      );
    } else if (_locationError != null) {
      return Row(
        children: [
          Icon(
            Icons.location_off,
            size: 16,
            color: Colors.orange,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              _t('Location unavailable - survey will be saved without location',
                  'Posizione non disponibile - il questionario verrà salvato senza posizione'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildHappinessSlider() {
    final question = WellbeingSurveyQuestion.question;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(question.text, 'Quanto sei felice in questo momento?'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            // Slider with improved UX
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _happinessScore == null ? Colors.red[300]! : Colors.grey[300]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t(question.minLabel, 'Per niente felice'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _happinessScore == null
                          ? ''
                          : _happinessScore!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _happinessScore == null ? Colors.red[600] : SouthAfricanTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        _t(question.maxLabel, 'Estremamente felice'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Slider(
                    value: _happinessScore ?? 5.0,
                    min: question.minValue,
                    max: question.maxValue,
                    divisions: 10, // 0, 1, 2, ..., 10
                    label: _happinessScore?.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _happinessScore = value;
                      });
                    },
                    activeColor: _happinessScore == null ? Colors.red[300] : SouthAfricanTheme.primaryBlue,
                    inactiveColor: Colors.grey[300],
                  ),
                  SizedBox(height: 8),
                  if (_happinessScore == null)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _t('Please move the slider to rate your happiness before submitting.',
                            'Sposta il cursore per valutare la tua felicità prima di inviare.'),
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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

  void _handleSubmit() async {
    if (_happinessScore == null) {
      setState(() {}); // Triggers validation message
      return;
    }

    // Proceed with submission
    _submitSurvey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Happiness Survey', 'Questionario sulla felicità')),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: SouthAfricanTheme.softYellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Happiness Survey', 'Questionario sulla felicità'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _t('Rate how happy you are feeling right now using the slider below.',
                      'Valuta quanto ti senti felice in questo momento usando il cursore qui sotto.'),
                  style: TextStyle(
                    fontSize: 14,
                    color: SouthAfricanTheme.darkGrey,
                  ),
                ),
                SizedBox(height: 8),
                _buildLocationStatus(),
              ],
            ),
          ),
          
          // Questions
          Expanded(
            child: SingleChildScrollView(
              child: _buildHappinessSlider(),
            ),
          ),
          
          // Submit button
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(_t('Submitting...', 'Invio in corso...')),
                        ],
                      )
                    : Text(
                        _t('Submit Survey', 'Invia questionario'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

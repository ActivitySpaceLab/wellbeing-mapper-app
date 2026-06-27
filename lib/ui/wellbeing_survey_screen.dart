import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_mode.dart';
import '../models/wellbeing_survey_models.dart';
import '../services/app_mode_service.dart';
import '../services/geo_location_service.dart';
import '../services/wellbeing_survey_service.dart';
import '../theme/south_african_theme.dart';
import '../util/env.dart';

class WellbeingSurveyScreen extends StatefulWidget {
  @override
  _WellbeingSurveyScreenState createState() => _WellbeingSurveyScreenState();
}

class _WellbeingSurveyScreenState extends State<WellbeingSurveyScreen> {
  final Map<WellbeingMetric, int> _answers = {
    for (final question in WellbeingSurveyQuestion.questions)
      question.metric: 3,
  };

  bool _isSubmitting = false;
  bool _isCapturingLocation = false;
  AppLocation? _currentLocation;
  String? _locationError;

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';
  String _t(String en, String it) => _isItalian ? it : en;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
      _locationError = null;
    });

    try {
      if (kIsWeb) {
        setState(() {
          _locationError = _t(
            'Location capture not available on web platform',
            'Acquisizione posizione non disponibile su web',
          );
          _isCapturingLocation = false;
        });
        return;
      }

      await _ensureLocationServiceConfigured();

      final location = await GeoLocationService.instance.getCurrentPosition(
        persist: false,
        desiredAccuracy: 40,
        maximumAge: 300000,
        timeout: 75,
        samples: 3,
      );

      setState(() {
        _currentLocation = location;
        _isCapturingLocation = false;
        if (location == null) {
          _locationError = _t(
            'Unable to determine current location. The survey can still be submitted without a location.',
            'Impossibile determinare la posizione attuale. Il questionario puo comunque essere inviato senza posizione.',
          );
        }
      });
    } catch (error) {
      setState(() {
        _locationError = error.toString();
        _isCapturingLocation = false;
      });
      debugPrint('[WellbeingSurveyScreen] Location capture error: $error');
    }
  }

  Future<void> _ensureLocationServiceConfigured() async {
    if (GeoLocationService.instance.isConfigured) return;

    final prefs = await SharedPreferences.getInstance();
    String? userUUID = prefs.getString('user_uuid');
    String? sampleId = prefs.getString('sample_id');

    if (userUUID == null || userUUID.isEmpty) {
      userUUID = const Uuid().v4();
      await prefs.setString('user_uuid', userUUID);
    }
    if (sampleId == null || sampleId.isEmpty) {
      sampleId = ENV.DEFAULT_SAMPLE_ID;
    }

    if (userUUID.isEmpty || sampleId.isEmpty) {
      return;
    }

    await GeoLocationService.instance.configure(
      userId: userUUID,
      sampleId: sampleId,
    );
  }

  String _questionText(WellbeingMetric metric) {
    switch (metric) {
      case WellbeingMetric.cheerfulSpirits:
        return _t('Have you been in good spirits?', 'Ti sei sentito/a di buon umore?');
      case WellbeingMetric.calmRelaxed:
        return _t('Have you felt calm and relaxed?', 'Ti sei sentito/a calmo/a e rilassato/a?');
      case WellbeingMetric.activeVigorous:
        return _t('Have you felt active and vigorous?', 'Ti sei sentito/a attivo/a e pieno/a di energia?');
      case WellbeingMetric.wokeUpFresh:
        return _t('Did you wake up feeling fresh and rested?', 'Ti sei svegliato/a fresco/a e riposato/a?');
      case WellbeingMetric.dailyLifeInteresting:
        return _t('Has your daily life been filled with things that interest you?', 'La tua vita quotidiana e stata ricca di cose che ti interessano?');
      case WellbeingMetric.composite:
        return _t('Composite wellbeing index', 'Indice composito di benessere');
    }
  }

  String _scaleLabel(int value) {
    switch (value) {
      case 0:
        return _t('At no time', 'Mai');
      case 1:
        return _t('Some of the time', 'Raramente');
      case 2:
        return _t('Less than half the time', 'Meno della meta del tempo');
      case 3:
        return _t('More than half the time', 'Piu della meta del tempo');
      case 4:
        return _t('Most of the time', 'Per la maggior parte del tempo');
      case 5:
        return _t('All the time', 'Sempre');
      default:
        return value.toString();
    }
  }

  Widget _buildLocationStatus() {
    if (_isCapturingLocation) {
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
            style: TextStyle(fontSize: 12, color: SouthAfricanTheme.primaryBlue),
          ),
        ],
      );
    }

    if (_currentLocation != null) {
      return Row(
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.green),
          SizedBox(width: 4),
          Text(
            _t(
              'Location captured (±${_currentLocation!.coords.accuracy.round()}m)',
              'Posizione acquisita (±${_currentLocation!.coords.accuracy.round()} m)',
            ),
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      );
    }

    if (_locationError != null) {
      return Row(
        children: [
          Icon(Icons.location_off, size: 16, color: Colors.orange),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              _t(
                'Location unavailable - survey will be saved without location',
                'Posizione non disponibile - il questionario verra salvato senza posizione',
              ),
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildQuestionCard(WellbeingSurveyQuestion question) {
    final value = _answers[question.metric] ?? 3;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _questionText(question.metric),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t('At no time', 'Mai'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  '$value - ${_scaleLabel(value)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: SouthAfricanTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(_t('All the time', 'Sempre'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: question.minValue.toDouble(),
              max: question.maxValue.toDouble(),
              divisions: question.maxValue - question.minValue,
              label: value.toString(),
              onChanged: (newValue) {
                setState(() {
                  _answers[question.metric] = newValue.round();
                });
              },
              activeColor: SouthAfricanTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSurvey() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = WellbeingSurveyService.createResponse(
        cheerfulSpirits: _answers[WellbeingMetric.cheerfulSpirits]!,
        calmRelaxed: _answers[WellbeingMetric.calmRelaxed]!,
        activeVigorous: _answers[WellbeingMetric.activeVigorous]!,
        wokeUpFresh: _answers[WellbeingMetric.wokeUpFresh]!,
        dailyLifeInteresting: _answers[WellbeingMetric.dailyLifeInteresting]!,
        latitude: _currentLocation?.coords.latitude,
        longitude: _currentLocation?.coords.longitude,
        accuracy: _currentLocation?.coords.accuracy,
        locationTimestamp: _currentLocation?.timestamp,
      );

      await WellbeingSurveyService().insertWellbeingSurvey(response);

      final mode = await AppModeService.getCurrentMode();
      final summary = response.compositeIndex.toStringAsFixed(0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == AppMode.appTesting
                ? _t(
                    'Beta testing: wellbeing saved locally. Composite index: $summary/100.',
                    'Beta testing: benessere salvato localmente. Indice composito: $summary/100.',
                  )
                : _t(
                    'Wellbeing survey submitted. Composite index: $summary/100.',
                    'Questionario inviato. Indice composito: $summary/100.',
                  ),
          ),
          backgroundColor: SouthAfricanTheme.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('[WellbeingSurveyScreen] submit error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Error submitting survey. Please try again.', 'Errore durante l\'invio del questionario. Riprova.')),
          backgroundColor: SouthAfricanTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Wellbeing Survey', 'Questionario sul benessere')),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: SouthAfricanTheme.softYellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('5-question wellbeing check-in', 'Check-in sul benessere a 5 domande'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _t(
                    'Rate each statement based on how you felt over the last two weeks.',
                    'Valuta ogni affermazione in base a come ti sei sentito/a nelle ultime due settimane.',
                  ),
                  style: TextStyle(fontSize: 13, color: SouthAfricanTheme.darkGrey),
                ),
                SizedBox(height: 8),
                _buildLocationStatus(),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: WellbeingSurveyQuestion.questions
                  .map(_buildQuestionCard)
                  .toList(),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SouthAfricanTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(_t('Submitting...', 'Invio in corso...')),
                        ],
                      )
                    : Text(
                        _t('Submit Survey', 'Invia questionario'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

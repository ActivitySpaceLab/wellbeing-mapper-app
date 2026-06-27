import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/wellbeing_survey_models.dart';
import '../services/wellbeing_survey_service.dart';

class WellbeingMapView extends StatefulWidget {
  @override
  _WellbeingMapViewState createState() => _WellbeingMapViewState();
}

class _WellbeingMapViewState extends State<WellbeingMapView> {
  List<WellbeingSurveyResponse> _surveyResponses = [];
  bool _isLoading = true;
  bool _showHeatMap = false;
  WellbeingMetric _selectedMetric = WellbeingMetric.composite;
  late MapController _mapController;

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';
  String _t(String en, String it) => _isItalian ? it : en;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadSurveyData();
  }

  String _metricLabel(WellbeingMetric metric) {
    switch (metric) {
      case WellbeingMetric.composite:
        return _t('Composite index', 'Indice composito');
      case WellbeingMetric.cheerfulSpirits:
        return _t('Good spirits', 'Buon umore');
      case WellbeingMetric.calmRelaxed:
        return _t('Calm and relaxed', 'Calma e rilassamento');
      case WellbeingMetric.activeVigorous:
        return _t('Active and vigorous', 'Attivo/a e pieno/a di energia');
      case WellbeingMetric.wokeUpFresh:
        return _t('Woke up fresh', 'Svegliato/a riposato/a');
      case WellbeingMetric.dailyLifeInteresting:
        return _t('Daily life interesting', 'Vita quotidiana interessante');
    }
  }

  double _metricMax(WellbeingMetric metric) {
    return metric == WellbeingMetric.composite ? 100.0 : 5.0;
  }

  String _metricUnit(WellbeingMetric metric) {
    return metric == WellbeingMetric.composite ? '/100' : '/5';
  }

  List<WellbeingSurveyResponse> get _responsesForSelectedMetric {
    return _surveyResponses
        .where((response) => response.metricValue(_selectedMetric) != null)
        .toList();
  }

  Future<void> _loadSurveyData() async {
    try {
      final responses = await WellbeingSurveyService().getAllWellbeingSurveys();
      final responsesWithLocation = responses
          .where((response) => response.latitude != null && response.longitude != null)
          .toList();

      setState(() {
        _surveyResponses = responsesWithLocation;
        _isLoading = false;
      });

      if (_surveyResponses.isNotEmpty) {
        final first = _surveyResponses.first;
        _mapController.move(LatLng(first.latitude!, first.longitude!), 12.0);
      }
    } catch (error) {
      debugPrint('[WellbeingMapView] load error: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Wellbeing Map', 'Mappa del benessere')),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(_showHeatMap ? Icons.scatter_plot : Icons.blur_on),
            tooltip: _showHeatMap
                ? _t('Show points', 'Mostra punti')
                : _t('Show heat map', 'Mostra mappa di calore'),
            onPressed: () => setState(() => _showHeatMap = !_showHeatMap),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: _t('Refresh data', 'Aggiorna dati'),
            onPressed: _loadSurveyData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _surveyResponses.isEmpty
              ? _buildNoDataView()
            : _responsesForSelectedMetric.isEmpty
              ? _buildNoMetricDataView()
              : Column(
                  children: [
                    _buildMetricSelector(),
                    _buildLegend(),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _surveyResponses.first.latitude!,
                            _surveyResponses.first.longitude!,
                          ),
                          initialZoom: 12.0,
                          minZoom: 2.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.wellbeingmapper.app',
                          ),
                          if (_showHeatMap) _buildHeatMapLayer(),
                          if (!_showHeatMap) _buildPointMarkers(),
                        ],
                      ),
                    ),
                    _buildStatsPanel(),
                  ],
                ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          Text(
            _t('Metric:', 'Metrica:'),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButton<WellbeingMetric>(
              value: _selectedMetric,
              isExpanded: true,
              onChanged: (metric) {
                if (metric == null) return;
                setState(() {
                  _selectedMetric = metric;
                });
              },
              items: WellbeingMetric.values
                  .map(
                    (metric) => DropdownMenuItem<WellbeingMetric>(
                      value: metric,
                      child: Text(_metricLabel(metric)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _t('No wellbeing data with location found', 'Nessun dato di benessere con posizione trovato'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMetricDataView() {
    return Column(
      children: [
        _buildMetricSelector(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  _t('No responses for selected metric', 'Nessuna risposta per la metrica selezionata'),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final maxValue = _metricMax(_selectedMetric);
    final step = _selectedMetric == WellbeingMetric.composite ? 20.0 : 1.0;

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_metricLabel(_selectedMetric)} ${_t('legend', 'legenda')}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (double value = 0; value <= maxValue; value += step)
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: WellbeingSurveyResponse.colorForMetric(_selectedMetric, value),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointMarkers() {
    return MarkerLayer(
      markers: _responsesForSelectedMetric.map((response) {
        final score = response.metricValue(_selectedMetric)!;
        return Marker(
          point: LatLng(response.latitude!, response.longitude!),
          child: GestureDetector(
            onTap: () => _showSurveyDetails(response),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: WellbeingSurveyResponse.colorForMetric(_selectedMetric, score),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeatMapLayer() {
    final max = _metricMax(_selectedMetric);

    return CircleLayer(
      circles: _responsesForSelectedMetric.map((response) {
        final score = response.metricValue(_selectedMetric)!;
        final normalized = (score / max).clamp(0.0, 1.0);
        return CircleMarker(
          point: LatLng(response.latitude!, response.longitude!),
          radius: 26 + (normalized * 26),
          color: WellbeingSurveyResponse.colorForMetric(_selectedMetric, score)
              .withValues(alpha: 0.28),
          borderColor: WellbeingSurveyResponse.colorForMetric(_selectedMetric, score),
          borderStrokeWidth: 2,
        );
      }).toList(),
    );
  }

  Widget _buildStatsPanel() {
    final values = _responsesForSelectedMetric
        .map((r) => r.metricValue(_selectedMetric)!)
        .toList();
    final total = values.length;
    final avg = values.reduce((a, b) => a + b) / total;
    final max = values.reduce((a, b) => a > b ? a : b);
    final noResponseCount = _surveyResponses.length - total;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(_t('Responses', 'Risposte'), total.toString()),
          _buildStatItem(_t('No response', 'Nessuna risposta'), noResponseCount.toString()),
          _buildStatItem(_t('Average', 'Media'), '${avg.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}'),
          _buildStatItem(_t('Best', 'Migliore'), '${max.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showSurveyDetails(WellbeingSurveyResponse response) {
    final value = response.metricValue(_selectedMetric);
    final valueText = value == null
        ? _t('Not selected', 'Non selezionato')
        : '${value.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Survey details', 'Dettagli questionario')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_t('Date', 'Data')}: ${response.timestamp.toString().split('.')[0]}'),
            SizedBox(height: 8),
            Text('${_metricLabel(_selectedMetric)}: $valueText'),
            Text('${_t('Category', 'Categoria')}: ${response.metricCategory(_selectedMetric)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t('Close', 'Chiudi')),
          ),
        ],
      ),
    );
  }
}

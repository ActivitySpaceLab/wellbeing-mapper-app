import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/wellbeing_survey_models.dart';
import '../services/wellbeing_survey_service.dart';

class WellbeingTimelineView extends StatefulWidget {
  @override
  _WellbeingTimelineViewState createState() => _WellbeingTimelineViewState();
}

class _WellbeingTimelineViewState extends State<WellbeingTimelineView> {
  List<WellbeingSurveyResponse> _surveyResponses = [];
  bool _isLoading = true;
  String _selectedPeriod = '14';
  WellbeingMetric _selectedMetric = WellbeingMetric.composite;

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';
  String _t(String en, String it) => _isItalian ? it : en;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadSurveyData() async {
    try {
      final responses = await WellbeingSurveyService().getAllWellbeingSurveys();
      setState(() {
        _surveyResponses = responses;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('[WellbeingTimelineView] Error loading survey data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<WellbeingSurveyResponse> get _filteredResponses {
    if (_surveyResponses.isEmpty) return [];

    if (_selectedPeriod == 'all') {
      final all = [..._surveyResponses];
      all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return all;
    }

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: int.parse(_selectedPeriod)));

    return _surveyResponses
        .where((response) => response.timestamp.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Wellbeing Timeline', 'Cronologia del benessere')),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.date_range),
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: '14', child: Text(_t('Last 2 weeks', 'Ultime 2 settimane'))),
              PopupMenuItem(value: '30', child: Text(_t('Last 30 days', 'Ultimi 30 giorni'))),
              PopupMenuItem(value: '90', child: Text(_t('Last 3 months', 'Ultimi 3 mesi'))),
              PopupMenuItem(value: '365', child: Text(_t('Last year', 'Ultimo anno'))),
              PopupMenuItem(value: 'all', child: Text(_t('All time', 'Tutto il periodo'))),
            ],
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadSurveyData),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredResponses.isEmpty
              ? _buildNoDataView()
              : Column(
                  children: [
                    _buildMetricSelector(),
                    _buildStatsCard(),
                    SizedBox(height: 12),
                    Expanded(child: _buildChart()),
                    _buildLegend(),
                  ],
                ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                setState(() => _selectedMetric = metric);
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
          Icon(Icons.timeline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _t('No wellbeing data found', 'Nessun dato di benessere trovato'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final values = _filteredResponses.map((r) => r.metricValue(_selectedMetric)).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final latestValue = values.last;

    final trend = _computeTrend(values);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_metricLabel(_selectedMetric)} (${_getPeriodText()})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(_t('Latest', 'Ultimo'), '${latestValue.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}'),
              _buildStatItem(_t('Average', 'Media'), '${avg.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}'),
              _buildStatItem(_t('Best', 'Migliore'), '${maxValue.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}'),
              _buildStatItem(_t('Lowest', 'Minimo'), '${minValue.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}'),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_t('Trend', 'Tendenza')}: $trend', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('${_filteredResponses.length} ${_t('surveys', 'questionari')}', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  String _computeTrend(List<double> values) {
    if (values.length < 4) return _t('Stable', 'Stabile');

    final midpoint = values.length ~/ 2;
    final firstAvg = values.take(midpoint).reduce((a, b) => a + b) / midpoint;
    final second = values.skip(midpoint).toList();
    final secondAvg = second.reduce((a, b) => a + b) / second.length;

    final threshold = _selectedMetric == WellbeingMetric.composite ? 4.0 : 0.25;
    if (secondAvg > firstAvg + threshold) return _t('Improving', 'In miglioramento');
    if (secondAvg < firstAvg - threshold) return _t('Declining', 'In peggioramento');
    return _t('Stable', 'Stabile');
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildChart() {
    final spots = <FlSpot>[];
    final dateFormatter = DateFormat('MM/dd');

    for (int i = 0; i < _filteredResponses.length; i++) {
      final response = _filteredResponses[i];
      spots.add(FlSpot(i.toDouble(), response.metricValue(_selectedMetric)));
    }

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getXAxisInterval(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _filteredResponses.length) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        dateFormatter.format(_filteredResponses[index].timestamp),
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _selectedMetric == WellbeingMetric.composite ? 20 : 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          minX: 0,
          maxX: (_filteredResponses.length - 1).toDouble(),
          minY: 0,
          maxY: _metricMax(_selectedMetric),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(colors: [Colors.teal, Colors.teal.shade300]),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: WellbeingSurveyResponse.colorForMetric(_selectedMetric, spot.y),
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final response = _filteredResponses[index];
                  final dateStr = DateFormat('MMM dd, yyyy').format(response.timestamp);
                  final value = response.metricValue(_selectedMetric);
                  return LineTooltipItem(
                    '$dateStr\n${_metricLabel(_selectedMetric)}: ${value.toStringAsFixed(1)}${_metricUnit(_selectedMetric)}',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${_metricLabel(_selectedMetric)} ${_t('shown on timeline', 'mostrata sulla cronologia')}',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  double _getXAxisInterval() {
    final count = _filteredResponses.length;
    if (count <= 6) return 1;
    if (count <= 15) return 2;
    if (count <= 30) return 5;
    return (count / 6).floorToDouble();
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case '14':
        return _t('Last 2 weeks', 'Ultime 2 settimane');
      case '30':
        return _t('Last 30 days', 'Ultimi 30 giorni');
      case '90':
        return _t('Last 3 months', 'Ultimi 3 mesi');
      case '365':
        return _t('Last year', 'Ultimo anno');
      case 'all':
        return _t('All time', 'Tutto il periodo');
      default:
        return _t('Last 2 weeks', 'Ultime 2 settimane');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/wellbeing_survey_models.dart';
import '../services/wellbeing_survey_service.dart';
import 'package:intl/intl.dart';

class WellbeingTimelineView extends StatefulWidget {
  @override
  _WellbeingTimelineViewState createState() => _WellbeingTimelineViewState();
}

class _WellbeingTimelineViewState extends State<WellbeingTimelineView> {
  List<WellbeingSurveyResponse> _surveyResponses = [];
  bool _isLoading = true;
  String _selectedPeriod = '14'; // days - default to 2 weeks to match biweekly survey
  
  @override
  void initState() {
    super.initState();
    _loadSurveyData();
  }

  Future<void> _loadSurveyData() async {
    try {
      final responses = await WellbeingSurveyService().getAllWellbeingSurveys();
      setState(() {
        _surveyResponses = responses;
        _isLoading = false;
      });
    } catch (error) {
      print('[WellbeingTimelineView] Error loading survey data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<WellbeingSurveyResponse> get _filteredResponses {
    if (_surveyResponses.isEmpty) return [];
    
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
        title: Text('Wellbeing Timeline'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: '14', child: Text('Last 2 weeks')),
              PopupMenuItem(value: '30', child: Text('Last 30 days')),
              PopupMenuItem(value: '90', child: Text('Last 3 months')),
              PopupMenuItem(value: '365', child: Text('Last year')),
              PopupMenuItem(value: 'all', child: Text('All time')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSurveyData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredResponses.isEmpty
              ? _buildNoDataView()
              : Column(
                  children: [
                    _buildStatsCard(),
                    SizedBox(height: 16),
                    Expanded(child: _buildChart()),
                    _buildLegend(),
                  ],
                ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No survey data found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Take some wellbeing surveys to see your timeline!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_filteredResponses.isEmpty) return SizedBox.shrink();

    final scores = _filteredResponses.map((r) => r.wellbeingScore).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final latestScore = _filteredResponses.last.wellbeingScore;

    // Calculate trend (comparing first half to second half of period)
    String trend = 'Stable';
    if (_filteredResponses.length >= 4) {
      final midpoint = _filteredResponses.length ~/ 2;
      final firstHalf = _filteredResponses.take(midpoint).map((r) => r.wellbeingScore);
      final secondHalf = _filteredResponses.skip(midpoint).map((r) => r.wellbeingScore);
      
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      
      if (secondAvg > firstAvg + 0.3) {
        trend = 'Improving';
      } else if (secondAvg < firstAvg - 0.3) {
        trend = 'Declining';
      }
    }

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
            'Wellbeing Summary (${_getPeriodText()})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Latest', latestScore.toStringAsFixed(1), 
                  WellbeingSurveyResponse.getWellbeingColor(latestScore)),
              _buildStatItem('Average', avgScore.toStringAsFixed(1), Colors.blue),
              _buildStatItem('Best', maxScore.toStringAsFixed(1), Colors.green),
              _buildStatItem('Lowest', minScore.toStringAsFixed(1), Colors.orange),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trend: $trend', 
                   style: TextStyle(fontWeight: FontWeight.w500)),
              Text('${_filteredResponses.length} surveys',
                   style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_filteredResponses.isEmpty) return SizedBox.shrink();

    final spots = <FlSpot>[];
    final dateFormatter = DateFormat('MM/dd');
    
    for (int i = 0; i < _filteredResponses.length; i++) {
      final response = _filteredResponses[i];
      spots.add(FlSpot(i.toDouble(), response.wellbeingScore.toDouble()));
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
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
                interval: 2,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 12),
                  );
                },
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
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade300],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final score = spot.y;
                  return FlDotCirclePainter(
                    radius: 6,
                    color: WellbeingSurveyResponse.getWellbeingColor(score),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withValues(alpha: 0.2),
                    Colors.teal.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index >= 0 && index < _filteredResponses.length) {
                    final response = _filteredResponses[index];
                    final dateStr = DateFormat('MMM dd, yyyy').format(response.timestamp);
                    final timeStr = DateFormat('HH:mm').format(response.timestamp);
                    return LineTooltipItem(
                      '$dateStr\n$timeStr\nHappiness: ${response.wellbeingScore.toStringAsFixed(1)}/10\n${response.wellbeingCategory}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
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
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Happiness Scale',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int score = 0; score <= 10; score += 2)
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: WellbeingSurveyResponse.getWellbeingColor(score.toDouble()),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      score.toString(),
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

  double _getXAxisInterval() {
    final count = _filteredResponses.length;
    if (count <= 5) return 1.0;
    if (count <= 15) return 2.0;
    if (count <= 30) return 5.0;
    return (count / 6).floorToDouble();
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case '14': return 'Last 2 weeks';
      case '30': return 'Last 30 days';
      case '90': return 'Last 3 months';
      case '365': return 'Last year';
      case 'all': return 'All time';
      default: return 'Last 2 weeks';
    }
  }
}

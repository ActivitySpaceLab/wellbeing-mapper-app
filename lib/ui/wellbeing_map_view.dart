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
  bool _showHeatMap = false; // Toggle between points and heat map
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadSurveyData();
  }

  Future<void> _loadSurveyData() async {
    try {
      final responses = await WellbeingSurveyService().getAllWellbeingSurveys();
      // Filter only responses with location data
      final responsesWithLocation = responses.where((response) => 
        response.latitude != null && response.longitude != null).toList();
      
      setState(() {
        _surveyResponses = responsesWithLocation;
        _isLoading = false;
      });

      // Center map on first survey location if available
      if (_surveyResponses.isNotEmpty) {
        final firstResponse = _surveyResponses.first;
        _mapController.move(
          LatLng(firstResponse.latitude!, firstResponse.longitude!), 
          12.0
        );
      }
    } catch (error) {
      print('[WellbeingMapView] Error loading survey data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellbeing Map'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(_showHeatMap ? Icons.scatter_plot : Icons.blur_on),
            tooltip: _showHeatMap ? 'Show Points' : 'Show Heat Map',
            onPressed: () {
              setState(() {
                _showHeatMap = !_showHeatMap;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadSurveyData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _surveyResponses.isEmpty
              ? _buildNoDataView()
              : Column(
                  children: [
                    _buildLegend(),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _surveyResponses.isNotEmpty
                              ? LatLng(_surveyResponses.first.latitude!, _surveyResponses.first.longitude!)
                              : LatLng(51.5, -0.09), // Default to London
                          initialZoom: 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.wellbeingmapper.app',
                          ),
                          if (!_showHeatMap) _buildPointMarkers(),
                          if (_showHeatMap) _buildHeatMapLayer(),
                        ],
                      ),
                    ),
                    _buildStatsPanel(),
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
            Icons.location_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No survey data with location found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Take some wellbeing surveys to see your data on the map!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.all(8),
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
            'Happiness Score Legend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int score = 0; score <= 10; score += 2)
                _buildLegendItem(score.toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(double score) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: WellbeingSurveyResponse.getWellbeingColor(score),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        SizedBox(height: 4),
        Text(
          score.toInt().toString(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPointMarkers() {
    return MarkerLayer(
      markers: _surveyResponses.map((response) {
        return Marker(
          point: LatLng(response.latitude!, response.longitude!),
          child: GestureDetector(
            onTap: () => _showSurveyDetails(response),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: WellbeingSurveyResponse.getWellbeingColor(response.wellbeingScore),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  response.wellbeingScore.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeatMapLayer() {
    // For now, create larger, semi-transparent circles for heat map effect
    // In future, could implement proper heat map rendering
    return CircleLayer(
      circles: _surveyResponses.map((response) {
        return CircleMarker(
          point: LatLng(response.latitude!, response.longitude!),
          radius: 30 + (response.wellbeingScore * 5), // Adjusted for 0-10 scale
          color: WellbeingSurveyResponse.getWellbeingColor(response.wellbeingScore)
              .withValues(alpha: 0.3),
          borderColor: WellbeingSurveyResponse.getWellbeingColor(response.wellbeingScore),
          borderStrokeWidth: 2,
        );
      }).toList(),
    );
  }

  Widget _buildStatsPanel() {
    if (_surveyResponses.isEmpty) return SizedBox.shrink();

    final totalResponses = _surveyResponses.length;
    final avgScore = _surveyResponses
        .map((r) => r.wellbeingScore)
        .reduce((a, b) => a + b) / totalResponses;
    
    final scoreDistribution = <int, int>{};
    for (int i = 0; i <= 10; i++) {
      scoreDistribution[i] = _surveyResponses.where((r) => r.wellbeingScore.round() == i).length;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Happiness Statistics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Surveys', totalResponses.toString()),
              _buildStatItem('Average Score', avgScore.toStringAsFixed(1)),
              _buildStatItem('Highest Score', 
                _surveyResponses.map((r) => r.wellbeingScore).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showSurveyDetails(WellbeingSurveyResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Survey Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${response.timestamp.toString().split('.')[0]}'),
            SizedBox(height: 8),
            Text('Happiness Score: ${response.wellbeingScore.toStringAsFixed(1)}/10'),
            Text('Category: ${response.wellbeingCategory}'),
            if (response.accuracy != null) ...[
              SizedBox(height: 8),
              Text('Location accuracy: ${response.accuracy!.toStringAsFixed(1)}m'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

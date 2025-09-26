import 'package:flutter/material.dart';

class WellbeingSurveyResponse {
  final String id;
  final DateTime timestamp;
  final double? happinessScore; // 0.0 to 10.0 from slider, null means not answered
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationTimestamp;
  final bool isSynced; // For research users - tracks if synced to server

  WellbeingSurveyResponse({
    required this.id,
    required this.timestamp,
    this.happinessScore, // Now optional - null means not answered
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationTimestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'happiness_score': happinessScore,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'location_timestamp': locationTimestamp,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory WellbeingSurveyResponse.fromJson(Map<String, dynamic> json) {
    return WellbeingSurveyResponse(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      happinessScore: json['happiness_score']?.toDouble(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      locationTimestamp: json['location_timestamp'],
      isSynced: (json['is_synced'] ?? 0) == 1,
    );
  }

  /// Get wellbeing score (0-10) based on happiness slider
  double get wellbeingScore {
    return happinessScore ?? 0.0;
  }

  /// Get number of questions answered (1 if happiness score provided, 0 if not)
  int get answeredQuestionCount {
    return happinessScore != null ? 1 : 0;
  }

  /// Get total number of questions (always 1 now)
  int get totalQuestionCount => 1;

  /// Check if the question was answered
  bool get isComplete => happinessScore != null;

  /// Get wellbeing score as a normalized value (0.0 - 1.0) for color mapping
  double get normalizedWellbeingScore {
    if (happinessScore == null) return 0.0;
    return happinessScore! / 10.0; // Convert 0-10 scale to 0-1
  }

  /// Get wellbeing category based on happiness score (0-10)
  String get wellbeingCategory {
    if (happinessScore == null) return 'Not Answered';
    final score = happinessScore!;
    if (score >= 9.0) return 'Extremely Happy';
    if (score >= 8.0) return 'Very Happy';
    if (score >= 7.0) return 'Happy';
    if (score >= 6.0) return 'Somewhat Happy';
    if (score >= 5.0) return 'Neutral';
    if (score >= 4.0) return 'Somewhat Unhappy';
    if (score >= 3.0) return 'Unhappy';
    if (score >= 2.0) return 'Very Unhappy';
    if (score >= 1.0) return 'Extremely Unhappy';
    return 'Not Happy at All';
  }

  /// Get color for wellbeing score (for map visualization)
  /// Red (low) to Green (high) gradient based on 0-10 happiness scale
  static Color getWellbeingColor(double score) {
    if (score >= 9.0) return const Color(0xFF1B5E20); // Dark Green
    if (score >= 8.0) return const Color(0xFF2E7D32); // Green
    if (score >= 7.0) return const Color(0xFF388E3C); // Medium Green
    if (score >= 6.0) return const Color(0xFF4CAF50); // Light Green
    if (score >= 5.0) return const Color(0xFF8BC34A); // Yellow-Green
    if (score >= 4.0) return const Color(0xFFFFC107); // Amber
    if (score >= 3.0) return const Color(0xFFFF9800); // Orange
    if (score >= 2.0) return const Color(0xFFFF5722); // Red-Orange
    if (score >= 1.0) return const Color(0xFFD32F2F); // Dark Red
    return const Color(0xFF9E9E9E); // Grey for 0 or no response
  }

  /// Creates a copy with updated sync status
  WellbeingSurveyResponse copyWithSyncStatus(bool synced) {
    return WellbeingSurveyResponse(
      id: id,
      timestamp: timestamp,
      happinessScore: happinessScore,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      locationTimestamp: locationTimestamp,
      isSynced: synced,
    );
  }

  /// For research data export - includes participant metadata
  Map<String, dynamic> toResearchJson(String participantCode) {
    return {
      'participant_code': participantCode,
      'survey_id': id,
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        'happiness_score': happinessScore,
      },
      'location': latitude != null && longitude != null ? {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': locationTimestamp,
      } : null,
      'survey_type': 'wellbeing_action_button',
    };
  }
}

class WellbeingSurveyQuestion {
  final String id;
  final String text;
  final double minValue;
  final double maxValue;
  final String minLabel;
  final String maxLabel;

  const WellbeingSurveyQuestion({
    required this.id,
    required this.text,
    required this.minValue,
    required this.maxValue,
    required this.minLabel,
    required this.maxLabel,
  });

  static const WellbeingSurveyQuestion question = WellbeingSurveyQuestion(
    id: 'happiness_score',
    text: 'How happy are you right now?',
    minValue: 0.0,
    maxValue: 10.0,
    minLabel: 'Not happy at all',
    maxLabel: 'Extremely happy',
  );
}

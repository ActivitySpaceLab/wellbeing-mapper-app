import 'package:flutter/material.dart';

enum WellbeingMetric {
  composite,
  cheerfulSpirits,
  calmRelaxed,
  activeVigorous,
  wokeUpFresh,
  dailyLifeInteresting,
}

class WellbeingSurveyResponse {
  final String id;
  final DateTime timestamp;
  final int cheerfulSpirits; // 0..5
  final int calmRelaxed; // 0..5
  final int activeVigorous; // 0..5
  final int wokeUpFresh; // 0..5
  final int dailyLifeInteresting; // 0..5
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationTimestamp;
  final bool isSynced;

  WellbeingSurveyResponse({
    required this.id,
    required this.timestamp,
    required this.cheerfulSpirits,
    required this.calmRelaxed,
    required this.activeVigorous,
    required this.wokeUpFresh,
    required this.dailyLifeInteresting,
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
      'cheerful_spirits': cheerfulSpirits,
      'calm_relaxed': calmRelaxed,
      'active_vigorous': activeVigorous,
      'woke_up_fresh': wokeUpFresh,
      'daily_life_interesting': dailyLifeInteresting,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'location_timestamp': locationTimestamp,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory WellbeingSurveyResponse.fromJson(Map<String, dynamic> json) {
    return WellbeingSurveyResponse(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      cheerfulSpirits: (json['cheerful_spirits'] as num).toInt(),
      calmRelaxed: (json['calm_relaxed'] as num).toInt(),
      activeVigorous: (json['active_vigorous'] as num).toInt(),
      wokeUpFresh: (json['woke_up_fresh'] as num).toInt(),
      dailyLifeInteresting: (json['daily_life_interesting'] as num).toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      locationTimestamp: json['location_timestamp'] as String?,
      isSynced: (json['is_synced'] ?? 0) == 1,
    );
  }

  double get averageScore0to5 {
    return (cheerfulSpirits +
            calmRelaxed +
            activeVigorous +
            wokeUpFresh +
            dailyLifeInteresting) /
        5.0;
  }

  /// WHO-5 style index mapped to 0..100.
  double get compositeIndex {
    return averageScore0to5 * 20.0;
  }

  double metricValue(WellbeingMetric metric) {
    switch (metric) {
      case WellbeingMetric.composite:
        return compositeIndex;
      case WellbeingMetric.cheerfulSpirits:
        return cheerfulSpirits.toDouble();
      case WellbeingMetric.calmRelaxed:
        return calmRelaxed.toDouble();
      case WellbeingMetric.activeVigorous:
        return activeVigorous.toDouble();
      case WellbeingMetric.wokeUpFresh:
        return wokeUpFresh.toDouble();
      case WellbeingMetric.dailyLifeInteresting:
        return dailyLifeInteresting.toDouble();
    }
  }

  String metricCategory(WellbeingMetric metric) {
    final value = metricValue(metric);
    if (metric == WellbeingMetric.composite) {
      if (value >= 80) return 'Very High';
      if (value >= 60) return 'High';
      if (value >= 40) return 'Moderate';
      if (value >= 20) return 'Low';
      return 'Very Low';
    }

    if (value >= 5) return 'All the time';
    if (value >= 4) return 'Most of the time';
    if (value >= 3) return 'More than half the time';
    if (value >= 2) return 'Less than half the time';
    if (value >= 1) return 'Some of the time';
    return 'At no time';
  }

  static Color colorForMetric(WellbeingMetric metric, double value) {
    final normalized = metric == WellbeingMetric.composite
        ? (value / 100.0).clamp(0.0, 1.0)
        : (value / 5.0).clamp(0.0, 1.0);

    if (normalized >= 0.9) return const Color(0xFF1B5E20);
    if (normalized >= 0.8) return const Color(0xFF2E7D32);
    if (normalized >= 0.7) return const Color(0xFF388E3C);
    if (normalized >= 0.6) return const Color(0xFF4CAF50);
    if (normalized >= 0.5) return const Color(0xFF8BC34A);
    if (normalized >= 0.4) return const Color(0xFFFFC107);
    if (normalized >= 0.3) return const Color(0xFFFF9800);
    if (normalized >= 0.2) return const Color(0xFFFF5722);
    if (normalized >= 0.1) return const Color(0xFFD32F2F);
    return const Color(0xFF9E9E9E);
  }

  WellbeingSurveyResponse copyWithSyncStatus(bool synced) {
    return WellbeingSurveyResponse(
      id: id,
      timestamp: timestamp,
      cheerfulSpirits: cheerfulSpirits,
      calmRelaxed: calmRelaxed,
      activeVigorous: activeVigorous,
      wokeUpFresh: wokeUpFresh,
      dailyLifeInteresting: dailyLifeInteresting,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      locationTimestamp: locationTimestamp,
      isSynced: synced,
    );
  }

  Map<String, dynamic> toResearchJson(String participantCode) {
    return {
      'participant_code': participantCode,
      'survey_id': id,
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        'cheerful_spirits': cheerfulSpirits,
        'calm_relaxed': calmRelaxed,
        'active_vigorous': activeVigorous,
        'woke_up_fresh': wokeUpFresh,
        'daily_life_interesting': dailyLifeInteresting,
        'composite_index': compositeIndex,
      },
      'location': latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': accuracy,
              'timestamp': locationTimestamp,
            }
          : null,
      'survey_type': 'wellbeing_action_button',
    };
  }
}

class WellbeingSurveyQuestion {
  final WellbeingMetric metric;
  final String text;
  final int minValue;
  final int maxValue;
  final String minLabel;
  final String maxLabel;

  const WellbeingSurveyQuestion({
    required this.metric,
    required this.text,
    required this.minValue,
    required this.maxValue,
    required this.minLabel,
    required this.maxLabel,
  });

  static const List<WellbeingSurveyQuestion> questions = [
    WellbeingSurveyQuestion(
      metric: WellbeingMetric.cheerfulSpirits,
      text: 'Have you been in good spirits?',
      minValue: 0,
      maxValue: 5,
      minLabel: 'At no time',
      maxLabel: 'All the time',
    ),
    WellbeingSurveyQuestion(
      metric: WellbeingMetric.calmRelaxed,
      text: 'Have you felt calm and relaxed?',
      minValue: 0,
      maxValue: 5,
      minLabel: 'At no time',
      maxLabel: 'All the time',
    ),
    WellbeingSurveyQuestion(
      metric: WellbeingMetric.activeVigorous,
      text: 'Have you felt active and vigorous?',
      minValue: 0,
      maxValue: 5,
      minLabel: 'At no time',
      maxLabel: 'All the time',
    ),
    WellbeingSurveyQuestion(
      metric: WellbeingMetric.wokeUpFresh,
      text: 'Did you wake up feeling fresh and rested?',
      minValue: 0,
      maxValue: 5,
      minLabel: 'At no time',
      maxLabel: 'All the time',
    ),
    WellbeingSurveyQuestion(
      metric: WellbeingMetric.dailyLifeInteresting,
      text: 'Has your daily life been filled with things that interest you?',
      minValue: 0,
      maxValue: 5,
      minLabel: 'At no time',
      maxLabel: 'All the time',
    ),
  ];
}

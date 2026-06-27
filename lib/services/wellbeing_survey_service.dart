import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/wellbeing_survey_models.dart';
import '../models/survey_models.dart';
import '../db/survey_database.dart';

class WellbeingSurveyService {
  static final WellbeingSurveyService _instance = WellbeingSurveyService._internal();
  factory WellbeingSurveyService() => _instance;
  WellbeingSurveyService._internal();

  /// Insert a new wellbeing survey response
  Future<int> insertWellbeingSurvey(WellbeingSurveyResponse survey) async {
    final db = await SurveyDatabase().database;
    
    final map = survey.toJson();
    // Convert DateTime to string for SQLite
    map['timestamp'] = survey.timestamp.toIso8601String();
    
    final id = await db.insert('wellbeing_survey_responses', map);
    debugPrint('[WellbeingSurveyService] Inserted wellbeing survey with id: $id');
    return id;
  }

  /// Get all wellbeing survey responses ordered by timestamp descending
  Future<List<WellbeingSurveyResponse>> getAllWellbeingSurveys() async {
    final db = await SurveyDatabase().database;
    final maps = await db.query(
      'wellbeing_survey_responses', 
      orderBy: 'timestamp DESC',
    );
    final responses = List.generate(maps.length, (i) {
      return WellbeingSurveyResponse.fromJson(maps[i]);
    });

    return _attachNearbyLocationsIfMissing(responses);
  }

  Future<List<WellbeingSurveyResponse>> _attachNearbyLocationsIfMissing(
    List<WellbeingSurveyResponse> responses,
  ) async {
    final needsLocation = responses.any(
      (response) => response.latitude == null || response.longitude == null,
    );
    if (!needsLocation) return responses;

    final tracks = await SurveyDatabase().getAllLocationTracks();
    if (tracks.isEmpty) return responses;

    const maxOffsetSeconds = 15 * 60;
    return responses.map((response) {
      if (response.latitude != null && response.longitude != null) {
        return response;
      }

      LocationTrack? closestTrack;
      int? smallestOffset;

      for (final track in tracks) {
        final offset =
            (track.timestamp.difference(response.timestamp)).inSeconds.abs();
        if (offset > maxOffsetSeconds) continue;
        if (smallestOffset == null || offset < smallestOffset) {
          smallestOffset = offset;
          closestTrack = track;
        }
      }

      if (closestTrack == null) return response;

      return WellbeingSurveyResponse(
        id: response.id,
        timestamp: response.timestamp,
        cheerfulSpirits: response.cheerfulSpirits,
        calmRelaxed: response.calmRelaxed,
        activeVigorous: response.activeVigorous,
        wokeUpFresh: response.wokeUpFresh,
        dailyLifeInteresting: response.dailyLifeInteresting,
        latitude: closestTrack.latitude,
        longitude: closestTrack.longitude,
        accuracy: closestTrack.accuracy,
        locationTimestamp: closestTrack.timestamp.toIso8601String(),
        isSynced: response.isSynced,
      );
    }).toList();
  }

  /// Get unsynced wellbeing survey responses for research users
  Future<List<WellbeingSurveyResponse>> getUnsyncedWellbeingSurveys() async {
    final db = await SurveyDatabase().database;
    final maps = await db.query(
      'wellbeing_survey_responses',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    
    return List.generate(maps.length, (i) {
      return WellbeingSurveyResponse.fromJson(maps[i]);
    });
  }

  /// Mark a wellbeing survey as synced
  Future<void> markAsSynced(String surveyId) async {
    final db = await SurveyDatabase().database;
    await db.update(
      'wellbeing_survey_responses',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [surveyId],
    );
    debugPrint('[WellbeingSurveyService] Marked survey $surveyId as synced');
  }

  /// Get wellbeing surveys for export (both synced and unsynced)
  Future<List<WellbeingSurveyResponse>> getWellbeingSurveysForExport() async {
    final db = await SurveyDatabase().database;
    final maps = await db.query(
      'wellbeing_survey_responses',
      orderBy: 'timestamp ASC',
    );
    
    return List.generate(maps.length, (i) {
      return WellbeingSurveyResponse.fromJson(maps[i]);
    });
  }

  /// Delete all wellbeing survey responses (for testing/reset purposes)
  Future<void> deleteAllWellbeingSurveys() async {
    final db = await SurveyDatabase().database;
    await db.delete('wellbeing_survey_responses');
    debugPrint('[WellbeingSurveyService] Deleted all wellbeing surveys');
  }

  /// Get count of wellbeing surveys
  Future<int> getWellbeingSurveyCount() async {
    final db = await SurveyDatabase().database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM wellbeing_survey_responses');
    return result.first['count'] as int;
  }

  /// Create a new wellbeing survey response with current timestamp and optional location.
  static WellbeingSurveyResponse createResponse({
    int? cheerfulSpirits,
    int? calmRelaxed,
    int? activeVigorous,
    int? wokeUpFresh,
    int? dailyLifeInteresting,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationTimestamp,
  }) {
    return WellbeingSurveyResponse(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      cheerfulSpirits: cheerfulSpirits,
      calmRelaxed: calmRelaxed,
      activeVigorous: activeVigorous,
      wokeUpFresh: wokeUpFresh,
      dailyLifeInteresting: dailyLifeInteresting,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      locationTimestamp: locationTimestamp,
      isSynced: false,
    );
  }
}

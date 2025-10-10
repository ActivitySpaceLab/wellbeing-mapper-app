/// Models for managing participant consent to data sharing preferences
class DataSharingConsent {
  final String id;
  final LocationSharingOption locationSharingOption;
  final DateTime decisionTimestamp;
  final String participantUuid;
  final List<String>? customLocationIds; // For partial sharing option
  final String? reasonForPartialSharing; // Optional reason when selecting partial

  DataSharingConsent({
    required this.id,
    required this.locationSharingOption,
    required this.decisionTimestamp,
    required this.participantUuid,
    this.customLocationIds,
    this.reasonForPartialSharing,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_sharing_option': locationSharingOption.index,
      'decision_timestamp': decisionTimestamp.toIso8601String(),
      'participant_uuid': participantUuid,
      'custom_location_ids': customLocationIds,
      'reason_for_partial_sharing': reasonForPartialSharing,
    };
  }

  factory DataSharingConsent.fromJson(Map<String, dynamic> json) {
    return DataSharingConsent(
      id: json['id'],
      locationSharingOption: LocationSharingOption.values[json['location_sharing_option']],
      decisionTimestamp: DateTime.parse(json['decision_timestamp']),
      participantUuid: json['participant_uuid'],
      customLocationIds: json['custom_location_ids'] != null 
          ? List<String>.from(json['custom_location_ids'])
          : null,
      reasonForPartialSharing: json['reason_for_partial_sharing'],
    );
  }
}

/// Options for how much location data the participant wants to share
enum LocationSharingOption {
  fullData,        // Upload complete 2-week geolocation history
  partialData,     // Upload selected/filtered location data
  surveyOnly,      // Upload only survey responses, no location data
}

/// Summary of what data will be uploaded for user confirmation
class DataUploadSummary {
  final int surveyResponseCount;
  final int locationTrackCount;
  final DateTime oldestLocationDate;
  final DateTime newestLocationDate;
  final double locationAccuracyStats; // Average accuracy
  final List<LocationCluster> locationClusters; // Grouped locations for privacy preview

  DataUploadSummary({
    required this.surveyResponseCount,
    required this.locationTrackCount,
    required this.oldestLocationDate,
    required this.newestLocationDate,
    required this.locationAccuracyStats,
    required this.locationClusters,
  });
}

/// Grouped location data for privacy-conscious display
class LocationCluster {
  final String areaName; // General area name (e.g., "Johannesburg CBD")
  final int trackCount;
  final double centerLatitude;
  final double centerLongitude;
  final DateTime firstVisit;
  final DateTime lastVisit;

  LocationCluster({
    required this.areaName,
    required this.trackCount,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.firstVisit,
    required this.lastVisit,
  });
}

class ConsentResponse {
  final String participantUuid;
  final bool informedConsent;
  final bool dataProcessing;
  final bool locationData;
  final bool surveyData;
  final bool dataRetention;
  final bool dataSharing;
  final bool voluntaryParticipation;
  final DateTime consentedAt;
  final String participantSignature;

  ConsentResponse({
    required this.participantUuid,
    required this.informedConsent,
    required this.dataProcessing,
    required this.locationData,
    required this.surveyData,
    required this.dataRetention,
    required this.dataSharing,
    required this.voluntaryParticipation,
    required this.consentedAt,
    required this.participantSignature,
  });

  /// Check if all required consents have been given
  bool hasGivenValidConsent() {
    return informedConsent &&
           dataProcessing &&
           locationData &&
           surveyData &&
           dataRetention &&
           dataSharing &&
           voluntaryParticipation &&
           participantSignature.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'participantUuid': participantUuid,
      'informedConsent': informedConsent ? 1 : 0,
      'dataProcessing': dataProcessing ? 1 : 0,
      'locationData': locationData ? 1 : 0,
      'surveyData': surveyData ? 1 : 0,
      'dataRetention': dataRetention ? 1 : 0,
      'dataSharing': dataSharing ? 1 : 0,
      'voluntaryParticipation': voluntaryParticipation ? 1 : 0,
      'consentedAt': consentedAt.toIso8601String(),
      'participantSignature': participantSignature,
    };
  }

  factory ConsentResponse.fromJson(Map<String, dynamic> json) {
    return ConsentResponse(
      participantUuid: json['participantUuid'],
      informedConsent: json['informedConsent'] == 1,
      dataProcessing: json['dataProcessing'] == 1,
      locationData: json['locationData'] == 1,
      surveyData: json['surveyData'] == 1,
      dataRetention: json['dataRetention'] == 1,
      dataSharing: json['dataSharing'] == 1,
      voluntaryParticipation: json['voluntaryParticipation'] == 1,
      consentedAt: DateTime.parse(json['consentedAt']),
      participantSignature: json['participantSignature'] ?? '',
    );
  }
}

class ParticipationSettings {
  final bool isResearchParticipant;
  final String? participantCode;
  final String? researchSite; // 'barcelona' or 'gauteng'
  final DateTime createdAt;

  ParticipationSettings({
    required this.isResearchParticipant,
    this.participantCode,
    this.researchSite,
    required this.createdAt,
  });

  /// Factory method for private users
  factory ParticipationSettings.privateUser() {
    return ParticipationSettings(
      isResearchParticipant: false,
      participantCode: null,
      researchSite: null,
      createdAt: DateTime.now(),
    );
  }

  /// Factory method for research participants
  factory ParticipationSettings.researchParticipant(String participantCode, String researchSite) {
    return ParticipationSettings(
      isResearchParticipant: true,
      participantCode: participantCode,
      researchSite: researchSite,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isResearchParticipant': isResearchParticipant,
      'participantCode': participantCode,
      'researchSite': researchSite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ParticipationSettings.fromJson(Map<String, dynamic> json) {
    return ParticipationSettings(
      isResearchParticipant: json['isResearchParticipant'] ?? false,
      participantCode: json['participantCode'],
      researchSite: json['researchSite'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

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
  
  // Additional Gauteng-specific consent fields to match all 12 questions
  final bool consentParticipate;
  final bool consentQualtricsData;
  final bool consentRaceEthnicity;
  final bool consentHealth;
  final bool consentSexualOrientation;
  final bool consentLocationMobility;
  final bool consentDataTransfer;
  final bool consentPublicReporting;
  final bool consentResearcherSharing;
  final bool consentFurtherResearch;
  final bool consentPublicRepository;
  final bool consentFollowupContact;

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
    // New fields with defaults for backward compatibility
    this.consentParticipate = true,
    this.consentQualtricsData = true,
    this.consentRaceEthnicity = true,
    this.consentHealth = true,
    this.consentSexualOrientation = true,
    this.consentLocationMobility = true,
    this.consentDataTransfer = true,
    this.consentPublicReporting = true,
    this.consentResearcherSharing = true,
    this.consentFurtherResearch = true,
    this.consentPublicRepository = true,
    this.consentFollowupContact = false, // This one can be optional
  });

  /// Check if all required consents have been given (traditional model)
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

  /// Check if all required Gauteng consents have been given (all 11 required + 1 optional)
  bool hasGivenValidGautengConsent() {
    return consentParticipate &&
           consentQualtricsData &&
           consentRaceEthnicity &&
           consentHealth &&
           consentSexualOrientation &&
           consentLocationMobility &&
           consentDataTransfer &&
           consentPublicReporting &&
           consentResearcherSharing &&
           consentFurtherResearch &&
           consentPublicRepository;
    // consentFollowupContact is optional
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
      // New Gauteng fields
      'consentParticipate': consentParticipate ? 1 : 0,
      'consentQualtricsData': consentQualtricsData ? 1 : 0,
      'consentRaceEthnicity': consentRaceEthnicity ? 1 : 0,
      'consentHealth': consentHealth ? 1 : 0,
      'consentSexualOrientation': consentSexualOrientation ? 1 : 0,
      'consentLocationMobility': consentLocationMobility ? 1 : 0,
      'consentDataTransfer': consentDataTransfer ? 1 : 0,
      'consentPublicReporting': consentPublicReporting ? 1 : 0,
      'consentResearcherSharing': consentResearcherSharing ? 1 : 0,
      'consentFurtherResearch': consentFurtherResearch ? 1 : 0,
      'consentPublicRepository': consentPublicRepository ? 1 : 0,
      'consentFollowupContact': consentFollowupContact ? 1 : 0,
    };
  }

  /// Convert to Qualtrics-specific format for API sync
  Map<String, String> toQualtricsJson() {
    return {
      'PARTICIPANT_CODE': participantSignature,
      'PARTICIPANT_UUID': participantUuid,
      'CONSENT_PARTICIPATE': consentParticipate ? '1' : '0',
      'CONSENT_QUALTRICS_DATA': consentQualtricsData ? '1' : '0',
      'CONSENT_RACE_ETHNICITY': consentRaceEthnicity ? '1' : '0',
      'CONSENT_HEALTH': consentHealth ? '1' : '0',
      'CONSENT_SEXUAL_ORIENTATION': consentSexualOrientation ? '1' : '0',
      'CONSENT_LOCATION_MOBILITY': consentLocationMobility ? '1' : '0',
      'CONSENT_DATA_TRANSFER': consentDataTransfer ? '1' : '0',
      'CONSENT_PUBLIC_REPORTING': consentPublicReporting ? '1' : '0',
      'CONSENT_RESEARCHER_SHARING': consentResearcherSharing ? '1' : '0',
      'CONSENT_FURTHER_RESEARCH': consentFurtherResearch ? '1' : '0',
      'CONSENT_PUBLIC_REPOSITORY': consentPublicRepository ? '1' : '0',
      'CONSENT_FOLLOWUP_CONTACT': consentFollowupContact ? '1' : '0',
      'CONSENTED_AT': consentedAt.toIso8601String(),
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

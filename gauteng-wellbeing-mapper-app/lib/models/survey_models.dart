class InitialSurveyResponse {
  // Demographics (original initial survey fields)
  final int? age;
  final List<String> ethnicity;
  final String? gender;
  final String? sexuality;
  final String? birthPlace;
  final String? livesInBarcelona; // For Barcelona site only
  final String? suburb; // For Gauteng site only
  final String? buildingType;
  final List<String> householdItems;
  final String? education;
  final String? climateActivism;
  final String? generalHealth; // For Gauteng site only
  
  // Additional fields from biweekly survey (for baseline measurement)
  final List<String> activities;
  final String? livingArrangement;
  final String? relationshipStatus;
  
  // Wellbeing questions (0-5 scale) - baseline measurement
  final int? cheerfulSpirits;
  final int? calmRelaxed;
  final int? activeVigorous;
  final int? wokeUpFresh;
  final int? dailyLifeInteresting;
  
  // Personal characteristics (1-5 scale) - baseline measurement
  final int? cooperateWithPeople;
  final int? improvingSkills;
  final int? socialSituations;
  final int? familySupport;
  final int? familyKnowsMe;
  final int? accessToFood;
  final int? peopleEnjoyTime;
  final int? talkToFamily;
  final int? friendsSupport;
  final int? belongInCommunity;
  final int? familyStandsByMe;
  final int? friendsStandByMe;
  final int? treatedFairly;
  final int? opportunitiesResponsibility;
  final int? secureWithFamily;
  final int? opportunitiesAbilities;
  final int? enjoyCulturalTraditions;
  
  // Digital diary - baseline (no location data for initial survey)
  final String? environmentalChallenges;
  final String? challengesStressLevel;
  final String? copingHelp;
  
  // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
  // final List<String>? voiceNoteUrls; // URLs to uploaded audio files
  final List<String>? imageUrls; // URLs to uploaded image files
  
  final String researchSite; // Currently only 'gauteng'
  final DateTime submittedAt;

  InitialSurveyResponse({
    this.age,
    required this.ethnicity,
    this.gender,
    this.sexuality,
    this.birthPlace,
    this.livesInBarcelona,
    this.suburb,
    this.buildingType,
    required this.householdItems,
    this.education,
    this.climateActivism,
    this.generalHealth,
    required this.activities,
    this.livingArrangement,
    this.relationshipStatus,
    this.cheerfulSpirits,
    this.calmRelaxed,
    this.activeVigorous,
    this.wokeUpFresh,
    this.dailyLifeInteresting,
    this.cooperateWithPeople,
    this.improvingSkills,
    this.socialSituations,
    this.familySupport,
    this.familyKnowsMe,
    this.accessToFood,
    this.peopleEnjoyTime,
    this.talkToFamily,
    this.friendsSupport,
    this.belongInCommunity,
    this.familyStandsByMe,
    this.friendsStandByMe,
    this.treatedFairly,
    this.opportunitiesResponsibility,
    this.secureWithFamily,
    this.opportunitiesAbilities,
    this.enjoyCulturalTraditions,
    this.environmentalChallenges,
    this.challengesStressLevel,
    this.copingHelp,
    // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
    // this.voiceNoteUrls,
    this.imageUrls,
    required this.researchSite,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'ethnicity': ethnicity,
      'gender': gender,
      'sexuality': sexuality,
      'birthPlace': birthPlace,
      'livesInBarcelona': livesInBarcelona,
      'suburb': suburb,
      'buildingType': buildingType,
      'householdItems': householdItems,
      'education': education,
      'climateActivism': climateActivism,
      'generalHealth': generalHealth,
      'activities': activities,
      'livingArrangement': livingArrangement,
      'relationshipStatus': relationshipStatus,
      'cheerfulSpirits': cheerfulSpirits,
      'calmRelaxed': calmRelaxed,
      'activeVigorous': activeVigorous,
      'wokeUpFresh': wokeUpFresh,
      'dailyLifeInteresting': dailyLifeInteresting,
      'cooperateWithPeople': cooperateWithPeople,
      'improvingSkills': improvingSkills,
      'socialSituations': socialSituations,
      'familySupport': familySupport,
      'familyKnowsMe': familyKnowsMe,
      'accessToFood': accessToFood,
      'peopleEnjoyTime': peopleEnjoyTime,
      'talkToFamily': talkToFamily,
      'friendsSupport': friendsSupport,
      'belongInCommunity': belongInCommunity,
      'familyStandsByMe': familyStandsByMe,
      'friendsStandByMe': friendsStandByMe,
      'treatedFairly': treatedFairly,
      'opportunitiesResponsibility': opportunitiesResponsibility,
      'secureWithFamily': secureWithFamily,
      'opportunitiesAbilities': opportunitiesAbilities,
      'enjoyCulturalTraditions': enjoyCulturalTraditions,
      'environmentalChallenges': environmentalChallenges,
      'challengesStressLevel': challengesStressLevel,
      'copingHelp': copingHelp,
      // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
      // 'voiceNoteUrls': voiceNoteUrls,
      'imageUrls': imageUrls,
      'researchSite': researchSite,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory InitialSurveyResponse.fromJson(Map<String, dynamic> json) {
    return InitialSurveyResponse(
      age: json['age'],
      ethnicity: List<String>.from(json['ethnicity'] ?? []),
      gender: json['gender'],
      sexuality: json['sexuality'],
      birthPlace: json['birthPlace'],
      livesInBarcelona: json['livesInBarcelona'],
      suburb: json['suburb'],
      buildingType: json['buildingType'],
      householdItems: List<String>.from(json['householdItems'] ?? []),
      education: json['education'],
      climateActivism: json['climateActivism'],
      generalHealth: json['generalHealth'],
      activities: List<String>.from(json['activities'] ?? []),
      livingArrangement: json['livingArrangement'],
      relationshipStatus: json['relationshipStatus'],
      cheerfulSpirits: json['cheerfulSpirits'],
      calmRelaxed: json['calmRelaxed'],
      activeVigorous: json['activeVigorous'],
      wokeUpFresh: json['wokeUpFresh'],
      dailyLifeInteresting: json['dailyLifeInteresting'],
      cooperateWithPeople: json['cooperateWithPeople'],
      improvingSkills: json['improvingSkills'],
      socialSituations: json['socialSituations'],
      familySupport: json['familySupport'],
      familyKnowsMe: json['familyKnowsMe'],
      accessToFood: json['accessToFood'],
      peopleEnjoyTime: json['peopleEnjoyTime'],
      talkToFamily: json['talkToFamily'],
      friendsSupport: json['friendsSupport'],
      belongInCommunity: json['belongInCommunity'],
      familyStandsByMe: json['familyStandsByMe'],
      friendsStandByMe: json['friendsStandByMe'],
      treatedFairly: json['treatedFairly'],
      opportunitiesResponsibility: json['opportunitiesResponsibility'],
      secureWithFamily: json['secureWithFamily'],
      opportunitiesAbilities: json['opportunitiesAbilities'],
      enjoyCulturalTraditions: json['enjoyCulturalTraditions'],
      environmentalChallenges: json['environmentalChallenges'],
      challengesStressLevel: json['challengesStressLevel'],
      copingHelp: json['copingHelp'],
      // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
      // voiceNoteUrls: json['voiceNoteUrls'] != null ? List<String>.from(json['voiceNoteUrls']) : null,
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      researchSite: json['researchSite'] ?? 'barcelona',
      submittedAt: DateTime.parse(json['submittedAt']),
    );
  }
}

class RecurringSurveyResponse {
  final List<String> activities;
  final String? livingArrangement;
  final String? relationshipStatus;
  final String? generalHealth; // For Gauteng site only
  
  // Wellbeing questions (0-5 scale)
  final int? cheerfulSpirits;
  final int? calmRelaxed;
  final int? activeVigorous;
  final int? wokeUpFresh;
  final int? dailyLifeInteresting;
  
  // Personal characteristics (1-5 scale)
  final int? cooperateWithPeople;
  final int? improvingSkills;
  final int? socialSituations;
  final int? familySupport;
  final int? familyKnowsMe;
  final int? accessToFood;
  final int? peopleEnjoyTime;
  final int? talkToFamily;
  final int? friendsSupport;
  final int? belongInCommunity;
  final int? familyStandsByMe;
  final int? friendsStandByMe;
  final int? treatedFairly;
  final int? opportunitiesResponsibility;
  final int? secureWithFamily;
  final int? opportunitiesAbilities;
  final int? enjoyCulturalTraditions;
  
  // Digital diary
  final String? environmentalChallenges;
  final String? challengesStressLevel;
  final String? copingHelp;
  // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
  // final List<String>? voiceNoteUrls;
  final List<String>? imageUrls;
  
  final String researchSite; // Currently only 'gauteng'
  final DateTime submittedAt;
  final String? encryptedLocationData; // Encrypted location data captured at submission time
  final bool synced; // Whether this survey has been uploaded to the server

  RecurringSurveyResponse({
    required this.activities,
    this.livingArrangement,
    this.relationshipStatus,
    this.generalHealth,
    this.cheerfulSpirits,
    this.calmRelaxed,
    this.activeVigorous,
    this.wokeUpFresh,
    this.dailyLifeInteresting,
    this.cooperateWithPeople,
    this.improvingSkills,
    this.socialSituations,
    this.familySupport,
    this.familyKnowsMe,
    this.accessToFood,
    this.peopleEnjoyTime,
    this.talkToFamily,
    this.friendsSupport,
    this.belongInCommunity,
    this.familyStandsByMe,
    this.friendsStandByMe,
    this.treatedFairly,
    this.opportunitiesResponsibility,
    this.secureWithFamily,
    this.opportunitiesAbilities,
    this.enjoyCulturalTraditions,
    this.environmentalChallenges,
    this.challengesStressLevel,
    this.copingHelp,
    // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
    // this.voiceNoteUrls,
    this.imageUrls,
    required this.researchSite,
    required this.submittedAt,
    this.encryptedLocationData,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'activities': activities,
      'livingArrangement': livingArrangement,
      'relationshipStatus': relationshipStatus,
      'generalHealth': generalHealth,
      'cheerfulSpirits': cheerfulSpirits,
      'calmRelaxed': calmRelaxed,
      'activeVigorous': activeVigorous,
      'wokeUpFresh': wokeUpFresh,
      'dailyLifeInteresting': dailyLifeInteresting,
      'cooperateWithPeople': cooperateWithPeople,
      'improvingSkills': improvingSkills,
      'socialSituations': socialSituations,
      'familySupport': familySupport,
      'familyKnowsMe': familyKnowsMe,
      'accessToFood': accessToFood,
      'peopleEnjoyTime': peopleEnjoyTime,
      'talkToFamily': talkToFamily,
      'friendsSupport': friendsSupport,
      'belongInCommunity': belongInCommunity,
      'familyStandsByMe': familyStandsByMe,
      'friendsStandByMe': friendsStandByMe,
      'treatedFairly': treatedFairly,
      'opportunitiesResponsibility': opportunitiesResponsibility,
      'secureWithFamily': secureWithFamily,
      'opportunitiesAbilities': opportunitiesAbilities,
      'enjoyCulturalTraditions': enjoyCulturalTraditions,
      'environmentalChallenges': environmentalChallenges,
      'challengesStressLevel': challengesStressLevel,
      'copingHelp': copingHelp,
      // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
      // 'voiceNoteUrls': voiceNoteUrls,
      'imageUrls': imageUrls,
      'researchSite': researchSite,
      'submittedAt': submittedAt.toIso8601String(),
      'encryptedLocationData': encryptedLocationData,
      'synced': synced,
    };
  }

  factory RecurringSurveyResponse.fromJson(Map<String, dynamic> json) {
    return RecurringSurveyResponse(
      activities: List<String>.from(json['activities'] ?? []),
      livingArrangement: json['livingArrangement'],
      relationshipStatus: json['relationshipStatus'],
      generalHealth: json['generalHealth'],
      cheerfulSpirits: json['cheerfulSpirits'],
      calmRelaxed: json['calmRelaxed'],
      activeVigorous: json['activeVigorous'],
      wokeUpFresh: json['wokeUpFresh'],
      dailyLifeInteresting: json['dailyLifeInteresting'],
      cooperateWithPeople: json['cooperateWithPeople'],
      improvingSkills: json['improvingSkills'],
      socialSituations: json['socialSituations'],
      familySupport: json['familySupport'],
      familyKnowsMe: json['familyKnowsMe'],
      accessToFood: json['accessToFood'],
      peopleEnjoyTime: json['peopleEnjoyTime'],
      talkToFamily: json['talkToFamily'],
      friendsSupport: json['friendsSupport'],
      belongInCommunity: json['belongInCommunity'],
      familyStandsByMe: json['familyStandsByMe'],
      friendsStandByMe: json['friendsStandByMe'],
      treatedFairly: json['treatedFairly'],
      opportunitiesResponsibility: json['opportunitiesResponsibility'],
      secureWithFamily: json['secureWithFamily'],
      opportunitiesAbilities: json['opportunitiesAbilities'],
      enjoyCulturalTraditions: json['enjoyCulturalTraditions'],
      environmentalChallenges: json['environmentalChallenges'],
      challengesStressLevel: json['challengesStressLevel'],
      copingHelp: json['copingHelp'],
      // TODO: MULTIMEDIA DISABLED - Voice notes not implemented yet
      // voiceNoteUrls: json['voiceNoteUrls'] != null ? List<String>.from(json['voiceNoteUrls']) : null,
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      researchSite: json['researchSite'] ?? 'barcelona',
      submittedAt: DateTime.parse(json['submittedAt']),
      encryptedLocationData: json['encryptedLocationData'],
      synced: json['synced'] == 1 || json['synced'] == true,
    );
  }
}

/// Location track data model
class LocationTrack {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final String? activity;

  LocationTrack({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.activity,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'activity': activity,
    };
  }

  factory LocationTrack.fromJson(Map<String, dynamic> json) {
    return LocationTrack(
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      activity: json['activity'],
    );
  }
}

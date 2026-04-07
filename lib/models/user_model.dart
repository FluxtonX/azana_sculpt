class UserModel {
  final String uid;
  final String email;
  final String? fullName;
  final String? phone;
  final String? ageRange;
  
  // Physical
  final String? height;
  final String? weight;
  final String? heightUnit;
  final String? weightUnit;
  
  // Medical
  final bool? isTakingMedication;
  final List<String>? medicalConditions;
  
  // Fitness
  final String? activityLevel;
  final bool? hasGymAccess;
  final double? weightliftingExperience;
  final List<String>? equipment;
  final String? sleepQuality;
  
  // Goals & Mindset
  final String? fitnessGoal;
  final String? bodyVision;
  final double? commitmentLevel;
  final double? motivationLevel;
  final String? mentalBarriers;
  final String? coachingPreference;
  
  // Readiness
  final String? investmentReadiness;
  final String? commitmentReadiness;
  final String? referral;
  final String? socialMedia;
  final String? role; // 'client', 'coach', 'admin'

  // Gamification
  final int? streakCount;
  final int? longestStreak;
  final String? lastActiveDate; // 'YYYY-MM-DD'
  final List<String>? unlockedBadges;
  final String? coachId;

  // Professional
  final String? bio;
  final List<String>? specialties;
  final String? profileImageUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.phone,
    this.ageRange,
    this.height,
    this.weight,
    this.heightUnit,
    this.weightUnit,
    this.isTakingMedication,
    this.medicalConditions,
    this.activityLevel,
    this.hasGymAccess,
    this.weightliftingExperience,
    this.equipment,
    this.sleepQuality,
    this.fitnessGoal,
    this.bodyVision,
    this.commitmentLevel,
    this.motivationLevel,
    this.mentalBarriers,
    this.coachingPreference,
    this.investmentReadiness,
    this.commitmentReadiness,
    this.referral,
    this.socialMedia,
    this.role = 'client',
    this.streakCount,
    this.longestStreak,
    this.lastActiveDate,
    this.unlockedBadges,
    this.coachId,
    this.bio,
    this.specialties,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'ageRange': ageRange,
      'height': height,
      'weight': weight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
      'isTakingMedication': isTakingMedication,
      'medicalConditions': medicalConditions,
      'activityLevel': activityLevel,
      'hasGymAccess': hasGymAccess,
      'weightliftingExperience': weightliftingExperience,
      'equipment': equipment,
      'sleepQuality': sleepQuality,
      'fitnessGoal': fitnessGoal,
      'bodyVision': bodyVision,
      'commitmentLevel': commitmentLevel,
      'motivationLevel': motivationLevel,
      'mentalBarriers': mentalBarriers,
      'coachingPreference': coachingPreference,
      'investmentReadiness': investmentReadiness,
      'commitmentReadiness': commitmentReadiness,
      'referral': referral,
      'socialMedia': socialMedia,
      'role': role ?? 'client',
      'streakCount': streakCount,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'unlockedBadges': unlockedBadges,
      'coachId': coachId,
      'bio': bio,
      'specialties': specialties,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'],
      phone: map['phone'],
      ageRange: map['ageRange'],
      height: map['height'],
      weight: map['weight'],
      heightUnit: map['heightUnit'],
      weightUnit: map['weightUnit'],
      isTakingMedication: map['isTakingMedication'],
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      activityLevel: map['activityLevel'],
      hasGymAccess: map['hasGymAccess'],
      weightliftingExperience: (map['weightliftingExperience'] as num?)?.toDouble(),
      equipment: List<String>.from(map['equipment'] ?? []),
      sleepQuality: map['sleepQuality'],
      fitnessGoal: map['fitnessGoal'],
      bodyVision: map['bodyVision'],
      commitmentLevel: (map['commitmentLevel'] as num?)?.toDouble(),
      motivationLevel: (map['motivationLevel'] as num?)?.toDouble(),
      mentalBarriers: map['mentalBarriers'],
      coachingPreference: map['coachingPreference'],
      investmentReadiness: map['investmentReadiness'],
      commitmentReadiness: map['commitmentReadiness'],
      referral: map['referral'],
      socialMedia: map['socialMedia'],
      role: map['role'] ?? 'client',
      streakCount: map['streakCount'] as int?,
      longestStreak: map['longestStreak'] as int?,
      lastActiveDate: map['lastActiveDate'] as String?,
      unlockedBadges: map['unlockedBadges'] != null
          ? List<String>.from(map['unlockedBadges'])
          : null,
      coachId: map['coachId'],
      bio: map['bio'],
      specialties: map['specialties'] != null ? List<String>.from(map['specialties']) : null,
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? ageRange,
    String? height,
    String? weight,
    String? heightUnit,
    String? weightUnit,
    bool? isTakingMedication,
    List<String>? medicalConditions,
    String? activityLevel,
    bool? hasGymAccess,
    double? weightliftingExperience,
    List<String>? equipment,
    String? sleepQuality,
    String? fitnessGoal,
    String? bodyVision,
    double? commitmentLevel,
    double? motivationLevel,
    String? mentalBarriers,
    String? coachingPreference,
    String? investmentReadiness,
    String? commitmentReadiness,
    String? referral,
    String? socialMedia,
    String? role,
    int? streakCount,
    int? longestStreak,
    String? lastActiveDate,
    List<String>? unlockedBadges,
    String? coachId,
    String? bio,
    List<String>? specialties,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      ageRange: ageRange ?? this.ageRange,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      isTakingMedication: isTakingMedication ?? this.isTakingMedication,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      activityLevel: activityLevel ?? this.activityLevel,
      hasGymAccess: hasGymAccess ?? this.hasGymAccess,
      weightliftingExperience: weightliftingExperience ?? this.weightliftingExperience,
      equipment: equipment ?? this.equipment,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      bodyVision: bodyVision ?? this.bodyVision,
      commitmentLevel: commitmentLevel ?? this.commitmentLevel,
      motivationLevel: motivationLevel ?? this.motivationLevel,
      mentalBarriers: mentalBarriers ?? this.mentalBarriers,
      coachingPreference: coachingPreference ?? this.coachingPreference,
      investmentReadiness: investmentReadiness ?? this.investmentReadiness,
      commitmentReadiness: commitmentReadiness ?? this.commitmentReadiness,
      referral: referral ?? this.referral,
      socialMedia: socialMedia ?? this.socialMedia,
      role: role ?? this.role,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      coachId: coachId ?? this.coachId,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

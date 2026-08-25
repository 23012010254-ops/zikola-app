

class ChildProfile {
  String id;
  String name;
  String gender;
  int age;
  String avatar;
  String? avatarBase64;
  String backgroundColor;
  String favoriteColor;
  List<String> badges;
  SurveyData surveyData;
  int totalPoints;
  List<String> showcasedStickers;
  bool surveyCompleted;
  List<String> followers;
  List<String> following;
  List<String> collectedStickers;
  String? email;
  DateTime? createdAt;

  ChildProfile({
    String? id,
    this.name = '',
    this.gender = 'male',
    this.age = 6,
    this.avatar = '👦',
    this.avatarBase64,
    this.backgroundColor = '#3B82F6',
    this.favoriteColor = 'blue',
    this.badges = const ['super-star', 'brain-explorer'],
    SurveyData? surveyData,
    this.totalPoints = 0,
    this.showcasedStickers = const [],
    this.surveyCompleted = false,
    this.followers = const [],
    this.following = const [],
    this.collectedStickers = const [],
    this.email,
    this.createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        surveyData = surveyData ?? SurveyData();

  ChildProfile copyWith({
    String? id,
    String? name,
    String? gender,
    int? age,
    String? avatar,
    String? avatarBase64,
    String? backgroundColor,
    String? favoriteColor,
    List<String>? badges,
    SurveyData? surveyData,
    int? totalPoints,
    List<String>? showcasedStickers,
    bool? surveyCompleted,
    List<String>? followers,
    List<String>? following,
    List<String>? collectedStickers,
    String? email,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      avatar: avatar ?? this.avatar,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      favoriteColor: favoriteColor ?? this.favoriteColor,
      badges: badges ?? this.badges,
      surveyData: surveyData ?? this.surveyData,
      totalPoints: totalPoints ?? this.totalPoints,
      showcasedStickers: showcasedStickers ?? this.showcasedStickers,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      collectedStickers: collectedStickers ?? this.collectedStickers,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? 'male',
      age: json['age'] as int? ?? 6,
      avatar: json['avatar'] as String? ?? '👦',
      avatarBase64: json['avatarBase64'] as String?,
      backgroundColor: json['backgroundColor'] as String? ?? '#3B82F6',
      favoriteColor: json['favoriteColor'] as String? ?? 'blue',
      badges: (json['badges'] as List?)?.map((e) => e as String).toList() ?? const ['super-star', 'brain-explorer'],
      surveyData: json['surveyData'] != null ? SurveyData.fromJson(json['surveyData']) : SurveyData(),
      totalPoints: json['totalPoints'] as int? ?? 0,
      showcasedStickers: (json['showcasedStickers'] as List?)?.map((e) => e as String).toList() ?? const [],
      surveyCompleted: json['surveyCompleted'] as bool? ?? false,
      followers: (json['followers'] as List?)?.map((e) => e as String).toList() ?? const [],
      following: (json['following'] as List?)?.map((e) => e as String).toList() ?? const [],
      collectedStickers: (json['collectedStickers'] as List?)?.map((e) => e as String).toList() ?? const [],
      email: json['email'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'avatar': avatar,
      'avatarBase64': avatarBase64,
      'backgroundColor': backgroundColor,
      'favoriteColor': favoriteColor,
      'badges': badges,
      'surveyData': surveyData.toJson(),
      'totalPoints': totalPoints,
      'showcasedStickers': showcasedStickers,
      'surveyCompleted': surveyCompleted,
      'followers': followers,
      'following': following,
      'collectedStickers': collectedStickers,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Generate a short hash (8 chars) from avatarBase64 for identity validation.
  static String _shortHash(String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) return 'none';
    // Simple hash: take first 8 chars of base64-encoded hashCode
    final hash = base64Data.hashCode.toRadixString(16).padLeft(8, '0');
    return hash.substring(0, 8);
  }

  /// Encode identity as single string: "name|gender|photoCode"
  String toIdentityString() {
    final photoCode = _shortHash(avatarBase64);
    return '$name|$gender|$photoCode';
  }

  /// Parse identity string back to core fields.
  /// Returns a map with 'name', 'gender', 'photoCode' keys.
  static Map<String, String> parseIdentityString(String identity) {
    final parts = identity.split('|');
    return {
      'name': parts.isNotEmpty ? parts[0] : '',
      'gender': parts.length > 1 ? parts[1] : 'male',
      'photoCode': parts.length > 2 ? parts[2] : 'none',
    };
  }
}

class SurveyData {
  List<String> personality;
  List<String> activities;
  List<String> learningStyle;
  List<String> interests;
  List<String> hobbies;

  SurveyData({
    this.personality = const [],
    this.activities = const [],
    this.learningStyle = const [],
    this.interests = const [],
    this.hobbies = const [],
  });

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      personality: (json['personality'] as List?)?.map((e) => e as String).toList() ?? const [],
      activities: (json['activities'] as List?)?.map((e) => e as String).toList() ?? const [],
      learningStyle: (json['learningStyle'] as List?)?.map((e) => e as String).toList() ?? const [],
      interests: (json['interests'] as List?)?.map((e) => e as String).toList() ?? const [],
      hobbies: (json['hobbies'] as List?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personality': personality,
      'activities': activities,
      'learningStyle': learningStyle,
      'interests': interests,
      'hobbies': hobbies,
    };
  }
}

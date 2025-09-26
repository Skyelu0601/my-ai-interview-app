import 'dart:io';

class UserProfile {
  final String phoneNumber;
  final String? name;
  final String? targetIndustry;
  final String? targetRole;
  final File? resumeFile;
  final String? resumeText;
  final String? jobDescription;
  final bool hasSeenWelcomeChat;
  final bool isOnboardingCompleted;
  final DateTime? lastLoginTime;
  final String? userRole; // 用户角色，如"律师"、"产品经理"等

  const UserProfile({
    required this.phoneNumber,
    this.name,
    this.targetIndustry,
    this.targetRole,
    this.resumeFile,
    this.resumeText,
    this.jobDescription,
    this.hasSeenWelcomeChat = false,
    this.isOnboardingCompleted = false,
    this.lastLoginTime,
    this.userRole,
  });

  UserProfile copyWith({
    String? phoneNumber,
    String? name,
    String? targetIndustry,
    String? targetRole,
    File? resumeFile,
    String? resumeText,
    String? jobDescription,
    bool? hasSeenWelcomeChat,
    bool? isOnboardingCompleted,
    DateTime? lastLoginTime,
    String? userRole,
  }) {
    return UserProfile(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      targetIndustry: targetIndustry ?? this.targetIndustry,
      targetRole: targetRole ?? this.targetRole,
      resumeFile: resumeFile ?? this.resumeFile,
      resumeText: resumeText ?? this.resumeText,
      jobDescription: jobDescription ?? this.jobDescription,
      hasSeenWelcomeChat: hasSeenWelcomeChat ?? this.hasSeenWelcomeChat,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      userRole: userRole ?? this.userRole,
    );
  }

  // 检查用户是否是新用户（首次登录）
  bool get isNewUser => !hasSeenWelcomeChat && !isOnboardingCompleted;

  // 检查用户是否已完成设置
  bool get isFullySetUp => isOnboardingCompleted && targetRole != null;

  // 获取用户显示名称
  String get displayName => name ?? userRole ?? targetRole ?? '用户';

  // 获取用户角色描述
  String get roleDescription {
    if (userRole != null) return userRole!;
    if (targetRole != null) return targetRole!;
    return '未设置';
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'targetIndustry': targetIndustry,
      'targetRole': targetRole,
      'resumeText': resumeText,
      'jobDescription': jobDescription,
      'hasSeenWelcomeChat': hasSeenWelcomeChat,
      'isOnboardingCompleted': isOnboardingCompleted,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'userRole': userRole,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      targetIndustry: json['targetIndustry'] as String?,
      targetRole: json['targetRole'] as String?,
      resumeText: json['resumeText'] as String?,
      jobDescription: json['jobDescription'] as String?,
      hasSeenWelcomeChat: json['hasSeenWelcomeChat'] as bool? ?? false,
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? false,
      lastLoginTime: json['lastLoginTime'] != null 
          ? DateTime.parse(json['lastLoginTime'] as String)
          : null,
      userRole: json['userRole'] as String?,
    );
  }
}

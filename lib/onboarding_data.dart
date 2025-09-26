import 'dart:io';

class OnboardingData {
  final String? targetIndustry;
  final String? targetRole;
  final File? resumeFile;
  final String? resumeText; // 解析后的简历文本内容
  final String? jobDescription;
  final bool hasSeenWelcomeChat; // 是否已看过欢迎对话
  final bool isOnboardingCompleted; // 是否已完成onboarding
  
  // 临时状态字段 - 用于设置流程中的预览
  final String? tempTargetIndustry;
  final String? tempTargetRole;
  final File? tempResumeFile;
  final String? tempResumeText;
  final String? tempJobDescription;

  const OnboardingData({
    this.targetIndustry,
    this.targetRole,
    this.resumeFile,
    this.resumeText,
    this.jobDescription,
    this.hasSeenWelcomeChat = false,
    this.isOnboardingCompleted = false,
    this.tempTargetIndustry,
    this.tempTargetRole,
    this.tempResumeFile,
    this.tempResumeText,
    this.tempJobDescription,
  });

  OnboardingData copyWith({
    String? targetIndustry,
    String? targetRole,
    File? resumeFile,
    String? resumeText,
    String? jobDescription,
    bool? hasSeenWelcomeChat,
    bool? isOnboardingCompleted,
    String? tempTargetIndustry,
    String? tempTargetRole,
    File? tempResumeFile,
    String? tempResumeText,
    String? tempJobDescription,
  }) {
    return OnboardingData(
      targetIndustry: targetIndustry ?? this.targetIndustry,
      targetRole: targetRole ?? this.targetRole,
      resumeFile: resumeFile ?? this.resumeFile,
      resumeText: resumeText ?? this.resumeText,
      jobDescription: jobDescription ?? this.jobDescription,
      hasSeenWelcomeChat: hasSeenWelcomeChat ?? this.hasSeenWelcomeChat,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      tempTargetIndustry: tempTargetIndustry ?? this.tempTargetIndustry,
      tempTargetRole: tempTargetRole ?? this.tempTargetRole,
      tempResumeFile: tempResumeFile ?? this.tempResumeFile,
      tempResumeText: tempResumeText ?? this.tempResumeText,
      tempJobDescription: tempJobDescription ?? this.tempJobDescription,
    );
  }
}

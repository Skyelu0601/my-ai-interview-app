import 'dart:io';

class OnboardingData {
  final String? experienceLevel;
  final String? targetIndustry;
  final String? targetRole;
  final File? resumeFile;
  final String? jobDescription;

  const OnboardingData({
    this.experienceLevel,
    this.targetIndustry,
    this.targetRole,
    this.resumeFile,
    this.jobDescription,
  });

  OnboardingData copyWith({
    String? experienceLevel,
    String? targetIndustry,
    String? targetRole,
    File? resumeFile,
    String? jobDescription,
  }) {
    return OnboardingData(
      experienceLevel: experienceLevel ?? this.experienceLevel,
      targetIndustry: targetIndustry ?? this.targetIndustry,
      targetRole: targetRole ?? this.targetRole,
      resumeFile: resumeFile ?? this.resumeFile,
      jobDescription: jobDescription ?? this.jobDescription,
    );
  }
}



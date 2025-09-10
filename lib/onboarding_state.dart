import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_data.dart';

class OnboardingStateNotifier extends StateNotifier<OnboardingData> {
  OnboardingStateNotifier() : super(const OnboardingData());

  void updateExperienceLevel(String experienceLevel) {
    state = state.copyWith(experienceLevel: experienceLevel);
  }

  void updateTargetIndustry(String targetIndustry) {
    state = state.copyWith(targetIndustry: targetIndustry, targetRole: null);
  }

  void updateTargetRole(String targetRole) {
    state = state.copyWith(targetRole: targetRole);
  }

  void updateResumeFile(File resumeFile) {
    state = state.copyWith(resumeFile: resumeFile);
  }

  void updateJobDescription(String? jobDescription) {
    state = state.copyWith(jobDescription: jobDescription);
  }

  void resetIndustrySelection() {
    state = state.copyWith(targetIndustry: null, targetRole: null);
  }
}

final onboardingStateProvider =
    StateNotifierProvider<OnboardingStateNotifier, OnboardingData>(
  (ref) => OnboardingStateNotifier(),
);



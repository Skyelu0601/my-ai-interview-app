import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_data.dart';
import 'user_profile_manager.dart';

class OnboardingStateNotifier extends StateNotifier<OnboardingData> {
  final UserProfileManager _userProfileManager;
  
  OnboardingStateNotifier(this._userProfileManager) : super(const OnboardingData()) {
    _loadOnboardingState();
  }

  // 从本地存储加载onboarding状态
  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenWelcomeChat = prefs.getBool('hasSeenWelcomeChat') ?? false;
      final isOnboardingCompleted = prefs.getBool('isOnboardingCompleted') ?? false;
      final targetIndustry = prefs.getString('targetIndustry');
      final targetRole = prefs.getString('targetRole');
      final resumeText = prefs.getString('resumeText');
      final jobDescription = prefs.getString('jobDescription');

      state = state.copyWith(
        hasSeenWelcomeChat: hasSeenWelcomeChat,
        isOnboardingCompleted: isOnboardingCompleted,
        targetIndustry: targetIndustry,
        targetRole: targetRole,
        resumeText: resumeText,
        jobDescription: jobDescription,
      );
    } catch (e) {
      // 如果加载失败，保持默认状态
      print('Failed to load onboarding state: $e');
    }
  }

  // 保存onboarding状态到本地存储
  Future<void> _saveOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcomeChat', state.hasSeenWelcomeChat);
      await prefs.setBool('isOnboardingCompleted', state.isOnboardingCompleted);
      if (state.targetIndustry != null) {
        await prefs.setString('targetIndustry', state.targetIndustry!);
      }
      if (state.targetRole != null) {
        await prefs.setString('targetRole', state.targetRole!);
      }
      if (state.resumeText != null) {
        await prefs.setString('resumeText', state.resumeText!);
      }
      if (state.jobDescription != null) {
        await prefs.setString('jobDescription', state.jobDescription!);
      }
    } catch (e) {
      print('Failed to save onboarding state: $e');
    }
  }

  void updateTargetIndustry(String targetIndustry) {
    state = state.copyWith(targetIndustry: targetIndustry, targetRole: null);
    _saveOnboardingState();
  }

  void updateTargetRole(String targetRole) {
    state = state.copyWith(targetRole: targetRole);
    _saveOnboardingState();
  }

  void updateResumeFile(File resumeFile) {
    state = state.copyWith(resumeFile: resumeFile);
    _saveOnboardingState();
  }

  void updateResumeText(String resumeText) {
    state = state.copyWith(resumeText: resumeText);
    _saveOnboardingState();
  }

  void updateJobDescription(String? jobDescription) {
    state = state.copyWith(jobDescription: jobDescription);
    _saveOnboardingState();
  }

  // 临时状态管理方法 - 用于设置流程中的预览
  void updateTempTargetIndustry(String tempTargetIndustry) {
    state = state.copyWith(tempTargetIndustry: tempTargetIndustry, tempTargetRole: null);
  }

  void updateTempTargetRole(String tempTargetRole) {
    state = state.copyWith(tempTargetRole: tempTargetRole);
  }

  void updateTempResumeFile(File tempResumeFile) {
    state = state.copyWith(tempResumeFile: tempResumeFile);
  }

  void updateTempResumeText(String tempResumeText) {
    state = state.copyWith(tempResumeText: tempResumeText);
  }

  void updateTempJobDescription(String? tempJobDescription) {
    state = state.copyWith(tempJobDescription: tempJobDescription);
  }

  // 确认临时设置 - 将临时状态应用到正式状态
  void confirmTempSettings() {
    final newIndustry = state.tempTargetIndustry ?? state.targetIndustry;
    final newRole = state.tempTargetRole ?? state.targetRole;
    
    state = state.copyWith(
      targetIndustry: newIndustry,
      targetRole: newRole,
      resumeFile: state.tempResumeFile ?? state.resumeFile,
      resumeText: state.tempResumeText ?? state.resumeText,
      jobDescription: state.tempJobDescription ?? state.jobDescription,
      // 清除临时状态
      tempTargetIndustry: null,
      tempTargetRole: null,
      tempResumeFile: null,
      tempResumeText: null,
      tempJobDescription: null,
    );
    _saveOnboardingState();
    
    // 同步到用户档案
    if (newIndustry != null && newRole != null) {
      _userProfileManager.updateTargetInfo(
        industry: newIndustry,
        role: newRole,
      );
    }
  }

  // 取消临时设置 - 清除临时状态
  void cancelTempSettings() {
    state = state.copyWith(
      tempTargetIndustry: null,
      tempTargetRole: null,
      tempResumeFile: null,
      tempResumeText: null,
      tempJobDescription: null,
    );
  }

  void resetIndustrySelection() {
    state = state.copyWith(targetIndustry: null, targetRole: null);
    _saveOnboardingState();
  }

  void markWelcomeChatSeen() {
    state = state.copyWith(hasSeenWelcomeChat: true);
    _saveOnboardingState();
    // 同步到用户档案
    _userProfileManager.markWelcomeChatSeen();
  }

  void completeOnboarding() {
    state = state.copyWith(isOnboardingCompleted: true);
    _saveOnboardingState();
    // 同步到用户档案
    _userProfileManager.completeOnboarding();
  }

  void resetOnboarding() async {
    state = const OnboardingData();
    // 清除本地存储的onboarding数据
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasSeenWelcomeChat');
      await prefs.remove('isOnboardingCompleted');
      await prefs.remove('targetIndustry');
      await prefs.remove('targetRole');
      await prefs.remove('resumeText');
      await prefs.remove('jobDescription');
    } catch (e) {
      print('Failed to clear onboarding state: $e');
    }
  }
}

final onboardingStateProvider =
    StateNotifierProvider<OnboardingStateNotifier, OnboardingData>(
  (ref) {
    final userProfileManager = ref.read(userProfileManagerProvider.notifier);
    return OnboardingStateNotifier(userProfileManager);
  },
);

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

class UserProfileManager extends StateNotifier<UserProfile?> {
  UserProfileManager() : super(null);

  // 根据手机号加载用户档案
  Future<void> loadUserProfile(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileKey = 'user_profile_$phoneNumber';
      final profileJson = prefs.getString(userProfileKey);
      
      if (profileJson != null) {
        final profileData = json.decode(profileJson) as Map<String, dynamic>;
        state = UserProfile.fromJson(profileData);
        print('已加载用户档案: ${state?.phoneNumber}, 角色: ${state?.userRole}');
      } else {
        // 新用户，创建默认档案
        state = UserProfile(
          phoneNumber: phoneNumber,
          lastLoginTime: DateTime.now(),
        );
        print('创建新用户档案: $phoneNumber');
      }
    } catch (e) {
      print('加载用户档案失败: $e');
      // 创建默认档案
      state = UserProfile(
        phoneNumber: phoneNumber,
        lastLoginTime: DateTime.now(),
      );
    }
  }

  // 保存用户档案
  Future<void> saveUserProfile() async {
    if (state == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileKey = 'user_profile_${state!.phoneNumber}';
      final profileJson = json.encode(state!.toJson());
      await prefs.setString(userProfileKey, profileJson);
      print('用户档案已保存: ${state!.phoneNumber}');
    } catch (e) {
      print('保存用户档案失败: $e');
    }
  }

  // 更新用户信息
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    state = updatedProfile;
    await saveUserProfile();
  }

  // 更新用户角色
  Future<void> updateUserRole(String role) async {
    if (state == null) return;
    
    state = state!.copyWith(
      userRole: role,
      lastLoginTime: DateTime.now(),
    );
    await saveUserProfile();
  }

  // 更新目标行业和岗位
  Future<void> updateTargetInfo({
    String? industry,
    String? role,
  }) async {
    if (state == null) return;
    
    state = state!.copyWith(
      targetIndustry: industry,
      targetRole: role,
      lastLoginTime: DateTime.now(),
    );
    await saveUserProfile();
  }

  // 更新简历信息
  Future<void> updateResumeInfo({
    String? resumeText,
    String? jobDescription,
  }) async {
    if (state == null) return;
    
    state = state!.copyWith(
      resumeText: resumeText,
      jobDescription: jobDescription,
      lastLoginTime: DateTime.now(),
    );
    await saveUserProfile();
  }

  // 标记欢迎对话已看
  Future<void> markWelcomeChatSeen() async {
    if (state == null) return;
    
    state = state!.copyWith(
      hasSeenWelcomeChat: true,
      lastLoginTime: DateTime.now(),
    );
    await saveUserProfile();
  }

  // 完成onboarding
  Future<void> completeOnboarding() async {
    if (state == null) return;
    
    state = state!.copyWith(
      isOnboardingCompleted: true,
      lastLoginTime: DateTime.now(),
    );
    await saveUserProfile();
  }

  // 清除用户档案（用于登出或重置）
  void clearUserProfile() {
    state = null;
  }

  // 检查用户是否存在
  Future<bool> userExists(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileKey = 'user_profile_$phoneNumber';
      return prefs.containsKey(userProfileKey);
    } catch (e) {
      print('检查用户是否存在失败: $e');
      return false;
    }
  }

  // 获取所有用户档案（用于管理）
  Future<List<UserProfile>> getAllUserProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('user_profile_'));
      final profiles = <UserProfile>[];
      
      for (final key in keys) {
        final profileJson = prefs.getString(key);
        if (profileJson != null) {
          final profileData = json.decode(profileJson) as Map<String, dynamic>;
          profiles.add(UserProfile.fromJson(profileData));
        }
      }
      
      return profiles;
    } catch (e) {
      print('获取所有用户档案失败: $e');
      return [];
    }
  }
}

// 提供用户档案管理器
final userProfileManagerProvider = StateNotifierProvider<UserProfileManager, UserProfile?>((ref) {
  return UserProfileManager();
});

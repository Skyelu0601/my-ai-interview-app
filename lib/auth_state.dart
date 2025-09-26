import 'package:flutter_riverpod/flutter_riverpod.dart';

// 认证状态类
class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? phoneNumber;
  final String? verificationCode;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.phoneNumber,
    this.verificationCode,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? phoneNumber,
    String? verificationCode,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationCode: verificationCode ?? this.verificationCode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 认证状态管理器
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState());

  // 发送验证码
  Future<void> sendVerificationCode(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 这里应该调用实际的短信服务
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isLoading: false,
        phoneNumber: phoneNumber,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '发送验证码失败: ${e.toString()}',
      );
    }
  }

  // 验证码登录
  Future<void> verifyCodeAndLogin(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 这里应该调用实际的验证API
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟验证成功
      if (code.length >= 4) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          verificationCode: code,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '验证码格式不正确',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '验证失败: ${e.toString()}',
      );
    }
  }

  // 登出
  Future<void> logout() async {
    state = const AuthState();
  }

  // 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 认证状态提供者
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

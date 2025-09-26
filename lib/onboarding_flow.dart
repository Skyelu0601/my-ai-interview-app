import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_screens.dart';
import 'onboarding_state.dart';
import 'mock_interview_screen.dart';
import 'interview_loading_screen.dart';
import 'user_profile_manager.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _canNext {
    final s = ref.watch(onboardingStateProvider);
    if (_index == 0) return s.targetIndustry != null && s.targetRole != null;
    if (_index == 1) return s.resumeFile != null;
    return true;
  }

  void _next() {
    if (_index < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // 完成onboarding，更新用户档案并标记为已完成
      final onboardingState = ref.read(onboardingStateProvider);
      final userProfileManager = ref.read(userProfileManagerProvider.notifier);
      
      // 更新用户档案中的角色信息
      userProfileManager.updateTargetInfo(
        industry: onboardingState.targetIndustry,
        role: onboardingState.targetRole,
      );
      
      // 更新简历信息
      userProfileManager.updateResumeInfo(
        resumeText: onboardingState.resumeText,
        jobDescription: onboardingState.jobDescription,
      );
      
      // 如果用户选择了角色，设置为用户角色
      if (onboardingState.targetRole != null) {
        userProfileManager.updateUserRole(onboardingState.targetRole!);
      }
      
      // 标记onboarding完成
      ref.read(onboardingStateProvider.notifier).completeOnboarding();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InterviewLoadingScreen(),
        ),
      );
      // 延迟跳转到面试界面，给用户时间看到等待界面
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MockInterviewScreen(),
            ),
          );
        }
      });
    }
  }

  void _prev() {
    if (_index > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                IndustryRoleScreen(),
                UploadResumeScreen(),
                JobDescriptionScreen(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (_index > 0)
                  OutlinedButton(
                    onPressed: _prev,
                    child: const Text('上一步'),
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                FilledButton(
                  onPressed: _canNext ? _next : null,
                  child: Text(_index == 2 ? '开始面试练习' : '下一步'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

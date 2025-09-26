import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_screens.dart';
import 'onboarding_state.dart';

class SettingsFlow extends ConsumerStatefulWidget {
  const SettingsFlow({super.key});

  @override
  ConsumerState<SettingsFlow> createState() => _SettingsFlowState();
}

class _SettingsFlowState extends ConsumerState<SettingsFlow> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 延迟初始化，避免在 widget 生命周期中修改 provider
    Future.microtask(() {
      if (mounted) {
        final state = ref.read(onboardingStateProvider);
        if (state.tempTargetIndustry == null && state.tempTargetRole == null) {
          // 只有在没有临时状态时才初始化
          if (state.targetIndustry != null) {
            ref.read(onboardingStateProvider.notifier).updateTempTargetIndustry(state.targetIndustry!);
          }
          if (state.targetRole != null) {
            ref.read(onboardingStateProvider.notifier).updateTempTargetRole(state.targetRole!);
          }
          if (state.resumeFile != null) {
            ref.read(onboardingStateProvider.notifier).updateTempResumeFile(state.resumeFile!);
          }
          if (state.resumeText != null) {
            ref.read(onboardingStateProvider.notifier).updateTempResumeText(state.resumeText!);
          }
          if (state.jobDescription != null) {
            ref.read(onboardingStateProvider.notifier).updateTempJobDescription(state.jobDescription!);
          }
        }
      }
    });
  }

  bool get _canNext {
    final s = ref.watch(onboardingStateProvider);
    if (_index == 0) return s.tempTargetIndustry != null && s.tempTargetRole != null;
    if (_index == 1) return s.tempResumeFile != null;
    return true;
  }

  void _next() {
    if (_index < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // 完成设置，确认临时状态并回到主界面
      ref.read(onboardingStateProvider.notifier).confirmTempSettings();
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _prev() {
    if (_index > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('面试设置'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 直接返回主界面，不清除临时状态
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),
      ),
      body: Column(
        children: [
          // 进度指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_index + 1) / 3,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_index + 1}/3',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
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
                  child: Text(_index == 2 ? '完成设置' : '下一步'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

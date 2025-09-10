import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_screens.dart';
import 'onboarding_state.dart';

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
    if (_index == 0) return s.experienceLevel != null;
    if (_index == 1) return s.targetIndustry != null && s.targetRole != null;
    if (_index == 2) return s.resumeFile != null;
    return true;
  }

  void _next() {
    if (_index < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
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
      appBar: AppBar(title: const Text('Onboarding')),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                ExperienceScreen(),
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
                  onPressed: _canNext
                      ? () {
                          if (_index == 3) {
                            Navigator.pushReplacementNamed(context, '/study');
                          } else {
                            _next();
                          }
                        }
                      : null,
                  child: Text(_index == 3 ? '开始模拟面试' : '下一步'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



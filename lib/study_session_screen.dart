import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'study_session_notifier.dart';
import 'session_report_screen.dart';

class StudySessionScreen extends ConsumerWidget {
  const StudySessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studySessionProvider);
    final theme = Theme.of(context);

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('练习模式')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isLastQuestion = state.currentQuestionIndex == state.questions.length - 1;
    final progress = (state.currentQuestionIndex + 1) / state.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('练习模式'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 进度条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '问题 ${state.currentQuestionIndex + 1} / ${state.questions.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // 主要内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 问题卡片
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '面试问题',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentQuestion.question,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 参考答案区域
                  if (currentQuestion.isAnswerVisible && currentQuestion.aiAnswer != null) ...[
                    Card(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '参考答案',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentQuestion.aiAnswer!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // 操作按钮区域
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 显示参考答案按钮
                        if (!currentQuestion.isAnswerVisible) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: state.isGeneratingAnswer
                                  ? null
                                  : () => ref
                                      .read(studySessionProvider.notifier)
                                      .generateAnswerForQuestion(state.currentQuestionIndex),
                              icon: state.isGeneratingAnswer
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.visibility),
                              label: Text(
                                state.isGeneratingAnswer
                                    ? '正在生成答案...'
                                    : '显示参考答案',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // 下一题按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (isLastQuestion) {
                                // 最后一题，跳转到报告页
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SessionReportScreen(),
                                  ),
                                );
                              } else {
                                // 跳转到下一题
                                ref.read(studySessionProvider.notifier).goToNextQuestion();
                              }
                            },
                            icon: Icon(
                              isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                            ),
                            label: Text(
                              isLastQuestion ? '完成练习' : '下一题',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

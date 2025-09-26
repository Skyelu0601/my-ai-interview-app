import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'interview_state.dart';
import 'onboarding_state.dart';
import 'services/interview_service.dart';
import 'interview_loading_screen.dart';

class MockInterviewScreen extends ConsumerStatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  ConsumerState<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends ConsumerState<MockInterviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _typingController;
  late AnimationController _fadeController;
  Timer? _timer;
  bool _isGeneratingAnswer = false;
  bool _isDisplayingAnswer = false; // 新增：跟踪参考答案是否正在显示
  String _streamingAnswer = '';
  int _currentCharIndex = 0;
  bool _isInitializing = true; // 新增：跟踪初始化状态

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _startTimer();
    _initializeInterview();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final session = ref.read(interviewStateProvider);
      if (session != null && !session.isPaidSession && session.freeTimeRemaining != null) {
        final remaining = session.freeTimeRemaining! - const Duration(seconds: 1);
        if (remaining.inSeconds <= 0) {
          _showPaymentDialog();
          timer.cancel();
        } else {
          ref.read(interviewStateProvider.notifier).updateFreeTimeRemaining(remaining);
        }
      }
    });
  }

  void _initializeInterview() async {
    final onboardingState = ref.read(onboardingStateProvider);
    if (onboardingState.targetRole == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      return;
    }

    try {
      // 生成首批5个问题
      final questions = await ref.read(interviewServiceProvider.notifier).generateQuestions(
        targetRole: onboardingState.targetRole!,
        resumeText: onboardingState.resumeText ?? '',
        jobDescription: onboardingState.jobDescription,
        batchSize: 5,
        isFirstBatch: true,
      );

      // 启动面试会话
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(interviewStateProvider.notifier).startInterview(
        sessionId: sessionId,
        initialQuestions: questions,
        startTime: DateTime.now(),
      );
      
      // 初始化完成，隐藏加载界面
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动面试失败: $e')),
        );
      }
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('免费时间已用完'),
        content: const Text('您的30分钟免费面试时间已用完。升级到付费版本可继续使用。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 返回主界面
              Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            },
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(interviewStateProvider.notifier).upgradeToPaidSession();
            },
            child: const Text('立即升级'),
          ),
        ],
      ),
    );
  }

  void _showReferenceAnswer() async {
    if (_isGeneratingAnswer) return;
    
    final session = ref.read(interviewStateProvider);
    final currentQuestion = session?.currentQuestion;
    if (currentQuestion?.referenceAnswer != null) {
      // 如果已有参考答案，直接显示
      _displayAnswer(currentQuestion!.referenceAnswer!);
      return;
    }

    // 记录当前问题ID，用于验证答案是否匹配
    if (currentQuestion == null) return;
    
    final currentQuestionId = currentQuestion.questionId;
    final currentQuestionText = currentQuestion.question;
    
    // 调试日志
    print('开始生成参考答案 - 问题ID: $currentQuestionId');
    print('问题内容: ${currentQuestionText.substring(0, currentQuestionText.length > 50 ? 50 : currentQuestionText.length)}...');

    setState(() {
      _isGeneratingAnswer = true;
      _isDisplayingAnswer = true; // 开始生成答案时设置显示状态
      _streamingAnswer = '';
      _currentCharIndex = 0;
    });

    try {
      final onboardingState = ref.read(onboardingStateProvider);
      await ref.read(interviewServiceProvider.notifier).generateReferenceAnswer(
        question: currentQuestionText,
        targetRole: onboardingState.targetRole!,
        resumeText: onboardingState.resumeText ?? '',
        jobDescription: onboardingState.jobDescription,
        onChunk: (chunk) {
          // 验证当前问题是否仍然是生成答案时的问题
          final currentSession = ref.read(interviewStateProvider);
          if (currentSession != null && 
              currentSession.currentQuestion?.questionId == currentQuestionId) {
            setState(() {
              _streamingAnswer += chunk;
            });
            _typewriterEffect();
          } else {
            // 调试日志：问题已切换
            print('答案生成中断 - 问题已切换，当前问题ID: ${currentSession?.currentQuestion?.questionId}');
          }
        },
      );
      
      // 再次验证问题是否匹配，然后保存参考答案
      final finalSession = ref.read(interviewStateProvider);
      if (finalSession != null && 
          finalSession.currentQuestion?.questionId == currentQuestionId) {
        // 使用问题ID保存答案，确保答案保存到正确的问题
        print('保存参考答案 - 问题ID: $currentQuestionId');
        ref.read(interviewStateProvider.notifier).updateReferenceAnswerById(currentQuestionId, _streamingAnswer);
      } else {
        print('参考答案保存失败 - 问题已切换，目标问题ID: $currentQuestionId, 当前问题ID: ${finalSession?.currentQuestion?.questionId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成参考答案失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isGeneratingAnswer = false;
        // 注意：不重置 _isDisplayingAnswer，因为可能还有打字机效果在进行
      });
    }
  }

  void _displayAnswer(String answer) {
    setState(() {
      _streamingAnswer = answer;
      _currentCharIndex = answer.length.clamp(0, answer.length); // 确保不超出范围
      _isDisplayingAnswer = false; // 直接显示完整答案，不需要打字机效果
    });
    // 不需要调用 _typewriterEffect()，直接显示完整答案
  }

  void _typewriterEffect() {
    if (_currentCharIndex < _streamingAnswer.length) {
      _typingController.forward().then((_) {
        if (mounted) {
          setState(() {
            _currentCharIndex = (_currentCharIndex + 1).clamp(0, _streamingAnswer.length);
            _isDisplayingAnswer = true; // 正在显示打字机效果
          });
          Future.delayed(const Duration(milliseconds: 30), () {
            if (mounted) {
              _typewriterEffect();
            }
          });
        }
      });
    } else {
      // 打字机效果完成
      setState(() {
        _isDisplayingAnswer = false;
      });
    }
  }

  void _nextQuestion() async {
    final notifier = ref.read(interviewStateProvider.notifier);
    final session = ref.read(interviewStateProvider);
    
    // 如果正在显示参考答案（生成中或打字机效果中），不允许切换
    if (_isGeneratingAnswer || _isDisplayingAnswer) {
      return; // 直接返回，不允许切换
    }
    
    // 检查是否是最后一题
    if (session != null && !session.hasNextQuestion) {
      // 完成面试，记录统计数据
      notifier.completeInterview();
      
      // 显示完成提示并返回主界面
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('面试练习完成！统计数据已更新'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
        
        // 延迟返回主界面
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
          }
        });
      }
      return;
    }
    
    // 先切换到下一题，让用户能够继续
    notifier.nextQuestion();
    setState(() {
      _streamingAnswer = '';
      _currentCharIndex = 0;
      _isDisplayingAnswer = false; // 重置显示状态
    });
    
    // 然后检查是否需要生成更多问题（在后台进行）
    if (session != null && notifier.shouldGenerateMoreQuestions()) {
      // 在后台生成更多问题，不阻塞用户操作
      _generateMoreQuestions();
    }
  }

  Future<void> _generateMoreQuestions() async {
    final session = ref.read(interviewStateProvider);
    if (session == null) return;

    try {
      // 设置生成状态（仅用于UI显示，不阻塞用户操作）
      ref.read(interviewStateProvider.notifier).setGeneratingQuestions(true);
      
      final onboardingState = ref.read(onboardingStateProvider);
      
      // 计算需要生成的问题数量
      final remainingToGenerate = 50 - session.totalQuestionsGenerated;
      final batchSize = remainingToGenerate > 15 ? 15 : remainingToGenerate;
      
      if (batchSize <= 0) {
        ref.read(interviewStateProvider.notifier).setGeneratingQuestions(false);
        return;
      }
      
      // 获取已存在的问题，避免重复
      final existingQuestions = ref.read(interviewStateProvider.notifier).getAllQuestions();
      
      print('开始生成更多问题 - 当前已生成: ${session.totalQuestionsGenerated}, 批次大小: $batchSize, 已存在问题数: ${existingQuestions.length}');
      
      final newQuestions = await ref.read(interviewServiceProvider.notifier).generateMoreQuestions(
        targetRole: onboardingState.targetRole!,
        resumeText: onboardingState.resumeText ?? '',
        jobDescription: onboardingState.jobDescription,
        batchSize: batchSize,
        existingQuestions: existingQuestions,
      );
      
      // 更新问题列表
      ref.read(interviewStateProvider.notifier).updateQuestions(newQuestions);
      
      // 如果还需要更多问题，继续生成（在后台进行）
      final updatedSession = ref.read(interviewStateProvider);
      if (updatedSession != null && 
          updatedSession.totalQuestionsGenerated < 50 && 
          updatedSession.questions.length - updatedSession.currentQuestionIndex <= 5) {
        // 递归生成更多问题（不等待）
        _generateMoreQuestions();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成更多问题失败: $e')),
        );
      }
    } finally {
      ref.read(interviewStateProvider.notifier).setGeneratingQuestions(false);
      // 注意：不设置 setWaitingForNextQuestion(false)，因为用户操作不应该被阻塞
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // 在组件销毁时保存部分练习进度
    final session = ref.read(interviewStateProvider);
    final onboardingState = ref.read(onboardingStateProvider);
    if (session != null && onboardingState.targetRole != null) {
      ref.read(interviewStateProvider.notifier).savePartialProgress(onboardingState.targetRole!);
    }
    
    _typingController.dispose();
    _fadeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(interviewStateProvider);
    final onboardingState = ref.watch(onboardingStateProvider);

    // 如果正在初始化，显示等待界面
    if (_isInitializing) {
      return const InterviewLoadingScreen();
    }

    if (session == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = session.currentQuestion;
    if (currentQuestion == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '面试完成！',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.read(interviewStateProvider.notifier).resetInterview();
                  // 如果是从onboarding直接进入的，需要跳转到主界面
                  // 否则直接pop返回上一级
                  Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                },
                child: const Text('返回主界面'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部状态栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          // 保存部分练习进度
                          final onboardingState = ref.read(onboardingStateProvider);
                          if (onboardingState.targetRole != null) {
                            ref.read(interviewStateProvider.notifier).savePartialProgress(onboardingState.targetRole!);
                          }
                          
                          // 如果是从onboarding直接进入的，返回主界面
                          // 否则直接pop返回上一级
                          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '面试官招才',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              '目标岗位：${onboardingState.targetRole}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 时间显示
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: session.isPaidSession 
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : const Color(0xFFFF9800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          session.isPaidSession 
                              ? '付费用户'
                              : session.freeTimeRemaining != null 
                                  ? _formatDuration(session.freeTimeRemaining!)
                                  : '时间已用完',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: session.isPaidSession 
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 进度条
                  Row(
                    children: [
                      Text(
                        '${session.currentQuestionIndex + 1}/50',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (session.isWaitingForNextQuestion) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '生成中...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: session.progress,
                          backgroundColor: const Color(0xFFE0E0E0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 主内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 问题显示区域
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '面试问题',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  currentQuestion.question,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF1A1A1A),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 参考答案区域
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '参考答案',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const Spacer(),
                                if (!_isGeneratingAnswer && _streamingAnswer.isEmpty)
                                  FilledButton.icon(
                                    onPressed: _showReferenceAnswer,
                                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                                    label: const Text('显示参考答案'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                if (_isGeneratingAnswer)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '生成中...',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _streamingAnswer.isEmpty
                                      ? Container(
                                          key: const ValueKey('empty'),
                                          width: double.infinity,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFE0E0E0),
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  size: 32,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '点击上方按钮查看参考答案',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          key: const ValueKey('answer'),
                                          child: Text(
                                            _streamingAnswer.substring(0, _currentCharIndex.clamp(0, _streamingAnswer.length)),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF1A1A1A),
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 底部按钮
                    Row(
                      children: [
                        if (session.hasPreviousQuestion)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (_isGeneratingAnswer || _isDisplayingAnswer) ? null : () {
                                ref.read(interviewStateProvider.notifier).previousQuestion();
                                setState(() {
                                  _streamingAnswer = '';
                                  _currentCharIndex = 0;
                                  _isDisplayingAnswer = false;
                                });
                              },
                              child: const Text('上一题'),
                            ),
                          ),
                        if (session.hasPreviousQuestion) const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: (session.hasNextQuestion && !_isGeneratingAnswer && !_isDisplayingAnswer) ? _nextQuestion : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              session.hasNextQuestion ? '下一题' : '完成面试',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

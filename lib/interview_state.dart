import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'learning_stats_manager.dart';
import 'partial_practice_manager.dart';

class InterviewQuestion {
  final String question;
  final String? referenceAnswer;
  final bool isCompleted;
  final DateTime? completedAt;
  final String questionId; // 添加唯一ID用于跟踪问题

  const InterviewQuestion({
    required this.question,
    this.referenceAnswer,
    this.isCompleted = false,
    this.completedAt,
    required this.questionId,
  });

  InterviewQuestion copyWith({
    String? question,
    String? referenceAnswer,
    bool? isCompleted,
    DateTime? completedAt,
    String? questionId,
  }) {
    return InterviewQuestion(
      question: question ?? this.question,
      referenceAnswer: referenceAnswer ?? this.referenceAnswer,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      questionId: questionId ?? this.questionId,
    );
  }
}

class InterviewSession {
  final String sessionId;
  final List<InterviewQuestion> questions;
  final int currentQuestionIndex;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool isPaused;
  final Duration? freeTimeRemaining;
  final bool isPaidSession;
  final bool isGeneratingQuestions;
  final bool isWaitingForNextQuestion; // 新增：用户点击下一题但问题未准备好
  final int totalQuestionsGenerated;

  const InterviewSession({
    required this.sessionId,
    required this.questions,
    this.currentQuestionIndex = 0,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.isPaused = false,
    this.freeTimeRemaining,
    this.isPaidSession = false,
    this.isGeneratingQuestions = false,
    this.isWaitingForNextQuestion = false,
    this.totalQuestionsGenerated = 0,
  });

  InterviewSession copyWith({
    String? sessionId,
    List<InterviewQuestion>? questions,
    int? currentQuestionIndex,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    bool? isPaused,
    Duration? freeTimeRemaining,
    bool? isPaidSession,
    bool? isGeneratingQuestions,
    bool? isWaitingForNextQuestion,
    int? totalQuestionsGenerated,
  }) {
    return InterviewSession(
      sessionId: sessionId ?? this.sessionId,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isPaused: isPaused ?? this.isPaused,
      freeTimeRemaining: freeTimeRemaining ?? this.freeTimeRemaining,
      isPaidSession: isPaidSession ?? this.isPaidSession,
      isGeneratingQuestions: isGeneratingQuestions ?? this.isGeneratingQuestions,
      isWaitingForNextQuestion: isWaitingForNextQuestion ?? this.isWaitingForNextQuestion,
      totalQuestionsGenerated: totalQuestionsGenerated ?? this.totalQuestionsGenerated,
    );
  }

  InterviewQuestion? get currentQuestion {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  bool get hasNextQuestion => currentQuestionIndex < questions.length - 1;
  bool get hasPreviousQuestion => currentQuestionIndex > 0;
  double get progress => (currentQuestionIndex + 1) / 50.0;
}

class InterviewStateNotifier extends StateNotifier<InterviewSession?> {
  final LearningStatsManager _statsManager;
  final PartialPracticeManager _partialPracticeManager;
  
  InterviewStateNotifier(this._statsManager, this._partialPracticeManager) : super(null);

  void startInterview({
    required String sessionId,
    required List<String> initialQuestions,
    required DateTime startTime,
  }) {
    final questions = initialQuestions.asMap().entries.map((entry) => 
      InterviewQuestion(
        question: entry.value,
        questionId: '${sessionId}_${entry.key}',
      )
    ).toList();
    
    state = InterviewSession(
      sessionId: sessionId,
      questions: questions,
      startTime: startTime,
      freeTimeRemaining: const Duration(minutes: 30),
      totalQuestionsGenerated: initialQuestions.length,
    );
  }

  void updateQuestions(List<String> newQuestions) {
    if (state == null) return;
    
    final updatedQuestions = <InterviewQuestion>[];
    
    // Keep existing questions with their state
    for (int i = 0; i < state!.questions.length; i++) {
      updatedQuestions.add(state!.questions[i]);
    }
    
    // Add new questions with unique IDs
    for (int i = 0; i < newQuestions.length; i++) {
      final questionIndex = state!.questions.length + i;
      updatedQuestions.add(InterviewQuestion(
        question: newQuestions[i],
        questionId: '${state!.sessionId}_$questionIndex',
      ));
    }
    
    state = state!.copyWith(
      questions: updatedQuestions,
      totalQuestionsGenerated: state!.totalQuestionsGenerated + newQuestions.length,
      isGeneratingQuestions: false,
      // 注意：不设置 isWaitingForNextQuestion: false，因为用户操作不应该被阻塞
    );
  }

  void setGeneratingQuestions(bool isGenerating) {
    if (state == null) return;
    state = state!.copyWith(isGeneratingQuestions: isGenerating);
  }

  void setWaitingForNextQuestion(bool isWaiting) {
    if (state == null) return;
    state = state!.copyWith(isWaitingForNextQuestion: isWaiting);
  }

  bool shouldGenerateMoreQuestions() {
    if (state == null) return false;
    
    // 如果正在生成问题，不重复生成
    if (state!.isGeneratingQuestions) return false;
    
    // 如果已经生成了足够的问题（50个），不再生成
    if (state!.totalQuestionsGenerated >= 50) return false;
    
    // 优化触发规则：在剩余5个问题时就开始生成下一批
    // 这样可以确保用户无需等待，面试流程更流畅
    final remainingQuestions = state!.questions.length - state!.currentQuestionIndex;
    return remainingQuestions <= 5;
  }

  List<String> getAllQuestions() {
    if (state == null) return [];
    return state!.questions.map((q) => q.question).toList();
  }

  void nextQuestion() {
    if (state == null || !state!.hasNextQuestion) return;
    
    final updatedQuestions = List<InterviewQuestion>.from(state!.questions);
    if (state!.currentQuestionIndex < updatedQuestions.length) {
      updatedQuestions[state!.currentQuestionIndex] = updatedQuestions[state!.currentQuestionIndex]
          .copyWith(isCompleted: true, completedAt: DateTime.now());
    }
    
    state = state!.copyWith(
      questions: updatedQuestions,
      currentQuestionIndex: state!.currentQuestionIndex + 1,
      isWaitingForNextQuestion: false, // 切换到下一题后，取消等待状态
    );
  }

  void previousQuestion() {
    if (state == null || !state!.hasPreviousQuestion) return;
    
    state = state!.copyWith(
      currentQuestionIndex: state!.currentQuestionIndex - 1,
    );
  }

  void updateReferenceAnswer(String answer) {
    if (state == null || state!.currentQuestionIndex >= state!.questions.length) return;
    
    final updatedQuestions = List<InterviewQuestion>.from(state!.questions);
    updatedQuestions[state!.currentQuestionIndex] = updatedQuestions[state!.currentQuestionIndex]
        .copyWith(referenceAnswer: answer);
    
    state = state!.copyWith(questions: updatedQuestions);
  }

  void updateReferenceAnswerById(String questionId, String answer) {
    if (state == null) return;
    
    final updatedQuestions = List<InterviewQuestion>.from(state!.questions);
    final questionIndex = updatedQuestions.indexWhere((q) => q.questionId == questionId);
    
    print('尝试保存答案 - 问题ID: $questionId, 找到索引: $questionIndex');
    
    if (questionIndex != -1) {
      updatedQuestions[questionIndex] = updatedQuestions[questionIndex]
          .copyWith(referenceAnswer: answer);
      
      state = state!.copyWith(questions: updatedQuestions);
      print('答案保存成功 - 问题: ${updatedQuestions[questionIndex].question.substring(0, updatedQuestions[questionIndex].question.length > 30 ? 30 : updatedQuestions[questionIndex].question.length)}...');
    } else {
      print('答案保存失败 - 未找到问题ID: $questionId');
    }
  }

  void pauseInterview() {
    if (state == null) return;
    state = state!.copyWith(isPaused: true);
  }

  void resumeInterview() {
    if (state == null) return;
    state = state!.copyWith(isPaused: false);
  }

  void updateFreeTimeRemaining(Duration remaining) {
    if (state == null) return;
    state = state!.copyWith(freeTimeRemaining: remaining);
  }

  void upgradeToPaidSession() {
    if (state == null) return;
    state = state!.copyWith(isPaidSession: true, freeTimeRemaining: null);
  }

  void completeInterview() {
    if (state == null) return;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(state!.startTime);
    final durationMinutes = duration.inMinutes;
    
    // 计算完成的题目数量
    final completedQuestions = state!.questions.where((q) => q.isCompleted).length;
    
    // 记录学习统计数据
    _statsManager.recordPractice(
      duration: durationMinutes,
      questionCount: completedQuestions,
      correctCount: completedQuestions, // 假设所有完成的题目都是"正确"的
    );
    
    state = state!.copyWith(
      isCompleted: true,
      endTime: endTime,
    );
  }

  /// 保存部分练习进度（用户退出时调用）
  void savePartialProgress(String targetRole) {
    if (state == null) return;
    
    // 创建部分练习记录
    _partialPracticeManager.createFromInterviewSession(state!, targetRole);
    
    print('已保存部分练习进度: 完成${state!.questions.where((q) => q.isCompleted).length}题');
  }

  /// 从部分练习会话恢复面试
  void restoreFromPartialSession(PartialPracticeSession partialSession, List<String> questions) {
    final now = DateTime.now();
    
    // 创建面试问题列表，标记已完成的问题
    final interviewQuestions = <InterviewQuestion>[];
    for (int i = 0; i < questions.length; i++) {
      final questionId = '${partialSession.sessionId}_$i';
      final isCompleted = partialSession.completedQuestionIds.contains(questionId);
      
      interviewQuestions.add(InterviewQuestion(
        question: questions[i],
        questionId: questionId,
        isCompleted: isCompleted,
        completedAt: isCompleted ? partialSession.lastActiveTime : null,
      ));
    }
    
    // 计算当前问题索引（第一个未完成的问题）
    final currentIndex = interviewQuestions.indexWhere((q) => !q.isCompleted);
    final finalIndex = currentIndex == -1 ? interviewQuestions.length - 1 : currentIndex;
    
    state = InterviewSession(
      sessionId: partialSession.sessionId,
      questions: interviewQuestions,
      currentQuestionIndex: finalIndex,
      startTime: partialSession.startTime,
      freeTimeRemaining: const Duration(minutes: 30), // 重置免费时间
      totalQuestionsGenerated: questions.length,
    );
    
    print('已恢复部分练习会话: 当前第${finalIndex + 1}题');
  }

  void resetInterview() {
    state = null;
  }
}

final interviewStateProvider = StateNotifierProvider<InterviewStateNotifier, InterviewSession?>(
  (ref) => InterviewStateNotifier(
    ref.read(learningStatsProvider.notifier),
    ref.read(partialPracticeProvider.notifier),
  ),
);

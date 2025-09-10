class InterviewQuestion {
  final String question;
  String? aiAnswer; // 初始为null，点击后生成
  bool isAnswerVisible;

  InterviewQuestion({
    required this.question,
    this.aiAnswer,
    this.isAnswerVisible = false,
  });

  InterviewQuestion copyWith({
    String? question,
    String? aiAnswer,
    bool? isAnswerVisible,
  }) {
    return InterviewQuestion(
      question: question ?? this.question,
      aiAnswer: aiAnswer ?? this.aiAnswer,
      isAnswerVisible: isAnswerVisible ?? this.isAnswerVisible,
    );
  }
}

class StudySessionState {
  final List<InterviewQuestion> questions;
  final int currentQuestionIndex;
  final bool isGeneratingQuestions; // 用于显示生成新题的加载态
  final int completedSessionCount; // 记录完成了几轮练习
  final bool isGeneratingAnswer; // 用于显示生成答案的加载态

  const StudySessionState({
    required this.questions,
    required this.currentQuestionIndex,
    required this.isGeneratingQuestions,
    required this.completedSessionCount,
    required this.isGeneratingAnswer,
  });

  StudySessionState copyWith({
    List<InterviewQuestion>? questions,
    int? currentQuestionIndex,
    bool? isGeneratingQuestions,
    int? completedSessionCount,
    bool? isGeneratingAnswer,
  }) {
    return StudySessionState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isGeneratingQuestions: isGeneratingQuestions ?? this.isGeneratingQuestions,
      completedSessionCount: completedSessionCount ?? this.completedSessionCount,
      isGeneratingAnswer: isGeneratingAnswer ?? this.isGeneratingAnswer,
    );
  }

  // 初始状态
  static const StudySessionState initial = StudySessionState(
    questions: [],
    currentQuestionIndex: 0,
    isGeneratingQuestions: false,
    completedSessionCount: 0,
    isGeneratingAnswer: false,
  );
}

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interview_state.dart';
import 'learning_stats_manager.dart';

/// 部分练习会话数据
class PartialPracticeSession {
  final String sessionId;
  final String targetRole;
  final DateTime startTime;
  final DateTime? lastActiveTime;
  final int completedQuestions;
  final int totalQuestionsGenerated;
  final Duration totalDuration;
  final List<String> completedQuestionIds;
  final bool isCompleted;

  const PartialPracticeSession({
    required this.sessionId,
    required this.targetRole,
    required this.startTime,
    this.lastActiveTime,
    this.completedQuestions = 0,
    this.totalQuestionsGenerated = 0,
    this.totalDuration = Duration.zero,
    this.completedQuestionIds = const [],
    this.isCompleted = false,
  });

  PartialPracticeSession copyWith({
    String? sessionId,
    String? targetRole,
    DateTime? startTime,
    DateTime? lastActiveTime,
    int? completedQuestions,
    int? totalQuestionsGenerated,
    Duration? totalDuration,
    List<String>? completedQuestionIds,
    bool? isCompleted,
  }) {
    return PartialPracticeSession(
      sessionId: sessionId ?? this.sessionId,
      targetRole: targetRole ?? this.targetRole,
      startTime: startTime ?? this.startTime,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      totalQuestionsGenerated: totalQuestionsGenerated ?? this.totalQuestionsGenerated,
      totalDuration: totalDuration ?? this.totalDuration,
      completedQuestionIds: completedQuestionIds ?? this.completedQuestionIds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'targetRole': targetRole,
      'startTime': startTime.toIso8601String(),
      'lastActiveTime': lastActiveTime?.toIso8601String(),
      'completedQuestions': completedQuestions,
      'totalQuestionsGenerated': totalQuestionsGenerated,
      'totalDuration': totalDuration.inMinutes,
      'completedQuestionIds': completedQuestionIds,
      'isCompleted': isCompleted,
    };
  }

  factory PartialPracticeSession.fromJson(Map<String, dynamic> json) {
    return PartialPracticeSession(
      sessionId: json['sessionId'] ?? '',
      targetRole: json['targetRole'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      lastActiveTime: json['lastActiveTime'] != null 
          ? DateTime.parse(json['lastActiveTime']) 
          : null,
      completedQuestions: json['completedQuestions'] ?? 0,
      totalQuestionsGenerated: json['totalQuestionsGenerated'] ?? 0,
      totalDuration: Duration(minutes: json['totalDuration'] ?? 0),
      completedQuestionIds: List<String>.from(json['completedQuestionIds'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  /// 计算完成率
  double get completionRate {
    if (totalQuestionsGenerated == 0) return 0.0;
    return completedQuestions / totalQuestionsGenerated;
  }

  /// 获取格式化的时长
  String get formattedDuration {
    final minutes = totalDuration.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}小时${remainingMinutes}分钟';
    } else {
      return '${minutes}分钟';
    }
  }
}

/// 部分练习管理器
class PartialPracticeManager extends StateNotifier<List<PartialPracticeSession>> {
  final LearningStatsManager _statsManager;
  
  PartialPracticeManager(this._statsManager) : super([]) {
    _loadSessions();
  }

  /// 从本地存储加载部分练习会话
  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('partial_practice_sessions');
      
      if (sessionsJson != null) {
        final sessionsData = json.decode(sessionsJson) as List;
        state = sessionsData
            .map((data) => PartialPracticeSession.fromJson(data as Map<String, dynamic>))
            .toList();
        print('已加载${state.length}个部分练习会话');
      }
    } catch (e) {
      print('加载部分练习会话失败: $e');
      state = [];
    }
  }

  /// 保存部分练习会话到本地存储
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = json.encode(state.map((session) => session.toJson()).toList());
      await prefs.setString('partial_practice_sessions', sessionsJson);
      print('部分练习会话已保存');
    } catch (e) {
      print('保存部分练习会话失败: $e');
    }
  }

  /// 从面试会话创建部分练习记录
  void createFromInterviewSession(InterviewSession interviewSession, String targetRole) {
    final now = DateTime.now();
    final duration = now.difference(interviewSession.startTime);
    
    // 计算完成的题目
    final completedQuestions = interviewSession.questions.where((q) => q.isCompleted).length;
    final completedQuestionIds = interviewSession.questions
        .where((q) => q.isCompleted)
        .map((q) => q.questionId)
        .toList();

    final partialSession = PartialPracticeSession(
      sessionId: interviewSession.sessionId,
      targetRole: targetRole,
      startTime: interviewSession.startTime,
      lastActiveTime: now,
      completedQuestions: completedQuestions,
      totalQuestionsGenerated: interviewSession.totalQuestionsGenerated,
      totalDuration: duration,
      completedQuestionIds: completedQuestionIds,
      isCompleted: interviewSession.isCompleted,
    );

    // 检查是否已存在相同会话ID的记录
    final existingIndex = state.indexWhere((s) => s.sessionId == interviewSession.sessionId);
    
    if (existingIndex != -1) {
      // 更新现有记录
      state = [
        ...state.sublist(0, existingIndex),
        partialSession,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // 添加新记录
      state = [partialSession, ...state];
    }

    _saveSessions();
    
    // 记录到学习统计中
    _statsManager.recordPartialPractice(
      duration: duration.inMinutes,
      questionCount: completedQuestions,
    );
    
    print('创建部分练习记录: 完成${completedQuestions}题, 时长${duration.inMinutes}分钟');
  }

  /// 更新部分练习会话
  void updateSession(String sessionId, {
    int? completedQuestions,
    int? totalQuestionsGenerated,
    Duration? totalDuration,
    List<String>? completedQuestionIds,
    bool? isCompleted,
  }) {
    final sessionIndex = state.indexWhere((s) => s.sessionId == sessionId);
    if (sessionIndex == -1) return;

    final session = state[sessionIndex];
    state = [
      ...state.sublist(0, sessionIndex),
      session.copyWith(
        lastActiveTime: DateTime.now(),
        completedQuestions: completedQuestions,
        totalQuestionsGenerated: totalQuestionsGenerated,
        totalDuration: totalDuration,
        completedQuestionIds: completedQuestionIds,
        isCompleted: isCompleted,
      ),
      ...state.sublist(sessionIndex + 1),
    ];

    _saveSessions();
  }

  /// 获取最新的部分练习会话
  PartialPracticeSession? get latestSession {
    if (state.isEmpty) return null;
    return state.first;
  }

  /// 获取指定角色的部分练习会话
  List<PartialPracticeSession> getSessionsByRole(String targetRole) {
    return state.where((s) => s.targetRole == targetRole).toList();
  }

  /// 获取未完成的会话
  List<PartialPracticeSession> get incompleteSessions {
    return state.where((s) => !s.isCompleted).toList();
  }

  /// 获取总练习统计
  Map<String, dynamic> get totalStats {
    if (state.isEmpty) {
      return {
        'totalSessions': 0,
        'totalDuration': Duration.zero,
        'totalQuestions': 0,
        'averageCompletionRate': 0.0,
      };
    }

    final totalDuration = state.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.totalDuration,
    );
    
    final totalQuestions = state.fold<int>(
      0,
      (sum, session) => sum + session.completedQuestions,
    );

    final averageCompletionRate = state.fold<double>(
      0.0,
      (sum, session) => sum + session.completionRate,
    ) / state.length;

    return {
      'totalSessions': state.length,
      'totalDuration': totalDuration,
      'totalQuestions': totalQuestions,
      'averageCompletionRate': averageCompletionRate,
    };
  }

  /// 删除指定会话
  void deleteSession(String sessionId) {
    state = state.where((s) => s.sessionId != sessionId).toList();
    _saveSessions();
  }

  /// 清空所有会话
  void clearAllSessions() {
    state = [];
    _saveSessions();
  }

  /// 恢复指定的部分练习会话
  PartialPracticeSession? getSessionById(String sessionId) {
    try {
      return state.firstWhere((s) => s.sessionId == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// 删除指定的部分练习会话
  void deleteSessionById(String sessionId) {
    state = state.where((s) => s.sessionId != sessionId).toList();
    _saveSessions();
  }
}

/// 提供部分练习管理器
final partialPracticeProvider = StateNotifierProvider<PartialPracticeManager, List<PartialPracticeSession>>((ref) {
  return PartialPracticeManager(ref.read(learningStatsProvider.notifier));
});

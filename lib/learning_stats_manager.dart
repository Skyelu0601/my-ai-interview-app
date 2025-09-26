import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningStats {
  final int practiceCount; // 练习次数
  final int totalDuration; // 总练习时长（分钟）
  final int totalQuestions; // 总练习题目数量
  final int correctAnswers; // 正确答案数量
  final DateTime lastPracticeTime; // 最后练习时间
  final int consecutiveDays; // 连续练习天数
  final DateTime lastUpdateDate; // 最后更新日期
  final int partialPracticeCount; // 部分练习次数
  final int partialPracticeDuration; // 部分练习总时长（分钟）
  final int partialPracticeQuestions; // 部分练习题目数量

  const LearningStats({
    this.practiceCount = 0,
    this.totalDuration = 0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    required this.lastPracticeTime,
    this.consecutiveDays = 0,
    required this.lastUpdateDate,
    this.partialPracticeCount = 0,
    this.partialPracticeDuration = 0,
    this.partialPracticeQuestions = 0,
  });

  LearningStats copyWith({
    int? practiceCount,
    int? totalDuration,
    int? totalQuestions,
    int? correctAnswers,
    DateTime? lastPracticeTime,
    int? consecutiveDays,
    DateTime? lastUpdateDate,
    int? partialPracticeCount,
    int? partialPracticeDuration,
    int? partialPracticeQuestions,
  }) {
    return LearningStats(
      practiceCount: practiceCount ?? this.practiceCount,
      totalDuration: totalDuration ?? this.totalDuration,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      lastPracticeTime: lastPracticeTime ?? this.lastPracticeTime,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      partialPracticeCount: partialPracticeCount ?? this.partialPracticeCount,
      partialPracticeDuration: partialPracticeDuration ?? this.partialPracticeDuration,
      partialPracticeQuestions: partialPracticeQuestions ?? this.partialPracticeQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceCount': practiceCount,
      'totalDuration': totalDuration,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'lastPracticeTime': lastPracticeTime.toIso8601String(),
      'consecutiveDays': consecutiveDays,
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
      'partialPracticeCount': partialPracticeCount,
      'partialPracticeDuration': partialPracticeDuration,
      'partialPracticeQuestions': partialPracticeQuestions,
    };
  }

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      practiceCount: json['practiceCount'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      lastPracticeTime: DateTime.parse(json['lastPracticeTime'] ?? DateTime.now().toIso8601String()),
      consecutiveDays: json['consecutiveDays'] ?? 0,
      lastUpdateDate: DateTime.parse(json['lastUpdateDate'] ?? DateTime.now().toIso8601String()),
      partialPracticeCount: json['partialPracticeCount'] ?? 0,
      partialPracticeDuration: json['partialPracticeDuration'] ?? 0,
      partialPracticeQuestions: json['partialPracticeQuestions'] ?? 0,
    );
  }

  // 计算准确率
  double get accuracyRate {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions * 100);
  }

  // 计算平均每次练习时长
  double get averageDuration {
    if (practiceCount == 0) return 0.0;
    return totalDuration / practiceCount;
  }

  // 计算平均每次练习题目数
  double get averageQuestions {
    if (practiceCount == 0) return 0.0;
    return totalQuestions / practiceCount;
  }

  // 计算总练习时长（包括部分练习）
  int get totalPracticeDuration => totalDuration + partialPracticeDuration;

  // 计算总练习题目数（包括部分练习）
  int get totalPracticeQuestions => totalQuestions + partialPracticeQuestions;

  // 计算总练习次数（包括部分练习）
  int get totalPracticeCount => practiceCount + partialPracticeCount;
}

class LearningStatsManager extends StateNotifier<LearningStats> {
  LearningStatsManager() : super(LearningStats(
    lastPracticeTime: DateTime.now(),
    lastUpdateDate: DateTime.now(),
  )) {
    _loadStats();
  }

  // 从本地存储加载统计数据
  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('learning_stats');
      
      if (statsJson != null) {
        final statsData = json.decode(statsJson) as Map<String, dynamic>;
        state = LearningStats.fromJson(statsData);
        print('已加载学习统计数据: 练习${state.practiceCount}次, 时长${state.totalDuration}分钟');
      } else {
        // 新用户，创建默认统计
        state = LearningStats(
          lastPracticeTime: DateTime.now(),
          lastUpdateDate: DateTime.now(),
        );
        print('创建新的学习统计数据');
      }
    } catch (e) {
      print('加载学习统计数据失败: $e');
      state = LearningStats(
        lastPracticeTime: DateTime.now(),
        lastUpdateDate: DateTime.now(),
      );
    }
  }

  // 保存统计数据到本地存储
  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = json.encode(state.toJson());
      await prefs.setString('learning_stats', statsJson);
      print('学习统计数据已保存');
    } catch (e) {
      print('保存学习统计数据失败: $e');
    }
  }

  // 更新连续练习天数
  void _updateConsecutiveDays() {
    final now = DateTime.now();
    final lastDate = state.lastUpdateDate;
    
    // 计算日期差
    final daysDifference = now.difference(lastDate).inDays;
    
    if (daysDifference == 1) {
      // 连续练习
      state = state.copyWith(
        consecutiveDays: state.consecutiveDays + 1,
        lastUpdateDate: now,
      );
    } else if (daysDifference > 1) {
      // 中断了连续练习
      state = state.copyWith(
        consecutiveDays: 1,
        lastUpdateDate: now,
      );
    }
    // 如果是同一天，不更新连续天数
  }

  // 记录一次练习
  void recordPractice({
    required int duration, // 练习时长（分钟）
    required int questionCount, // 题目数量
    required int correctCount, // 正确答案数量
  }) {
    final now = DateTime.now();
    
    // 更新连续练习天数
    _updateConsecutiveDays();
    
    state = state.copyWith(
      practiceCount: state.practiceCount + 1,
      totalDuration: state.totalDuration + duration,
      totalQuestions: state.totalQuestions + questionCount,
      correctAnswers: state.correctAnswers + correctCount,
      lastPracticeTime: now,
    );
    
    _saveStats();
    print('记录练习: 时长${duration}分钟, 题目${questionCount}道, 正确${correctCount}道');
  }

  // 记录部分练习
  void recordPartialPractice({
    required int duration, // 练习时长（分钟）
    required int questionCount, // 题目数量
  }) {
    final now = DateTime.now();
    
    // 更新连续练习天数
    _updateConsecutiveDays();
    
    state = state.copyWith(
      partialPracticeCount: state.partialPracticeCount + 1,
      partialPracticeDuration: state.partialPracticeDuration + duration,
      partialPracticeQuestions: state.partialPracticeQuestions + questionCount,
      lastPracticeTime: now,
    );
    
    _saveStats();
    print('记录部分练习: 时长${duration}分钟, 题目${questionCount}道');
  }

  // 重置统计数据
  void resetStats() {
    state = LearningStats(
      lastPracticeTime: DateTime.now(),
      lastUpdateDate: DateTime.now(),
    );
    _saveStats();
    print('学习统计数据已重置');
  }

  // 获取格式化的时长字符串
  String getFormattedDuration() {
    final hours = state.totalDuration ~/ 60;
    final minutes = state.totalDuration % 60;
    
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else {
      return '${minutes}分钟';
    }
  }

  // 获取格式化的平均时长字符串
  String getFormattedAverageDuration() {
    final avgMinutes = state.averageDuration.round();
    if (avgMinutes >= 60) {
      final hours = avgMinutes ~/ 60;
      final minutes = avgMinutes % 60;
      return '${hours}小时${minutes}分钟';
    } else {
      return '${avgMinutes}分钟';
    }
  }
}

// 提供学习统计管理器
final learningStatsProvider = StateNotifierProvider<LearningStatsManager, LearningStats>((ref) {
  return LearningStatsManager();
});

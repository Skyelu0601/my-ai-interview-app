import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'learning_stats_manager.dart';
import 'partial_practice_manager.dart';
import 'interview_state.dart';
import 'services/interview_service.dart';
import 'mock_interview_screen.dart';

class LearningStatsWidget extends ConsumerWidget {
  const LearningStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(learningStatsProvider);
    final partialSessions = ref.watch(partialPracticeProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '学习统计',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              // 测试按钮（开发用）
              GestureDetector(
                onTap: () {
                  ref.read(learningStatsProvider.notifier).recordPractice(
                    duration: 5,
                    questionCount: 3,
                    correctCount: 3,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '测试+1',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 统计卡片网格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                context,
                '总时长',
                _formatDuration(stats.totalPracticeDuration),
                '',
                Icons.access_time,
                const Color(0xFF2196F3),
              ),
              _buildStatCard(
                context,
                '练习题目',
                '${stats.totalPracticeQuestions}',
                '道',
                Icons.quiz_outlined,
                const Color(0xFFFF9800),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 连续练习天数
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1976D2).withOpacity(0.1),
                  const Color(0xFF1976D2).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1976D2).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '连续练习',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.consecutiveDays} 天',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (stats.consecutiveDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStreakMessage(stats.consecutiveDays),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 部分练习进度显示
          if (partialSessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPartialPracticeSection(context, ref, partialSessions),
          ],
          
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h${remainingMinutes}m';
      }
    } else {
      return '${minutes}m';
    }
  }

  String _getStreakMessage(int days) {
    if (days >= 30) return '🔥 坚持达人';
    if (days >= 14) return '💪 持续进步';
    if (days >= 7) return '⭐ 一周坚持';
    if (days >= 3) return '🎯 渐入佳境';
    return '🚀 开始练习';
  }

  Widget _buildLatestSessionCard(BuildContext context, WidgetRef ref, PartialPracticeSession latestSession) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                latestSession.targetRole,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${(latestSession.completionRate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '已完成 ${latestSession.completedQuestions} 题 • ${latestSession.formattedDuration}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: latestSession.completionRate,
            backgroundColor: const Color(0xFFFF9800).withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _resumePractice(context, ref, latestSession),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('继续练习'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialPracticeSection(BuildContext context, WidgetRef ref, List<PartialPracticeSession> sessions) {
    final incompleteSessions = sessions.where((s) => !s.isCompleted).toList();
    
    if (incompleteSessions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9800).withOpacity(0.1),
            const Color(0xFFFF9800).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pause_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '未完成练习',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${incompleteSessions.length}个',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 显示最新的未完成练习
          if (incompleteSessions.isNotEmpty)
            _buildLatestSessionCard(context, ref, incompleteSessions.first),
        ],
      ),
    );
  }

  Future<void> _resumePractice(BuildContext context, WidgetRef ref, PartialPracticeSession session) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在恢复练习...'),
            ],
          ),
        ),
      );

      // 重新生成问题（使用相同的参数）
      final questions = await ref.read(interviewServiceProvider.notifier).generateQuestions(
        targetRole: session.targetRole,
        resumeText: '', // 这里可以存储更多信息来恢复
        jobDescription: null,
        batchSize: session.totalQuestionsGenerated,
        isFirstBatch: true,
      );

      // 恢复面试会话
      ref.read(interviewStateProvider.notifier).restoreFromPartialSession(session, questions);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 跳转到面试界面
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MockInterviewScreen(),
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误信息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复练习失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'onboarding_state.dart';
import 'study_mode_data.dart';

class StudySessionNotifier extends StateNotifier<StudySessionState> {
  StudySessionNotifier(this.ref) : super(StudySessionState.initial);

  final Ref ref;

  // DeepSeek API配置
  static const String _apiKey = 'YOUR_DEEPSEEK_API_KEY'; // 请替换为实际API Key
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  /// 生成面试问题
  Future<void> generateQuestions() async {
    state = state.copyWith(isGeneratingQuestions: true);

    try {
      // 1. 从OnboardingStateNotifier中获取用户数据
      final onboardingData = ref.read(onboardingStateProvider);

      // 2. 构建LLM Prompt
      final prompt = '''
# Role: 资深面试官
# Candidate Background: 工作经验: ${onboardingData.experienceLevel}, 应聘岗位: ${onboardingData.targetRole}
# Resume: ${onboardingData.resumeFile?.path ?? '未上传简历'}
# Job Description: ${onboardingData.jobDescription ?? '未提供'}
# Task: 生成10个高度个性化的面试问题列表，涵盖行为、技术、情境问题。
# Requirement: 输出必须严格是JSON数组格式: ["问题1", "问题2", ...]
''';

      // 3. 调用DeepSeek-V3 API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // 4. 解析返回的JSON，转换为List<InterviewQuestion>
        final List<dynamic> questionsJson = jsonDecode(content);
        final List<InterviewQuestion> newQuestions = questionsJson
            .map((q) => InterviewQuestion(question: q.toString()))
            .toList();

        // 5. 更新状态
        state = state.copyWith(
          questions: newQuestions,
          currentQuestionIndex: 0,
          isGeneratingQuestions: false,
        );
      } else {
        throw Exception('API调用失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，使用预设问题作为fallback
      final fallbackQuestions = _getFallbackQuestions();
      state = state.copyWith(
        questions: fallbackQuestions,
        currentQuestionIndex: 0,
        isGeneratingQuestions: false,
      );
      print('AI生成失败，使用预设问题: $e');
    }
  }

  /// 为指定问题生成参考答案
  Future<void> generateAnswerForQuestion(int questionIndex) async {
    if (questionIndex >= state.questions.length) return;

    state = state.copyWith(isGeneratingAnswer: true);

    try {
      final question = state.questions[questionIndex].question;
      final onboardingData = ref.read(onboardingStateProvider);

      final prompt = '''
# Role: 资深面试官
# 问题: $question
# 候选人背景: 工作经验: ${onboardingData.experienceLevel}, 应聘岗位: ${onboardingData.targetRole}
# 任务: 为这个问题提供一个高质量的参考答案，包含STAR方法（Situation, Task, Action, Result）
# 要求: 答案应该具体、有说服力，适合该候选人的经验水平
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.5,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];

        // 更新对应问题的答案
        final updatedQuestions = List<InterviewQuestion>.from(state.questions);
        updatedQuestions[questionIndex] = updatedQuestions[questionIndex].copyWith(
          aiAnswer: answer,
          isAnswerVisible: true,
        );

        state = state.copyWith(
          questions: updatedQuestions,
          isGeneratingAnswer: false,
        );
      } else {
        throw Exception('API调用失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，使用预设答案
      final fallbackAnswer = _getFallbackAnswer(state.questions[questionIndex].question);
      final updatedQuestions = List<InterviewQuestion>.from(state.questions);
      updatedQuestions[questionIndex] = updatedQuestions[questionIndex].copyWith(
        aiAnswer: fallbackAnswer,
        isAnswerVisible: true,
      );

      state = state.copyWith(
        questions: updatedQuestions,
        isGeneratingAnswer: false,
      );
      print('AI生成答案失败，使用预设答案: $e');
    }
  }

  /// 跳转到下一题
  void goToNextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  /// 开始新的练习会话
  void startNewSession() {
    state = state.copyWith(
      completedSessionCount: state.completedSessionCount + 1,
      questions: [],
      currentQuestionIndex: 0,
      isGeneratingQuestions: false,
      isGeneratingAnswer: false,
    );
  }

  /// 获取预设问题（API失败时的fallback）
  List<InterviewQuestion> _getFallbackQuestions() {
    return [
      '请介绍一下您自己',
      '为什么选择我们公司？',
      '您最大的优点和缺点是什么？',
      '描述一次您解决困难问题的经历',
      '您如何应对工作压力？',
      '您的职业规划是什么？',
      '描述一次团队合作的经历',
      '您如何保持学习和自我提升？',
      '如果遇到与同事意见不合，您会如何处理？',
      '您对我们这个岗位有什么了解？',
    ].map((q) => InterviewQuestion(question: q)).toList();
  }

  /// 获取预设答案（API失败时的fallback）
  String _getFallbackAnswer(String question) {
    return '''
这是一个很好的问题。基于您的背景和经验，我建议您可以这样回答：

1. 首先，明确问题的核心要点
2. 结合您的实际经验举例说明
3. 使用STAR方法（情况-任务-行动-结果）来组织答案
4. 强调您的贡献和学到的经验

记住要保持诚实、具体，并展示您的思考过程。
''';
  }
}

final studySessionProvider = StateNotifierProvider<StudySessionNotifier, StudySessionState>(
  (ref) => StudySessionNotifier(ref),
);

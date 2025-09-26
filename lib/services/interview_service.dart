import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class InterviewService {
  static const String _baseUrl = 'http://localhost:8787';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<String>> generateQuestions({
    required String targetRole,
    required String resumeText,
    String? jobDescription,
    int batchSize = 5,
    bool isFirstBatch = false,
    List<String> existingQuestions = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/interview/generate-questions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'targetRole': targetRole,
          'resumeText': resumeText,
          'jobDescription': jobDescription,
          'batchSize': batchSize,
          'isFirstBatch': isFirstBatch,
          'existingQuestions': existingQuestions,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['questions']);
      } else {
        throw Exception('生成问题失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  Future<void> generateReferenceAnswer({
    required String question,
    required String targetRole,
    required String resumeText,
    String? jobDescription,
    required Function(String) onChunk,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/api/interview/generate-answer'),
      );
      
      request.headers.addAll({
        'Content-Type': 'application/json',
      });
      
      request.body = jsonEncode({
        'question': question,
        'targetRole': targetRole,
        'resumeText': resumeText,
        'jobDescription': jobDescription,
      });

      final streamedResponse = await request.send().timeout(_timeout);
      
      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                return;
              }
              try {
                final parsed = jsonDecode(data);
                final content = parsed['content'];
                if (content != null && content.isNotEmpty) {
                  onChunk(content);
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          }
        }
      } else {
        throw Exception('生成参考答案失败: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }
}

class InterviewServiceNotifier extends StateNotifier<AsyncValue<void>> {
  InterviewServiceNotifier() : super(const AsyncValue.data(null));

  final InterviewService _service = InterviewService();

  Future<List<String>> generateQuestions({
    required String targetRole,
    required String resumeText,
    String? jobDescription,
    int batchSize = 5,
    bool isFirstBatch = false,
    List<String> existingQuestions = const [],
  }) async {
    try {
      return await _service.generateQuestions(
        targetRole: targetRole,
        resumeText: resumeText,
        jobDescription: jobDescription,
        batchSize: batchSize,
        isFirstBatch: isFirstBatch,
        existingQuestions: existingQuestions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> generateMoreQuestions({
    required String targetRole,
    required String resumeText,
    String? jobDescription,
    int batchSize = 15,
    List<String> existingQuestions = const [],
  }) async {
    try {
      return await _service.generateQuestions(
        targetRole: targetRole,
        resumeText: resumeText,
        jobDescription: jobDescription,
        batchSize: batchSize,
        isFirstBatch: false, // 后续批次不包含自我介绍问题
        existingQuestions: existingQuestions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> generateReferenceAnswer({
    required String question,
    required String targetRole,
    required String resumeText,
    String? jobDescription,
    required Function(String) onChunk,
  }) async {
    try {
      await _service.generateReferenceAnswer(
        question: question,
        targetRole: targetRole,
        resumeText: resumeText,
        jobDescription: jobDescription,
        onChunk: onChunk,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final interviewServiceProvider = StateNotifierProvider<InterviewServiceNotifier, AsyncValue<void>>(
  (ref) => InterviewServiceNotifier(),
);

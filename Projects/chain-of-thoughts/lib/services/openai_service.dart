import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';
import '../models/app_config.dart';

class OpenAIService {
  OpenAIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> validateApiKey(String apiKey) async {
    final response = await _client.get(
      Uri.parse('https://api.openai.com/v1/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<String> transcribeAudio({
    required File audioFile,
    required AppConfig config,
    required String apiKey,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = config.transcriptionModel;
    request.fields['language'] = config.language;
    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    final response = await _client.send(request);
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body);
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  Future<AnalysisResult> analyzeTranscript({
    required String transcript,
    required AppConfig config,
    required String apiKey,
  }) async {
    final bucketList = config.buckets.join(', ');
    final bucketMode = config.multiBucket
        ? 'Return an array with one or more buckets.'
        : 'Return a single bucket as a one-item array.';

    final payload = {
      'model': config.model,
      'text': {
        'format': {'type': 'json_object'}
      },
      'input': [
        {
          'role': 'system',
          'content':
              'You are an assistant that cleans spoken notes into structured text. '
                  'Return ONLY valid JSON with keys cleanedText, intent, topics. '
                  'Use only these buckets: $bucketList. $bucketMode '
                  'If none fit, use General.'
        },
        {'role': 'user', 'content': transcript}
      ]
    };

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = _extractOutputText(data);
    try {
      final resultJson = jsonDecode(outputText) as Map<String, dynamic>;
      return AnalysisResult.fromJson(resultJson);
    } catch (_) {
      return AnalysisResult(cleanedText: transcript, intent: '', topics: const ['General']);
    }
  }

  String _extractOutputText(Map<String, dynamic> data) {
    final outputText = data['output_text'];
    if (outputText is String) return outputText;
    final output = (data['output'] as List<dynamic>? ?? []);
    if (output.isEmpty) return '{}';
    final content = (output.first as Map<String, dynamic>)['content'] as List? ?? [];
    final block = content.firstWhere(
      (item) => item is Map && item['type'] == 'output_text',
      orElse: () => {},
    );
    if (block is Map && block['text'] is String) {
      return block['text'] as String;
    }
    return '{}';
  }
}

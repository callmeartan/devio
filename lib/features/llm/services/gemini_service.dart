import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as dev;

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final http.Client _client;
  static const _timeout = Duration(seconds: 120);

  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<LlmResponse> generateResponse({
    required String prompt,
    String modelName = 'gemini-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      dev.log('Generating Gemini response...');
      final startTime = DateTime.now();

      final response = await _client.post(
        Uri.parse('$_baseUrl/models/$modelName:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        }),
      ).timeout(_timeout);

      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime).inMicroseconds / 1000000;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        final tokenMetrics = jsonResponse['usageMetadata'];

        return LlmResponse(
          text: text,
          modelName: modelName,
          totalDuration: totalDuration,
          promptEvalCount: tokenMetrics['promptTokenCount'],
          evalCount: tokenMetrics['candidatesTokenCount'],
          evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
        );
      } else {
        dev.log('Error from Gemini API: ${response.body}');
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      dev.log('Error in Gemini generateResponse: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error connecting to Gemini API: $e',
      );
    }
  }

  List<String> getAvailableModels() {
    return [
      'gemini-pro',
      'gemini-pro-vision',
    ];
  }

  void dispose() {
    _client.close();
  }
} 
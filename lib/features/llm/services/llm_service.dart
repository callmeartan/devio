import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';

class LlmService {
  final String baseUrl;
  final http.Client _client;

  LlmService({
    this.baseUrl = 'http://localhost:8080',  // Default local server URL
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/models'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<String>.from(jsonResponse['models']);
      } else {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<LlmResponse> generateResponse({
    required String prompt,
    String? modelName,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'model_name': modelName,
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        dev.log('Raw response: $jsonResponse');

        // Clean up the response text
        String cleanText = (jsonResponse['response'] as String? ?? jsonResponse['text'] as String)
            .replaceAll('â', "'")
            .replaceAll('â', "'")
            .replaceAll('â', '"')
            .replaceAll('â', '"')
            .replaceAll('â', '-')
            .replaceAll('■', "'");

        // Extract metrics from Ollama format
        final Map<String, dynamic> metrics = {};
        
        if (jsonResponse.containsKey('total_duration')) {
          metrics['total_duration'] = _convertNanosecondsToSeconds(jsonResponse['total_duration']);
        }
        
        if (jsonResponse.containsKey('load_duration')) {
          metrics['load_duration'] = _convertNanosecondsToSeconds(jsonResponse['load_duration']);
        }
        
        if (jsonResponse.containsKey('prompt_eval_count')) {
          metrics['prompt_eval_count'] = jsonResponse['prompt_eval_count'];
        }
        
        if (jsonResponse.containsKey('prompt_eval_duration')) {
          metrics['prompt_eval_duration'] = _convertNanosecondsToSeconds(jsonResponse['prompt_eval_duration']);
        }
        
        if (jsonResponse.containsKey('eval_count')) {
          metrics['eval_count'] = jsonResponse['eval_count'];
        }
        
        if (jsonResponse.containsKey('eval_duration')) {
          metrics['eval_duration'] = _convertNanosecondsToSeconds(jsonResponse['eval_duration']);
        }
        
        // Calculate rates if we have both count and duration
        if (metrics.containsKey('prompt_eval_count') && metrics.containsKey('prompt_eval_duration')) {
          final count = metrics['prompt_eval_count'] as int;
          final duration = metrics['prompt_eval_duration'] as double;
          if (duration > 0) {
            metrics['prompt_eval_rate'] = count / duration;
          }
        }
        
        if (metrics.containsKey('eval_count') && metrics.containsKey('eval_duration')) {
          final count = metrics['eval_count'] as int;
          final duration = metrics['eval_duration'] as double;
          if (duration > 0) {
            metrics['eval_rate'] = count / duration;
          }
        }

        dev.log('Extracted metrics: $metrics');
        
        // Create response object
        final cleanedResponse = <String, dynamic>{
          'text': cleanText,
          'model_name': modelName,
          ...metrics,
        };
        
        dev.log('Final response object: $cleanedResponse');
        return LlmResponse.fromJson(cleanedResponse);
      } else {
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Failed to generate response: ${response.statusCode}',
        );
      }
    } catch (e) {
      dev.log('Error in generateResponse: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error connecting to LLM server: $e',
      );
    }
  }

  double _convertNanosecondsToSeconds(dynamic value) {
    if (value is int) {
      return value / 1e9; // Convert nanoseconds to seconds
    } else if (value is double) {
      return value / 1e9;
    }
    return 0.0;
  }

  void dispose() {
    _client.close();
  }
} 
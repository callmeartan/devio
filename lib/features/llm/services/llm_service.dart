import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';

class LlmService {
  final String baseUrl;
  final http.Client _client;
  static const _timeout = Duration(seconds: 120);

  LlmService({
    String? baseUrl,
    http.Client? client,
  }) : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
       _client = client ?? http.Client();

  static String _getDefaultBaseUrl() {
    // When running on iOS simulator or device, we need to use the host machine's IP
    if (Platform.isIOS) {
      return 'http://localhost:8080';  // Update this to your machine's IP if needed
    }
    return 'http://localhost:8080';
  }

  Future<List<String>> getAvailableModels() async {
    try {
      dev.log('Fetching available models from: $baseUrl/models');
      final response = await _client.get(
        Uri.parse('$baseUrl/models'),
      ).timeout(_timeout);

      dev.log('Models response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final models = List<String>.from(jsonResponse['models']);
        dev.log('Available models: $models');
        return models;
      } else {
        dev.log('Error fetching models: ${response.body}');
        throw Exception('Failed to fetch models: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      dev.log('Error connecting to server: $e');
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
      dev.log('Generating response...');
      dev.log('Base URL: $baseUrl');
      
      // Ensure model name has the correct format
      final formattedModelName = modelName?.contains(':') == true 
          ? modelName 
          : '${modelName}:latest';
      
      dev.log('Request parameters:');
      dev.log('- Prompt: $prompt');
      dev.log('- Model (formatted): $formattedModelName');
      dev.log('- Max tokens: $maxTokens');
      dev.log('- Temperature: $temperature');
      
      final requestBody = {
        'prompt': prompt,
        'model_name': formattedModelName,
        'max_tokens': maxTokens,
        'temperature': temperature,
      };
      dev.log('Request body: $requestBody');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      dev.log('Response status code: ${response.statusCode}');
      dev.log('Response headers: ${response.headers}');
      dev.log('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        dev.log('Parsed JSON response: $jsonResponse');

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
        dev.log('Error generating response: ${response.body}');
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
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
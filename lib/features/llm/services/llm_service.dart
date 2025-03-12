import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LlmService {
  final http.Client _client;
  static const _timeout = Duration(seconds: 120);
  static const String _customOllamaIpKey = 'custom_ollama_ip';

  LlmService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Get the saved custom Ollama IP address
  Future<String?> getCustomOllamaIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customOllamaIpKey);
  }

  // Save a custom Ollama IP address
  Future<bool> setCustomOllamaIp(String? ipAddress) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Save locally
      if (ipAddress == null || ipAddress.isEmpty) {
        prefs.remove(_customOllamaIpKey);
      } else {
        prefs.setString(_customOllamaIpKey, ipAddress);
      }

      return true;
    } catch (e) {
      dev.log('Error saving custom Ollama IP: $e');
      return false;
    }
  }

  // Get the Ollama server URL with the custom IP if set
  Future<String> getOllamaServerUrl() async {
    // Get from local preferences
    final customIp = await getCustomOllamaIp();
    if (customIp == null || customIp.isEmpty) {
      return 'http://localhost:11434'; // Default Ollama URL
    }

    // Check if the IP already includes http:// or https://
    if (customIp.startsWith('http://') || customIp.startsWith('https://')) {
      return customIp;
    } else {
      // Parse the IP and port from the format IP:PORT
      final parts = customIp.split(':');
      if (parts.length >= 2) {
        final ip = parts[0];
        final port = parts.last; // Get the last part as port
        return 'http://$ip:$port'; // Use the provided port
      } else {
        return 'http://$customIp:11434'; // Add protocol and default port
      }
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      final ollamaUrl = await getOllamaServerUrl();
      dev.log('Fetching available models from: $ollamaUrl/api/tags');

      final response = await _client
          .get(
            Uri.parse('$ollamaUrl/api/tags'),
          )
          .timeout(const Duration(seconds: 5));

      dev.log('Models response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final models = jsonResponse['models'] != null
            ? List<String>.from(
                jsonResponse['models'].map((model) => model['name'] as String))
            : <String>[];
        dev.log('Available models: $models');
        return models;
      } else {
        dev.log('Error fetching models: ${response.body}');
        // Return default models instead of throwing
        return _getDefaultModels();
      }
    } catch (e) {
      dev.log('Error connecting to Ollama server: $e');
      // Return default models instead of throwing
      return _getDefaultModels();
    }
  }

  List<String> _getDefaultModels() {
    // Return a list of commonly available models
    return [
      'deepseek-r1:8b',
      'llama3:8b',
      'mistral:7b',
      'phi3:14b',
    ];
  }

  Future<LlmResponse> generateResponse({
    required String prompt,
    String? modelName,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      final ollamaUrl = await getOllamaServerUrl();
      dev.log('Generating response using Ollama directly...');
      dev.log('Ollama URL: $ollamaUrl');

      // Ensure model name has the correct format
      final formattedModelName =
          modelName?.contains(':') == true ? modelName : '$modelName:latest';

      dev.log('Request parameters:');
      dev.log('- Prompt: $prompt');
      dev.log('- Model (formatted): $formattedModelName');
      dev.log('- Max tokens: $maxTokens');
      dev.log('- Temperature: $temperature');

      final requestBody = {
        'model': formattedModelName,
        'prompt': prompt,
        'stream': false,
        'options': {
          'num_predict': maxTokens,
          'temperature': temperature,
        }
      };
      dev.log('Request body: $requestBody');

      final response = await _client
          .post(
            Uri.parse('$ollamaUrl/api/generate'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      dev.log('Response status code: ${response.statusCode}');
      dev.log('Response headers: ${response.headers}');
      dev.log('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        dev.log('Parsed JSON response: $jsonResponse');

        // Extract the response text
        final responseText = jsonResponse['response'] as String? ?? '';

        // Extract metrics from Ollama format
        final Map<String, dynamic> metrics = {};

        if (jsonResponse.containsKey('total_duration')) {
          metrics['total_duration'] =
              _convertNanosecondsToSeconds(jsonResponse['total_duration']);
        }

        if (jsonResponse.containsKey('load_duration')) {
          metrics['load_duration'] =
              _convertNanosecondsToSeconds(jsonResponse['load_duration']);
        }

        if (jsonResponse.containsKey('prompt_eval_count')) {
          metrics['prompt_eval_count'] = jsonResponse['prompt_eval_count'];
        }

        if (jsonResponse.containsKey('prompt_eval_duration')) {
          metrics['prompt_eval_duration'] = _convertNanosecondsToSeconds(
              jsonResponse['prompt_eval_duration']);
        }

        if (jsonResponse.containsKey('eval_count')) {
          metrics['eval_count'] = jsonResponse['eval_count'];
        }

        if (jsonResponse.containsKey('eval_duration')) {
          metrics['eval_duration'] =
              _convertNanosecondsToSeconds(jsonResponse['eval_duration']);
        }

        // Calculate rates if we have both count and duration
        if (metrics.containsKey('prompt_eval_count') &&
            metrics.containsKey('prompt_eval_duration')) {
          final count = metrics['prompt_eval_count'] as int;
          final duration = metrics['prompt_eval_duration'] as double;
          if (duration > 0) {
            metrics['prompt_eval_rate'] = count / duration;
          }
        }

        if (metrics.containsKey('eval_count') &&
            metrics.containsKey('eval_duration')) {
          final count = metrics['eval_count'] as int;
          final duration = metrics['eval_duration'] as double;
          if (duration > 0) {
            metrics['eval_rate'] = count / duration;
          }
        }

        dev.log('Extracted metrics: $metrics');

        // Create response object
        final cleanedResponse = <String, dynamic>{
          'text': responseText,
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
          errorMessage:
              'Failed to generate response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      dev.log('Error in generateResponse: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error connecting to Ollama server: $e',
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

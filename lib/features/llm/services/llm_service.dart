import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LlmService {
  final String baseUrl;
  final http.Client _client;
  static const _timeout = Duration(seconds: 120);
  static const String _customOllamaIpKey = 'custom_ollama_ip';

  LlmService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _client = client ?? http.Client();

  static String _getDefaultBaseUrl() {
    // When running on iOS simulator or device, we need to use the host machine's IP
    if (Platform.isIOS) {
      return 'http://localhost:8080'; // Use localhost for iOS too
    }
    return 'http://localhost:8080';
  }

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

      // Update server config
      await _updateServerOllamaConfig(ipAddress);
      return true;
    } catch (e) {
      dev.log('Error saving custom Ollama IP: $e');
      return false;
    }
  }

  // Update the server's Ollama configuration
  Future<void> _updateServerOllamaConfig(String? ipAddress) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/config/ollama'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'custom_ollama_ip': ipAddress,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        dev.log('Error updating server Ollama config: ${response.body}');
      } else {
        dev.log('Server Ollama config updated successfully');
      }
    } catch (e) {
      dev.log('Error connecting to server to update Ollama config: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  // Get the Ollama server URL with the custom IP if set
  Future<String> getOllamaServerUrl() async {
    try {
      // Try to get the current config from the server
      final response = await _client
          .get(Uri.parse('$baseUrl/config/ollama'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['ollama_api_base'] as String;
      }
    } catch (e) {
      dev.log('Error getting Ollama config from server: $e');
    }

    // Fallback to local preferences
    final customIp = await getCustomOllamaIp();
    if (customIp == null || customIp.isEmpty) {
      return 'http://localhost:11434'; // Default Ollama URL
    }

    // Check if the IP already includes http:// or https://
    if (customIp.startsWith('http://') || customIp.startsWith('https://')) {
      return customIp;
    } else {
      return 'http://$customIp:11434'; // Add protocol and port
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      dev.log('Fetching available models from: $baseUrl/models');
      final response = await _client
          .get(
            Uri.parse('$baseUrl/models'),
          )
          .timeout(const Duration(
              seconds: 5)); // Use shorter timeout for model check

      dev.log('Models response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final models = List<String>.from(jsonResponse['models']);
        dev.log('Available models: $models');
        return models;
      } else {
        dev.log('Error fetching models: ${response.body}');
        // Return default models instead of throwing
        return _getDefaultModels();
      }
    } catch (e) {
      dev.log('Error connecting to server: $e');
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
      dev.log('Generating response...');
      dev.log('Base URL: $baseUrl');

      // Ensure model name has the correct format
      final formattedModelName =
          modelName?.contains(':') == true ? modelName : '$modelName:latest';

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

      final response = await _client
          .post(
            Uri.parse('$baseUrl/generate'),
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

        // Clean up the response text
        String cleanText = (jsonResponse['response'] as String? ??
                jsonResponse['text'] as String)
            .replaceAll('â', "'")
            .replaceAll('â', "'")
            .replaceAll('â', '"')
            .replaceAll('â', '"')
            .replaceAll('â', '-')
            .replaceAll('■', "'");

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
          errorMessage:
              'Failed to generate response: ${response.statusCode} - ${response.body}',
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

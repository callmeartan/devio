import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LlmService {
  final http.Client _client;
  static const _timeout = Duration(seconds: 120);
  static const String _customOllamaIpKey = 'custom_ollama_ip';
  static const String _defaultOllamaUrl = 'http://localhost:11434';

  LlmService({http.Client? client}) : _client = client ?? http.Client();

  // Get the saved custom Ollama IP address
  Future<String?> getCustomOllamaIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customOllamaIpKey);
    } catch (e) {
      dev.log('Error getting custom Ollama IP: $e');
      return null;
    }
  }

  // Save a custom Ollama IP address
  Future<bool> setCustomOllamaIp(String? ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (ipAddress == null || ipAddress.isEmpty) {
        await prefs.remove(_customOllamaIpKey);
      } else {
        await prefs.setString(_customOllamaIpKey, ipAddress);
      }

      return true;
    } catch (e) {
      dev.log('Error saving custom Ollama IP: $e');
      return false;
    }
  }

  // Get the Ollama server URL with the custom IP if set
  Future<String> getOllamaServerUrl() async {
    try {
      final customIp = await getCustomOllamaIp();
      if (customIp == null || customIp.isEmpty) {
        return _defaultOllamaUrl;
      }

      // Check if the IP already includes http:// or https://
      if (customIp.startsWith('http://') || customIp.startsWith('https://')) {
        return customIp;
      }

      // Parse the IP and port from the format IP:PORT
      final parts = customIp.split(':');
      if (parts.length >= 2) {
        final ip = parts[0];
        final port = parts.last; // Get the last part as port
        return 'http://$ip:$port';
      }

      // If no port specified, use default Ollama port
      return 'http://$customIp:11434';
    } catch (e) {
      dev.log('Error getting Ollama server URL: $e');
      return _defaultOllamaUrl;
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      final ollamaUrl = await getOllamaServerUrl();
      dev.log('Fetching available models from: $ollamaUrl/api/tags');

      final response = await _client
          .get(Uri.parse('$ollamaUrl/api/tags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['models'] != null) {
          final models = List<String>.from(
              jsonResponse['models'].map((model) => model['name'] as String));
          dev.log('Available models: $models');
          return models;
        }
      }

      dev.log(
          'Error fetching models: ${response.statusCode} - ${response.body}');
      return _getDefaultModels();
    } catch (e) {
      dev.log('Error connecting to Ollama server: $e');
      return _getDefaultModels();
    }
  }

  List<String> _getDefaultModels() => [
        'deepseek-r1:8b',
        'llama3:8b',
        'mistral:7b',
        'phi3:14b',
      ];

  Future<LlmResponse> generateResponse({
    required String prompt,
    String? modelName,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      final ollamaUrl = await getOllamaServerUrl();

      // Ensure model name has the correct format
      final formattedModelName =
          modelName?.contains(':') == true ? modelName : '$modelName:latest';

      dev.log('Generating response with model: $formattedModelName');

      final requestBody = {
        'model': formattedModelName,
        'prompt': prompt,
        'stream': false,
        'options': {
          'num_predict': maxTokens,
          'temperature': temperature,
        }
      };

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

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = jsonResponse['response'] as String? ?? '';
        final metrics = _extractMetrics(jsonResponse);

        return LlmResponse.fromJson({
          'text': responseText,
          'model_name': modelName,
          ...metrics,
        });
      } else {
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

  Map<String, dynamic> _extractMetrics(Map<String, dynamic> jsonResponse) {
    final Map<String, dynamic> metrics = {};

    final metricsFields = [
      'total_duration',
      'load_duration',
      'prompt_eval_duration',
      'eval_duration',
    ];

    for (final field in metricsFields) {
      if (jsonResponse.containsKey(field)) {
        metrics[field] = _convertNanosecondsToSeconds(jsonResponse[field]);
      }
    }

    final countFields = ['prompt_eval_count', 'eval_count'];
    for (final field in countFields) {
      if (jsonResponse.containsKey(field)) {
        metrics[field] = jsonResponse[field];
      }
    }

    // Calculate rates
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

    return metrics;
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

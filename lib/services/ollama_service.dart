import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for interacting with the Ollama API
class OllamaService {
  String _serverUrl = 'http://localhost:11434';
  final http.Client _client = http.Client();

  OllamaService() {
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('server_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _serverUrl = savedUrl;
      }
    } catch (e) {
      log('Error loading saved server URL: $e');
    }
  }

  /// Updates the Ollama server URL
  void updateServerUrl(String url) {
    _serverUrl = url;
  }

  /// Gets the current Ollama server URL
  String get serverUrl => _serverUrl;

  /// Lists available models from the Ollama server
  Future<List<String>> listModels() async {
    try {
      final response = await _client
          .get(Uri.parse('$_serverUrl/api/tags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List<dynamic>?;

        if (models != null) {
          return models.map((model) => model['name'] as String).toList();
        }
      }

      return [];
    } catch (e) {
      log('Error listing models: $e');
      return [];
    }
  }

  /// Generates a chat completion from the Ollama server
  Future<Map<String, dynamic>> generateCompletion({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_serverUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'options': options ?? {},
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Error generating completion: ${response.statusCode} ${response.body}');
        return {
          'error': 'Failed to generate completion: ${response.statusCode}',
        };
      }
    } catch (e) {
      log('Error generating completion: $e');
      return {
        'error': 'Failed to generate completion: ${e.toString()}',
      };
    }
  }

  /// Checks if the Ollama server is running
  Future<Map<String, dynamic>> checkServer() async {
    try {
      final response = await _client
          .get(Uri.parse('$_serverUrl/api/tags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {
          'status': 'connected',
          'models': jsonDecode(response.body)['models'],
        };
      } else {
        return {
          'status': 'error',
          'error': 'Server responded with status ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Disposes of the HTTP client
  void dispose() {
    _client.close();
  }
}

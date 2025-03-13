import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'dart:io';
import '../services/llm_service.dart';
import 'llm_state.dart';
import 'dart:developer' as dev;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LlmProvider {
  local,
}

class LlmCubit extends Cubit<LlmState> {
  final LlmService _llmService;
  LlmProvider _currentProvider = LlmProvider.local;
  String? _customOllamaIp;
  Map<String, dynamic> _advancedSettings = {
    'timeout': 120,
    'contextSize': 4096,
    'threads': 4,
  };

  static const String _defaultOllamaIp = 'localhost:11434';

  LlmCubit({
    LlmService? llmService,
  })  : _llmService = llmService ?? LlmService(),
        super(const LlmState.initial()) {
    _loadCustomOllamaIp();
    _loadAdvancedSettings();
  }

  Future<void> _loadCustomOllamaIp() async {
    try {
      // First check if there's a value in the .env file
      final envOllamaHost = dotenv.env['OLLAMA_HOST'];

      if (envOllamaHost != null && envOllamaHost.isNotEmpty) {
        dev.log('Setting Ollama IP from environment: $envOllamaHost');
        await setCustomOllamaIp(envOllamaHost);
        return;
      }

      // Fall back to stored preferences
      _customOllamaIp = await _llmService.getCustomOllamaIp();

      // If no custom IP is set, use default
      if (_customOllamaIp == null || _customOllamaIp!.isEmpty) {
        _customOllamaIp = _defaultOllamaIp;
        await _llmService.setCustomOllamaIp(_customOllamaIp);
        dev.log('Set default Ollama IP to $_defaultOllamaIp');
      } else {
        dev.log('Loaded custom Ollama IP from preferences: $_customOllamaIp');
      }
    } catch (e) {
      dev.log('Error loading Ollama IP: $e');
      // Set default IP if there's an error
      _customOllamaIp = _defaultOllamaIp;
    }
  }

  Future<void> _loadAdvancedSettings() async {
    try {
      _advancedSettings = await _llmService.getAdvancedSettings();
    } catch (e) {
      dev.log('Error loading advanced settings: $e');
    }
  }

  LlmProvider get currentProvider => _currentProvider;
  String? get customOllamaIp => _customOllamaIp;

  // Get current advanced settings
  Map<String, dynamic> get advancedSettings => _advancedSettings;

  // Update advanced settings
  Future<void> updateAdvancedSettings({
    required int timeout,
    required int contextSize,
    required int threads,
  }) async {
    try {
      final success = await _llmService.saveAdvancedSettings(
        timeout: timeout,
        contextSize: contextSize,
        threads: threads,
      );

      if (success) {
        _advancedSettings = {
          'timeout': timeout,
          'contextSize': contextSize,
          'threads': threads,
        };
        emit(const LlmState.initial());
      }
    } catch (e) {
      dev.log('Error updating advanced settings: $e');
    }
  }

  // Test Ollama connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      return await _llmService.testConnection();
    } catch (e) {
      dev.log('Error testing connection: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Get server status
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      return await _llmService.getServerStatus();
    } catch (e) {
      dev.log('Error getting server status: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Pull a new model
  Future<Map<String, dynamic>> pullModel(String modelName) async {
    try {
      emit(const LlmState.loading());
      final result = await _llmService.pullModel(modelName);
      emit(const LlmState.initial());
      return result;
    } catch (e) {
      dev.log('Error pulling model: $e');
      emit(LlmState.error(e.toString()));
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Delete a model
  Future<Map<String, dynamic>> deleteModel(String modelName) async {
    try {
      emit(const LlmState.loading());
      final result = await _llmService.deleteModel(modelName);
      emit(const LlmState.initial());
      return result;
    } catch (e) {
      dev.log('Error deleting model: $e');
      emit(LlmState.error(e.toString()));
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Get model details
  Future<Map<String, dynamic>> getModelDetails(String modelName) async {
    try {
      return await _llmService.getModelDetails(modelName);
    } catch (e) {
      dev.log('Error getting model details: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  void setProvider(LlmProvider provider) {
    dev.log('Switching LLM provider to: $provider');
    _currentProvider = provider;

    // Make sure we have a custom Ollama IP
    if (_customOllamaIp == null || _customOllamaIp!.isEmpty) {
      _ensureOllamaIpIsSet();
    }

    emit(const LlmState.initial());
  }

  Future<void> _ensureOllamaIpIsSet() async {
    // Check if there's a value in the .env file
    final envOllamaHost = dotenv.env['OLLAMA_HOST'];

    if (envOllamaHost != null && envOllamaHost.isNotEmpty) {
      dev.log('Setting Ollama IP from environment: $envOllamaHost');
      await setCustomOllamaIp(envOllamaHost);
    } else {
      // Set default IP
      await setCustomOllamaIp(_defaultOllamaIp);
      dev.log('Set default Ollama IP: $_defaultOllamaIp');
    }
  }

  Future<void> setCustomOllamaIp(String? ipAddress) async {
    try {
      dev.log('Setting custom Ollama IP: $ipAddress');
      final success = await _llmService.setCustomOllamaIp(ipAddress);

      if (success) {
        _customOllamaIp = ipAddress;
        // Refresh models
        emit(const LlmState.initial());
      } else {
        dev.log('Failed to save custom Ollama IP');
      }
    } catch (e) {
      dev.log('Error setting custom Ollama IP: $e');
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      dev.log('Getting available models');
      final models = await _llmService.getAvailableModels();
      return models;
    } catch (e) {
      dev.log('Error getting available models: $e');
      return [];
    }
  }

  Future<void> generateResponse({
    required String prompt,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    dev.log('Generating response');
    dev.log('Model name: $modelName');

    emit(const LlmState.loading());

    try {
      final response = await _llmService.generateResponse(
        prompt: prompt,
        modelName: modelName ?? 'deepseek-r1:8b',
        maxTokens: maxTokens ?? 1000,
        temperature: temperature ?? 0.7,
      );

      if (response.isError) {
        dev.log('Error in response: ${response.errorMessage}');
        emit(LlmState.error(response.errorMessage ?? 'Unknown error occurred'));
      } else {
        dev.log('Response generated successfully');
        emit(LlmState.success(response));
      }
    } catch (e) {
      dev.log('Error generating response: $e');
      emit(LlmState.error('Failed to generate response: $e'));
    }
  }

  Future<void> generateResponseWithImage({
    required String prompt,
    required Uint8List imageBytes,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    dev.log('Generating response with image');

    emit(const LlmState.loading());

    try {
      // For now, we'll use a standard text response approach since
      // the Ollama API doesn't natively support image analysis
      // This method could be extended later to use a multimodal model

      const String errorMessage =
          'Image analysis is not supported with local models. '
          'Consider using a multimodal model like llava, bakllava, or moondream.';

      dev.log(errorMessage);
      emit(LlmState.error(errorMessage));

      // Alternatively, when implementing real image analysis:
      // 1. Convert image to base64
      // 2. Create a request with both prompt and image
      // 3. Send to an LLM service that supports multimodal inputs
    } catch (e) {
      dev.log('Error in image analysis: $e');
      emit(LlmState.error('Failed to analyze image: $e'));
    }
  }

  @override
  Future<void> close() {
    _llmService.dispose();
    return super.close();
  }
}

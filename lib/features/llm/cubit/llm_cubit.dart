import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/llm_response.dart';
import '../services/llm_provider_registry.dart';
import '../services/llm_service.dart';
import '../services/providers/llm_provider.dart' as provider_api;
import 'llm_state.dart';
import 'dart:developer' as dev;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LlmProvider {
  local,
  ollama,
  lmstudio,
  openai,
}

class LlmCubit extends Cubit<LlmState> {
  final LlmService _llmService;
  final LlmProviderRegistry _providerRegistry;
  String _currentProviderId = 'ollama';
  String? _baseUrl;
  String? _apiKey;
  String? _selectedModel;
  double _temperature = 0.7;
  int? _maxTokens;
  String? _customOllamaIp;
  Map<String, dynamic> _advancedSettings = {
    'timeout': 120,
    'contextSize': 4096,
    'threads': 4,
  };

  static const String _defaultOllamaIp = 'localhost:11434';
  static const String _providerIdKey = 'llm_provider_id';
  static const String _baseUrlKey = 'llm_base_url';
  static const String _apiKeyKey = 'llm_api_key';
  static const String _selectedModelKey = 'llm_selected_model';
  static const String _temperatureKey = 'llm_temperature';
  static const String _maxTokensKey = 'llm_max_tokens';

  LlmCubit({
    LlmService? llmService,
    LlmProviderRegistry? providerRegistry,
  })  : _llmService = llmService ?? LlmService(),
        _providerRegistry = providerRegistry ?? LlmProviderRegistry(),
        super(const LlmState.initial()) {
    _loadProviderSettings();
    _loadCustomOllamaIp();
    _loadAdvancedSettings();
  }

  Future<void> _loadProviderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentProviderId = prefs.getString(_providerIdKey) ?? 'ollama';
      if (_currentProviderId == 'local') {
        _currentProviderId = 'ollama';
      }
      _baseUrl = prefs.getString(_baseUrlKey);
      _apiKey = prefs.getString(_apiKeyKey);
      _selectedModel = prefs.getString(_selectedModelKey);
      _temperature = prefs.getDouble(_temperatureKey) ?? 0.7;
      _maxTokens = prefs.getInt(_maxTokensKey);
      emit(const LlmState.initial());
    } catch (e) {
      _debugLog('Error loading provider settings: $e');
    }
  }

  Future<void> _loadCustomOllamaIp() async {
    try {
      // First check if there's a value in the .env file
      final envOllamaHost = _readEnvValue('OLLAMA_HOST');

      if (envOllamaHost != null && envOllamaHost.isNotEmpty) {
        _debugLog('Setting Ollama IP from environment');
        await setCustomOllamaIp(envOllamaHost);
        return;
      }

      // Fall back to stored preferences
      _customOllamaIp = await _llmService.getCustomOllamaIp();

      // If no custom IP is set, use default
      if (_customOllamaIp == null || _customOllamaIp!.isEmpty) {
        await setCustomOllamaIp(
            _defaultOllamaIp); // Use setCustomOllamaIp to ensure it's saved
        _debugLog('Set default Ollama IP');
      } else {
        _debugLog('Loaded custom Ollama IP from preferences');
      }
    } catch (e) {
      _debugLog('Error loading Ollama IP: $e');
      // Set and save default IP if there's an error
      await setCustomOllamaIp(_defaultOllamaIp);
    }
  }

  Future<void> _loadAdvancedSettings() async {
    try {
      _advancedSettings = await _llmService.getAdvancedSettings();
    } catch (e) {
      _debugLog('Error loading advanced settings: $e');
    }
  }

  LlmProvider get currentProvider {
    switch (_currentProviderId) {
      case 'lmstudio':
        return LlmProvider.lmstudio;
      case 'openai':
        return LlmProvider.openai;
      case 'ollama':
      default:
        return LlmProvider.local;
    }
  }

  String get currentProviderId => _currentProviderId;
  String? get customOllamaIp => _customOllamaIp;
  String? get baseUrl => _baseUrl;
  String? get selectedModel => _selectedModel;

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
      _debugLog('Error updating advanced settings: $e');
    }
  }

  // Test Ollama connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      if (_currentProviderId != 'ollama') {
        final config = await _activeProviderConfig();
        final models =
            await _providerRegistry.get(_currentProviderId).listModels(config);
        return {
          'status': 'connected',
          'provider': _currentProviderId,
          'models': models.length,
        };
      }
      return await _llmService.testConnection();
    } catch (e) {
      _debugLog('Error testing connection: $e');
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
      _debugLog('Error getting server status: $e');
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
      _debugLog('Error pulling model: $e');
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
      _debugLog('Error deleting model: $e');
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
      _debugLog('Error getting model details: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  void setProvider(LlmProvider provider) {
    final providerId = switch (provider) {
      LlmProvider.local || LlmProvider.ollama => 'ollama',
      LlmProvider.lmstudio => 'lmstudio',
      LlmProvider.openai => 'openai',
    };
    _debugLog('Switching LLM provider to: $providerId');
    _currentProviderId = providerId;

    // Make sure we have a custom Ollama IP
    if (providerId == 'ollama' &&
        (_customOllamaIp == null || _customOllamaIp!.isEmpty)) {
      _ensureOllamaIpIsSet();
    }

    _saveProviderSettings();
    emit(const LlmState.initial());
  }

  Future<void> switchProvider(
    String providerId,
    provider_api.LlmProviderConfig config,
  ) async {
    final normalizedId = providerId == 'local' ? 'ollama' : providerId;
    _providerRegistry.get(normalizedId);
    _currentProviderId = normalizedId;
    _baseUrl = config.baseUrl;
    _apiKey = config.apiKey;
    _selectedModel = config.model;
    _temperature = config.temperature;
    _maxTokens = config.maxTokens;
    await _saveProviderSettings();
    emit(const LlmState.initial());
  }

  Future<void> _ensureOllamaIpIsSet() async {
    // Check if there's a value in the .env file
    final envOllamaHost = _readEnvValue('OLLAMA_HOST');

    if (envOllamaHost != null && envOllamaHost.isNotEmpty) {
      _debugLog('Setting Ollama IP from environment');
      await setCustomOllamaIp(envOllamaHost);
    } else {
      // Set default IP
      await setCustomOllamaIp(_defaultOllamaIp);
      _debugLog('Set default Ollama IP');
    }
  }

  String? _readEnvValue(String key) {
    try {
      return dotenv.env[key];
    } catch (e) {
      _debugLog('Dotenv is not initialized; using default local settings.');
      return null;
    }
  }

  Future<void> setCustomOllamaIp(String? ipAddress) async {
    try {
      _debugLog('Setting custom Ollama IP');
      final success = await _llmService.setCustomOllamaIp(ipAddress);

      if (success) {
        _customOllamaIp = ipAddress;
        if (_currentProviderId == 'ollama') {
          _baseUrl = await _llmService.getOllamaServerUrl();
          await _saveProviderSettings();
        }
        // Refresh models
        emit(const LlmState.initial());
      } else {
        _debugLog('Failed to save custom Ollama IP');
      }
    } catch (e) {
      _debugLog('Error setting custom Ollama IP: $e');
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      _debugLog('Getting available models');
      final config = await _activeProviderConfig();
      return _providerRegistry.get(_currentProviderId).listModels(config);
    } catch (e) {
      _debugLog('Error getting available models: $e');
      return [];
    }
  }

  Future<void> generateResponse({
    required String prompt,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    _debugLog('Generating response with selected model');

    emit(const LlmState.loading());

    try {
      final config = await _activeProviderConfig(
        modelName: modelName,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      final text = await _providerRegistry.get(_currentProviderId).chatOnce(
        config,
        [provider_api.LlmMessage(role: 'user', content: prompt)],
      );
      final response = LlmResponse(text: text, modelName: config.model);

      if (response.isError) {
        _debugLog('Error in response: ${response.errorMessage}');
        emit(LlmState.error(response.errorMessage ?? 'Unknown error occurred'));
      } else {
        emit(LlmState.success(response));
      }
    } catch (e) {
      _debugLog('Error generating response: $e');
      emit(LlmState.error(e.toString()));
    }
  }

  // New method for streaming responses
  Stream<LlmState> streamResponse({
    required String prompt,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async* {
    _debugLog('Streaming response with selected model');

    yield const LlmState.loading();

    try {
      final config = await _activeProviderConfig(
        modelName: modelName,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      final stream = _providerRegistry.get(_currentProviderId).chat(
        config,
        [provider_api.LlmMessage(role: 'user', content: prompt)],
      );

      await for (final chunk in stream) {
        yield LlmState.success(LlmResponse(
          text: chunk,
          modelName: config.model,
        ));
      }
    } catch (e) {
      _debugLog('Error streaming response: $e');
      yield LlmState.error(e.toString());
    }
  }

  Future<void> generateResponseWithImage({
    required String prompt,
    required Uint8List imageBytes,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    _debugLog('Generating response with image');

    emit(const LlmState.loading());

    try {
      // For now, we'll use a standard text response approach since
      // the Ollama API doesn't natively support image analysis
      // This method could be extended later to use a multimodal model

      const String errorMessage =
          'Image analysis is not supported with local models. '
          'Consider using a multimodal model like llava, bakllava, or moondream.';

      _debugLog(errorMessage);
      emit(LlmState.error(errorMessage));

      // Alternatively, when implementing real image analysis:
      // 1. Convert image to base64
      // 2. Create a request with both prompt and image
      // 3. Send to an LLM service that supports multimodal inputs
    } catch (e) {
      _debugLog('Error in image analysis: $e');
      emit(LlmState.error('Failed to analyze image: $e'));
    }
  }

  Future<provider_api.LlmProviderConfig> _activeProviderConfig({
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    final baseUrl = switch (_currentProviderId) {
      'lmstudio' => _baseUrl ?? 'http://localhost:1234',
      'openai' => _baseUrl ?? 'https://api.openai.com',
      _ => await _llmService.getOllamaServerUrl(),
    };
    final model = modelName ?? _selectedModel ?? 'deepseek-r1:8b';
    return provider_api.LlmProviderConfig(
      baseUrl: baseUrl,
      apiKey: _apiKey,
      model: model,
      temperature: temperature ?? _temperature,
      maxTokens: maxTokens ?? _maxTokens ?? 1000,
      contextSize: _advancedSettings['contextSize'] as int?,
    );
  }

  Future<void> _saveProviderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_providerIdKey, _currentProviderId);
      if (_baseUrl == null || _baseUrl!.isEmpty) {
        await prefs.remove(_baseUrlKey);
      } else {
        await prefs.setString(_baseUrlKey, _baseUrl!);
      }
      if (_apiKey == null || _apiKey!.isEmpty) {
        await prefs.remove(_apiKeyKey);
      } else {
        await prefs.setString(_apiKeyKey, _apiKey!);
      }
      if (_selectedModel == null || _selectedModel!.isEmpty) {
        await prefs.remove(_selectedModelKey);
      } else {
        await prefs.setString(_selectedModelKey, _selectedModel!);
      }
      await prefs.setDouble(_temperatureKey, _temperature);
      if (_maxTokens == null) {
        await prefs.remove(_maxTokensKey);
      } else {
        await prefs.setInt(_maxTokensKey, _maxTokens!);
      }
    } catch (e) {
      _debugLog('Error saving provider settings: $e');
    }
  }

  void _debugLog(String message) {
    assert(() {
      dev.log(message);
      return true;
    }());
  }

  @override
  Future<void> close() {
    _llmService.dispose();
    _providerRegistry.dispose();
    return super.close();
  }
}

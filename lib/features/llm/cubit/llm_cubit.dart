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

  static const String _defaultOllamaIp = 'localhost:11434';

  LlmCubit({
    LlmService? llmService,
  })  : _llmService = llmService ?? LlmService(),
        super(const LlmState.initial()) {
    _loadCustomOllamaIp();
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

  LlmProvider get currentProvider => _currentProvider;
  String? get customOllamaIp => _customOllamaIp;

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

  @override
  Future<void> close() {
    _llmService.dispose();
    return super.close();
  }
}

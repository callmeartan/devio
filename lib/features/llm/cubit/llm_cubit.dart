import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'dart:io';
import '../services/llm_service.dart';
import '../services/gemini_service.dart';
import 'llm_state.dart';
import 'dart:developer' as dev;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LlmProvider {
  local,
  gemini,
}

class LlmCubit extends Cubit<LlmState> {
  final LlmService _llmService;
  final GeminiService _geminiService;
  LlmProvider _currentProvider = LlmProvider.gemini;
  String? _customOllamaIp;

  static const String _defaultOllamaIp = 'localhost:11434';

  LlmCubit({
    LlmService? llmService,
    GeminiService? geminiService,
  })  : _llmService = llmService ?? LlmService(),
        _geminiService = geminiService ?? GeminiService(),
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

    // If switching to local provider, make sure we have a custom Ollama IP
    if (provider == LlmProvider.local &&
        (_customOllamaIp == null || _customOllamaIp!.isEmpty)) {
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

        if (_currentProvider == LlmProvider.local) {
          // Refresh models if we're currently using local provider
          emit(const LlmState.initial());
        }
      } else {
        dev.log('Failed to save custom Ollama IP');
      }
    } catch (e) {
      dev.log('Error setting custom Ollama IP: $e');
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      dev.log('Getting available models for provider: $_currentProvider');
      final models = _currentProvider == LlmProvider.local
          ? await _llmService.getAvailableModels()
          : await _geminiService.getAvailableModels();
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
    dev.log('Generating response with provider: $_currentProvider');
    dev.log('Model name: $modelName');

    emit(const LlmState.loading());

    try {
      if (_currentProvider == LlmProvider.local) {
        final response = await _llmService.generateResponse(
          prompt: prompt,
          modelName: modelName ?? 'deepseek-r1:8b',
          maxTokens: maxTokens ?? 1000,
          temperature: temperature ?? 0.7,
        );

        if (response.isError) {
          dev.log('Error in response: ${response.errorMessage}');
          emit(LlmState.error(
              response.errorMessage ?? 'Unknown error occurred'));
        } else {
          dev.log('Response generated successfully');
          emit(LlmState.success(response));
        }
      } else {
        final response = await _geminiService.generateResponse(
          prompt: prompt,
          modelName: modelName ?? 'gemini-1.5-pro',
          maxTokens: maxTokens ?? 1000,
          temperature: temperature ?? 0.7,
        );

        if (response.isError) {
          dev.log('Error in response: ${response.errorMessage}');
          if (response.errorMessage?.contains('503') == true ||
              response.errorMessage?.contains('overloaded') == true) {
            // Model switching is handled internally by GeminiService
            emit(LlmState.error(
                'All available models are currently overloaded. Please try again later.'));
          } else {
            emit(LlmState.error(
                response.errorMessage ?? 'Unknown error occurred'));
          }
        } else {
          if (response.modelName != modelName) {
            // If a different model was used, notify the user
            emit(LlmState.modelSwitching(
              fromModel: modelName ?? 'gemini-pro',
              toModel: response.modelName ?? 'unknown',
              attempt: 1,
            ));
            await Future.delayed(
                const Duration(seconds: 2)); // Show switching message briefly
          }
          dev.log('Response generated successfully');
          emit(LlmState.success(response));
        }
      }
    } catch (e) {
      dev.log('Error generating response: $e');
      emit(LlmState.error('Failed to generate response: $e'));
    }
  }

  Future<void> generateResponseWithImage({
    required String prompt,
    required Uint8List imageBytes,
    String? mimeType,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    dev.log('Generating response with image using provider: $_currentProvider');

    if (_currentProvider != LlmProvider.gemini) {
      emit(const LlmState.error(
          'Image processing is only supported with Gemini'));
      return;
    }

    emit(const LlmState.loading());

    try {
      final response = await _geminiService.generateResponseWithImage(
        prompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType ?? 'image/jpeg',
        modelName: modelName ?? 'gemini-1.5-pro-vision',
        maxTokens: maxTokens ?? 1000,
        temperature: temperature ?? 0.7,
      );

      if (response.isError) {
        dev.log('Error in response: ${response.errorMessage}');
        if (response.errorMessage?.contains('503') == true ||
            response.errorMessage?.contains('overloaded') == true) {
          // Model switching is handled internally by GeminiService
          emit(LlmState.error(
              'All available vision models are currently overloaded. Please try again later.'));
        } else {
          emit(LlmState.error(
              response.errorMessage ?? 'Unknown error occurred'));
        }
      } else {
        if (response.modelName != modelName) {
          // If a different model was used, notify the user
          emit(LlmState.modelSwitching(
            fromModel: modelName ?? 'gemini-pro-vision',
            toModel: response.modelName ?? 'unknown',
            attempt: 1,
          ));
          await Future.delayed(
              const Duration(seconds: 2)); // Show switching message briefly
        }
        dev.log('Response generated successfully');
        emit(LlmState.success(response));
      }
    } catch (e) {
      dev.log('Error generating response with image: $e');
      emit(LlmState.error('Failed to generate response with image: $e'));
    }
  }

  Future<void> generateResponseWithDocument({
    required String prompt,
    required String documentPath,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    dev.log(
        'Generating response with document using provider: $_currentProvider');

    if (_currentProvider != LlmProvider.gemini) {
      emit(const LlmState.error(
          'Document analysis is only supported with Gemini'));
      return;
    }

    emit(const LlmState.loading());

    try {
      final file = File(documentPath);
      final response = await _geminiService.analyzeDocument(
        file: file,
        customPrompt: prompt,
        modelName: modelName ?? 'gemini-1.5-pro',
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
      dev.log('Error analyzing document: $e');
      emit(LlmState.error('Failed to analyze document: $e'));
    }
  }

  Future<void> askAboutDocument({
    required String documentPath,
    required String question,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    dev.log('Asking question about document using provider: $_currentProvider');

    if (_currentProvider != LlmProvider.gemini) {
      emit(const LlmState.error(
          'Document analysis is only supported with Gemini'));
      return;
    }

    emit(const LlmState.loading());

    try {
      final file = File(documentPath);
      final response = await _geminiService.askAboutDocument(
        file: file,
        question: question,
        modelName: modelName ?? 'gemini-1.5-pro',
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
      dev.log('Error asking about document: $e');
      emit(LlmState.error('Failed to ask about document: $e'));
    }
  }

  @override
  Future<void> close() {
    _llmService.dispose();
    _geminiService.dispose();
    return super.close();
  }
}

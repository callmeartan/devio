import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/llm_service.dart';
import '../services/gemini_service.dart';
import 'llm_state.dart';
import 'dart:developer' as dev;

enum LlmProvider {
  local,
  gemini,
}

class LlmCubit extends Cubit<LlmState> {
  final LlmService _llmService;
  final GeminiService _geminiService;
  LlmProvider _currentProvider = LlmProvider.local;

  LlmCubit({
    LlmService? llmService,
    GeminiService? geminiService,
  })  : _llmService = llmService ?? LlmService(),
        _geminiService = geminiService ?? GeminiService(),
        super(const LlmState.initial());

  LlmProvider get currentProvider => _currentProvider;

  void setProvider(LlmProvider provider) {
    dev.log('Switching LLM provider to: $provider');
    _currentProvider = provider;
    emit(const LlmState.initial());
  }

  Future<List<String>> getAvailableModels() async {
    dev.log('Getting available models for provider: $_currentProvider');
    final models = _currentProvider == LlmProvider.local
        ? await _llmService.getAvailableModels()
        : _geminiService.getAvailableModels();
    dev.log('Available models: $models');
    return models;
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
      final response = _currentProvider == LlmProvider.local
          ? await _llmService.generateResponse(
              prompt: prompt,
              modelName: modelName ?? 'deepseek-r1:8b',
              maxTokens: maxTokens ?? 1000,
              temperature: temperature ?? 0.7,
            )
          : await _geminiService.generateResponse(
              prompt: prompt,
              modelName: modelName ?? 'gemini-pro',
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
    _geminiService.dispose();
    return super.close();
  }
} 
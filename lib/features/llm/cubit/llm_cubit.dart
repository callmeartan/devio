import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'dart:io';
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
  LlmProvider _currentProvider = LlmProvider.gemini;

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
      emit(const LlmState.error('Image processing is only supported with Gemini'));
      return;
    }

    emit(const LlmState.loading());

    try {
      final response = await _geminiService.generateResponseWithImage(
        prompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType ?? 'image/jpeg',
        modelName: modelName ?? 'gemini-1.5-pro-vision-latest',
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
    dev.log('Generating response with document using provider: $_currentProvider');
    
    if (_currentProvider != LlmProvider.gemini) {
      emit(const LlmState.error('Document analysis is only supported with Gemini'));
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
      emit(const LlmState.error('Document analysis is only supported with Gemini'));
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
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/llm_service.dart';
import 'llm_state.dart';

class LlmCubit extends Cubit<LlmState> {
  final LlmService _llmService;

  LlmCubit({LlmService? llmService})
      : _llmService = llmService ?? LlmService(),
        super(const LlmState.initial());

  Future<void> generateResponse({
    required String prompt,
    String? modelName,
    int? maxTokens,
    double? temperature,
  }) async {
    emit(const LlmState.loading());

    try {
      final response = await _llmService.generateResponse(
        prompt: prompt,
        modelName: modelName ?? 'deepseek-r1:8b',
        maxTokens: maxTokens ?? 1000,
        temperature: temperature ?? 0.7,
      );

      if (response.isError) {
        emit(LlmState.error(response.errorMessage ?? 'Unknown error occurred'));
      } else {
        emit(LlmState.success(response));
      }
    } catch (e) {
      emit(LlmState.error('Failed to generate response: $e'));
    }
  }

  @override
  Future<void> close() {
    _llmService.dispose();
    return super.close();
  }
} 
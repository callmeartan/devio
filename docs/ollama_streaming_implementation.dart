// This is a simplified implementation of the Ollama streaming API
// It shows the key components needed for streaming responses without relying on the isFinal field

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Simple model class for responses
class LlmResponse {
  final String text;
  final bool isError;
  final String? errorMessage;
  final String? modelName;
  final double? totalDuration;
  final double? loadDuration;
  final int? promptEvalCount;
  final double? promptEvalDuration;
  final double? promptEvalRate;
  final int? evalCount;
  final double? evalDuration;
  final double? evalRate;

  LlmResponse({
    required this.text,
    this.isError = false,
    this.errorMessage,
    this.modelName,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.promptEvalRate,
    this.evalCount,
    this.evalDuration,
    this.evalRate,
  });
}

// Simple state class for LLM
enum LlmStateType { initial, loading, streaming, loaded, error }

class LlmState {
  final LlmStateType type;
  final LlmResponse? response;
  final String? errorMessage;

  LlmState.initial()
      : type = LlmStateType.initial,
        response = null,
        errorMessage = null;
  LlmState.loading()
      : type = LlmStateType.loading,
        response = null,
        errorMessage = null;
  LlmState.streaming(LlmResponse this.response)
      : type = LlmStateType.streaming,
        errorMessage = null;
  LlmState.loaded(LlmResponse this.response)
      : type = LlmStateType.loaded,
        errorMessage = null;
  LlmState.error(this.errorMessage)
      : type = LlmStateType.error,
        response = null;
}

// LLM Service implementation
class LlmService {
  final String _baseUrl;
  final String _defaultModel;

  LlmService({
    required String baseUrl,
    required String defaultModel,
  })  : _baseUrl = baseUrl,
        _defaultModel = defaultModel;

  // Streaming implementation
  Stream<LlmResponse> streamResponse(String prompt,
      {String? modelName}) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'prompt': prompt,
        'model': modelName ?? _defaultModel,
        'stream': true,
      });

      final streamedResponse = await client.send(request);

      // Handle errors
      if (streamedResponse.statusCode != 200) {
        yield LlmResponse(
          text: '',
          isError: true,
          errorMessage:
              'Failed to get response: ${streamedResponse.statusCode}',
        );
        return;
      }

      String accumulatedText = '';
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.trim().isEmpty) continue;

        try {
          final json = jsonDecode(line);
          final responseText = json['response'] as String? ?? '';
          accumulatedText += responseText;

          // Yield incremental response
          yield LlmResponse(
            text: responseText,
            modelName: json['model'] as String?,
          );

          // Check if this is the final response (contains metrics)
          final hasTotalDuration = json['total_duration'] != null;
          final hasEvalCount = json['eval_count'] != null;
          final isDone = json['done'] == true;

          if (isDone || hasTotalDuration || hasEvalCount) {
            // Yield final response with accumulated text and metrics
            yield LlmResponse(
              text: accumulatedText,
              modelName: json['model'] as String?,
              totalDuration: _parseDouble(json['total_duration']),
              loadDuration: _parseDouble(json['load_duration']),
              promptEvalCount: _parseInt(json['prompt_eval_count']),
              promptEvalDuration: _parseDouble(json['prompt_eval_duration']),
              promptEvalRate: _parseDouble(json['prompt_eval_rate']),
              evalCount: _parseInt(json['eval_count']),
              evalDuration: _parseDouble(json['eval_duration']),
              evalRate: _parseDouble(json['eval_rate']),
            );
            break;
          }
        } catch (e) {
          yield LlmResponse(
            text: '',
            isError: true,
            errorMessage: 'Error parsing streaming response: $e',
          );
        }
      }
    } catch (e) {
      yield LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Network error: $e',
      );
    } finally {
      client.close();
    }
  }

  // Helper methods for parsing values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// LLM Controller/Cubit implementation
class LlmController {
  final LlmService _llmService;

  LlmController(this._llmService);

  Stream<LlmState> handleStreamingRequest(String prompt,
      {String? modelName}) async* {
    yield LlmState.loading();

    try {
      final stream = _llmService.streamResponse(prompt, modelName: modelName);
      await for (final response in stream) {
        if (response.isError) {
          yield LlmState.error(response.errorMessage ?? 'Unknown error');
          return;
        }

        // Check if this is the final response based on metrics
        final isFinalResponse =
            response.totalDuration != null || response.evalCount != null;

        if (isFinalResponse) {
          // Final response with metrics
          yield LlmState.loaded(response);
        } else {
          // Incremental response
          yield LlmState.streaming(response);
        }
      }
    } catch (e) {
      yield LlmState.error('Error streaming response: $e');
    }
  }
}

// Example usage:
void main() async {
  final llmService = LlmService(
    baseUrl: 'http://localhost:11434',
    defaultModel: 'llama2',
  );

  final llmController = LlmController(llmService);

  String accumulatedText = '';

  final subscription = llmController
      .handleStreamingRequest('Explain quantum computing in simple terms')
      .listen((state) {
    if (state.type == LlmStateType.streaming && state.response != null) {
      // Handle streaming update
      accumulatedText += state.response!.text;
      print('STREAMING: $accumulatedText');
    } else if (state.type == LlmStateType.loaded && state.response != null) {
      // Handle final response with metrics
      print('FINAL: ${state.response!.text}');
      print('Duration: ${state.response!.totalDuration}');
    } else if (state.type == LlmStateType.error) {
      // Handle error
      print('ERROR: ${state.errorMessage}');
    }
  });

  // Don't forget to cancel the subscription when done
  // subscription.cancel();
}

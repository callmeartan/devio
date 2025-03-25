// This file contains replacement code for implementing Ollama streaming
// without relying on Freezed pattern matching features

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

// ----- MODEL CLASSES -----

// Simple LlmResponse model without Freezed
class SimpleLlmResponse {
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
  final int? completionTokens;
  final int? totalTokens;

  // Helper property to determine if this is a final response
  bool get isFinalResponse => totalDuration != null || evalCount != null;

  const SimpleLlmResponse({
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
    this.completionTokens,
    this.totalTokens,
  });

  // Create a copy with modified fields
  SimpleLlmResponse copyWith({
    String? text,
    bool? isError,
    String? errorMessage,
    String? modelName,
    double? totalDuration,
    double? loadDuration,
    int? promptEvalCount,
    double? promptEvalDuration,
    double? promptEvalRate,
    int? evalCount,
    double? evalDuration,
    double? evalRate,
    int? completionTokens,
    int? totalTokens,
  }) {
    return SimpleLlmResponse(
      text: text ?? this.text,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      modelName: modelName ?? this.modelName,
      totalDuration: totalDuration ?? this.totalDuration,
      loadDuration: loadDuration ?? this.loadDuration,
      promptEvalCount: promptEvalCount ?? this.promptEvalCount,
      promptEvalDuration: promptEvalDuration ?? this.promptEvalDuration,
      promptEvalRate: promptEvalRate ?? this.promptEvalRate,
      evalCount: evalCount ?? this.evalCount,
      evalDuration: evalDuration ?? this.evalDuration,
      evalRate: evalRate ?? this.evalRate,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
    );
  }
}

// Simple state classes for LLM without Freezed
enum SimpleLlmStateType { initial, loading, streaming, loaded, error }

class SimpleLlmState {
  final SimpleLlmStateType type;
  final SimpleLlmResponse? response;
  final String? errorMessage;

  const SimpleLlmState._({
    required this.type,
    this.response,
    this.errorMessage,
  });

  // Factory constructors for each state type
  factory SimpleLlmState.initial() => const SimpleLlmState._(
        type: SimpleLlmStateType.initial,
        response: null,
        errorMessage: null,
      );

  factory SimpleLlmState.loading() => const SimpleLlmState._(
        type: SimpleLlmStateType.loading,
        response: null,
        errorMessage: null,
      );

  factory SimpleLlmState.streaming(SimpleLlmResponse response) =>
      SimpleLlmState._(
        type: SimpleLlmStateType.streaming,
        response: response,
        errorMessage: null,
      );

  factory SimpleLlmState.loaded(SimpleLlmResponse response) => SimpleLlmState._(
        type: SimpleLlmStateType.loaded,
        response: response,
        errorMessage: null,
      );

  factory SimpleLlmState.error(String message) => SimpleLlmState._(
        type: SimpleLlmStateType.error,
        response: null,
        errorMessage: message,
      );
}

// ----- SERVICE IMPLEMENTATION -----

class SimpleLlmService {
  final String baseUrl;
  final String currentModel;

  SimpleLlmService({
    required this.baseUrl,
    required this.currentModel,
  });

  // Stream implementation for Ollama API
  Stream<SimpleLlmResponse> streamResponse(String prompt,
      {String? modelName}) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'prompt': prompt,
        'model': modelName ?? currentModel,
        'stream': true,
      });

      final streamedResponse = await client.send(request);

      // Handle errors
      if (streamedResponse.statusCode != 200) {
        yield SimpleLlmResponse(
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
          yield SimpleLlmResponse(
            text: responseText,
            modelName: json['model'] as String?,
          );

          // Check if this is the final response (contains metrics)
          final hasTotalDuration = json['total_duration'] != null;
          final hasEvalCount = json['eval_count'] != null;
          final isDone = json['done'] == true;

          if (isDone || hasTotalDuration || hasEvalCount) {
            // Yield final response with accumulated text and metrics
            yield SimpleLlmResponse(
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
              completionTokens: _parseInt(json['completion_tokens']),
              totalTokens: _parseInt(json['total_tokens']),
            );
            break;
          }
        } catch (e) {
          yield SimpleLlmResponse(
            text: '',
            isError: true,
            errorMessage: 'Error parsing streaming response: $e',
          );
        }
      }
    } catch (e) {
      yield SimpleLlmResponse(
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

// ----- CUBIT IMPLEMENTATION -----

class SimpleLlmCubit extends Cubit<SimpleLlmState> {
  final SimpleLlmService _llmService;

  SimpleLlmCubit(this._llmService) : super(SimpleLlmState.initial());

  // Handle streaming method
  Stream<SimpleLlmState> handleStreamingRequest(String prompt,
      {String? modelName}) async* {
    yield SimpleLlmState.loading();

    try {
      final stream = _llmService.streamResponse(prompt, modelName: modelName);
      await for (final response in stream) {
        if (response.isError) {
          yield SimpleLlmState.error(response.errorMessage ?? 'Unknown error');
          return;
        }

        // Check if this is the final response based on metrics
        if (response.isFinalResponse) {
          // Final response with metrics
          yield SimpleLlmState.loaded(response);
        } else {
          // Incremental response
          yield SimpleLlmState.streaming(response);
        }
      }
    } catch (e) {
      yield SimpleLlmState.error('Error streaming response: $e');
    }
  }
}

// ----- USAGE EXAMPLE -----

// This is how you would use it in a widget
class OllamaStreamingExample extends StatefulWidget {
  const OllamaStreamingExample({Key? key}) : super(key: key);

  @override
  State<OllamaStreamingExample> createState() => _OllamaStreamingExampleState();
}

class _OllamaStreamingExampleState extends State<OllamaStreamingExample> {
  final _llmService = SimpleLlmService(
    baseUrl: 'http://localhost:11434',
    currentModel: 'llama2',
  );
  late final _llmCubit = SimpleLlmCubit(_llmService);

  StreamSubscription<SimpleLlmState>? _subscription;
  String _accumulatedText = '';
  bool _isWaitingForResponse = false;
  String? _errorMessage;

  @override
  void dispose() {
    _subscription?.cancel();
    _llmCubit.close();
    super.dispose();
  }

  void _sendMessage(String message) {
    setState(() {
      _isWaitingForResponse = true;
      _errorMessage = null;
      _accumulatedText = '';
    });

    final messageId = const Uuid().v4();

    // Start streaming
    _subscription?.cancel();
    _subscription = _llmCubit.handleStreamingRequest(message).listen(
      (state) {
        // Handle different state types
        if (state.type == SimpleLlmStateType.streaming &&
            state.response != null) {
          setState(() {
            // Accumulate text
            _accumulatedText += state.response!.text;
          });
        } else if (state.type == SimpleLlmStateType.loaded &&
            state.response != null) {
          setState(() {
            _isWaitingForResponse = false;

            // Final response is already in accumulatedText
            // If needed, additional metrics are in state.response!
          });
        } else if (state.type == SimpleLlmStateType.error) {
          setState(() {
            _isWaitingForResponse = false;
            _errorMessage = state.errorMessage;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isWaitingForResponse = false;
          _errorMessage = 'Stream error: $error';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display accumulated text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_accumulatedText.isNotEmpty) Text(_accumulatedText),
              if (_isWaitingForResponse && _accumulatedText.isEmpty)
                const Text('Thinking...'),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton(
            onPressed: _isWaitingForResponse
                ? null
                : () => _sendMessage('Tell me about quantum computing'),
            child: const Text('Send Example Query'),
          ),
        ),
      ],
    );
  }
}

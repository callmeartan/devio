# Ollama Streaming API Implementation

This document outlines how to implement the Ollama streaming API in a Flutter application, enabling real-time text streaming from the language model.

## Overview

Ollama provides two API endpoints for generating text:
1. Standard (non-streaming) API: `/api/generate`
2. Streaming API: `/api/generate` with streaming enabled

The streaming implementation offers a better user experience by showing the AI response as it's being generated rather than waiting for the complete response.

## Implementation Details

### 1. LlmService Implementation

```dart
Stream<LlmResponse> streamResponse(String prompt, {String? modelName}) async* {
  final client = http.Client();
  try {
    final response = await client.post(
      Uri.parse('$_baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'model': modelName ?? currentModel,
        'stream': true,
      }),
    );

    // Handle errors
    if (response.statusCode != 200) {
      yield LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Failed to get response: ${response.statusCode}',
      );
      return;
    }

    String accumulatedText = '';
    final streamedResponse = response.bodyBytes.transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in streamedResponse) {
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
        if (json['done'] == true || 
            (json['total_duration'] != null || json['eval_count'] != null)) {
          // Yield final response with accumulated text and metrics
          yield LlmResponse(
            text: accumulatedText,
            modelName: json['model'] as String?,
            totalDuration: json['total_duration'] as double?,
            loadDuration: json['load_duration'] as double?,
            promptEvalCount: json['prompt_eval_count'] as int?,
            promptEvalDuration: json['prompt_eval_duration'] as double?,
            promptEvalRate: json['prompt_eval_rate'] as double?,
            evalCount: json['eval_count'] as int?,
            evalDuration: json['eval_duration'] as double?,
            evalRate: json['eval_rate'] as double?,
          );
          break;
        }
      } catch (e) {
        developer.log('Error parsing streaming response: $e');
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
```

### 2. Cubit Implementation for State Management

```dart
Stream<LlmState> handleStreamingRequest(String prompt, {String? modelName}) async* {
  yield const LlmState.loading();
  
  try {
    final stream = _llmService.streamResponse(prompt, modelName: modelName);
    await for (final response in stream) {
      if (response.isError) {
        yield LlmState.error(response.errorMessage ?? 'Unknown error');
        return;
      }
      
      // Check if this is the final response based on metrics
      final isFinalResponse = response.totalDuration != null || response.evalCount != null;
      
      if (isFinalResponse) {
        // Final response with metrics
        yield LlmState.loaded(response: response);
      } else {
        // Incremental response
        yield LlmState.streaming(response: response);
      }
    }
  } catch (e) {
    yield LlmState.error('Error streaming response: $e');
  }
}
```

### 3. UI Implementation for Chat Screen

```dart
// In the chat screen
StreamSubscription<LlmState>? _subscription;
String _accumulatedText = '';

void _sendMessage(String message) {
  setState(() {
    _isWaitingForAiResponse = true;
  });
  
  final messageId = const Uuid().v4();
  
  // Add user message to chat
  context.read<ChatCubit>().addMessage(
    ChatMessage.user(
      chatId: widget.chatId,
      content: message,
      userId: _userId,
    ),
  );
  
  // Add initial placeholder for AI response
  context.read<ChatCubit>().addMessage(
    ChatMessage.ai(
      chatId: widget.chatId,
      content: 'Thinking...',
      userId: 'ai',
      isPlaceholder: true,
    ),
  );
  
  // Reset accumulated text
  _accumulatedText = '';
  
  // Start streaming
  final llmCubit = context.read<LlmCubit>();
  _subscription = llmCubit.handleStreamingRequest(message).listen(
    (state) {
      state.maybeWhen(
        streaming: (response) {
          // Accumulate text
          _accumulatedText += response.text;
          
          // Update the AI message with new content
          context.read<ChatCubit>().updateMessageContent(
            messageId: messageId,
            content: _accumulatedText,
          );
        },
        loaded: (response) {
          // Final response with metrics
          context.read<ChatCubit>().updateMessageWithMetrics(
            messageId: messageId,
            content: response.text,
            totalDuration: response.totalDuration,
            loadDuration: response.loadDuration,
            promptEvalCount: response.promptEvalCount,
            promptEvalDuration: response.promptEvalDuration,
            promptEvalRate: response.promptEvalRate,
            evalCount: response.evalCount,
            evalDuration: response.evalDuration,
            evalRate: response.evalRate,
          );
          
          setState(() {
            _isWaitingForAiResponse = false;
          });
          
          // Cancel subscription
          _subscription?.cancel();
        },
        error: (message) {
          context.read<ChatCubit>().updateMessageContent(
            messageId: messageId,
            content: 'Error: $message',
          );
          
          setState(() {
            _isWaitingForAiResponse = false;
          });
          
          // Cancel subscription
          _subscription?.cancel();
        },
        orElse: () {},
      );
    },
  );
}
```

## Error Handling

There are several types of errors to handle:

1. **Network errors**: Connection to Ollama server fails
2. **Server errors**: Ollama returns an error code
3. **Parsing errors**: Invalid JSON in the response stream
4. **Timeout errors**: Response takes too long

Implement appropriate error handling for each case and display user-friendly error messages.

## Performance Considerations

1. **Memory management**: Properly cancel stream subscriptions to avoid memory leaks
2. **Buffer management**: Handle large responses efficiently
3. **UI updates**: Use efficient state management to avoid excessive rebuilds

## References

- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Flutter Streams Documentation](https://dart.dev/tutorials/language/streams)
- [HTTP Package for Dart](https://pub.dev/packages/http) 
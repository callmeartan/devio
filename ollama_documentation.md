# Ollama API Integration

This document provides information on how to integrate with Ollama's API for local language model inference, including real-time streaming responses.

## API Endpoints

### 1. Generate (Non-Streaming)

```
POST /api/generate
```

Request body:
```json
{
  "model": "modelName:tag",
  "prompt": "Your prompt here",
  "stream": false,
  "options": {
    "num_predict": 1000,
    "temperature": 0.7
  }
}
```

Example response:
```json
{
  "model": "llama3:8b",
  "response": "Hello, I'm an AI assistant built with Llama 3. How can I help you today?",
  "done": true,
  "total_duration": 875879083,
  "load_duration": 100565667,
  "prompt_eval_duration": 38670917,
  "eval_duration": 736535250,
  "prompt_eval_count": 13,
  "eval_count": 42
}
```

### 2. Generate (Streaming)

```
POST /api/generate
```

Request body:
```json
{
  "model": "modelName:tag",
  "prompt": "Your prompt here",
  "stream": true,
  "options": {
    "num_predict": 1000,
    "temperature": 0.7
  }
}
```

The response is a stream of JSON objects, one per line. Each chunk contains a piece of the response:

```json
{"model":"llama3:8b","response":"Hello","done":false}
{"model":"llama3:8b","response":", ","done":false}
{"model":"llama3:8b","response":"I'm","done":false}
{"model":"llama3:8b","response":" an","done":false}
{"model":"llama3:8b","response":" AI","done":false}
{"model":"llama3:8b","response":" assistant","done":false}
...
{"model":"llama3:8b","response":"today?","done":false}
{"model":"llama3:8b","response":"","done":true,"total_duration":875879083,"load_duration":100565667,"prompt_eval_duration":38670917,"eval_duration":736535250,"prompt_eval_count":13,"eval_count":42}
```

The final chunk has `"done": true` and includes performance metrics.

## Implementation in DevIO

### LlmService Implementation

The `LlmService` class handles communication with the Ollama API:

```dart
// Non-streaming method
Future<LlmResponse> generateResponse({
  required String prompt,
  String? modelName,
  int maxTokens = 1000,
  double temperature = 0.7,
}) async {
  // Implementation details...
}

// Streaming method
Stream<LlmResponse> streamResponse({
  required String prompt,
  String? modelName,
  int maxTokens = 1000,
  double temperature = 0.7,
}) async* {
  try {
    final ollamaUrl = await getOllamaServerUrl();
    final formattedModelName = modelName?.contains(':') == true ? modelName : '$modelName:latest';
    
    final requestBody = {
      'model': formattedModelName,
      'prompt': prompt,
      'stream': true,
      'options': {
        'num_predict': maxTokens,
        'temperature': temperature,
      }
    };

    final request = http.Request('POST', Uri.parse('$ollamaUrl/api/generate'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(requestBody);

    final streamedResponse = await _client.send(request);
    
    if (streamedResponse.statusCode == 200) {
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String accumulatedText = '';
      Map<String, dynamic> finalMetrics = {};
      bool isDone = false;

      await for (final chunk in stream) {
        if (chunk.isEmpty) continue;
        
        final jsonChunk = jsonDecode(chunk);
        
        if (jsonChunk['done'] == true) {
          isDone = true;
          finalMetrics = _extractMetrics(jsonChunk);
          
          yield LlmResponse.fromJson({
            'text': accumulatedText,
            'model_name': modelName,
            ...finalMetrics,
          });
          break;
        }

        final responseText = jsonChunk['response'] as String? ?? '';
        accumulatedText += responseText;
        
        yield LlmResponse.fromJson({
          'text': responseText,
          'model_name': modelName,
        });
      }

      if (!isDone && accumulatedText.isNotEmpty) {
        yield LlmResponse.fromJson({
          'text': accumulatedText,
          'model_name': modelName,
        });
      }
    } else {
      // Handle error response
      yield LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Failed to generate: ${streamedResponse.statusCode}',
      );
    }
  } catch (e) {
    yield LlmResponse(
      text: '',
      isError: true,
      errorMessage: 'Error: $e',
    );
  }
}
```

### LlmCubit Implementation

The `LlmCubit` exposes the streaming functionality:

```dart
Stream<LlmState> streamResponse({
  required String prompt,
  String? modelName,
  int? maxTokens,
  double? temperature,
}) async* {
  yield const LlmState.loading();
  
  try {
    final stream = _llmService.streamResponse(
      prompt: prompt,
      modelName: modelName,
      maxTokens: maxTokens ?? 1000,
      temperature: temperature ?? 0.7,
    );
    
    await for (final response in stream) {
      if (response.isError) {
        yield LlmState.error(response.errorMessage!);
        break;
      } else {
        yield LlmState.success(response);
        
        // If this is the final response with metrics, we're done
        if (response.totalDuration != null || response.evalCount != null) {
          break;
        }
      }
    }
  } catch (e) {
    yield LlmState.error(e.toString());
  }
}
```

### UI Implementation

The UI needs to handle streaming responses by updating a message incrementally:

```dart
// Create a message in the chat immediately with empty content
final messageId = DateTime.now().millisecondsSinceEpoch.toString();
context.read<ChatCubit>().sendMessage(
  senderId: 'ai',
  content: '', // Start with empty content
  isAI: true,
  id: messageId,
  senderName: 'AI Assistant',
);

// Subscribe to the stream to update the message content in real-time
String accumulatedText = '';
subscription = responseStream.listen(
  (state) {
    state.maybeWhen(
      success: (response) {
        // Update the message with the new content
        if (response.text.isNotEmpty) {
          accumulatedText += response.text;
          context.read<ChatCubit>().updateMessageContent(
            messageId: messageId,
            newContent: accumulatedText,
          );
        }
        
        // Check if this is the final response with metrics
        final isFinalResponse = response.totalDuration != null || response.evalCount != null;
        if (isFinalResponse) {
          // Update metrics
          context.read<ChatCubit>().updateMessageMetrics(
            messageId: messageId,
            totalDuration: response.totalDuration,
            loadDuration: response.loadDuration,
            promptEvalCount: response.promptEvalCount,
            promptEvalDuration: response.promptEvalDuration,
            evalCount: response.evalCount,
            evalDuration: response.evalDuration,
          );
        }
      },
      // Handle other states...
    );
  },
);
```

## Benefits of Streaming

1. **Improved User Experience**: Responses appear incrementally, making the app feel more responsive
2. **Real-Time Feedback**: Users see the AI's "thought process" as it happens
3. **Faster Perceived Response Time**: The initial words appear quickly, rather than waiting for the entire response
4. **Progress Visibility**: Users know the system is working rather than wondering if it's frozen

## Handling Streaming Errors

Error handling is crucial with streaming responses:

1. Handle network interruptions
2. Manage timeout scenarios
3. Deal with malformed responses
4. Provide graceful fallback if streaming fails

## Performance Considerations

1. **Server Load**: Streaming creates more HTTP overhead but can actually reduce load on the client
2. **Memory Usage**: Be mindful of accumulating text in long responses
3. **UI Updates**: Throttle UI updates for extremely fast model responses to avoid excessive rebuilds
4. **Connection Stability**: Mobile connections may struggle with long-lived streaming connections

## References

- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [HTTP Package for Dart](https://pub.dev/packages/http)
- [Flutter BLoC Documentation](https://bloclibrary.dev/)


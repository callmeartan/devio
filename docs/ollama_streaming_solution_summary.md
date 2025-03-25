# Ollama Streaming API Implementation Solution

## Overview of Issues

The project was facing several issues when implementing the Ollama streaming API:

1. **Freezed Model Generation Problems**:
   - Missing implementations of required methods and getters in models
   - Pattern matching methods like `maybeWhen` and `whenOrNull` not being generated
   - Compilation errors in Freezed-generated code

2. **Streaming API Implementation Challenges**:
   - Need to track accumulated text from incremental responses
   - Properly detecting final responses with metrics
   - Managing stream subscriptions

## Solutions

### Solution 1: Fix Freezed Model Classes

The first approach was to fix the Freezed model generation by adding the `abstract` keyword to the model classes:

```dart
@freezed
abstract class LlmResponse with _$LlmResponse {
  const factory LlmResponse({
    required String text,
    // ...fields
  }) = _LlmResponse;

  factory LlmResponse.fromJson(Map<String, dynamic> json) =>
      _$LlmResponseFromJson(json);
}
```

However, this solution was only partly successful as the pattern matching methods like `maybeWhen` and `whenOrNull` still had issues.

### Solution 2: Alternative Implementation Without Freezed Dependencies

A more robust solution is to implement streaming without relying on Freezed's pattern matching. This approach uses:

1. **Simple Model Classes**:
   - Plain Dart classes without Freezed
   - Helper properties to determine response state

2. **Stream-Based API**:
   - HTTP request with streaming enabled
   - Proper handling of incremental responses
   - Detection of final responses based on metrics

3. **State Management**:
   - Enum-based state types
   - Type-safe factory constructors
   - Simple pattern matching with if/else

### Implementation Highlights

#### 1. LlmResponse Model

```dart
class SimpleLlmResponse {
  final String text;
  final bool isError;
  final String? errorMessage;
  final String? modelName;
  // ...other fields
  
  // Helper property to determine if this is a final response
  bool get isFinalResponse => totalDuration != null || evalCount != null;
}
```

#### 2. LlmState Model

```dart
enum SimpleLlmStateType { initial, loading, streaming, loaded, error }

class SimpleLlmState {
  final SimpleLlmStateType type;
  final SimpleLlmResponse? response;
  final String? errorMessage;
  
  // Factory constructors for each state type
  factory SimpleLlmState.streaming(SimpleLlmResponse response) => SimpleLlmState._(
    type: SimpleLlmStateType.streaming,
    response: response,
    errorMessage: null,
  );
  
  // ...other factory constructors
}
```

#### 3. Stream Implementation

```dart
Stream<SimpleLlmResponse> streamResponse(String prompt, {String? modelName}) async* {
  // ...setup code
  
  String accumulatedText = '';
  await for (final line in stream) {
    // Parse JSON response
    final responseText = json['response'] as String? ?? '';
    accumulatedText += responseText;
    
    // Yield incremental response
    yield SimpleLlmResponse(text: responseText);
    
    // Check if this is the final response
    if (isDone || hasTotalDuration || hasEvalCount) {
      // Yield final response with accumulated text and metrics
      yield SimpleLlmResponse(
        text: accumulatedText,
        modelName: json['model'] as String?,
        // ...metrics
      );
      break;
    }
  }
}
```

#### 4. State Management in UI

```dart
void _sendMessage(String message) {
  // ...setup code
  
  _subscription = _llmCubit.handleStreamingRequest(message).listen(
    (state) {
      if (state.type == SimpleLlmStateType.streaming && state.response != null) {
        setState(() {
          // Accumulate text
          _accumulatedText += state.response!.text;
        });
      } else if (state.type == SimpleLlmStateType.loaded && state.response != null) {
        setState(() {
          _isWaitingForResponse = false;
          // Final response handling
        });
      } else if (state.type == SimpleLlmStateType.error) {
        setState(() {
          _isWaitingForResponse = false;
          _errorMessage = state.errorMessage;
        });
      }
    },
  );
}
```

## Recommendations

1. **For New Projects**:
   - Use the simplified implementation without Freezed dependencies
   - Add Freezed once the pattern is established and working

2. **For Existing Projects**:
   - Update Freezed to the latest version
   - Add the `abstract` keyword to all Freezed model classes
   - Ensure `build_runner` is properly configured

3. **Detecting Final Responses**:
   - Don't rely on a single `isFinal` field
   - Check for metrics like `totalDuration` or `evalCount`
   - Handle stream completion appropriately

## Conclusion

The Ollama streaming API can be effectively implemented without requiring complex code generation tools like Freezed. The simplified approach provides:

- Better stability and easier debugging
- More control over response handling
- Simpler state management
- Clearer code paths for error handling

For projects already using Freezed, the proper model class definitions with the `abstract` keyword should resolve most issues. 
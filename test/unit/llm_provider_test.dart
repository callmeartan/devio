import 'package:flutter_test/flutter_test.dart';

import 'package:devio/features/llm/services/providers/lm_studio_provider.dart';
import 'package:devio/features/llm/services/providers/ollama_provider.dart';

void main() {
  test('parses Ollama chat NDJSON deltas', () {
    final delta = parseOllamaChatLine(
      '{"message":{"role":"assistant","content":"Hello"},"done":false}',
    );
    final done = parseOllamaChatLine('{"done":true}');

    expect(delta, 'Hello');
    expect(done, '');
  });

  test('parses OpenAI-compatible SSE deltas', () {
    final delta = parseOpenAiSseLine(
      'data: {"choices":[{"delta":{"content":"Hello"}}]}',
    );
    final done = parseOpenAiSseLine('data: [DONE]');

    expect(delta, 'Hello');
    expect(done, '');
  });
}

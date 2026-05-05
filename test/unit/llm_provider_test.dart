import 'package:flutter_test/flutter_test.dart';

import 'package:devio/features/llm/models/model_capabilities.dart';
import 'package:devio/features/llm/services/providers/lm_studio_provider.dart';
import 'package:devio/features/llm/services/providers/llm_provider.dart';
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

  test('formats image messages for OpenAI-compatible vision APIs', () {
    final json = toOpenAiChatMessageJson(
      const LlmMessage(
        role: 'user',
        content: 'What is this?',
        images: ['data:image/png;base64,abc123'],
      ),
    );

    expect(json['role'], 'user');
    expect(json['content'], isA<List>());
    expect((json['content'] as List).last, {
      'type': 'image_url',
      'image_url': {'url': 'data:image/png;base64,abc123'},
    });
  });

  test('parses LM Studio model metadata capabilities', () {
    final models = parseLmStudioV1ModelInfos('''
{
  "models": [
    {
      "type": "llm",
      "key": "qwen/qwen3.6-27b",
      "display_name": "Qwen3.6 27B",
      "publisher": "lmstudio-community",
      "architecture": "qwen35",
      "format": "gguf",
      "params_string": "27B",
      "max_context_length": 131072,
      "quantization": {"name": "IQ4_NL", "bits_per_weight": 4},
      "size_bytes": 18253611008,
      "loaded_instances": [{"id": "instance-1"}],
      "capabilities": {
        "vision": true,
        "trained_for_tool_use": true,
        "reasoning": {
          "allowed_options": ["low", "medium", "high"],
          "default": "medium"
        }
      }
    }
  ]
}
''');

    expect(models, hasLength(1));
    expect(models.single.id, 'qwen/qwen3.6-27b');
    expect(models.single.displayName, 'Qwen3.6 27B');
    expect(models.single.capabilitiesKnown, isTrue);
    expect(models.single.capabilities.supportsVision, isTrue);
    expect(models.single.capabilities.supportsToolUse, isTrue);
    expect(models.single.capabilities.reasoningOptions, contains('high'));
    expect(models.single.isLoaded, isTrue);
    expect(models.single.format, 'GGUF');
    expect(models.single.paramsString, '27B');
  });

  test('infers common local vision model names', () {
    expect(inferModelCapabilities('llava:13b').supportsVision, isTrue);
    expect(inferModelCapabilities('qwen/qwen2.5-vl-7b').supportsVision, isTrue);
    expect(inferModelCapabilities('qwen/qwen3.5-9b').supportsVision, isFalse);
  });
}

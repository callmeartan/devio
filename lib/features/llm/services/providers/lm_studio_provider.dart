import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';

class LmStudioProvider implements LlmProviderInterface {
  final http.Client _client;

  LmStudioProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get providerId => 'lmstudio';

  @override
  Future<List<String>> listModels(LlmProviderConfig config) async {
    try {
      final response = await _client
          .get(Uri.parse('${_trimBaseUrl(config.baseUrl)}/v1/models'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw HttpException(
          'LM Studio model list failed with status ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! List) {
        return [];
      }
      return (decoded['data'] as List)
          .whereType<Map>()
          .map((model) => model['id'])
          .whereType<String>()
          .toList();
    } on SocketException catch (e) {
      throw Exception('Unable to connect to LM Studio: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while listing LM Studio models');
    }
  }

  @override
  LlmStream chat(LlmProviderConfig config, List<LlmMessage> messages) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${_trimBaseUrl(config.baseUrl)}/v1/chat/completions'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode({
        'model': config.model,
        'messages': messages
            .map((message) => {
                  'role': message.role,
                  'content': message.content,
                })
            .toList(),
        'stream': true,
        'temperature': config.temperature,
        if (config.maxTokens != null) 'max_tokens': config.maxTokens,
      });

      final response =
          await _client.send(request).timeout(const Duration(seconds: 120));
      if (response.statusCode != 200) {
        throw HttpException(
          'LM Studio chat failed with status ${response.statusCode}',
        );
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        final delta = parseOpenAiSseLine(line);
        if (delta == null) {
          continue;
        }
        if (delta.isEmpty) {
          break;
        }
        yield delta;
      }
    } on SocketException catch (e) {
      throw Exception('Unable to connect to LM Studio: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while streaming from LM Studio');
    }
  }

  @override
  Future<String> chatOnce(
    LlmProviderConfig config,
    List<LlmMessage> messages,
  ) async {
    final buffer = StringBuffer();
    await for (final chunk in chat(config, messages)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  void dispose() {
    _client.close();
  }
}

String? parseOpenAiSseLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('data: ')) {
    return null;
  }

  final data = trimmed.substring(6).trim();
  if (data == '[DONE]') {
    return '';
  }

  final decoded = jsonDecode(data);
  if (decoded is! Map) {
    return null;
  }
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) {
    return null;
  }
  final firstChoice = choices.first;
  if (firstChoice is! Map) {
    return null;
  }
  final delta = firstChoice['delta'];
  if (delta is! Map) {
    return null;
  }
  final content = delta['content'];
  return content is String && content.isNotEmpty ? content : null;
}

String _trimBaseUrl(String baseUrl) {
  return baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
}

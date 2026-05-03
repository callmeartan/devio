import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';

class OllamaProvider implements LlmProviderInterface {
  final http.Client _client;

  OllamaProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get providerId => 'ollama';

  @override
  Future<List<String>> listModels(LlmProviderConfig config) async {
    try {
      final response = await _client
          .get(Uri.parse('${_trimBaseUrl(config.baseUrl)}/api/tags'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw HttpException(
          'Ollama model list failed with status ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['models'] is! List) {
        return [];
      }

      return (decoded['models'] as List)
          .whereType<Map>()
          .map((model) => model['name'])
          .whereType<String>()
          .toList();
    } on SocketException catch (e) {
      throw Exception('Unable to connect to Ollama: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while listing Ollama models');
    }
  }

  @override
  LlmStream chat(LlmProviderConfig config, List<LlmMessage> messages) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${_trimBaseUrl(config.baseUrl)}/api/chat'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/x-ndjson',
      });
      request.body = jsonEncode({
        'model': config.model,
        'messages': messages.map((message) => message.toJson()).toList(),
        'stream': true,
        'options': {
          'temperature': config.temperature,
          if (config.maxTokens != null) 'num_predict': config.maxTokens,
          if (config.contextSize != null) 'num_ctx': config.contextSize,
        },
      });

      final response =
          await _client.send(request).timeout(const Duration(seconds: 120));
      if (response.statusCode != 200) {
        throw HttpException(
          'Ollama chat failed with status ${response.statusCode}',
        );
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        final delta = parseOllamaChatLine(line);
        if (delta == null) {
          continue;
        }
        if (delta.isEmpty) {
          break;
        }
        yield delta;
      }
    } on SocketException catch (e) {
      throw Exception('Unable to connect to Ollama: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while streaming from Ollama');
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

String? parseOllamaChatLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final decoded = jsonDecode(trimmed);
  if (decoded is! Map) {
    return null;
  }
  if (decoded['done'] == true) {
    return '';
  }

  final message = decoded['message'];
  if (message is! Map) {
    return null;
  }

  final content = message['content'];
  return content is String && content.isNotEmpty ? content : null;
}

String _trimBaseUrl(String baseUrl) {
  return baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
}

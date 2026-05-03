import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';
import 'lm_studio_provider.dart';

class OpenAiCompatibleProvider implements LlmProviderInterface {
  final http.Client _client;

  OpenAiCompatibleProvider({http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get providerId => 'openai';

  @override
  Future<List<String>> listModels(LlmProviderConfig config) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${_baseUrl(config.baseUrl)}/v1/models'),
            headers: _headers(config),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw HttpException(
          'OpenAI-compatible model list failed with status '
          '${response.statusCode}',
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
      throw Exception(
          'Unable to connect to OpenAI-compatible API: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while listing OpenAI-compatible models');
    }
  }

  @override
  LlmStream chat(LlmProviderConfig config, List<LlmMessage> messages) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${_baseUrl(config.baseUrl)}/v1/chat/completions'),
      );
      request.headers.addAll(_headers(config));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
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
          'OpenAI-compatible chat failed with status ${response.statusCode}',
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
      throw Exception(
          'Unable to connect to OpenAI-compatible API: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while streaming from OpenAI-compatible API');
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

  Map<String, String> _headers(LlmProviderConfig config) {
    final apiKey = config.apiKey?.trim();
    return {
      if (apiKey != null && apiKey.isNotEmpty)
        'Authorization': 'Bearer $apiKey',
    };
  }

  String _baseUrl(String baseUrl) {
    final resolved =
        baseUrl.trim().isEmpty ? 'https://api.openai.com' : baseUrl;
    return resolved.endsWith('/')
        ? resolved.substring(0, resolved.length - 1)
        : resolved;
  }
}

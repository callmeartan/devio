import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/model_capabilities.dart';
import 'llm_provider.dart';

class LmStudioProvider implements LlmProviderInterface {
  final http.Client _client;

  LmStudioProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get providerId => 'lmstudio';

  @override
  Future<List<String>> listModels(LlmProviderConfig config) async {
    final modelInfos = await listModelInfos(config);
    return modelInfos.map((model) => model.id).toList();
  }

  @override
  Future<List<LlmModelInfo>> listModelInfos(LlmProviderConfig config) async {
    try {
      final nativeResponse = await _client
          .get(
            Uri.parse('${_trimApiBaseUrl(config.baseUrl)}/api/v1/models'),
            headers: _headers(config),
          )
          .timeout(const Duration(seconds: 10));
      if (nativeResponse.statusCode == 200) {
        return parseLmStudioV1ModelInfos(nativeResponse.body);
      }

      final legacyResponse = await _client
          .get(
            Uri.parse('${_trimApiBaseUrl(config.baseUrl)}/api/v0/models'),
            headers: _headers(config),
          )
          .timeout(const Duration(seconds: 10));
      if (legacyResponse.statusCode == 200) {
        final legacyModels = parseLmStudioV0ModelInfos(legacyResponse.body);
        if (legacyModels.isNotEmpty) {
          return legacyModels;
        }
      }

      final openAiResponse = await _client
          .get(
            Uri.parse('${_trimOpenAiBaseUrl(config.baseUrl)}/models'),
            headers: _headers(config),
          )
          .timeout(const Duration(seconds: 10));
      if (openAiResponse.statusCode != 200) {
        throw HttpException(
          'LM Studio model list failed with status '
          '${nativeResponse.statusCode}',
        );
      }
      return parseOpenAiModelInfos(openAiResponse.body, providerId);
    } on SocketException catch (e) {
      throw Exception('Unable to connect to LM Studio: ${e.message}');
    } on TimeoutException {
      throw Exception('Timed out while listing LM Studio models');
    }
  }

  List<LlmModelInfo> parseOpenAiModelInfos(String body, String providerId) {
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['data'] is! List) {
      return [];
    }
    return (decoded['data'] as List)
        .whereType<Map>()
        .map((model) => model['id'])
        .whereType<String>()
        .map((id) => LlmModelInfo.basic(id, providerId: providerId))
        .toList();
  }

  List<LlmModelInfo> parseLmStudioV0ModelInfos(String body) {
    final decoded = jsonDecode(body);
    final models =
        decoded is Map ? decoded['data'] ?? decoded['models'] : decoded;
    if (models is! List) {
      return [];
    }
    return models
        .whereType<Map>()
        .map((model) => _modelInfoFromLmStudioMap(model))
        .whereType<LlmModelInfo>()
        .toList();
  }

  @override
  LlmStream chat(LlmProviderConfig config, List<LlmMessage> messages) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${_trimOpenAiBaseUrl(config.baseUrl)}/chat/completions'),
      );
      request.headers.addAll({
        ..._headers(config),
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode({
        'model': config.model,
        'messages': messages.map(toOpenAiChatMessageJson).toList(),
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

  Map<String, String> _headers(LlmProviderConfig config) {
    final apiKey = config.apiKey?.trim();
    return {
      if (apiKey != null && apiKey.isNotEmpty)
        'Authorization': 'Bearer $apiKey',
    };
  }
}

List<LlmModelInfo> parseLmStudioV1ModelInfos(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map || decoded['models'] is! List) {
    return [];
  }
  return (decoded['models'] as List)
      .whereType<Map>()
      .map((model) => _modelInfoFromLmStudioMap(model))
      .whereType<LlmModelInfo>()
      .toList();
}

LlmModelInfo? _modelInfoFromLmStudioMap(Map model) {
  final key = model['key'] ?? model['id'];
  if (key is! String || key.isEmpty) {
    return null;
  }

  final capabilities = model['capabilities'];
  final reasoning = capabilities is Map ? capabilities['reasoning'] : null;
  final loadedInstances = model['loaded_instances'];
  final quantization = model['quantization'];
  final inferred = inferModelCapabilities(key);
  final capabilitiesKnown = capabilities is Map;

  return LlmModelInfo(
    id: key,
    displayName:
        _stringOrNull(model['display_name'] ?? model['displayName']) ?? key,
    providerId: 'lmstudio',
    type: _stringOrNull(model['type']),
    publisher: _stringOrNull(model['publisher']),
    architecture: _stringOrNull(model['architecture'] ?? model['arch']),
    quantizationName: quantization is Map
        ? _stringOrNull(quantization['name'] ?? quantization['type'])
        : _stringOrNull(model['quantization']),
    quantizationBits: quantization is Map
        ? _intOrNull(
            quantization['bits_per_weight'] ?? quantization['bitsPerWeight'],
          )
        : null,
    sizeBytes: _intOrNull(
      model['size_bytes'] ?? model['sizeBytes'] ?? model['size_on_disk_bytes'],
    ),
    paramsString: _stringOrNull(model['params_string']),
    maxContextLength: _intOrNull(
      model['max_context_length'] ?? model['context_length'],
    ),
    format: _stringOrNull(model['format'])?.toUpperCase(),
    isLoaded: loadedInstances is List && loadedInstances.isNotEmpty ||
        model['state'] == 'loaded',
    loadedInstanceIds: loadedInstances is List
        ? loadedInstances
            .whereType<Map>()
            .map((instance) => instance['id'])
            .whereType<String>()
            .toList()
        : const [],
    capabilities: ModelCapabilities(
      supportsVision: capabilitiesKnown
          ? capabilities['vision'] == true
          : inferred.supportsVision,
      supportsToolUse: capabilitiesKnown
          ? capabilities['trained_for_tool_use'] == true ||
              capabilities['tool_use'] == true
          : inferred.supportsToolUse,
      reasoningOptions: reasoning is Map && reasoning['allowed_options'] is List
          ? (reasoning['allowed_options'] as List).whereType<String>().toList()
          : inferred.reasoningOptions,
      defaultReasoning:
          reasoning is Map ? _stringOrNull(reasoning['default']) : null,
    ),
    capabilitiesKnown: capabilitiesKnown,
    description: _stringOrNull(model['description']),
    selectedVariant: _stringOrNull(
      model['selected_variant'] ?? model['selectedVariant'],
    ),
  );
}

String? _stringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : value?.toString();

int? _intOrNull(Object? value) => value is int
    ? value
    : value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

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

String _trimApiBaseUrl(String baseUrl) {
  final trimmed = _trimBaseUrl(baseUrl);
  return trimmed.endsWith('/v1')
      ? trimmed.substring(0, trimmed.length - 3)
      : trimmed;
}

String _trimOpenAiBaseUrl(String baseUrl) {
  final trimmed = _trimBaseUrl(baseUrl);
  return trimmed.endsWith('/v1') ? trimmed : '$trimmed/v1';
}

String _trimBaseUrl(String baseUrl) {
  final resolved = baseUrl.trim().isEmpty ? 'http://localhost:1234' : baseUrl;
  return resolved.endsWith('/')
      ? resolved.substring(0, resolved.length - 1)
      : resolved;
}

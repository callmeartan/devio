import '../../models/model_capabilities.dart';

class LlmMessage {
  final String role;
  final String content;

  /// Base64 image payloads. Data URL prefixes are accepted and stripped for
  /// providers that require raw base64.
  final List<String>? images;

  const LlmMessage({
    required this.role,
    required this.content,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (images != null && images!.isNotEmpty)
        'images': images!.map(stripImageDataUrlPrefix).toList(),
    };
  }
}

Map<String, dynamic> toOpenAiChatMessageJson(LlmMessage message) {
  final images = message.images;
  if (images == null || images.isEmpty) {
    return {
      'role': message.role,
      'content': message.content,
    };
  }

  return {
    'role': message.role,
    'content': [
      if (message.content.trim().isNotEmpty)
        {
          'type': 'text',
          'text': message.content,
        },
      ...images.map(
        (image) => {
          'type': 'image_url',
          'image_url': {
            'url': imageDataUrl(image),
          },
        },
      ),
    ],
  };
}

String imageDataUrl(String imagePayload) {
  if (imagePayload.startsWith('data:image/')) {
    return imagePayload;
  }
  return 'data:image/jpeg;base64,$imagePayload';
}

String stripImageDataUrlPrefix(String imagePayload) {
  final commaIndex = imagePayload.indexOf(',');
  if (imagePayload.startsWith('data:image/') && commaIndex != -1) {
    return imagePayload.substring(commaIndex + 1);
  }
  return imagePayload;
}

class LlmProviderConfig {
  final String baseUrl;
  final String? apiKey;
  final String model;
  final double temperature;
  final int? maxTokens;
  final int? contextSize;

  const LlmProviderConfig({
    required this.baseUrl,
    this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens,
    this.contextSize,
  });
}

typedef LlmStream = Stream<String>;

abstract interface class LlmProviderInterface {
  String get providerId;

  Future<List<String>> listModels(LlmProviderConfig config);

  Future<List<LlmModelInfo>> listModelInfos(LlmProviderConfig config);

  LlmStream chat(LlmProviderConfig config, List<LlmMessage> messages);

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
}

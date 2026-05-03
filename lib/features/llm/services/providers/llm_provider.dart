class LlmMessage {
  final String role;
  final String content;
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
      if (images != null && images!.isNotEmpty) 'images': images,
    };
  }
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

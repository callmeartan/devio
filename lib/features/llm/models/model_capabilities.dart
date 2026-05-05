class ModelCapabilities {
  final bool supportsVision;
  final bool supportsToolUse;
  final List<String> reasoningOptions;
  final String? defaultReasoning;

  const ModelCapabilities({
    required this.supportsVision,
    this.supportsToolUse = false,
    this.reasoningOptions = const [],
    this.defaultReasoning,
  });

  String get label => supportsVision ? 'Vision' : 'Text';

  String get description => supportsVision
      ? 'Understands text and attached images'
      : 'Text generation only';

  bool get supportsReasoning => reasoningOptions.isNotEmpty;
}

class LlmModelInfo {
  final String id;
  final String displayName;
  final String? providerId;
  final String? type;
  final String? publisher;
  final String? architecture;
  final String? quantizationName;
  final int? quantizationBits;
  final int? sizeBytes;
  final String? paramsString;
  final int? maxContextLength;
  final String? format;
  final bool isLoaded;
  final List<String> loadedInstanceIds;
  final ModelCapabilities capabilities;
  final bool capabilitiesKnown;
  final String? description;
  final String? selectedVariant;

  const LlmModelInfo({
    required this.id,
    required this.displayName,
    this.providerId,
    this.type,
    this.publisher,
    this.architecture,
    this.quantizationName,
    this.quantizationBits,
    this.sizeBytes,
    this.paramsString,
    this.maxContextLength,
    this.format,
    this.isLoaded = false,
    this.loadedInstanceIds = const [],
    required this.capabilities,
    this.capabilitiesKnown = false,
    this.description,
    this.selectedVariant,
  });

  factory LlmModelInfo.basic(
    String id, {
    String? displayName,
    String? providerId,
  }) {
    return LlmModelInfo(
      id: id,
      displayName: displayName ?? id,
      providerId: providerId,
      capabilities: inferModelCapabilities(id),
    );
  }

  String get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return '';
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(gb >= 10 ? 1 : 2)} GB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  String get primaryId => selectedVariant ?? id;
}

ModelCapabilities inferModelCapabilities(String? modelName) {
  final normalized = (modelName ?? '').toLowerCase();
  final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  final visionPatterns = <RegExp>[
    RegExp(r'(^|-)vision($|-)'),
    RegExp(r'(^|-)llava($|-)'),
    RegExp(r'(^|-)bakllava($|-)'),
    RegExp(r'(^|-)moondream($|-)'),
    RegExp(r'(^|-)pixtral($|-)'),
    RegExp(r'(^|-)internvl($|-)'),
    RegExp(r'(^|-)deepseek-vl($|-)'),
    RegExp(r'(^|-)qwen-vl($|-)'),
    RegExp(r'(^|-)qwen2-vl($|-)'),
    RegExp(r'(^|-)qwen2-5-vl($|-)'),
    RegExp(r'(^|-)qwen2vl($|-)'),
    RegExp(r'(^|-)qwen2-5vl($|-)'),
    RegExp(r'(^|-)minicpm-v($|-)'),
    RegExp(r'(^|-)mllama($|-)'),
    RegExp(r'(^|-)granite-vision($|-)'),
    RegExp(r'(^|-)phi-3-5-vision($|-)'),
  ];

  return ModelCapabilities(
    supportsVision: visionPatterns.any((pattern) => pattern.hasMatch(compact)),
  );
}

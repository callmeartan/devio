class ModelCapabilities {
  final bool supportsVision;

  const ModelCapabilities({
    required this.supportsVision,
  });

  String get label => supportsVision ? 'Vision' : 'Text';

  String get description => supportsVision
      ? 'Understands text and attached images'
      : 'Text generation only';
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

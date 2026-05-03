import 'providers/llm_provider.dart';
import 'providers/lm_studio_provider.dart';
import 'providers/ollama_provider.dart';
import 'providers/openai_compatible_provider.dart';

class LlmProviderRegistry {
  final Map<String, LlmProviderInterface> _providers;

  LlmProviderRegistry({
    OllamaProvider? ollamaProvider,
    LmStudioProvider? lmStudioProvider,
    OpenAiCompatibleProvider? openAiProvider,
  }) : _providers = {
          'ollama': ollamaProvider ?? OllamaProvider(),
          'lmstudio': lmStudioProvider ?? LmStudioProvider(),
          'openai': openAiProvider ?? OpenAiCompatibleProvider(),
        };

  LlmProviderInterface get(String providerId) {
    final normalizedId = providerId == 'local' ? 'ollama' : providerId;
    final provider = _providers[normalizedId];
    if (provider == null) {
      throw ArgumentError('Unknown LLM provider: $providerId');
    }
    return provider;
  }

  List<String> get availableProviders => _providers.keys.toList();

  void dispose() {
    for (final provider in _providers.values) {
      if (provider is OllamaProvider) {
        provider.dispose();
      } else if (provider is LmStudioProvider) {
        provider.dispose();
      } else if (provider is OpenAiCompatibleProvider) {
        provider.dispose();
      }
    }
  }
}

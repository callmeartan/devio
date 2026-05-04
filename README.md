# DevIO

DevIO is a Flutter chat workspace for building with local and OpenAI-compatible LLMs. The app is provider-first: you connect a model server, choose a model, and work from a clean chat surface without onboarding copy getting in the way.

## What Changed

- New Claude-inspired visual system with warmer surfaces, quieter borders, and more focused controls.
- Provider connection is now explicit. The model area shows Ollama, LM Studio, and OpenAI-compatible options with connection actions.
- Old intro and welcome text has been removed from chat, landing, onboarding, and empty states.
- The chat composer has been redesigned with a compact model chip, attachment/action controls, and a cleaner send affordance.
- Empty chat now starts from the actual task: connect a provider or start building.
- Provider status is visible from the chat header and model selection flow.

## Supported Providers

DevIO currently supports:

- Ollama, using the local `/api/chat` streaming API.
- LM Studio, using OpenAI-compatible `/v1/models` and `/v1/chat/completions` endpoints.
- OpenAI-compatible APIs, with configurable base URL and optional bearer token.

Provider IDs used internally:

```text
ollama
lmstudio
openai
```

`LlmProvider.local` is still mapped to Ollama for compatibility.

## Requirements

- Flutter SDK with Dart 3.x support
- Xcode for iOS/macOS builds
- At least one model provider:
  - Ollama on a local or network host
  - LM Studio with its local server enabled
  - Any OpenAI-compatible chat API

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Optional default Ollama host:

```bash
echo "OLLAMA_HOST=localhost:11434" > .env
```

## Connecting a Provider

Open the provider/model control in the chat UI and choose the provider you want to connect.

- Ollama: use a host like `localhost:11434`.
- LM Studio: use a base URL like `http://localhost:1234`.
- OpenAI-compatible: use a base URL like `https://api.openai.com` and add an API key when required.

After connecting, refresh models and select the model for the current chat.

## Local Data

Chats are stored locally with Drift and SQLite.

- Database file: `devio.sqlite`
- Location: platform application documents directory
- Main schema: `lib/database/app_database.dart`
- Migration service: `lib/database/migration_service.dart`

Provider settings are stored with SharedPreferences:

```text
llm_provider_id
llm_base_url
llm_api_key
llm_selected_model
llm_temperature
llm_max_tokens
```

Legacy SharedPreferences chat data is migrated once into SQLite and then left untouched.

## Project Structure

```text
lib/
├── blocs/           # BLoC state management
├── cubits/          # Cubit state management
├── database/        # Drift schema and migration service
├── features/        # LLM and settings features
├── models/          # Data models
├── repositories/    # Data access layer
├── screens/         # App screens
├── services/        # App services
├── theme/           # Visual system
└── widgets/         # Reusable UI components
```

Provider implementations live in:

```text
lib/features/llm/services/
├── llm_provider_registry.dart
├── llm_service.dart
└── providers/
    ├── llm_provider.dart
    ├── ollama_provider.dart
    ├── lm_studio_provider.dart
    └── openai_compatible_provider.dart
```

## Development

Run code generation after changing Drift tables, freezed models, or JSON-serializable models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Common checks:

```bash
flutter analyze
flutter test
```

The test suite includes coverage for Drift-backed chat storage, chat history behavior, message updates, metrics, Ollama stream parsing, and OpenAI-compatible SSE stream parsing.

## Adding a Provider

1. Implement `LlmProviderInterface` in `lib/features/llm/services/providers/`.
2. Register it in `lib/features/llm/services/llm_provider_registry.dart`.
3. Persist any provider-specific settings through `LlmCubit`.
4. Add parser or provider tests under `test/unit/`.
5. Expose only the provider controls that users need to connect and select a model.

## License

MIT

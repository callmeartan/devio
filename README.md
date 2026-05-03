# DevIO

DevIO is a Flutter application for local-first AI chat and app-development guidance. It supports Ollama by default and includes provider abstractions for LM Studio and OpenAI-compatible chat APIs.

## Current Status

### Implemented
- **Ollama chat** - Default local provider, using Ollama's multi-turn `/api/chat` streaming API.
- **LM Studio provider** - OpenAI-compatible model listing and streaming chat through `/v1/models` and `/v1/chat/completions`.
- **OpenAI-compatible provider** - Configurable base URL with optional bearer API key support.
- **Local chat storage** - Conversations and messages are stored locally in Drift/SQLite.
- **Legacy migration** - Existing SharedPreferences chat data migrates into SQLite on first launch.
- **Chat management** - Existing chat title generation, pinning, renaming, deleting, message updates, streaming placeholders, search filtering, and metrics storage are preserved.
- **Demo mode** - Test app behavior without a running LLM server.

### Not Yet Implemented
- Anthropic provider
- Full provider-selection UI for every OpenAI-compatible setting

## Requirements

- Flutter SDK with Dart 3.x support
- Ollama server for the default local LLM workflow
- LM Studio or another OpenAI-compatible server if using non-Ollama providers

## Setup

```bash
# Install dependencies
flutter pub get

# Generate Drift, freezed, and JSON serialization code
dart run build_runner build --delete-conflicting-outputs

# Optional: set the default Ollama host
echo "OLLAMA_HOST=localhost:11434" > .env

# Run the app
flutter run
```

## Local Data

Chat persistence is handled by Drift/SQLite:

- Database file: `devio.sqlite`
- Location: the platform application documents directory
- Main schema: `lib/database/app_database.dart`
- Migration service: `lib/database/migration_service.dart`

Settings and provider preferences still use SharedPreferences. Legacy chat keys are read once for migration:

- `devio.local.chat.messages.v1`
- `devio.local.chat.metadata.v1`

After a successful migration, the app marks `drift_migration_done_v1` and keeps the old SharedPreferences data untouched.

## LLM Providers

Provider code lives under `lib/features/llm/services/`.

```
lib/features/llm/services/
├── llm_provider_registry.dart
├── llm_service.dart
└── providers/
    ├── llm_provider.dart
    ├── ollama_provider.dart
    ├── lm_studio_provider.dart
    └── openai_compatible_provider.dart
```

Supported provider IDs:

- `ollama`
- `lmstudio`
- `openai`

`LlmProvider.local` is kept as a compatibility path and maps to Ollama.

## Code Generation

Run code generation after changing Drift tables, freezed models, or JSON-serializable models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

```
lib/
├── blocs/           # BLoC state management
├── cubits/          # Cubit state management
├── database/        # Drift database schema and migration service
├── features/        # Feature modules organized by domain
│   ├── llm/         # LLM cubit, models, services, provider implementations
│   └── settings/    # App preferences
├── models/          # Data models
├── repositories/    # Data access layer
├── screens/         # UI screens
├── services/        # Business logic services
├── theme/           # App theming
└── widgets/         # Reusable UI components
```

## Key Technologies

- **flutter_bloc** / **cubits** - State management
- **provider** - Dependency wiring
- **go_router** - Navigation
- **drift** + **sqlite3_flutter_libs** - Local SQLite persistence
- **shared_preferences** - Settings and provider preferences
- **freezed** + **json_serializable** - Immutable models and JSON serialization
- **http** - API communication with LLM servers

## Validation

Common checks:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

The test suite includes focused coverage for:

- Drift-backed chat repository behavior
- Chat history sorting, rename, delete cascade, message updates, and metrics roundtrip
- Ollama NDJSON stream parsing
- OpenAI-compatible SSE stream parsing

## Adding a New LLM Provider

1. Implement `LlmProviderInterface` from `lib/features/llm/services/providers/llm_provider.dart`.
2. Register the provider in `lib/features/llm/services/llm_provider_registry.dart`.
3. Update `LlmCubit` provider switching/config persistence if the provider needs new settings.
4. Add parser or provider tests under `test/unit/`.
5. Update UI only where provider selection or provider-specific settings need to be exposed.

## License

MIT

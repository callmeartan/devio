# DevIO

DevIO is a privacy-first Flutter chat client for working with local and OpenAI-compatible language models. It gives you a clean cross-platform interface for connecting to Ollama, LM Studio, or any compatible chat-completions endpoint while keeping provider configuration and chat history under your control.

**Repository About**

Privacy-first Flutter client for local and OpenAI-compatible LLMs, with Ollama and LM Studio support, streaming chat, provider switching, and local chat storage.

## Features

- Connect to Ollama, LM Studio, or OpenAI-compatible APIs.
- Stream chat responses from local or self-hosted model servers.
- Switch providers, models, temperature, token limits, and endpoint settings from the app.
- Read LM Studio model metadata for vision, tool-use, reasoning, quantization, context length, and loaded-state indicators.
- Store chat history locally with Drift and SQLite.
- Persist provider settings locally with SharedPreferences and secure storage.
- Attach images for vision-capable LM Studio and OpenAI-compatible models.
- Run across Flutter-supported platforms from one codebase.

## Supported Providers

| Provider | Default endpoint | Notes |
| --- | --- | --- |
| Ollama | `http://localhost:11434` | Uses Ollama chat and model APIs. |
| LM Studio | `http://localhost:1234` | Uses LM Studio native model metadata APIs plus OpenAI-compatible chat completions. |
| OpenAI-compatible | `https://api.openai.com` | Works with compatible `/v1/models` and `/v1/chat/completions` APIs, including multimodal image content when supported by the model. |

Provider implementations live in [`lib/features/llm/services/providers/`](lib/features/llm/services/providers/).

### LM Studio Support

DevIO treats LM Studio as a first-class local provider:

- Discovers models through LM Studio's native `/api/v1/models` endpoint.
- Falls back to `/api/v0/models`, then OpenAI-compatible `/v1/models`, when needed.
- Shows model capabilities from LM Studio metadata instead of relying on hardcoded model-name checks.
- Indicates vision, tool-use, reasoning, format, quantization, parameter size, context length, disk size, and loaded state in the model UI.
- Sends image attachments using OpenAI-compatible multimodal chat content for vision-capable models.

## Requirements

- Flutter SDK with Dart 3 support
- Xcode for iOS or macOS builds
- Android Studio or Android SDK for Android builds
- A running model server, such as Ollama or LM Studio

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Generate Drift, Freezed, and JSON serialization files when models or database schema change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run the app:

```bash
flutter run
```

Run checks:

```bash
flutter analyze
flutter test
```

## Environment

DevIO can run without a committed `.env` file. Local environment values are optional and should stay private.

Create a local `.env` from the example when you want a default Ollama host:

```bash
cp .env.example .env
```

Example:

```dotenv
OLLAMA_HOST=localhost:11434
```

The app also stores provider choices, base URLs, API keys, selected models, temperature, and token limits through local preferences.

## Project Structure

```text
lib/
  blocs/          Auth state
  cubits/         Chat state
  database/       Drift database and migrations
  features/       LLM, settings, profile, help, feedback, notifications
  models/         Serializable app models
  repositories/   Data access layer
  screens/        App screens
  services/       AI and demo services
  theme/          Material theme
  widgets/        Reusable UI components
```

Important paths:

- [`lib/main.dart`](lib/main.dart): app bootstrap, dependency setup, and routing.
- [`lib/database/app_database.dart`](lib/database/app_database.dart): Drift schema.
- [`lib/repositories/chat_repository.dart`](lib/repositories/chat_repository.dart): chat persistence.
- [`lib/features/llm/cubit/llm_cubit.dart`](lib/features/llm/cubit/llm_cubit.dart): provider configuration state.
- [`lib/features/llm/services/llm_provider_registry.dart`](lib/features/llm/services/llm_provider_registry.dart): provider registration.

## Development Notes

Regenerate code after changing:

- Drift tables or DAOs
- Freezed state or model classes
- JSON-serializable models

Do not commit local machine state, generated build output, private environment files, IDE workspace settings, dependency symlinks, or downloaded archives.

## License

MIT

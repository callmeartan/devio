# DevIO

A Flutter application for interacting with locally hosted LLMs (Ollama, LM Studio, OpenAI-compatible APIs).

## Current Status

### Implemented
- **Ollama** - Full support for local Ollama instances
- **Local chat storage** - All data stored locally via SharedPreferences
- **Demo mode** - Test features without a running LLM server

### Not Yet Implemented
- LM Studio provider
- OpenAI-compatible API provider
- Anthropic provider

## Requirements

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Ollama server (for local LLM features)

## Setup

```bash
# Install dependencies
flutter pub get

# (Optional) Create .env for default Ollama host
echo "OLLAMA_HOST=localhost:11434" > .env

# Run the app
flutter run
```

## Code Generation

This project uses freezed and json_serializable for immutable models and JSON serialization.

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture

```
lib/
├── blocs/           # BLoC state management
├── cubits/          # Cubit state management (lighter than BLoC)
├── features/        # Feature modules organized by domain
│   ├── llm/         # LLM integration (service, cubit, models)
│   └── settings/    # App preferences
├── models/          # Data models (freezed)
├── repositories/    # Data access layer
├── screens/         # UI screens
├── services/        # Business logic services
├── theme/           # App theming
└── widgets/        # Reusable UI components
```

## Key Technologies

- **flutter_bloc** / **cubits** - State management
- **go_router** - Navigation
- **freezed** + **json_serializable** - Immutable models
- **SharedPreferences** - Local storage (chats, settings)
- **http** - API communication with LLM servers

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run the analyzer (`flutter analyze`)
5. Commit and push
6. Open a PR

### Adding a New LLM Provider

1. Add provider to `LlmProvider` enum in `lib/features/llm/cubit/llm_cubit.dart`
2. Create a new service class or extend `LlmService`
3. Update UI to handle the new provider
4. Add appropriate tests

## License

MIT
# Devio - Your AI Guide to App Building

Devio is a mobile application that provides AI-driven guidance throughout the app development process, from idea validation to deployment.

## Features

- Clean, modern UI with Material Design 3
- Chat-based interface for interacting with AI
- Authentication flow (mock implementation)
- Progress tracking
- Profile management

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / Xcode for running on emulators/simulators

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/devio.git
```

2. Navigate to the project directory:
```bash
cd devio
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run code generation for Freezed models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart           # App entry point
├── routes.dart         # Navigation routes
├── screens/           # Screen widgets
│   ├── landing_screen.dart
│   ├── auth_screen.dart
│   ├── chat_screen.dart
│   └── profile_screen.dart
├── widgets/           # Reusable widgets
│   └── chat_message.dart
├── models/            # Data models
│   └── message.dart
├── services/          # Business logic
│   └── ai_service.dart
└── theme/            # App theme
    └── app_theme.dart
```

## Development

The app is built with:
- Flutter for the UI framework
- GoRouter for navigation
- Freezed for immutable models
- Material Design 3 for theming

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

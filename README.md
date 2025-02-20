# DevIO - AI Development Guide

A modern Flutter application that combines AI-powered development assistance with Firebase backend integration, featuring a robust authentication system, real-time data synchronization, and a beautiful Material Design 3 UI.

## Features

- 🔐 Multi-provider Authentication
  - Google Sign-In
  - Apple Sign-In
  - GitHub Sign-In
  - Email/Password Authentication

- 🔥 Firebase Integration
  - Cloud Firestore for real-time data storage
  - Firebase Storage for file management
  - Firebase Analytics for usage tracking
  - Firebase Crashlytics for error reporting
  - Firebase Cloud Messaging for push notifications

- 🤖 AI Development Features
  - Interactive chat interface with AI models
  - Real-time code suggestions
  - Development guidance
  - Performance optimization tips

- 🎨 Modern UI/UX
  - Material Design 3 with dynamic theming
  - Responsive layout for all screen sizes
  - Cached network images for optimal performance
  - Custom animations and transitions

## Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (latest stable version)
- Dart SDK (>=3.0.0 <4.0.0)
- Firebase CLI
- Git

## Setup

### 1. Flutter Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/devio.git
cd devio

# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication methods:
   - Google
   - Apple
   - GitHub
   - Email/Password
3. Create a Firestore database
4. Set up Firebase Storage
5. Download and add configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
   - Configure web platform if needed

### 3. Environment Configuration

Create a `.env` file in the root directory:

```env
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
```

## Project Structure

```
lib/
├── core/
│   ├── config/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── chat/
│   ├── dashboard/
│   └── settings/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── services/
└── main.dart
```

## State Management

The app uses Flutter Bloc (Cubit) for state management with the following principles:
- Separate business logic from UI
- Immutable state objects using Freezed
- Reactive programming patterns
- Error handling and loading states

## Authentication Flow

1. User selects authentication method
2. Authentication process handled by respective provider
3. Firebase Authentication token generated
4. User profile created/updated in Firestore
5. App state updated with user session

## Development Guidelines

### Code Style
- Follow Flutter's official style guide
- Use `flutter_lints` for consistent code quality
- Maintain proper documentation
- Implement error handling

### Performance
- Use const constructors where possible
- Implement proper caching strategies
- Optimize Firebase queries
- Monitor analytics and crashlytics

### Testing
```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Available Commands

```bash
# Development
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Generate l10n
flutter gen-l10n

# Update dependencies
flutter pub upgrade
```

## Deployment

### Android
1. Update version in pubspec.yaml
2. Generate release build
3. Test on release build
4. Deploy to Play Store

### iOS
1. Update version in pubspec.yaml
2. Generate release build
3. Test on release build
4. Deploy through App Store Connect

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Troubleshooting

- **Firebase Authentication Issues**
  - Verify Firebase configuration files
  - Check enabled authentication methods
  - Verify OAuth configurations

- **Build Issues**
  - Run `flutter clean`
  - Delete build/ folder
  - Re-run `flutter pub get`
  - Re-run code generation

- **Performance Issues**
  - Check Firebase query optimization
  - Verify image caching
  - Monitor memory usage
  - Check widget rebuilds

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- All contributors who have helped shape this project

# DevIO - AI Development Guide

A modern Flutter application that combines AI-powered development assistance with Firebase backend integration. Built with Flutter and Firebase, featuring Material Design 3, robust state management with Bloc pattern, and comprehensive authentication system.

## Tech Stack

- 🎯 **Flutter SDK** (>=3.0.0 <4.0.0)
- 🔥 **Firebase Suite** (v3.11.0+)
- 🏗️ **State Management**: flutter_bloc (v9.0.0)
- 🛣️ **Navigation**: go_router (v14.8.0)
- 🧊 **Immutable Models**: freezed (v2.4.5)
- 🎨 **UI Components**: flutter_hooks (v0.20.0)
- 🔐 **Authentication Providers**:
  - Firebase Auth (v5.4.2)
  - Google Sign In (v6.2.1)
  - Apple Sign In (v6.1.4)
  - GitHub Sign In (v0.0.5-dev.4)

## Features

### 🔐 Authentication & Security
- Multi-provider authentication system
- Secure token management
- User session persistence
- Role-based access control
- Biometric authentication support

### 🎨 Modern UI/UX
- Material Design 3 implementation
- Dynamic color theming
- Responsive layouts
- Custom animations
- Font Awesome icons integration
- Adaptive layouts for different screen sizes
- Dark mode support

### 🔥 Firebase Integration
- Real-time data synchronization
- Cloud Storage for file management
- Analytics tracking
- Push notifications
- Crash reporting
- Cloud Functions integration
- Security Rules implementation

### 🚀 Performance Optimizations
- Cached network images
- Lazy loading
- Efficient state management
- Optimized Firebase queries
- Memory management
- Widget rebuilding optimization

## Architecture

### Project Structure
```
lib/
├── core/           # Core functionality and configurations
│   ├── config/     # App configuration
│   ├── constants/  # App constants
│   ├── theme/      # App theming
│   └── utils/      # Utility functions
├── features/       # Feature-based modules
│   ├── auth/       # Authentication feature
│   ├── home/       # Home feature
│   └── settings/   # Settings feature
├── shared/         # Shared widgets and utilities
│   ├── widgets/    # Common widgets
│   ├── models/     # Shared models
│   └── services/   # Shared services
└── main.dart       # Application entry point
```

### State Management
- **Bloc Pattern**
  - Cubits for simple state management
  - Blocs for complex flows
  - Event-driven architecture
  - State immutability with Freezed
  - Proper error handling

### Testing Strategy
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for feature flows
- Golden tests for visual regression
- Bloc test coverage
- Firebase test coverage

## Getting Started

### Prerequisites
```bash
# Required tools
flutter --version  # Flutter 3.0.0 or higher
dart --version    # Dart 3.0.0 or higher
firebase --version # Firebase CLI
git --version     # Git
```

### Installation

1. **Clone the Repository**
```bash
git clone <repository-url>
cd devio
```

2. **Install Dependencies**
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Firebase Setup**
- Create a new Firebase project
- Enable required services:
  - Authentication
  - Firestore
  - Storage
  - Analytics
  - Crashlytics
  - Cloud Messaging
- Download and add configuration files:
  - Android: `google-services.json`
  - iOS: `GoogleService-Info.plist`
  - Web: Firebase configuration object

4. **Environment Configuration**
Create a `.env` file in the project root:
```env
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
```

## Project Structure
```
lib/
├── core/           # Core functionality and configurations
├── features/       # Feature-based modules
├── shared/         # Shared widgets and utilities
└── main.dart       # Application entry point
```

## Development Guidelines

### Code Style & Conventions
- Use `flutter_lints` for consistent code quality
- Follow Flutter's style guide
- Implement proper error handling
- Write comprehensive documentation
- Use trailing commas for better formatting
- Keep lines under 80 characters
- Use const constructors for immutable widgets
- Implement descriptive variable names with auxiliary verbs (e.g., isLoading)

### State Management Best Practices
- Use Bloc/Cubit for state management
- Implement Freezed for immutable state
- Handle loading and error states properly
- Use proper dependency injection
- Prefer context.read() or context.watch() for accessing Bloc states
- Handle state transitions and side effects in mapEventToState

### Error Handling
- Display errors using SelectableText.rich with red color
- Handle empty states within the displaying screen
- Manage error handling within Cubit states
- Implement proper Firebase exception handling
- Use detailed error messages and appropriate logging

### Firebase Guidelines
- Implement proper security rules
- Use indexes for optimized queries
- Include createdAt, updatedAt, and isDeleted fields
- Handle real-time updates efficiently
- Implement proper error handling for Firebase operations
- Use appropriate caching strategies

### Widget Guidelines
- Create small, private widget classes instead of methods
- Implement RefreshIndicator for pull-to-refresh
- Use proper text input configurations
- Always include errorBuilder for network images
- Implement responsive layouts using LayoutBuilder
- Use proper Theme.of(context) text styles

### Performance Best Practices
- Implement const constructors
- Use proper caching strategies
- Optimize Firebase queries
- Monitor analytics and crashlytics
- Use ListView.builder for long lists
- Implement proper image caching
- Optimize widget rebuilds

## Available Commands

### Development
```bash
# Run in debug mode
flutter run

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes and run code generation
flutter pub run build_runner watch --delete-conflicting-outputs

# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test

# Run golden tests
flutter test --update-goldens
```

### Code Generation
```bash
# Generate freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# Generate l10n files
flutter gen-l10n

# Generate assets
flutter pub run flutter_gen
```

### Build
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
flutter build ipa --release

# Web
flutter build web --release
```

### Firebase Deployment
```bash
# Deploy Firebase Functions
firebase deploy --only functions

# Deploy Firestore Rules
firebase deploy --only firestore:rules

# Deploy Storage Rules
firebase deploy --only storage:rules
```

## Deployment

### Android Release
1. Update version in pubspec.yaml
2. Prepare release notes
3. Build release APK/Bundle
4. Deploy to Play Store

### iOS Release
1. Update version in pubspec.yaml
2. Prepare release notes
3. Build and archive in Xcode
4. Deploy through App Store Connect

## Troubleshooting

### Common Issues
- **Build Errors**: Run `flutter clean` and rebuild
- **Dependencies**: Update packages and rebuild
- **Firebase**: Verify configuration files
- **Code Generation**: Delete generated files and rerun build_runner

### Performance Issues
- Check widget rebuilds
- Monitor memory usage
- Verify Firebase query optimization
- Inspect image caching

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Built with 💙 using Flutter

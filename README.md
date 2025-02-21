# DevIO - AI Development Guide

A modern Flutter application that combines AI-powered development assistance with Firebase backend integration. Built with Flutter and Firebase, featuring Material Design 3, robust state management with Bloc pattern, and comprehensive authentication system.

## Tech Stack

- 🎯 **Flutter SDK** (>=3.0.0 <4.0.0)
- �� **Firebase Suite**
  - Core (v3.11.0)
  - Auth (v5.4.2)
  - Firestore (v5.6.3)
  - Storage (v12.4.2)
  - Analytics (v11.4.2)
  - Messaging (v15.2.2)
  - Crashlytics (v4.3.2)
- 🏗️ **State Management**
  - flutter_bloc (v9.0.0)
  - provider (v6.1.1)
- 🛣️ **Navigation**: go_router (v14.8.0)
- 🧊 **Data Handling**
  - freezed (v2.4.5)
  - json_serializable (v6.7.1)
- 🔐 **Authentication**
  - Firebase Auth (v5.4.2)
  - Google Sign In (v6.2.1)
  - Apple Sign In (v6.1.4)
  - GitHub Sign In (v0.0.5-dev.4)
- 🎨 **UI Components**
  - font_awesome_flutter (v10.7.0)
  - cached_network_image (v3.3.1)
  - JosefinSans Font Family

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
- Use `flutter_lints` (v5.0.0) for consistent code quality
- Follow Flutter's style guide and Material Design 3 principles
- Implement proper error handling with SelectableText.rich
- Write comprehensive documentation with examples
- Use trailing commas for better formatting and diffs
- Keep lines under 80 characters
- Use const constructors for immutable widgets
- Implement descriptive variable names with auxiliary verbs (e.g., isLoading)
- Follow functional and declarative programming patterns
- Prefer composition over inheritance

### State Management Best Practices
- Use Bloc for complex flows and Cubit for simple state management
- Implement Freezed for immutable state classes and unions
- Handle loading and error states within Cubit states
- Use proper dependency injection with Provider
- Prefer context.read() or context.watch() for accessing Bloc states
- Handle state transitions and side effects in mapEventToState
- Use BlocObserver for monitoring state transitions during debugging

### Firebase Integration Guidelines
- Implement proper security rules (defined in firestore.rules)
- Use indexes for optimized queries (defined in firestore.indexes.json)
- Include createdAt, updatedAt, and isDeleted fields in documents
- Handle real-time updates efficiently with StreamBuilder
- Implement proper error handling for Firebase operations
- Use appropriate caching strategies with cached_network_image
- Secure database rules based on user roles and permissions
- Use Firebase Analytics for tracking user behavior

### Widget Guidelines
- Create small, private widget classes instead of methods
- Implement RefreshIndicator for pull-to-refresh functionality
- Use proper text input configurations (textCapitalization, keyboardType)
- Always include errorBuilder when using Image.network
- Implement responsive layouts using LayoutBuilder or MediaQuery
- Use Theme.of(context).textTheme for consistent text styling
- Implement adaptive layouts for different screen sizes
- Use BlocBuilder for state-dependent UI updates
- Use BlocListener for handling side effects

### Performance Best Practices
- Implement const constructors where possible
- Use ListView.builder for long lists
- Implement proper image caching with cached_network_image
- Optimize Firebase queries with proper indexing
- Monitor analytics and crashlytics
- Use proper widget keys for efficient rebuilds
- Implement proper memory management
- Use AssetImage for static images
- Optimize widget rebuilds with proper state management

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
```

### Firebase Commands
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Cloud Functions
firebase deploy --only functions

# Run Firebase emulators
firebase emulators:start
```

### Build Commands
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

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

* Flutter Team for the amazing framework
* Firebase Team for the robust backend services
* All contributors who have helped shape this project

---
Built with 💙 using Flutter

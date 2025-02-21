# DevIO - AI Development Guide

A modern Flutter application that combines AI-powered development assistance with Firebase backend integration. Built with Flutter and Firebase, featuring Material Design 3, robust state management with Bloc pattern, and comprehensive authentication system.

## Tech Stack

- 🎯 **Flutter SDK** (>=3.0.0 <4.0.0)
- 🔥 **Firebase Suite** (v3.11.0+)
- 🏗️ **State Management**: flutter_bloc (v9.0.0)
- 🛣️ **Navigation**: go_router (v14.8.0)
- 🧊 **Immutable Models**: freezed (v2.4.5)
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

### 🎨 Modern UI/UX
- Material Design 3 implementation
- Dynamic color theming
- Responsive layouts
- Custom animations
- Font Awesome icons integration

### 🔥 Firebase Integration
- Real-time data synchronization
- Cloud Storage for file management
- Analytics tracking
- Push notifications
- Crash reporting

### 🚀 Performance Optimizations
- Cached network images
- Lazy loading
- Efficient state management
- Optimized Firebase queries

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

### Code Style
- Use `flutter_lints` for consistent code quality
- Follow Flutter's style guide
- Implement proper error handling
- Write comprehensive documentation

### State Management
- Use Bloc/Cubit for state management
- Implement Freezed for immutable state
- Handle loading and error states
- Use proper dependency injection

### Performance Best Practices
- Implement const constructors
- Use proper caching strategies
- Optimize Firebase queries
- Monitor analytics and crashlytics

## Available Commands

### Development
```bash
# Run in debug mode
flutter run

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test
```

### Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

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
1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Built with 💙 using Flutter

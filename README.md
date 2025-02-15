# DevIO

AI-driven guidance for app development.

## Overview

DevIO is a modern Flutter application that provides AI-driven guidance for app development. Built with Flutter and Firebase, it offers a robust platform for developers to interact with AI assistance, manage projects, and collaborate effectively.

## Features

- 🔐 **Authentication**
  - Multi-provider authentication (Email, Google, Apple, GitHub)
  - Secure user session management
  - Profile management

- 💬 **Real-time Chat**
  - AI-powered development assistance
  - Real-time messaging
  - Code snippet support
  - File sharing capabilities

- 🎨 **Modern UI/UX**
  - Dark theme support
  - Responsive design
  - Material 3 design principles
  - Smooth animations and transitions

- 🔥 **Firebase Integration**
  - Cloud Firestore for data storage
  - Firebase Authentication
  - Firebase Storage for file management
  - Firebase Analytics for usage tracking
  - Firebase Crashlytics for error reporting

## Technical Stack

- **Framework**: Flutter (SDK >=3.0.0)
- **State Management**: flutter_bloc, Provider
- **Routing**: go_router
- **Code Generation**: freezed, json_serializable
- **Backend**: Firebase
- **Authentication**: firebase_auth, google_sign_in, sign_in_with_apple, github_sign_in
- **Storage**: firebase_storage
- **Database**: cloud_firestore
- **Analytics**: firebase_analytics
- **Error Tracking**: firebase_crashlytics

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase project setup
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/devio.git
   cd devio
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── blocs/          # State management
├── models/         # Data models
├── screens/        # UI screens
├── services/       # Business logic
├── theme/          # App theming
├── widgets/        # Reusable widgets
├── routes.dart     # Navigation routes
└── main.dart       # App entry point
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the robust backend services
- All contributors who help improve the project

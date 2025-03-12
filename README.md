# DevIO - AI-Driven Development Assistant

DevIO is a Flutter application that provides AI-powered assistance for app development using local AI models. It offers a seamless interface for developers to get real-time guidance and code suggestions.

## ✨ Features

### 🤖 AI Chat Interface
- Real-time chat interface with AI development assistant
- Support for local AI models through Ollama

### 💬 Chat Management
- Create and manage multiple chat sessions
- Pin important conversations
- Search through chat history
- Rename and delete conversations

### 🔐 Authentication
- Firebase Authentication integration
- Support for anonymous sign-in
- Google Sign-in
- Apple Sign-in (iOS)

### 🌐 Web Integration
- WebView support for in-app browsing
- Seamless integration with web resources
- Platform-specific WebView implementations

### ⚡ Performance Features
- Real-time performance metrics
- Token usage tracking
- Response generation speed monitoring
- Automatic message scrolling
- Responsive design with max width constraints

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase project setup
- Ollama installed locally for AI models

### Environment Setup
1. Configure Firebase:
   - Add `google-services.json` (Android)
   - Add `GoogleService-Info.plist` (iOS)
   - Set up Firestore rules using the provided `firestore.rules` file

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

3. Generate necessary files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## 📦 Dependencies

### Core
- flutter_bloc: ^9.0.0
- go_router: ^14.8.0
- freezed_annotation: ^3.0.0
- json_annotation: ^4.8.1
- intl: ^0.20.2
- uuid: ^4.2.1
- provider: ^6.1.1

### Firebase
- firebase_core: ^3.12.1
- firebase_auth: ^5.5.1
- cloud_firestore: ^5.6.5
- firebase_storage: ^12.4.4
- firebase_analytics: ^11.4.4
- firebase_messaging: ^15.2.4
- firebase_crashlytics: ^4.3.4

### Authentication
- google_sign_in: ^6.2.1
- sign_in_with_apple: ^6.1.4

### Web Integration
- webview_flutter: ^4.7.0
- webview_flutter_wkwebview: ^3.12.0

### UI & Utilities
- cached_network_image: ^3.3.1
- flutter_dotenv: ^5.1.0
- font_awesome_flutter: ^10.7.0
- google_fonts: ^6.2.1
- animate_do: ^4.2.0
- flutter_animate: ^4.5.0
- smooth_page_indicator: ^1.2.1
- path: ^1.8.3
- mime: ^2.0.0
- shared_preferences: ^2.2.2
- url_launcher: ^6.2.4

## 🏗️ Architecture

The app follows a clean architecture pattern with:
- BLoC/Cubit pattern for state management
- Feature-first directory structure
- Service layer for external integrations
- Repository pattern for data management

### Directory Structure
```
lib/
├── blocs/          # BLoC state management
├── constants/      # App constants and configurations
├── cubits/         # Cubit state management
├── features/       # Feature modules
│   ├── llm/        # LLM integration
│   ├── settings/   # App settings
│   └── ...         # Other features
├── models/         # Data models
├── providers/      # Provider implementations
├── repositories/   # Data repositories
├── screens/        # UI screens
├── services/       # External service integrations
├── theme/          # App theming
├── widgets/        # Reusable UI components
├── firebase_options.dart
├── main.dart       # App entry point
├── router.dart     # Navigation routing
└── routes.dart     # Route definitions
```

### Key Components
- LlmCubit: Manages AI model interactions
- ChatCubit: Handles chat state and operations
- AuthCubit: Manages authentication state
- PreferencesCubit: Manages app preferences
- LlmService: Manages local AI model interactions

## 🔧 Development

### Code Generation
The project uses code generation for:
- Freezed models
- JSON serialization
- Route generation

After modifying annotated classes, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Styling
The app uses the JosefinSans font family and a custom theme defined in the `theme` directory.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments
- Flutter team
- Firebase team
- Ollama project
- All contributors

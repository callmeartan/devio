# DevIO - AI-Driven Development Assistant

DevIO is a Flutter application that provides AI-powered assistance for app development using Google's Gemini AI models. It offers a seamless interface for developers to get real-time guidance, document analysis, and code suggestions.

## ✨ Features

### 🤖 AI Chat Interface
- Real-time chat interface with AI development assistant
- Support for multiple Gemini models:
  - `gemini-1.5-pro` (Default)
  - `gemini-1.5-pro-vision`
  - `gemini-1.5-pro-vision-latest`
  - And more...

### 📄 Document Analysis
- PDF document analysis and text extraction
- Ask questions about uploaded documents
- Smart text chunking for large documents

### 🖼️ Image Analysis
- Image analysis using Gemini Vision models
- Support for various image formats
- Visual context understanding

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
- Google Cloud project with Gemini API enabled

### Environment Setup
1. Create a `.env` file in the root directory with:
```
GEMINI_API_KEY=your_api_key_here
```

2. Configure Firebase:
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
- freezed_annotation: ^2.4.1
- json_annotation: ^4.8.1
- intl: ^0.19.0
- uuid: ^4.2.1

### Firebase
- firebase_core: ^3.11.0
- firebase_auth: ^5.4.2
- cloud_firestore: ^5.6.3
- firebase_storage: ^12.4.2
- firebase_analytics: ^11.4.2
- firebase_messaging: ^15.2.2
- firebase_crashlytics: ^4.3.2

### Authentication
- google_sign_in: ^6.2.1
- sign_in_with_apple: ^6.1.4

### AI & Document Handling
- google_generative_ai: ^0.0.1-dev
- syncfusion_flutter_pdf: ^24.1.46
- file_picker: ^6.1.1

### UI & Utilities
- cached_network_image: ^3.3.1
- flutter_dotenv: ^5.1.0
- image_picker: ^1.0.7
- font_awesome_flutter: ^10.7.0
- google_fonts: ^4.0.0
- animate_do: ^3.3.4
- flutter_animate: ^4.5.0
- path: ^1.8.3
- mime: ^1.0.4

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
- DocumentService: Handles document processing
- GeminiService: Manages Gemini API interactions

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
- Google Gemini AI
- Flutter team
- Firebase team
- All contributors

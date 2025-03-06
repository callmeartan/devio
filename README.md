# DevIO - AI-Driven Development Assistant

DevIO is a Flutter application that provides AI-powered assistance for app development using Google's Gemini AI models.

## Features

### AI Chat Interface
- Real-time chat interface with AI development assistant
- Support for multiple Gemini models:
  - `gemini-1.5-pro` (Default)
  - `gemini-1.5-pro-vision`
  - `gemini-1.5-pro-vision-latest`
  - And more...

### Document Analysis
- PDF document analysis and text extraction
- Ask questions about uploaded documents
- Smart text chunking for large documents

### Image Analysis
- Image analysis using Gemini Vision models
- Support for various image formats
- Visual context understanding

### Chat Management
- Create and manage multiple chat sessions
- Pin important conversations
- Search through chat history
- Rename and delete conversations

### Authentication
- Firebase Authentication integration
- Support for anonymous sign-in
- Google Sign-in
- GitHub Sign-in
- Apple Sign-in (iOS)

### Performance Features
- Real-time performance metrics
- Token usage tracking
- Response generation speed monitoring
- Automatic message scrolling
- Responsive design with max width constraints

## Getting Started

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

3. Run the app:
```bash
flutter run
```

## Dependencies

### Core
- flutter_bloc: ^9.0.0
- go_router: ^14.8.0
- freezed_annotation: ^2.4.1
- json_annotation: ^4.8.1

### Firebase
- firebase_core: ^3.11.0
- firebase_auth: ^5.4.2
- cloud_firestore: ^5.6.3
- firebase_storage: ^12.4.2
- firebase_analytics: ^11.4.2
- firebase_messaging: ^15.2.2
- firebase_crashlytics: ^4.3.2

### AI & Document Handling
- google_generative_ai: ^0.0.1-dev
- syncfusion_flutter_pdf: ^24.1.46
- file_picker: ^6.1.1

### UI & Utilities
- cached_network_image: ^3.3.1
- flutter_dotenv: ^5.1.0
- image_picker: ^1.0.7
- path: ^1.8.3
- mime: ^1.0.4

## Architecture

The app follows a clean architecture pattern with:
- BLoC pattern for state management
- Feature-first directory structure
- Service layer for external integrations
- Repository pattern for data management

### Key Components
- LlmCubit: Manages AI model interactions
- ChatCubit: Handles chat state and operations
- AuthCubit: Manages authentication state
- DocumentService: Handles document processing
- GeminiService: Manages Gemini API interactions

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- Google Gemini AI
- Flutter team
- Firebase team
- All contributors

# DevIO - Desktop & Mobile Interface for Local LLMs

DevIO is a professional Flutter application designed to connect to local LLM (Large Language Model) servers from your macOS desktop or mobile device. It features a clean, modern, and minimal UI that prioritizes ease of use while keeping your data local and private.

## 🔍 Overview

DevIO transforms your device into a powerful interface for interacting with locally hosted large language models. Connect to Ollama or other LLM servers to leverage the power of AI while keeping your data private and secure - no cloud accounts, no sign-ups, just pure local-first functionality.

## 🖥️ Supported Platforms

- macOS (Universal)
- iOS
- Android (coming soon)
- Web (experimental)

## ✨ Key Features

### 🤖 Multi-Provider LLM Integration
- **Ollama** - Connect to locally hosted Ollama instances with full support
- **LM Studio** - Coming soon
- **OpenAI Compatible APIs** - Coming soon (use local models with OpenAI-compatible interfaces)
- **Anthropic** - Coming soon
- Supports various open-source models (llama3, deepseek, mistral, phi3, etc.)
- Performance metrics tracking and real-time monitoring
- Automatic reconnection and connection status indicators

### 📱 Modern Flutter Interface
- Clean, minimal design with both dark and light theme support
- Responsive layout optimized for various screen sizes
- Integrated with Flutter Bloc/Cubit for robust state management
- Onboarding screens for new users with interactive setup guide

### 💬 Advanced Chat Capabilities
- Multi-session chat management with conversation history
- Code highlighting and formatting for code snippets
- Image analysis with multimodal model support
- Document handling with PDF support
- Real-time typing indicators and message status

### 🔐 Privacy & Local-First Use
- No login, signup, or cloud account required
- Chat history is stored locally on your device
- All processing happens locally - your data never leaves your machine
- Demo mode for exploring features without a connection

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- A running Ollama server (local or remote)
- macOS 12.0 or later (for desktop version)
- iOS 15.0 or later (for mobile version)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/callmeartan/devio.git
cd devio
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure your environment:
   - Create a `.env` file in the project root with:
   ```
   OLLAMA_HOST=localhost:11434  # Change to your Ollama server address
   ```

4. Build and run:
```bash
flutter run
```

## 💻 Connecting to Local LLM Servers

DevIO is designed to work seamlessly with locally hosted LLM servers. By default, it connects to Ollama running on localhost:11434.

### Configuring Ollama

1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Pull your preferred models:
```bash
ollama pull llama3.1
ollama pull deepseek-r1:8b
ollama pull mistral:7b
ollama pull phi3:14b
```
3. Start the Ollama server with network access:
```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

### Remote Connections

To connect to a remote Ollama instance:
1. Ensure the remote server is accessible
2. Update the server address in the app settings
3. Use the built-in connection test to verify connectivity

## 🏗️ Architecture

DevIO follows modern Flutter architecture patterns:

- **Clean Architecture** with separation of concerns
- **BLoC/Cubit Pattern** for state management
- **Feature-first Structure** organized by functionality
- **Repository Pattern** for data access abstraction

### Key Technologies

- **Flutter 3.x** for cross-platform UI development
- **go_router** for navigation
- **flutter_bloc** for state management
- **freezed** for immutable state classes
- **http** for API communication with LLM servers
- **shared_preferences** for local settings and chat storage

### Directory Structure

```
lib/
├── blocs/          # Bloc state management
├── constants/      # App constants and configurations
├── cubits/         # Cubit state management
├── features/       # Feature modules
│   ├── llm/        # Core LLM functionality
│   └── settings/   # App configuration
├── models/         # Data models
├── providers/      # Provider implementations
├── repositories/   # Data repositories
├── screens/        # UI screens
├── services/       # Service implementations
├── theme/          # Theming and styling
├── utils/          # Utility functions
├── widgets/        # Reusable UI components
├── main.dart       # Application entry point
└── router.dart     # Navigation configuration
```

## 🛠️ Development

### Building for Production

```bash
# macOS
flutter build macos --release

# iOS
flutter build ios --release

# Android
flutter build apk --release
```

### Running Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🔮 Future Roadmap

- LM Studio provider support
- OpenAI-compatible API integration
- Anthropic provider support
- Windows and Linux support
- Audio input and output capabilities
- Advanced document analysis and summarization
- Plugin support for extending functionality
- Local model management interface
- Multi-user collaborative features
- Enhanced multimodal support

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- The Ollama team for making local LLMs accessible
- Open-source LLM communities
- Flutter team for the amazing cross-platform framework
- All contributors to this project
# DevIO - Desktop & Mobile Interface for Local LLMs

DevIO is a professional Flutter application designed to connect to local LLM (Large Language Model) servers from your macOS desktop or mobile device. It features a clean, modern, and minimal UI that prioritizes ease of use while providing powerful functionality.

## 🔍 Overview

DevIO transforms your device into a powerful interface for interacting with locally hosted large language models. Connect to Ollama or other LLM servers to leverage the power of AI while keeping your data private and secure.

## 🖥️ Supported Platforms
- macOS (Universal)
- iOS
- Android (coming soon)

## ✨ Key Features

### 🤖 Local LLM Integration
- Connect to locally hosted Ollama instances
- Customize server IP and port configurations
- Compatible with popular open-source models (llama3, deepseek, mistral, phi3, etc.)
- Performance metrics tracking and optimization

### 📱 Modern Mobile Interface
- Clean, minimal design focused on content
- Dark and light theme support
- Responsive layout optimized for various screen sizes
- Intuitive navigation and interactions

### 💬 Advanced Chat Capabilities
- Multi-session chat management
- Conversation history with search functionality
- Code highlighting and formatting
- Image analysis capabilities with multimodal models
- Message organization with pinning and labeling

### 🔐 Privacy-Focused
- Local processing keeps data on your device
- Optional cloud synchronization with Firebase
- Flexible authentication options
- Control over data retention and usage

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- A running Ollama server (local or remote)
- macOS 12.0 or later (for desktop version)
- iOS 18.0 or later (for mobile version)
- (Optional) Firebase project for cloud features

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
ollama pull llama3
ollama pull deepseek-r1:8b
ollama pull mistral:7b
```
3. Start the Ollama server:
```bash
ollama serve
```

### Remote Connections
To connect to a remote Ollama instance:
1. Ensure the remote server is accessible
2. Update the OLLAMA_HOST in .env or in the app settings
3. For security, consider using SSH tunneling or a VPN

## 🏗️ Architecture

DevIO follows modern Flutter architecture patterns:

- **Clean Architecture**: Separation of concerns with presentation, domain, and data layers
- **BLoC/Cubit Pattern**: Predictable state management
- **Feature-first Structure**: Organized by functionality rather than technical concerns
- **Service-Repository Pattern**: Abstract data access and external services

### Directory Structure
```
lib/
├── features/       # Feature modules
│   ├── llm/        # Core LLM functionality
│   ├── settings/   # App configuration
│   └── ...         # Other features
├── screens/        # Main UI screens
├── widgets/        # Reusable UI components
├── services/       # External service integrations
├── theme/          # App theming and styling
└── ...
```

## 🛠️ Development

### Building for Production
```bash
# macOS
flutter build macos --release

# iOS
flutter build ios --release

# Android (coming soon)
flutter build apk --release
```

### Environment Configuration
Create a `.env` file in the project root with:
```
OLLAMA_HOST=your_ollama_server:port
```

## 🔮 Future Roadmap

- Windows and Linux support
- Audio input and output capabilities
- Document analysis and summarization
- Plugin support for extending functionality
- Advanced prompt templating system
- Model fine-tuning interface

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

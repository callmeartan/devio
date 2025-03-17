import 'dart:math';
import '../features/llm/models/llm_response.dart';

/// A service that provides demo responses when the user is not connected to Ollama
class DemoResponseService {
  static final DemoResponseService _instance = DemoResponseService._internal();

  factory DemoResponseService() => _instance;

  DemoResponseService._internal();

  final Random _random = Random();

  /// Get a demo response for a given prompt
  Future<LlmResponse> getDemoResponse(String prompt) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    final responseText = _generateResponseForPrompt(prompt);

    // Simulate performance metrics
    final totalDuration = 0.5 + _random.nextDouble() * 1.5;
    final loadDuration = 0.1 + _random.nextDouble() * 0.3;
    final promptEvalCount = prompt.split(' ').length;
    final promptEvalDuration = 0.2 + _random.nextDouble() * 0.5;
    final promptEvalRate = promptEvalCount / promptEvalDuration;
    final evalCount = responseText.split(' ').length;
    final evalDuration = totalDuration - loadDuration - promptEvalDuration;
    final evalRate = evalCount / evalDuration;

    return LlmResponse(
      text: responseText,
      modelName: 'demo-mode',
      totalDuration: totalDuration,
      loadDuration: loadDuration,
      promptEvalCount: promptEvalCount,
      promptEvalDuration: promptEvalDuration,
      promptEvalRate: promptEvalRate,
      evalCount: evalCount,
      evalDuration: evalDuration,
      evalRate: evalRate,
    );
  }

  /// Generate a response based on the prompt content
  String _generateResponseForPrompt(String prompt) {
    final promptLower = prompt.toLowerCase();

    // Check for common greeting patterns
    if (_containsAny(promptLower, ['hello', 'hi', 'hey', 'greetings'])) {
      return _getRandomGreeting();
    }

    // Check for questions about Ollama
    if (_containsAny(
        promptLower, ['ollama', 'connection', 'setup', 'install'])) {
      return _getOllamaSetupResponse();
    }

    // Check for questions about the app
    if (_containsAny(
        promptLower, ['app', 'devio', 'application', 'features'])) {
      return _getAppInfoResponse();
    }

    // Check for code-related questions
    if (_containsAny(
        promptLower, ['code', 'programming', 'develop', 'flutter', 'dart'])) {
      return _getCodeRelatedResponse();
    }

    // Default response for other prompts
    return _getGenericResponse(prompt);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String _getRandomGreeting() {
    final greetings = [
      "Hello! I'm currently running in demo mode because you're not connected to Ollama. Would you like help setting up a connection to use the full AI features?",
      "Hi there! I'm in demo mode right now. To access my full capabilities, you'll need to connect to Ollama. Would you like help with that?",
      "Greetings! I'm operating in demo mode with limited functionality. Connect to Ollama to unlock my full potential as your development assistant.",
    ];

    return greetings[_random.nextInt(greetings.length)];
  }

  String _getOllamaSetupResponse() {
    return '''I'm currently in demo mode because you're not connected to Ollama.

To set up Ollama:
1. Install Ollama on your computer from ollama.ai
2. Start the Ollama server with: OLLAMA_HOST=0.0.0.0:11434 ollama serve
3. Find your computer's IP address
4. Enter your IP address followed by :11434 in the connection settings

You can access the setup guide by tapping "Setup Now" in the connection banner at the top of the chat.''';
  }

  String _getAppInfoResponse() {
    return '''DevIO is an AI-powered development assistant that helps you with app development.

Key features:
• AI chat assistance for coding and development questions
• Local AI processing using Ollama for privacy and performance
• Support for multiple AI models
• Code generation and explanation
• Development workflow guidance

I'm currently in demo mode with limited functionality. Connect to Ollama to access all features.''';
  }

  String _getCodeRelatedResponse() {
    return '''I can help with coding and development questions, but I'm currently in demo mode with limited functionality.

When connected to Ollama, I can:
• Generate code samples
• Explain code concepts
• Help debug issues
• Suggest best practices
• Provide step-by-step guidance

To access these features, please connect to Ollama by following the setup guide.''';
  }

  String _getGenericResponse(String prompt) {
    return '''Thank you for your message! I'm currently running in demo mode because you're not connected to Ollama.

To access my full AI capabilities and get a proper response to your query about "${prompt.length > 30 ? prompt.substring(0, 30) + '...' : prompt}", please connect to Ollama.

You can set up the connection by tapping "Setup Now" in the connection banner at the top of the chat.''';
  }

  /// Get the initial greeting message for demo mode
  String getInitialGreeting() {
    return '''Hello! 👋 I'm currently in demo mode because you're not connected to Ollama.

To access my full AI capabilities:
• Set up Ollama on your computer
• Configure the connection in settings
• Choose an AI model

Tap "Setup Now" in the connection banner to get started.''';
  }
}

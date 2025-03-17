import 'dart:math';

/// A service that provides demo AI responses when no Ollama connection is available
class DemoResponseService {
  // Random generator for variety in responses
  final Random _random = Random();

  // List of sample prompts that the demo can handle well
  final List<String> _samplePrompts = [
    'Tell me about Flutter',
    'What is Dart programming?',
    'How do I use BLoC pattern?',
    'Explain widget trees',
    'Write a simple counter app',
  ];

  // Default responses for generic queries
  final List<String> _genericResponses = [
    'This is a demo response. To get real AI responses, connect to an Ollama server.',
    'I\'m currently in demo mode. For full functionality, please set up an Ollama connection.',
    'This is a preview of what I can do. Connect to Ollama for more advanced capabilities.',
    'To unlock my full potential, you\'ll need to connect me to an Ollama server.',
    'I have limited capabilities in demo mode. Connect to Ollama for a complete experience.',
  ];

  // Demo responses for specific topics
  final Map<String, List<String>> _topicResponses = {
    'flutter': [
      'Flutter is Google\'s UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. It uses the Dart programming language and provides a rich set of pre-built widgets.',
      'Flutter allows developers to create beautiful, natively compiled applications with a single codebase. Its hot reload feature enables quick experimentation and UI building.',
    ],
    'dart': [
      'Dart is a client-optimized programming language for apps on multiple platforms. It is developed by Google and used to build mobile, desktop, server, and web applications.',
      'Dart features sound null safety, strong typing, and a rich standard library. It\'s the language used for Flutter development.',
    ],
    'bloc': [
      'BLoC (Business Logic Component) is a state management pattern for Flutter. It helps separate business logic from the UI, making code more maintainable and testable.',
      'The BLoC pattern uses streams to communicate between components. Events go in, states come out, creating a predictable flow of data.',
    ],
    'widget': [
      'In Flutter, widgets are the basic building blocks of the UI. Everything in Flutter is a widget, from buttons to layouts to animations.',
      'Flutter widgets form a tree structure, with parent widgets containing children. This composition-based approach makes UI development flexible and intuitive.',
    ],
    'code': [
      'Here\'s a simple counter app in Flutter:\n\n```dart\nclass CounterApp extends StatefulWidget {\n  @override\n  _CounterAppState createState() => _CounterAppState();\n}\n\nclass _CounterAppState extends State<CounterApp> {\n  int _count = 0;\n\n  void _incrementCounter() {\n    setState(() {\n      _count++;\n    });\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    return Scaffold(\n      appBar: AppBar(title: Text(\'Counter App\')),\n      body: Center(\n        child: Column(\n          mainAxisAlignment: MainAxisAlignment.center,\n          children: [\n            Text(\'Count:\'),\n            Text(\'$_count\', style: TextStyle(fontSize: 24)),\n          ],\n        ),\n      ),\n      floatingActionButton: FloatingActionButton(\n        onPressed: _incrementCounter,\n        child: Icon(Icons.add),\n      ),\n    );\n  }\n}```',
      'Creating a Flutter app starts with the `main()` function and a `runApp()` call. Your app will typically have stateless widgets for UI components that don\'t change, and stateful widgets for those that need to maintain state.',
    ],
    'ollama': [
      'Ollama is a tool for running large language models locally. It simplifies running, customizing and sharing models like Llama 2, Mistral, and others.',
      'To use DevIO\'s full capabilities, you should connect it to an Ollama server running on your computer or network. This allows you to leverage powerful AI models while keeping your data private.',
    ],
  };

  /// Get a list of sample prompts that work well in demo mode
  List<String> getSamplePrompts() {
    return _samplePrompts;
  }

  /// Generate a demo response for a given prompt
  ///
  /// This simulates an AI response without actually using AI
  String generateDemoResponse(String prompt) {
    // Lowercase prompt for matching
    final lowerPrompt = prompt.toLowerCase();

    // Check if the prompt contains any of our topic keywords
    for (final topic in _topicResponses.keys) {
      if (lowerPrompt.contains(topic)) {
        final responses = _topicResponses[topic]!;
        return responses[_random.nextInt(responses.length)];
      }
    }

    // If no specific topic matched, return a generic response
    return _genericResponses[_random.nextInt(_genericResponses.length)];
  }

  /// Generate a "trying to connect" response
  String generateConnectionPrompt() {
    final responses = [
      'I\'m having trouble connecting to Ollama. Would you like to set up a connection now?',
      'It looks like I\'m not connected to an Ollama server. Do you need help setting up?',
      'To chat with AI, you\'ll need to connect to an Ollama server first. Want to set that up?',
      'I need a connection to an Ollama server to provide AI responses. Ready to connect?',
    ];

    return responses[_random.nextInt(responses.length)];
  }

  /// Generate an initial greeting for demo mode
  String generateDemoGreeting() {
    return 'Welcome to DevIO in demo mode! To experience full AI capabilities, '
        'please connect to an Ollama server. In the meantime, '
        'I can provide basic responses to common questions about Flutter, Dart, and programming.';
  }

  /// Simulate a loading delay to make the demo feel more realistic
  Future<void> simulateResponseDelay() async {
    final delay = Duration(milliseconds: 500 + _random.nextInt(1500));
    await Future.delayed(delay);
  }
}

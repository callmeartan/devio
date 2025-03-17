/// String resources for the application
class Strings {
  /// App name
  static const String appName = 'DevIO';

  /// Connection related strings
  static const String connectionRequired = 'Connection to Ollama Required';
  static const String connectionRequiredMessage =
      'This app requires a connection to an Ollama server to function properly. '
      'Ollama lets you run AI models locally on your computer.';

  static const String setupOllama = 'Set Up Ollama';
  static const String connectionSuccess = 'Connection Successful';
  static const String connectionError = 'Connection Error';
  static const String connectionInProgress = 'Connecting...';

  /// Demo mode
  static const String demoMode = 'Demo Mode';
  static const String demoModeDescription =
      'You\'re currently in demo mode. Some features are limited. '
      'Connect to an Ollama server for full functionality.';

  /// Connection wizard
  static const String installOllama = 'Install Ollama';
  static const String startOllama = 'Start Ollama';
  static const String connectToOllama = 'Connect to Ollama';
  static const String setupComplete = 'Setup Complete';

  /// Error messages
  static const String errorConnecting = 'Error connecting to Ollama';
  static const String errorNoModels = 'No models found on Ollama server';
  static const String errorInvalidUrl = 'Invalid server URL';
}

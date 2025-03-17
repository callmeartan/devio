import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/assets.dart';
import '../constants/strings.dart';
import '../cubit/server_connection_cubit.dart';
import '../models/server_status.dart';
import '../services/ollama_service.dart';
import '../theme/app_theme.dart';
import 'connection_status_banner.dart';

/// A step-by-step wizard that guides users through setting up
/// their Ollama connection with auto-detection and clear feedback
class ConnectionWizard extends StatefulWidget {
  /// Called when the setup is completed successfully
  final VoidCallback onComplete;

  const ConnectionWizard({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ConnectionWizard> createState() => _ConnectionWizardState();
}

class _ConnectionWizardState extends State<ConnectionWizard> {
  final PageController _pageController = PageController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController =
      TextEditingController(text: '11434');

  int _currentStep = 0;
  bool _isConnectionTested = false;
  bool _isConnectionSuccessful = false;
  String? _errorMessage;
  List<String> _availableIpAddresses = [];

  @override
  void initState() {
    super.initState();
    _detectIpAddresses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _detectIpAddresses() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();

      setState(() {
        _availableIpAddresses = [
          if (wifiIP != null) wifiIP,
          'localhost',
          '127.0.0.1',
        ];

        if (_availableIpAddresses.isNotEmpty) {
          _ipController.text = _availableIpAddresses.first;
        }
      });
    } catch (e) {
      setState(() {
        _availableIpAddresses = ['localhost', '127.0.0.1'];
        _ipController.text = 'localhost';
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isConnectionTested = false;
      _isConnectionSuccessful = false;
      _errorMessage = null;
    });

    final host = _ipController.text.trim();
    final port = _portController.text.trim();

    if (host.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid IP address or hostname';
      });
      return;
    }

    if (port.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid port number';
      });
      return;
    }

    final ollamaService = context.read<OllamaService>();
    try {
      final serverUrl = 'http://$host:$port';

      // Update the server URL in the service and cubit
      ollamaService.updateServerUrl(serverUrl);
      context.read<ServerConnectionCubit>().updateServerUrl(serverUrl);

      // Test the connection
      final status =
          await context.read<ServerConnectionCubit>().checkServerStatus();

      setState(() {
        _isConnectionTested = true;
        _isConnectionSuccessful = status.status == ServerStatus.connected;
        _errorMessage = status.status != ServerStatus.connected
            ? 'Could not connect to Ollama server. Please check your settings and ensure Ollama is running.'
            : null;
      });

      if (_isConnectionSuccessful) {
        // Wait briefly to show success state before moving to next step
        await Future.delayed(const Duration(seconds: 1));
        _nextStep();
      }
    } catch (e) {
      setState(() {
        _isConnectionTested = true;
        _isConnectionSuccessful = false;
        _errorMessage = 'Error connecting to server: ${e.toString()}';
      });
    }
  }

  Future<void> _launchOllamaDownload() async {
    final url = Uri.parse('https://ollama.com/download');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Ollama'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onComplete,
        ),
      ),
      body: Column(
        children: [
          // Step indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                  ),
                );
              }),
            ),
          ),

          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInstallOllamaStep(),
                _buildStartOllamaStep(),
                _buildConnectServerStep(),
                _buildSuccessStep(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: _previousStep,
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(width: 80),
                ElevatedButton(
                  onPressed: _currentStep == 2 ? _testConnection : _nextStep,
                  child: Text(_currentStep == 2 ? 'Test Connection' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallOllamaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Install Ollama',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'To use this app, you need to install Ollama on your computer. '
            'Ollama lets you run large language models locally on your machine.',
          ),
          const SizedBox(height: 24.0),
          Center(
            child: Image.asset(
              Assets.ollamaLogo,
              height: 100,
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            onPressed: _launchOllamaDownload,
            icon: const Icon(Icons.download),
            label: const Text('Download Ollama'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Follow the installation instructions on the Ollama website. '
            'Once installed, proceed to the next step.',
          ),
        ],
      ),
    );
  }

  Widget _buildStartOllamaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Start Ollama',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Text(
            Platform.isMacOS
                ? 'Launch Ollama from your Applications folder or Spotlight.'
                : Platform.isWindows
                    ? 'Launch Ollama from your Start menu or desktop shortcut.'
                    : 'Start Ollama using the command line or application launcher.',
          ),
          const SizedBox(height: 24.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  Platform.isMacOS
                      ? 'On macOS, you should see the Ollama icon in your menu bar when it\'s running.'
                      : Platform.isWindows
                          ? 'On Windows, you should see the Ollama icon in your system tray when it\'s running.'
                          : 'On Linux, you can start Ollama with the command: ollama serve',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          const Text(
            'You\'ll need at least one model downloaded to use with Ollama. '
            'If you haven\'t downloaded a model yet, you can do this after connecting.',
          ),
        ],
      ),
    );
  }

  Widget _buildConnectServerStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Connect to Ollama',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Now let\'s connect to your Ollama server. '
            'We\'ve detected possible IP addresses for your server.',
          ),
          const SizedBox(height: 24.0),
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Server Address',
              hintText: 'localhost or IP address',
              suffixIcon: _availableIpAddresses.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        _ipController.text = value;
                      },
                      itemBuilder: (context) {
                        return _availableIpAddresses.map((ip) {
                          return PopupMenuItem<String>(
                            value: ip,
                            child: Text(ip),
                          );
                        }).toList();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '11434',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24.0),
          if (_isConnectionTested) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _isConnectionSuccessful
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnectionSuccessful ? Icons.check_circle : Icons.error,
                    color: _isConnectionSuccessful ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      _isConnectionSuccessful
                          ? 'Successfully connected to Ollama!'
                          : _errorMessage ?? 'Connection failed',
                      style: TextStyle(
                        color:
                            _isConnectionSuccessful ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Troubleshooting:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  '• Make sure Ollama is running\n'
                  '• Check your firewall settings\n'
                  '• Try "localhost" or "127.0.0.1" for local connections\n'
                  '• The default port is 11434',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          Lottie.asset(
            Assets.successAnimation,
            height: 200,
            repeat: false,
          ),
          const SizedBox(height: 24.0),
          Text(
            'Connection Successful!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'You\'re now connected to your Ollama server and ready to start chatting with AI models running on your computer.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          ElevatedButton.icon(
            onPressed: widget.onComplete,
            icon: const Icon(Icons.chat),
            label: const Text('Start Chatting'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

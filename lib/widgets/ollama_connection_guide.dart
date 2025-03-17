import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' show Platform;
import '../features/llm/cubit/llm_cubit.dart';

class OllamaConnectionGuide extends StatefulWidget {
  final VoidCallback? onConnectionSuccess;

  const OllamaConnectionGuide({
    super.key,
    this.onConnectionSuccess,
  });

  @override
  State<OllamaConnectionGuide> createState() => _OllamaConnectionGuideState();
}

class _OllamaConnectionGuideState extends State<OllamaConnectionGuide> {
  final TextEditingController _ipController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionError;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIp() async {
    final llmCubit = context.read<LlmCubit>();
    _ipController.text = llmCubit.customOllamaIp ?? '';
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionError = null;
    });

    try {
      final llmCubit = context.read<LlmCubit>();
      await llmCubit.setCustomOllamaIp(_ipController.text.trim());

      final result = await llmCubit.testConnection();

      if (result['status'] == 'connected') {
        if (widget.onConnectionSuccess != null) {
          widget.onConnectionSuccess!();
        }
      } else {
        setState(() {
          _connectionError = result['error'] ??
              'Please configure your Ollama server IP address in settings';
        });
      }
    } catch (e) {
      setState(() {
        _connectionError = e.toString();
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  String _getPlatformSpecificCommand() {
    if (Platform.isMacOS) {
      return 'OLLAMA_HOST=0.0.0.0:11434 ollama serve';
    } else if (Platform.isWindows) {
      return 'set OLLAMA_HOST=0.0.0.0:11434 && ollama serve';
    } else {
      return 'OLLAMA_HOST=0.0.0.0:11434 ollama serve';
    }
  }

  String _getPlatformSpecificIpCommand() {
    if (Platform.isMacOS) {
      return 'ifconfig | grep "inet " | grep -v 127.0.0.1';
    } else if (Platform.isWindows) {
      return 'ipconfig';
    } else {
      return 'ip addr show | grep "inet " | grep -v 127.0.0.1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect to Ollama',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              controlsBuilder: (context, details) {
                return Row(
                  children: [
                    if (details.currentStep < 3)
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: const Text('Next'),
                      ),
                    if (details.currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                  ],
                );
              },
              onStepContinue: () {
                setState(() {
                  if (_currentStep < 3) {
                    _currentStep++;
                  }
                });
              },
              onStepCancel: () {
                setState(() {
                  if (_currentStep > 0) {
                    _currentStep--;
                  }
                });
              },
              steps: [
                Step(
                  title: const Text('Install Ollama'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First, install Ollama on your computer:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'curl -fsSL https://ollama.ai/install.sh | sh',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(
                                  text:
                                      'curl -fsSL https://ollama.ai/install.sh | sh',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Command copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy to clipboard',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Or visit https://ollama.ai for installation instructions.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text('Start Ollama Server'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start the Ollama server with network access:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getPlatformSpecificCommand(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                  text: _getPlatformSpecificCommand(),
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Command copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy to clipboard',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Keep this terminal window open while using the app.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text('Find Your IP Address'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your computer\'s IP address:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getPlatformSpecificIpCommand(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                  text: _getPlatformSpecificIpCommand(),
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Command copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy to clipboard',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Look for an IP address that starts with 192.168. or 10.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 2,
                ),
                Step(
                  title: const Text('Connect to Ollama'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your computer\'s IP address followed by :11434',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          hintText: '192.168.1.5:11434',
                          labelText: 'Ollama Server Address',
                          border: const OutlineInputBorder(),
                          errorText: _connectionError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _isTestingConnection ? null : _testConnection,
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.network_check),
                          label: Text(_isTestingConnection
                              ? 'Testing Connection...'
                              : 'Test Connection'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you\'re using the same device, try "localhost:11434"',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

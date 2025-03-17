import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' show Platform;
import '../features/llm/cubit/llm_cubit.dart';

class ConnectionWizard extends StatefulWidget {
  final VoidCallback? onConnectionSuccess;
  final VoidCallback? onClose;

  const ConnectionWizard({
    super.key,
    this.onConnectionSuccess,
    this.onClose,
  });

  @override
  State<ConnectionWizard> createState() => _ConnectionWizardState();
}

class _ConnectionWizardState extends State<ConnectionWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  bool _isLastPage = false;

  // Connection settings
  final TextEditingController _ipController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionError;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
    _loadSavedIp();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
        _isLastPage = _currentPage == _totalPages - 1;
      });
    }
  }

  Future<void> _loadSavedIp() async {
    final llmCubit = context.read<LlmCubit>();
    _ipController.text = llmCubit.customOllamaIp ?? '';
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionError = null;
      _connectionSuccess = false;
    });

    try {
      final llmCubit = context.read<LlmCubit>();
      await llmCubit.setCustomOllamaIp(_ipController.text.trim());

      final result = await llmCubit.testConnection();

      if (result['status'] == 'connected') {
        setState(() {
          _connectionSuccess = true;
        });

        if (_isLastPage && widget.onConnectionSuccess != null) {
          widget.onConnectionSuccess!();
        } else {
          // Move to next page on success if not on last page
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        setState(() {
          _connectionError =
              result['error'] ?? 'Failed to connect to Ollama server';
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

  String _getPlatformSpecificModelCommand() {
    return 'ollama pull mistral';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Connection Wizard'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: theme.colorScheme.surfaceVariant,
            color: theme.colorScheme.primary,
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInstallPage(theme),
                _buildStartServerPage(theme),
                _buildConnectPage(theme),
                _buildModelPage(theme),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: _currentPage == 2
                      ? _testConnection
                      : () {
                          if (_isLastPage) {
                            if (widget.onConnectionSuccess != null) {
                              widget.onConnectionSuccess!();
                            }
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                  child: Text(_getButtonText()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_isTestingConnection) {
      return 'Testing...';
    }

    if (_currentPage == 2) {
      return 'Test Connection';
    }

    if (_isLastPage) {
      return 'Finish';
    }

    return 'Next';
  }

  Widget _buildInstallPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Install Ollama',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ollama is a tool that runs AI models locally on your computer. You need to install it before you can use it with this app.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Installation instructions
          _buildInstructionCard(
            theme,
            title: 'Installation Command',
            content: 'curl -fsSL https://ollama.ai/install.sh | sh',
            onCopy: () {
              Clipboard.setData(const ClipboardData(
                text: 'curl -fsSL https://ollama.ai/install.sh | sh',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Text(
            'Or visit https://ollama.ai for installation instructions.',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),
          _buildInfoBox(
            theme,
            'Ollama is completely free and open source. It runs on your computer, so your data stays private.',
          ),
        ],
      ),
    );
  }

  Widget _buildStartServerPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Start Ollama Server',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You need to start the Ollama server with network access enabled so this app can connect to it.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Server start command
          _buildInstructionCard(
            theme,
            title: 'Start Server Command',
            content: _getPlatformSpecificCommand(),
            onCopy: () {
              Clipboard.setData(ClipboardData(
                text: _getPlatformSpecificCommand(),
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Text(
            'Keep this terminal window open while using the app.',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),
          _buildInfoBox(
            theme,
            'The server needs to be running with network access enabled (0.0.0.0) to allow connections from this app.',
          ),

          const SizedBox(height: 16),
          _buildInstructionCard(
            theme,
            title: 'Find Your IP Address',
            content: _getPlatformSpecificIpCommand(),
            onCopy: () {
              Clipboard.setData(ClipboardData(
                text: _getPlatformSpecificIpCommand(),
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Text(
            'Look for an IP address that starts with 192.168. or 10.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Connect to Ollama',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter your computer\'s IP address followed by :11434 to connect to the Ollama server.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Connection form
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Ollama Server Address',
              hintText: '192.168.1.5:11434',
              errorText: _connectionError,
              border: const OutlineInputBorder(),
              suffixIcon: _connectionSuccess
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'If you\'re using the same device, try "localhost:11434"',
            style: theme.textTheme.bodyMedium,
          ),

          if (_connectionSuccess) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Successfully connected to Ollama server!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4: Download a Model',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You need to download at least one AI model to use with Ollama.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Model download command
          _buildInstructionCard(
            theme,
            title: 'Download Model Command',
            content: _getPlatformSpecificModelCommand(),
            onCopy: () {
              Clipboard.setData(ClipboardData(
                text: _getPlatformSpecificModelCommand(),
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Text(
            'This will download the Mistral model, which is a good balance of size and capability.',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),
          _buildInfoBox(
            theme,
            'Model downloads can take several minutes depending on your internet speed and computer performance.',
          ),

          const SizedBox(height: 24),
          Text(
            'Other popular models:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildModelOption(
            theme,
            name: 'llama3',
            description: 'Powerful general-purpose model',
            command: 'ollama pull llama3',
          ),
          _buildModelOption(
            theme,
            name: 'phi3',
            description: 'Smaller, faster model',
            command: 'ollama pull phi3:mini',
          ),
          _buildModelOption(
            theme,
            name: 'llava',
            description: 'Model with image understanding',
            command: 'ollama pull llava',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(
    ThemeData theme, {
    required String title,
    required String content,
    required VoidCallback onCopy,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: onCopy,
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption(
    ThemeData theme, {
    required String name,
    required String description,
    required String command,
  }) {
    return ListTile(
      title: Text(
        name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(description),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: command));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Command copied: $command'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        tooltip: 'Copy command',
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../features/llm/cubit/llm_cubit.dart';

class ServerHealthIndicator extends StatefulWidget {
  final VoidCallback? onTap;
  final bool compact;

  const ServerHealthIndicator({
    super.key,
    this.onTap,
    this.compact = false,
  });

  @override
  State<ServerHealthIndicator> createState() => _ServerHealthIndicatorState();
}

class _ServerHealthIndicatorState extends State<ServerHealthIndicator> {
  Timer? _refreshTimer;
  Map<String, dynamic>? _serverStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();

    // Refresh status every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkServerStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkServerStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final llmCubit = context.read<LlmCubit>();
      final status = await llmCubit.getServerStatus();

      if (mounted) {
        setState(() {
          _serverStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverStatus = {
            'status': 'error',
            'error': e.toString(),
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine status
    bool isConnected =
        _serverStatus != null && _serverStatus!['status'] != 'error';

    // Determine colors based on status
    Color statusColor = isConnected ? Colors.green : Colors.red;

    // Determine icon based on status
    IconData statusIcon = isConnected ? Icons.cloud_done : Icons.cloud_off;

    if (_isLoading) {
      statusColor = Colors.blue;
      statusIcon = Icons.sync;
    }

    if (widget.compact) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isLoading) {
      return 'Checking...';
    }

    if (_serverStatus == null || _serverStatus!['status'] == 'error') {
      return 'Disconnected';
    }

    if (_serverStatus!.containsKey('version')) {
      return 'Ollama v${_serverStatus!['version']}';
    }

    return 'Connected';
  }
}

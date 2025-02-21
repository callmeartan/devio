import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';
import '../features/llm/cubit/llm_state.dart';
import '../features/llm/services/llm_service.dart';
import '../features/llm/models/llm_response.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_cubit.dart';
import '../cubits/chat/chat_cubit.dart';
import '../cubits/chat/chat_state.dart';
import '../widgets/drawer_menu_item.dart';
import '../widgets/simple_drawer_menu_item.dart' as simple;
import 'dart:developer' as developer;

const String _kAiUserName = 'AI Assistant';

class MessageBubble extends StatelessWidget {
  final Widget child;
  final bool isUser;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.child,
    required this.isUser,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class PerformanceMetrics extends StatelessWidget {
  final LlmResponse response;
  final bool isExpanded;
  final VoidCallback onToggle;

  const PerformanceMetrics({
    super.key,
    required this.response,
    required this.isExpanded,
    required this.onToggle,
  });

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    String? unit,
    {bool isHighlight = false}
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isHighlight 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'monospace',
                ),
              ),
              if (unit != null)
                Text(
                  ' $unit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds == 0) return '-';
    if (seconds < 0.001) {
      return '${(seconds * 1000000).toStringAsFixed(1)}μs';
    } else if (seconds < 1) {
      return '${(seconds * 1000).toStringAsFixed(1)}ms';
    } else {
      return '${seconds.toStringAsFixed(1)}s';
    }
  }

  String _formatRate(double? rate) {
    if (rate == null || rate == 0) return '-';
    if (rate >= 1000) {
      return '${(rate / 1000).toStringAsFixed(1)}k';
    }
    return rate.toStringAsFixed(1);
  }

  String _formatTokens(int? tokens) {
    if (tokens == null || tokens == 0) return '-';
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
    return tokens.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if we have any valid metrics
    final hasMetrics = response.totalDuration != null && 
                      response.totalDuration! > 0;

    if (!hasMetrics) return const SizedBox.shrink();

    return Column(
      children: [
        // Metrics Toggle Button
        Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: 0,
            top: 4,
          ),
          child: Material(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Performance Metrics',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded 
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Metrics Content
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(
              left: 0,
              right: 0,
              top: 4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main metrics
                _buildMetricRow(
                  context,
                  'Total Time',
                  _formatDuration(response.totalDuration),
                  null,
                  isHighlight: true,
                ),
                
                // Prompt metrics
                if (response.promptEvalCount != null && response.promptEvalCount! > 0) ...[
                  const Divider(height: 12),
                  _buildMetricRow(
                    context,
                    'Prompt',
                    _formatTokens(response.promptEvalCount),
                    'tokens',
                  ),
                  _buildMetricRow(
                    context,
                    'Processing',
                    _formatDuration(response.promptEvalDuration),
                    null,
                  ),
                  _buildMetricRow(
                    context,
                    'Speed',
                    _formatRate(response.promptEvalRate),
                    't/s',
                  ),
                ],
                
                // Generation metrics
                if (response.evalCount != null && response.evalCount! > 0) ...[
                  const Divider(height: 12),
                  _buildMetricRow(
                    context,
                    'Response',
                    _formatTokens(response.evalCount),
                    'tokens',
                  ),
                  _buildMetricRow(
                    context,
                    'Generation',
                    _formatDuration(response.evalDuration),
                    null,
                  ),
                  _buildMetricRow(
                    context,
                    'Speed',
                    _formatRate(response.evalRate),
                    't/s',
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class LlmChatScreen extends StatefulWidget {
  const LlmChatScreen({super.key});

  @override
  State<LlmChatScreen> createState() => _LlmChatScreenState();
}

class _LlmChatScreenState extends State<LlmChatScreen> {
  final _promptController = TextEditingController();
  final _chatScrollController = ScrollController();
  final _historyScrollController = ScrollController();
  final Map<int, bool> _expandedMetrics = {};
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
    _chatScrollController.addListener(_scrollListener);
    
    // Check auth state and sign in anonymously if needed
    final authState = context.read<AuthCubit>().state;
    authState.maybeWhen(
      authenticated: (uid, displayName, email) {
        developer.log('User is authenticated - UID: $uid, Name: $displayName, Email: $email');
        // Add initial greeting for new chats
        if (context.read<ChatCubit>().state.currentChatId == null) {
          _sendInitialGreeting();
        }
      },
      unauthenticated: () {
        developer.log('User is not authenticated, signing in anonymously...');
        context.read<AuthCubit>().signInAnonymously().then((_) {
          developer.log('Anonymous sign-in successful');
          if (context.read<ChatCubit>().state.currentChatId == null) {
            _sendInitialGreeting();
          }
        }).catchError((error) {
          developer.log('Anonymous sign-in failed: $error');
          context.go('/auth', extra: {'mode': 'login'});
        });
      },
      error: (message) {
        developer.log('Authentication error: $message');
        context.go('/auth', extra: {'mode': 'login'});
      },
      orElse: () {
        developer.log('Unknown authentication state, signing in anonymously...');
        context.read<AuthCubit>().signInAnonymously().then((_) {
          developer.log('Anonymous sign-in successful');
          if (context.read<ChatCubit>().state.currentChatId == null) {
            _sendInitialGreeting();
          }
        }).catchError((error) {
          developer.log('Anonymous sign-in failed: $error');
          context.go('/auth', extra: {'mode': 'login'});
        });
      },
    );

    // Schedule scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _sendInitialGreeting() {
    final greeting = 'Hello! I\'m your AI development assistant. I can help you with:\n\n'
        '• Flutter/Dart development\n'
        '• Code review and optimization\n'
        '• Architecture decisions\n'
        '• Best practices and patterns\n'
        '• Debugging and problem-solving\n\n'
        'How can I assist you today?';

    // Get the authenticated user's ID
    final authState = context.read<AuthCubit>().state;
    final userId = authState.maybeWhen(
      authenticated: (uid, _, __) => uid,
      orElse: () => throw Exception('User must be authenticated to send messages'),
    );

    // Send initial greeting with the authenticated user's ID
    context.read<ChatCubit>().sendMessage(
      senderId: userId,  // Using authenticated user's ID
      content: greeting,
      isAI: true,  // Mark as AI message
      senderName: _kAiUserName,  // Still use AI name for display
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _chatScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_chatScrollController.hasClients) return;
    
    final showButton = _chatScrollController.position.pixels <
        _chatScrollController.position.maxScrollExtent - 300;
    
    if (_showScrollToBottom != showButton) {
      setState(() {
        _showScrollToBottom = showButton;
      });
    }
  }

  Future<void> _loadAvailableModels() async {
    try {
      final service = LlmService();
      final models = await service.getAvailableModels();
      setState(() {
        _availableModels = models;
        _selectedModel = models.isNotEmpty ? models.first : null;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load models: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.jumpTo(
        _chatScrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
        // Auto-scroll to bottom when new messages arrive if we're already near the bottom
        if (_chatScrollController.hasClients &&
            _chatScrollController.position.pixels >
                _chatScrollController.position.maxScrollExtent - 300) {
          _scrollToBottom();
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return authState.maybeWhen(
            initial: () => const Center(
              child: CircularProgressIndicator(),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            authenticated: (uid, _, __) {
              return Scaffold(
                backgroundColor: theme.colorScheme.background,
                drawer: Drawer(
                  backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Logo and Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Devio',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF343541) : const Color(0xFFF7F7F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(
                                    Icons.search,
                                    size: 20,
                                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                  ),
                                ),
                                Text(
                                  'Search chats',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chats Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Chats',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  context.read<ChatCubit>().startNewChat();
                                  Navigator.pop(context);
                                },
                                tooltip: 'New Chat',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                        // Chat List
                        Expanded(
                          child: BlocBuilder<ChatCubit, ChatState>(
                            builder: (context, state) {
                              if (state.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (state.error != null) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: theme.colorScheme.error,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error loading chats',
                                        style: TextStyle(color: theme.colorScheme.error),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (state.chatHistories.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 32,
                                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No chat history',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Separate pinned and unpinned chats
                              final pinnedChats = state.chatHistories.where((chat) => chat['isPinned'] == true).toList();
                              final unpinnedChats = state.chatHistories.where((chat) => chat['isPinned'] != true).toList();

                              return ListView(
                                controller: _historyScrollController,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                children: [
                                  if (pinnedChats.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                      child: Text(
                                        'Pinned',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    ...pinnedChats.map((chat) => _buildChatItem(chat, state.currentChatId, isDark, context)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(height: 1),
                                    ),
                                  ],
                                  if (unpinnedChats.isNotEmpty) ...[
                                    if (pinnedChats.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                        child: Text(
                                          'Other',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ...unpinnedChats.map((chat) => _buildChatItem(chat, state.currentChatId, isDark, context)),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),

                        const Divider(height: 1),
                        
                        // User Profile
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: simple.SimpleDrawerMenuItem(
                            icon: CircleAvatar(
                              radius: 14,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                              child: authState.maybeWhen(
                                authenticated: (_, __, photoUrl) {
                                  if (photoUrl != null && photoUrl.startsWith('http')) {
                                    return ClipOval(
                                      child: Image.network(
                                        photoUrl,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.person,
                                          size: 16,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    );
                                  }
                                  return Icon(
                                    Icons.person,
                                    size: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  );
                                },
                                orElse: () => Icon(
                                  Icons.person,
                                  size: 16,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            title: authState.maybeWhen(
                              authenticated: (_, displayName, __) => displayName ?? 'User',
                              orElse: () => 'User',
                            ),
                            onTap: () => context.push('/profile'),
                            isDark: isDark,
                            showLeadingBackground: false,
                            showTrailingIcon: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                appBar: AppBar(
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  title: Row(
                    children: [
                      Hero(
                        tag: 'ai_icon',
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.smart_toy_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Devio',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reload Models',
                      onPressed: _loadAvailableModels,
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ),
                body: Column(
                  children: [
                    // Model Selection Card without animation
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.model_training,
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Select AI Model',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_availableModels.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_availableModels.isEmpty)
                            Center(
                              child: Text(
                                'Loading available models...',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedModel,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                prefixIcon: Icon(
                                  Icons.psychology_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              items: _availableModels.map((String model) {
                                return DropdownMenuItem<String>(
                                  value: model,
                                  child: Text(
                                    model,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedModel = newValue;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    // Chat Messages with constrained width
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 768),
                          child: BlocConsumer<LlmCubit, LlmState>(
                            listener: (context, state) {
                              developer.log('LLM state changed: $state');
                              state.maybeWhen(
                                success: (response) {
                                  developer.log('Received AI response: ${response.text}');
                                  // Get the authenticated user's ID for sending the AI response
                                  final authState = context.read<AuthCubit>().state;
                                  final userId = authState.maybeWhen(
                                    authenticated: (uid, _, __) => uid,
                                    orElse: () {
                                      developer.log('User not authenticated when handling AI response');
                                      throw Exception('User must be authenticated to send messages');
                                    },
                                  );

                                  developer.log('Sending AI response with user ID: $userId');
                                  // Send AI response with the authenticated user's ID
                                  context.read<ChatCubit>().sendMessage(
                                    senderId: userId,  // Using authenticated user's ID
                                    content: response.text,
                                    isAI: true,  // Mark as AI message
                                    senderName: _kAiUserName,  // Use AI name for display
                                  ).then((_) {
                                    developer.log('AI response sent successfully');
                                    // Scroll to bottom after message is sent
                                    _scrollToBottom();
                                  }).catchError((error) {
                                    developer.log('Error sending AI response: $error');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error sending AI response: $error'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  });
                                },
                                error: (error) {
                                  developer.log('Error generating AI response: $error');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $error'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                },
                                orElse: () {
                                  developer.log('Unhandled LLM state');
                                },
                              );
                            },
                            builder: (context, state) {
                              return BlocBuilder<ChatCubit, ChatState>(
                                builder: (context, chatState) {
                                  if (chatState.isLoading) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  if (chatState.error != null) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Error: ${chatState.error}',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: theme.colorScheme.error,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (chatState.messages.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 48,
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Start a conversation',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Ask me anything about app development',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Scrollbar(
                                    controller: _chatScrollController,
                                    child: ListView.builder(
                                      key: const PageStorageKey('chat_messages'),
                                      controller: _chatScrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      itemCount: chatState.messages.length,
                                      reverse: false,
                                      addAutomaticKeepAlives: false,
                                      addRepaintBoundaries: false,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                      itemBuilder: (context, index) {
                                        final message = chatState.messages[index];
                                        final isUser = !message.isAI;
                                        final isLastMessage = index == chatState.messages.length - 1;

                                        // Auto-scroll to bottom for new messages
                                        if (isLastMessage) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (_chatScrollController.hasClients &&
                                                _chatScrollController.position.pixels >
                                                    _chatScrollController.position.maxScrollExtent - 300) {
                                              _scrollToBottom();
                                            }
                                          });
                                        }

                                        return RepaintBoundary(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 16.0),
                                            child: Column(
                                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              children: [
                                                MessageBubble(
                                                  isUser: isUser,
                                                  child: Column(
                                                    crossAxisAlignment: isUser
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment.start,
                                                    children: [
                                                      if (!isUser)
                                                        Padding(
                                                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                Icons.smart_toy_outlined,
                                                                size: 16,
                                                                color: theme.colorScheme.primary,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                message.senderName ?? _kAiUserName,
                                                                style: theme.textTheme.bodySmall?.copyWith(
                                                                  color: theme.colorScheme.primary,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                          left: isUser ? 64 : 0,
                                                          right: isUser ? 0 : 64,
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isUser
                                                              ? theme.colorScheme.primary
                                                              : theme.colorScheme.surface,
                                                          borderRadius: BorderRadius.only(
                                                            topLeft: const Radius.circular(16),
                                                            topRight: const Radius.circular(16),
                                                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                                                            bottomRight: Radius.circular(isUser ? 4 : 16),
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: theme.shadowColor.withOpacity(0.1),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: SelectableText.rich(
                                                          TextSpan(
                                                            text: message.content,
                                                            style: theme.textTheme.bodyLarge?.copyWith(
                                                              color: isUser
                                                                  ? theme.colorScheme.onPrimary
                                                                  : theme.colorScheme.onSurface,
                                                            ),
                                                          ),
                                                          scrollPhysics: const NeverScrollableScrollPhysics(),
                                                          minLines: 1,
                                                          maxLines: null,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Add performance metrics for AI responses with proper alignment
                                                if (!isUser)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                      left: 0,
                                                      right: 64,
                                                      top: 4,
                                                    ),
                                                    child: BlocBuilder<LlmCubit, LlmState>(
                                                      builder: (context, llmState) {
                                                        return llmState.maybeWhen(
                                                          success: (response) {
                                                            return PerformanceMetrics(
                                                              response: response,
                                                              isExpanded: _expandedMetrics[index] ?? false,
                                                              onToggle: () {
                                                                setState(() {
                                                                  _expandedMetrics[index] = !(_expandedMetrics[index] ?? false);
                                                                });
                                                              },
                                                            );
                                                          },
                                                          orElse: () => const SizedBox.shrink(),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                    // Input field with constrained width
                    Container(
                      color: theme.colorScheme.surface,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 12 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 768),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promptController,
                                  decoration: InputDecoration(
                                    hintText: 'Ask me anything...',
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceVariant,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.edit_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.newline,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              BlocBuilder<LlmCubit, LlmState>(
                                builder: (context, state) {
                                  final isLoading = state.maybeWhen(
                                    loading: () => true,
                                    orElse: () => false,
                                  );

                                  return Row(
                                    children: [
                                      if (_showScrollToBottom)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Material(
                                            color: theme.colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(20),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: _scrollToBottom,
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                child: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Material(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: _selectedModel == null || isLoading
                                              ? null
                                              : _sendMessage,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            child: isLoading
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        theme.colorScheme.onPrimary,
                                                      ),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.send_rounded,
                                                    color: theme.colorScheme.onPrimary,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            unauthenticated: () {
              // Redirect to login screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/auth', extra: {'mode': 'login'});
              });
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/auth', extra: {'mode': 'login'}),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
            orElse: () => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  void _sendMessage() {
    if (_selectedModel == null) {
      developer.log('No model selected');
      return;
    }
    
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      developer.log('Empty prompt');
      return;
    }

    developer.log('Sending message with prompt: $prompt');
    developer.log('Selected model: $_selectedModel');

    final authState = context.read<AuthCubit>().state;
    final userId = authState.maybeWhen(
      authenticated: (uid, displayName, _) => uid,
      orElse: () {
        developer.log('User not authenticated');
        throw Exception('User must be authenticated to send messages');
      },
    );

    final userName = authState.maybeWhen(
      authenticated: (_, displayName, __) => displayName,
      orElse: () => null,
    );

    developer.log('Sending user message with ID: $userId and name: $userName');

    // First send the user's message with the authenticated user's ID
    context.read<ChatCubit>().sendMessage(
      senderId: userId,  // Using the authenticated user's ID
      content: prompt,
      isAI: false,
      senderName: userName,
    ).then((_) {
      developer.log('User message sent successfully, generating AI response...');
      // After the user's message is sent, generate AI response
      context.read<LlmCubit>().generateResponse(
        prompt: prompt,
        modelName: _selectedModel!,
      );
      _promptController.clear();
      _scrollToBottom();
    }).catchError((error) {
      developer.log('Error sending message: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  Widget _buildChatItem(Map<String, dynamic> chat, String? currentChatId, bool isDark, BuildContext context) {
    final isSelected = chat['id'] == currentChatId;
    final isPinned = chat['isPinned'] as bool? ?? false;
    final chatId = chat['id'] as String;
    final theme = Theme.of(context);

    return DrawerMenuItem(
      icon: Icon(
        Icons.chat_bubble_outline,
        size: 20,
        color: isSelected
            ? theme.colorScheme.primary
            : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
      ),
      title: chat['title'] as String,
      onTap: () {
        Navigator.pop(context);
        context.read<ChatCubit>().selectChat(chatId);
      },
      isDark: isDark,
      showLeadingBackground: false,
      isSelected: isSelected,
      isPinned: isPinned,
      onPin: (title) => context.read<ChatCubit>().pinChat(chatId),
      onUnpin: (title) => context.read<ChatCubit>().unpinChat(chatId),
      onDelete: (title) => context.read<ChatCubit>().deleteChat(chatId),
      onRename: (oldTitle, newTitle) => context.read<ChatCubit>().renameChat(chatId, newTitle),
    );
  }
} 
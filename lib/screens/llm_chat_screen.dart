import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/llm/cubit/llm_cubit.dart';
import '../features/llm/cubit/llm_state.dart';
import '../features/llm/models/llm_response.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_cubit.dart';
import '../cubits/chat/chat_cubit.dart';
import '../cubits/chat/chat_state.dart';
import '../widgets/drawer_menu_item.dart';
import '../widgets/simple_drawer_menu_item.dart' as simple;
import '../constants/assets.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../widgets/chat_message_widget.dart';
import '../widgets/loading_animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

const String _kAiUserName = 'AI Assistant';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? senderName;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.senderName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

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
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showPerformanceMetrics = false;
  bool _isDrawerOpen = false;
  bool _isSettingsOpen = false;
  bool _isPromptLibraryOpen = false;
  String? _selectedPromptId;
  bool _isWaitingForAiResponse = false;
  String? _placeholderMessageId;
  final ImagePicker _picker = ImagePicker();
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _showScrollToBottom = false;
  Uint8List? _selectedImageBytes;
  File? _selectedDocument;
  bool _isLoadingModels = false;
  bool _showModelSelection = false;

  @override
  void initState() {
    super.initState();
    // Set Gemini as default provider
    context.read<LlmCubit>().setProvider(LlmProvider.gemini);
    _loadAvailableModels();
    _chatScrollController.addListener(_scrollListener);
    
    // Check auth state but only sign in if unauthenticated
    final authState = context.read<AuthCubit>().state;
    authState.maybeWhen(
      authenticated: (uid, displayName, email) {
        developer.log('User is already authenticated - UID: $uid');
      },
      unauthenticated: () {
        developer.log('User is not authenticated, signing in anonymously...');
        context.read<AuthCubit>().signInAnonymously().then((_) {
          developer.log('Anonymous sign-in successful');
        }).catchError((error) {
          developer.log('Anonymous sign-in failed: $error');
          context.go('/auth', extra: {'mode': 'login'});
        });
      },
      error: (message) {
        developer.log('Authentication error: $message');
        context.go('/auth', extra: {'mode': 'login'});
      },
      orElse: () => null, // Do nothing for other states like initial or loading
    );

    // Schedule scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Show model selection initially only if no model is selected
    _showModelSelection = _selectedModel == null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatScrollController.dispose();
    _historyScrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _messageFocusNode.dispose();
    _searchFocusNode.dispose();
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
      setState(() {
        _isLoadingModels = true;
      });
      
      developer.log('Loading available models...');
      final models = await context.read<LlmCubit>().getAvailableModels();
      developer.log('Models loaded: $models');
      
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
          _availableModels = models;
          final provider = context.read<LlmCubit>().currentProvider;
          
          // Filter models based on current context
          final filteredModels = models.where((model) {
            if (provider == LlmProvider.local) {
              return true;
            }
            if (_selectedImageBytes != null) {
              return model.contains('vision');
            }
            return !model.contains('vision');
          }).toList();

          // Ensure we have at least one model available
          if (filteredModels.isEmpty) {
            _availableModels = provider == LlmProvider.gemini 
                ? [_selectedImageBytes != null ? 'gemini-pro-vision' : 'gemini-pro']
                : ['local-model'];
          }

          // Update selected model based on filtered list
          if (_selectedModel == null || !filteredModels.contains(_selectedModel)) {
            _selectedModel = provider == LlmProvider.gemini 
                ? (_selectedImageBytes != null ? 'gemini-pro-vision' : 'gemini-pro')
                : filteredModels.firstOrNull;
          }
          // If switching to Gemini, ensure we have a Gemini model selected
          else if (provider == LlmProvider.gemini && !_selectedModel!.startsWith('gemini-')) {
            _selectedModel = _selectedImageBytes != null ? 'gemini-pro-vision' : 'gemini-pro';
          }
          
          developer.log('Selected model: $_selectedModel');
          developer.log('Available models: $_availableModels');
        });
      }
    } catch (e) {
      developer.log('Error loading models: $e');
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
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
        backgroundColor: Colors.grey.shade800,
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedDocument = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  void _clearSelectedDocument() {
    setState(() {
      _selectedDocument = null;
    });
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
                  backgroundColor: isDark ? const Color(0xFF202123) : theme.colorScheme.surface,
                  child: Column(
                    children: [
                      SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  // Search widget (now with Expanded to take available width)
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _searchFocusNode.hasFocus
                                                ? theme.colorScheme.primary.withOpacity(0.1)
                                                : Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: _searchFocusNode.hasFocus
                                              ? theme.colorScheme.primary.withOpacity(0.3)
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: BlocBuilder<ChatCubit, ChatState>(
                                        buildWhen: (previous, current) => 
                                          previous.searchQuery != current.searchQuery,
                                        builder: (context, state) {
                                          final isSearchActive = state.searchQuery.isNotEmpty;
                                          return Focus(
                                            onFocusChange: (hasFocus) {
                                              // Trigger rebuild to update container styling
                                              setState(() {});
                                            },
                                            child: TextField(
                                              controller: _searchController,
                                              focusNode: _searchFocusNode,
                                              decoration: InputDecoration(
                                                hintText: 'Search',
                                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                                  color: isDark 
                                                      ? Colors.white.withOpacity(0.5) 
                                                      : Colors.black.withOpacity(0.5),
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 8,
                                                ),
                                                prefixIcon: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  padding: const EdgeInsets.all(8),
                                                  child: Icon(
                                                    Icons.search,
                                                    size: 18,
                                                    color: isSearchActive || _searchFocusNode.hasFocus
                                                        ? theme.colorScheme.primary
                                                        : (isDark 
                                                            ? Colors.white.withOpacity(0.5) 
                                                            : Colors.black.withOpacity(0.5)),
                                                  ),
                                                ),
                                                suffixIcon: isSearchActive
                                                  ? Container(
                                                      margin: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: isDark 
                                                            ? Colors.grey.shade600 
                                                            : Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(50),
                                                      ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.clear,
                                                          size: 14,
                                                          color: isDark 
                                                              ? Colors.white.withOpacity(0.9) 
                                                              : Colors.black.withOpacity(0.6),
                                                        ),
                                                        onPressed: () {
                                                          _searchController.clear();
                                                          context.read<ChatCubit>().searchChats('');
                                                          // Keep focus on the field after clearing
                                                          _searchFocusNode.requestFocus();
                                                        },
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    )
                                                  : null,
                                              ),
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: isDark ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onChanged: (value) {
                                                context.read<ChatCubit>().searchChats(value);
                                              },
                                              textInputAction: TextInputAction.search,
                                              cursorColor: theme.colorScheme.primary,
                                              cursorWidth: 1.5,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  // New Chat button
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.8) 
                                            : Colors.black.withOpacity(0.7),
                                      ),
                                      onPressed: () {
                                        context.read<ChatCubit>().startNewChat();
                                        Navigator.pop(context);
                                      },
                                      tooltip: 'New Chat',
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            BlocBuilder<ChatCubit, ChatState>(
                              buildWhen: (previous, current) => 
                                previous.searchQuery != current.searchQuery,
                              builder: (context, state) {
                                final chatCubit = context.read<ChatCubit>();
                                final filteredChats = chatCubit.getFilteredChatHistories();
                                final isSearchActive = state.searchQuery.isNotEmpty;
                                
                                if (!isSearchActive) return const SizedBox.shrink();
                                
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${filteredChats.length} result${filteredChats.length != 1 ? 's' : ''}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.7) 
                                              : Colors.black.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Chats Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Text(
                              'Chats',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.5) 
                                    : Colors.black.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
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
                                      color: Colors.grey.shade800,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading chats',
                                      style: TextStyle(color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final chatCubit = context.read<ChatCubit>();
                            final filteredChats = chatCubit.getFilteredChatHistories();

                            if (filteredChats.isEmpty) {
                              if (state.searchQuery.isNotEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.05) 
                                              : Colors.black.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.search_off_rounded,
                                          size: 32,
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.7) 
                                              : Colors.black.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No chats found',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.9) 
                                              : Colors.black.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try a different search term',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.6) 
                                              : Colors.black.withOpacity(0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<ChatCubit>().searchChats('');
                                        },
                                        icon: Icon(
                                          Icons.clear,
                                          size: 16,
                                        ),
                                        label: const Text('Clear search'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.05) 
                                            : Colors.black.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        size: 32,
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.7) 
                                            : Colors.black.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No chat history',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.9) 
                                            : Colors.black.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start a new chat to begin',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.6) 
                                            : Colors.black.withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<ChatCubit>().startNewChat();
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        size: 16,
                                      ),
                                      label: const Text('New Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Separate pinned and unpinned chats
                            final pinnedChats = filteredChats.where((chat) => chat['isPinned'] == true).toList();
                            final unpinnedChats = filteredChats.where((chat) => chat['isPinned'] != true).toList();

                            return ListView(
                              controller: _chatScrollController,
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
                                  ...pinnedChats.map((chat) => _buildChatItem(chat, state.currentChatId, isDark, context)).toList(),
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
                                  ...unpinnedChats.map(
                                    (chat) => _buildChatItem(chat, state.currentChatId, isDark, context),
                                  ).toList(),
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
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/profile');
                          },
                          isDark: isDark,
                          showLeadingBackground: false,
                          showTrailingIcon: true,
                        ),
                      ),
                    ],
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
                        tag: 'app_logo',
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Image.asset(
                            AppAssets.logo,
                            fit: BoxFit.contain,
                            color: null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Show a compact model indicator instead of the full selection UI
                    _buildCompactModelIndicator(context),
                    const SizedBox(width: 8),
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
                    // Use AnimatedSwitcher for smooth appearance/disappearance
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _showModelSelection
                          ? _buildModelSelectionUI(context)
                          : const SizedBox.shrink(),
                    ),
                    // Chat Messages with constrained width
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 768),
                          child: BlocConsumer<LlmCubit, LlmState>(
                            listener: (context, llmState) {
                              llmState.maybeWhen(
                                success: (response) {
                                  final authState = context.read<AuthCubit>().state;
                                  final userId = authState.maybeWhen(
                                    authenticated: (uid, _, __) => uid,
                                    orElse: () => throw Exception('User must be authenticated to send messages'),
                                  );

                                  // Remove the placeholder message if it exists
                                  if (_placeholderMessageId != null) {
                                    context.read<ChatCubit>().removePlaceholderMessage(_placeholderMessageId!);
                                  }

                                  context.read<ChatCubit>().sendMessage(
                                    senderId: userId,
                                    content: response.text,
                                    isAI: true,
                                    senderName: _kAiUserName,
                                    totalDuration: response.totalDuration,
                                    loadDuration: response.loadDuration,
                                    promptEvalCount: response.promptEvalCount,
                                    promptEvalDuration: response.promptEvalDuration,
                                    promptEvalRate: response.promptEvalRate,
                                    evalCount: response.evalCount,
                                    evalDuration: response.evalDuration,
                                    evalRate: response.evalRate,
                                  ).then((_) {
                                    _scrollToBottom();
                                    // Reset waiting flag
                                    setState(() {
                                      _isWaitingForAiResponse = false;
                                      _placeholderMessageId = null;
                                    });
                                  }).catchError((error) {
                                    setState(() {
                                      _isWaitingForAiResponse = false;
                                      _placeholderMessageId = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error sending AI response: $error'),
                                        backgroundColor: Colors.grey.shade800,
                                      ),
                                    );
                                  });
                                },
                                error: (message) {
                                  // Remove the placeholder message if it exists
                                  if (_placeholderMessageId != null) {
                                    context.read<ChatCubit>().removePlaceholderMessage(_placeholderMessageId!);
                                  }
                                  
                                  setState(() {
                                    _isWaitingForAiResponse = false;
                                    _placeholderMessageId = null;
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $message'),
                                      backgroundColor: Colors.grey.shade800,
                                    ),
                                  );
                                },
                                orElse: () {},
                              );
                            },
                            builder: (context, llmState) {
                              return BlocBuilder<ChatCubit, ChatState>(
                                builder: (context, chatState) {
                                  if (chatState.isLoading && chatState.messages.isEmpty) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  if (chatState.error != null) {
                                    return Center(
                                      child: SelectableText.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Error: ',
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: chatState.error.toString(),
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (chatState.messages.isEmpty) {
                                    return LoadingAnimation(
                                      onTap: () => _sendInitialGreeting(),
                                      showRefreshIndicator: true,
                                    );
                                  }

                                  return ListView.builder(
                                    controller: _chatScrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: chatState.messages.length,
                                    itemBuilder: (context, index) {
                                      final message = chatState.messages[index];
                                      final messageId = message.id;
                                      
                                      // Check if this is a placeholder message
                                      if (messageId == _placeholderMessageId) {
                                        return _buildTypingIndicator(context);
                                      }
                                      
                                      return ChatMessageWidget(
                                        message: message,
                                        showMetrics: _showPerformanceMetrics,
                                        onMetricsToggle: () {
                                          setState(() {
                                            _showPerformanceMetrics = !_showPerformanceMetrics;
                                          });
                                        },
                                      );
                                    },
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
                    _buildInputField(),
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
                    color: Colors.grey.shade800,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade800,
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
      _showErrorSnackBar('Please select a model first');
      return;
    }

    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    // Check if we're trying to send an image with a non-vision model
    if (_selectedImageBytes != null && !_selectedModel!.contains('vision')) {
      _showErrorSnackBar('Please select a vision-capable model to analyze images');
      return;
    }

    // Check if we're using the correct provider for image analysis
    if (_selectedImageBytes != null && context.read<LlmCubit>().currentProvider != LlmProvider.gemini) {
      _showErrorSnackBar('Image analysis is only available with Gemini');
      return;
    }

    // Check if we're already waiting for a response
    if (_isWaitingForAiResponse) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final userId = authState.maybeWhen(
      authenticated: (uid, displayName, _) => uid,
      orElse: () => throw Exception('User must be authenticated to send messages'),
    );

    final userName = authState.maybeWhen(
      authenticated: (_, displayName, __) => displayName,
      orElse: () => null,
    );

    // Set waiting flag
    setState(() {
      _isWaitingForAiResponse = true;
    });

    // First send the user's message
    context.read<ChatCubit>().sendMessage(
      senderId: userId,
      content: prompt,
      isAI: false,
      senderName: userName,
    ).then((_) {
      // Add a placeholder message for the AI response
      final placeholderId = 'placeholder-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _placeholderMessageId = placeholderId;
      });
      
      // Add the placeholder message to the chat
      context.read<ChatCubit>().addPlaceholderMessage(
        id: placeholderId,
        senderId: 'ai',
        isAI: true,
        senderName: _kAiUserName,
      );

      // Generate response based on whether an image or document is selected
      if (_selectedImageBytes != null) {
        context.read<LlmCubit>().generateResponseWithImage(
          prompt: prompt,
          imageBytes: _selectedImageBytes!,
          modelName: _selectedModel!,
        );
        _clearSelectedImage();
      } else if (_selectedDocument != null) {
        context.read<LlmCubit>().generateResponseWithDocument(
          prompt: prompt,
          documentPath: _selectedDocument!.path,
          modelName: _selectedModel!,
        );
        _clearSelectedDocument();
      } else {
        context.read<LlmCubit>().generateResponse(
          prompt: prompt,
          modelName: _selectedModel!,
        );
      }
      
      _messageController.clear();
      _scrollToBottom();
    }).catchError((error) {
      setState(() {
        _isWaitingForAiResponse = false;
        _placeholderMessageId = null;
      });
      _showErrorSnackBar('Failed to send message: $error');
    });
  }

  void _sendInitialGreeting() {
    final greeting = 'Hello! I\'m Devio your AI development assistant. I can help you with:\n\n'
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
      onPin: (id) => context.read<ChatCubit>().pinChat(id),
      onUnpin: (id) => context.read<ChatCubit>().unpinChat(id),
      onDelete: (id) => context.read<ChatCubit>().deleteChat(id),
      onRename: (id, newTitle) => context.read<ChatCubit>().renameChat(id, newTitle),
    );
  }

  Widget _buildModelSelectionUI(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Select AI Model',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                onPressed: _loadAvailableModels,
                tooltip: 'Refresh models',
              ),
              // Close button
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _showModelSelection = false;
                  });
                },
                tooltip: 'Close model selection',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Provider selector
          Row(
            children: [
              _buildProviderSelector(context),
              const Spacer(),
              // Model selector dropdown
              if (_isLoadingModels)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Model list
          if (_isLoadingModels)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading available models...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else if (_availableModels.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    Icons.error_outline,
                    size: 24,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No models available at the moment',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadAvailableModels,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                  ),
                ],
              ),
            )
          else
            _buildModelSelector(context),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(BuildContext context) {
    final llmCubit = context.read<LlmCubit>();
    final theme = Theme.of(context);

    return PopupMenuButton<LlmProvider>(
      initialValue: llmCubit.currentProvider,
      onSelected: (LlmProvider provider) {
        llmCubit.setProvider(provider);
        _loadAvailableModels();
      },
      tooltip: 'Select AI provider',
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<LlmProvider>>[
        PopupMenuItem<LlmProvider>(
          value: LlmProvider.local,
          child: Row(
            children: [
              Icon(
                Icons.computer,
                color: llmCubit.currentProvider == LlmProvider.local
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Local Model',
                style: TextStyle(
                  color: llmCubit.currentProvider == LlmProvider.local
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<LlmProvider>(
          value: LlmProvider.gemini,
          child: Row(
            children: [
              Icon(
                Icons.cloud,
                color: llmCubit.currentProvider == LlmProvider.gemini
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gemini',
                style: TextStyle(
                  color: llmCubit.currentProvider == LlmProvider.gemini
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              llmCubit.currentProvider == LlmProvider.local
                  ? Icons.computer
                  : Icons.cloud,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              llmCubit.currentProvider == LlmProvider.local
                  ? 'Local'
                  : 'Gemini',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    final filteredModels = _getFilteredModels();
    
    // Group models by type
    final textModels = filteredModels.where((m) => !m.contains('vision')).toList();
    final visionModels = filteredModels.where((m) => m.contains('vision')).toList();
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (textModels.isNotEmpty && _selectedImageBytes == null) ...[
            _ModelGroupHeader(title: 'Text Models'),
            const SizedBox(height: 4),
            _buildModelRadioGroup(textModels),
            const SizedBox(height: 12),
          ],
          if (visionModels.isNotEmpty && (_selectedImageBytes != null || textModels.isEmpty)) ...[
            _ModelGroupHeader(title: 'Vision Models'),
            const SizedBox(height: 4),
            _buildModelRadioGroup(visionModels),
          ],
        ],
      ),
    );
  }

  Widget _buildModelRadioGroup(List<String> models) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: models.map((model) {
        return RadioListTile<String>(
          title: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _getModelDisplayName(model),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                      fontWeight: model == _selectedModel ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark 
                          ? Colors.green.withOpacity(0.5) 
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.brightness == Brightness.dark 
                          ? Colors.green.shade300 
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          subtitle: Text(
            _getModelDescription(model),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          value: model,
          groupValue: _selectedModel,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedModel = value;
                // Auto-hide the model selection UI after selecting a model
                Future.delayed(const Duration(milliseconds: 300), () {
                  setState(() {
                    _showModelSelection = false;
                  });
                });
              });
            }
          },
          activeColor: theme.colorScheme.primary,
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  List<String> _getFilteredModels() {
    final provider = context.read<LlmCubit>().currentProvider;
    
    // Filter models based on current context
    return _availableModels.where((model) {
      if (provider == LlmProvider.local) {
        return true;
      }
      if (_selectedImageBytes != null) {
        return model.contains('vision');
      }
      return !model.contains('vision');
    }).toList();
  }

  String _getModelDisplayName(String model) {
    // Convert model names to more user-friendly display names
    switch (model) {
      case 'gemini-pro':
        return 'Gemini Pro';
      case 'gemini-1.5-pro':
        return 'Gemini 1.5 Pro';
      case 'gemini-1.0-pro':
        return 'Gemini 1.0 Pro';
      case 'gemini-pro-vision':
        return 'Gemini Pro Vision';
      case 'gemini-1.5-pro-vision':
        return 'Gemini 1.5 Pro Vision';
      case 'gemini-1.5-pro-vision-latest':
        return 'Gemini 1.5 Pro Vision (Latest)';
      case 'gemini-1.0-pro-vision':
        return 'Gemini 1.0 Pro Vision';
      case 'gemini-ultra':
        return 'Gemini Ultra';
      case 'gemini-ultra-vision':
        return 'Gemini Ultra Vision';
      default:
        return model;
    }
  }

  String _getModelDescription(String model) {
    // Provide brief descriptions of model capabilities
    if (model.contains('ultra')) {
      return 'Highest capability model with advanced reasoning';
    } else if (model.contains('1.5')) {
      return 'Latest generation with improved capabilities';
    } else if (model.contains('vision')) {
      return 'Specialized for image analysis and understanding';
    } else {
      return 'General purpose AI model for text generation';
    }
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    
    return Container(
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
          child: Column(
            children: [
              if (_selectedImageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: theme.colorScheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                            onPressed: _clearSelectedImage,
                            tooltip: 'Remove image',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_selectedDocument != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedDocument!.path.toLowerCase().endsWith('.pdf')
                            ? Icons.picture_as_pdf
                            : Icons.description,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          path.basename(_selectedDocument!.path),
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                        onPressed: _clearSelectedDocument,
                        tooltip: 'Remove document',
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _selectedImageBytes != null
                            ? 'Ask about this image...'
                            : _selectedDocument != null
                                ? 'Ask about this document...'
                                : 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isWaitingForAiResponse,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: _selectedImageBytes != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed: _isWaitingForAiResponse ? null : _pickImage,
                          tooltip: 'Add image',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: _selectedDocument != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed: _isWaitingForAiResponse ? null : _pickDocument,
                          tooltip: 'Add document',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: (_selectedModel == null || _isWaitingForAiResponse)
                          ? null
                          : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isWaitingForAiResponse
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactModelIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        setState(() {
          _showModelSelection = !_showModelSelection;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
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
              _selectedModel != null ? _getModelDisplayName(_selectedModel!) : 'Select Model',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showModelSelection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.smart_toy_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotWidget(),
                const SizedBox(width: 4),
                _DotWidget(delay: const Duration(milliseconds: 200)),
                const SizedBox(width: 4),
                _DotWidget(delay: const Duration(milliseconds: 400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelGroupHeader extends StatelessWidget {
  final String title;

  const _ModelGroupHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: message.isUser ? 64 : 0,
          right: message.isUser ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: message.isUser 
              ? null 
              : Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.spaceGrotesk(
            color: message.isUser 
                ? theme.colorScheme.onPrimary 
                : theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _MessageInput({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.spaceGrotesk(color: theme.colorScheme.onSurface),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSubmit,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotWidget extends StatelessWidget {
  final Duration delay;

  const _DotWidget({this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant,
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.0, 1.0),
      duration: const Duration(milliseconds: 600),
      delay: delay,
      curve: Curves.easeInOut,
    );
  }
} 
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
import '../widgets/model_selection_ui.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/performance_metrics.dart';
import '../widgets/compact_model_indicator.dart';
import '../widgets/typing_indicator.dart';
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
  final bool _isDrawerOpen = false;
  final bool _isSettingsOpen = false;
  final bool _isPromptLibraryOpen = false;
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

    // Don't show model selection initially
    _showModelSelection = false;
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

          // Filter out models that are known to be unavailable
          // This is a fallback in case the API returns models that are actually unavailable
          final provider = context.read<LlmCubit>().currentProvider;
          if (provider == LlmProvider.gemini) {
            // For Gemini, we'll use a more conservative list of models that are likely to be available
            // This helps prevent the 429 quota errors
            _availableModels = _filterReliableGeminiModels(models);
          } else {
            _availableModels = models;
          }

          // Filter models based on current context
          final filteredModels = _getFilteredModels();

          // Ensure we have at least one model available
          if (filteredModels.isEmpty) {
            if (provider == LlmProvider.gemini) {
              // Default to the most reliable model based on context
              _availableModels = [
                _selectedImageBytes != null
                    ? 'gemini-1.0-pro-vision'
                    : 'gemini-1.0-pro'
              ];
            } else {
              _availableModels = ['local-model'];
            }
          }

          // Always select a default model if none is selected
          if (_selectedModel == null) {
            _selectedModel = provider == LlmProvider.gemini
                ? (_selectedImageBytes != null
                    ? 'gemini-1.0-pro-vision'
                    : 'gemini-1.0-pro')
                : filteredModels.firstOrNull;
          }
          // If switching to Gemini, ensure we have a Gemini model selected
          else if (provider == LlmProvider.gemini &&
              !_selectedModel!.startsWith('gemini-')) {
            _selectedModel = _selectedImageBytes != null
                ? 'gemini-1.0-pro-vision'
                : 'gemini-1.0-pro';
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
          // If we encounter an error, set a minimal set of reliable models
          final provider = context.read<LlmCubit>().currentProvider;
          if (provider == LlmProvider.gemini) {
            _availableModels = [
              _selectedImageBytes != null
                  ? 'gemini-1.0-pro-vision'
                  : 'gemini-1.0-pro'
            ];
            _selectedModel = _availableModels.first;
          } else {
            _availableModels = ['local-model'];
            _selectedModel = 'local-model';
          }
        });
        _showErrorSnackBar('Failed to load models: $e');
      }
    }
  }

  // Helper method to filter Gemini models to only include the most reliable ones
  List<String> _filterReliableGeminiModels(List<String> allModels) {
    // These are the models that are most likely to be available and not hit quota limits
    final reliableModels = [
      'gemini-1.0-pro',
      'gemini-1.0-pro-vision',
    ];

    // Filter the available models to only include the reliable ones
    final filteredModels =
        allModels.where((model) => reliableModels.contains(model)).toList();

    // If no reliable models are found, return a default set
    if (filteredModels.isEmpty) {
      return _selectedImageBytes != null
          ? ['gemini-1.0-pro-vision']
          : ['gemini-1.0-pro'];
    }

    return filteredModels;
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
                backgroundColor: theme.colorScheme.surface,
                drawer: Drawer(
                  backgroundColor: isDark
                      ? const Color(0xFF202123)
                      : theme.colorScheme.surface,
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
                                      duration:
                                          const Duration(milliseconds: 200),
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _searchFocusNode.hasFocus
                                                ? theme.colorScheme.primary
                                                    .withOpacity(0.1)
                                                : Colors.black
                                                    .withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: _searchFocusNode.hasFocus
                                              ? theme.colorScheme.primary
                                                  .withOpacity(0.3)
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: BlocBuilder<ChatCubit, ChatState>(
                                        buildWhen: (previous, current) =>
                                            previous.searchQuery !=
                                            current.searchQuery,
                                        builder: (context, state) {
                                          final isSearchActive =
                                              state.searchQuery.isNotEmpty;
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
                                                hintStyle: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.5)
                                                      : Colors.black
                                                          .withOpacity(0.5),
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 8,
                                                ),
                                                prefixIcon: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Icon(
                                                    Icons.search,
                                                    size: 18,
                                                    color: isSearchActive ||
                                                            _searchFocusNode
                                                                .hasFocus
                                                        ? theme
                                                            .colorScheme.primary
                                                        : (isDark
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.5)
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.5)),
                                                  ),
                                                ),
                                                suffixIcon: isSearchActive
                                                    ? Container(
                                                        margin: const EdgeInsets
                                                            .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isDark
                                                              ? Colors
                                                                  .grey.shade600
                                                              : Colors.grey
                                                                  .shade200,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                        child: IconButton(
                                                          icon: Icon(
                                                            Icons.clear,
                                                            size: 14,
                                                            color: isDark
                                                                ? Colors.white
                                                                    .withOpacity(
                                                                        0.9)
                                                                : Colors.black
                                                                    .withOpacity(
                                                                        0.6),
                                                          ),
                                                          onPressed: () {
                                                            _searchController
                                                                .clear();
                                                            context
                                                                .read<
                                                                    ChatCubit>()
                                                                .searchChats(
                                                                    '');
                                                            // Keep focus on the field after clearing
                                                            _searchFocusNode
                                                                .requestFocus();
                                                          },
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onChanged: (value) {
                                                context
                                                    .read<ChatCubit>()
                                                    .searchChats(value);
                                              },
                                              textInputAction:
                                                  TextInputAction.search,
                                              cursorColor:
                                                  theme.colorScheme.primary,
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
                                      color: isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade100,
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
                                        context
                                            .read<ChatCubit>()
                                            .startNewChat();
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
                                final filteredChats =
                                    chatCubit.getFilteredChatHistories();
                                final isSearchActive =
                                    state.searchQuery.isNotEmpty;

                                if (!isSearchActive)
                                  return const SizedBox.shrink();

                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${filteredChats.length} result${filteredChats.length != 1 ? 's' : ''}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
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
                              return const Center(
                                  child: CircularProgressIndicator());
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
                                      style: TextStyle(
                                          color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final chatCubit = context.read<ChatCubit>();
                            final filteredChats =
                                chatCubit.getFilteredChatHistories();

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
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.black.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try a different search term',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.6)
                                              : Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          context
                                              .read<ChatCubit>()
                                              .searchChats('');
                                        },
                                        icon: Icon(
                                          Icons.clear,
                                          size: 16,
                                        ),
                                        label: const Text('Clear search'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.black.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start a new chat to begin',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.black.withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<ChatCubit>()
                                            .startNewChat();
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        size: 16,
                                      ),
                                      label: const Text('New Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
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
                            final pinnedChats = filteredChats
                                .where((chat) => chat['isPinned'] == true)
                                .toList();
                            final unpinnedChats = filteredChats
                                .where((chat) => chat['isPinned'] != true)
                                .toList();

                            return ListView(
                              controller: _chatScrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                if (pinnedChats.isNotEmpty) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                    child: Text(
                                      'Pinned',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.black.withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ...pinnedChats.map((chat) => _buildChatItem(
                                      chat,
                                      state.currentChatId,
                                      isDark,
                                      context)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(height: 1),
                                  ),
                                ],
                                if (unpinnedChats.isNotEmpty) ...[
                                  if (pinnedChats.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 4),
                                      child: Text(
                                        'Other',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black.withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ...unpinnedChats.map(
                                    (chat) => _buildChatItem(chat,
                                        state.currentChatId, isDark, context),
                                  ),
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
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            child: authState.maybeWhen(
                              authenticated: (_, __, photoUrl) {
                                if (photoUrl != null &&
                                    photoUrl.startsWith('http')) {
                                  return ClipOval(
                                    child: Image.network(
                                      photoUrl,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
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
                            authenticated: (_, displayName, __) =>
                                displayName ?? 'User',
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
                    CompactModelIndicator(
                      selectedModel: _selectedModel,
                      showModelSelection: _showModelSelection,
                      onTap: () {
                        setState(() {
                          _showModelSelection = !_showModelSelection;
                        });
                      },
                      getModelDisplayName: _getModelDisplayName,
                    ),
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
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _showModelSelection
                          ? Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: SingleChildScrollView(
                                child: ModelSelectionUI(
                                  availableModels: _availableModels,
                                  selectedModel: _selectedModel,
                                  isLoadingModels: _isLoadingModels,
                                  onRefresh: _loadAvailableModels,
                                  onClose: () {
                                    setState(() {
                                      _showModelSelection = false;
                                    });
                                  },
                                  onModelSelected: (model) {
                                    setState(() {
                                      _selectedModel = model;
                                      // Auto-hide the model selection UI after selecting a model
                                      Future.delayed(
                                          const Duration(milliseconds: 300),
                                          () {
                                        setState(() {
                                          _showModelSelection = false;
                                        });
                                      });
                                    });
                                  },
                                  selectedImageBytes: _selectedImageBytes,
                                ),
                              ),
                            )
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
                                  final authState =
                                      context.read<AuthCubit>().state;
                                  final userId = authState.maybeWhen(
                                    authenticated: (uid, _, __) => uid,
                                    orElse: () => throw Exception(
                                        'User must be authenticated to send messages'),
                                  );

                                  // Remove the placeholder message if it exists
                                  if (_placeholderMessageId != null) {
                                    context
                                        .read<ChatCubit>()
                                        .removePlaceholderMessage(
                                            _placeholderMessageId!);
                                  }

                                  context
                                      .read<ChatCubit>()
                                      .sendMessage(
                                        senderId: userId,
                                        content: response.text,
                                        isAI: true,
                                        senderName: _kAiUserName,
                                        totalDuration: response.totalDuration,
                                        loadDuration: response.loadDuration,
                                        promptEvalCount:
                                            response.promptEvalCount,
                                        promptEvalDuration:
                                            response.promptEvalDuration,
                                        promptEvalRate: response.promptEvalRate,
                                        evalCount: response.evalCount,
                                        evalDuration: response.evalDuration,
                                        evalRate: response.evalRate,
                                      )
                                      .then((_) {
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
                                    _handleApiError(error);
                                  });
                                },
                                error: (message) {
                                  // Remove the placeholder message if it exists
                                  if (_placeholderMessageId != null) {
                                    context
                                        .read<ChatCubit>()
                                        .removePlaceholderMessage(
                                            _placeholderMessageId!);
                                  }

                                  setState(() {
                                    _isWaitingForAiResponse = false;
                                    _placeholderMessageId = null;
                                  });

                                  _handleApiError(message);
                                },
                                orElse: () {},
                              );
                            },
                            builder: (context, llmState) {
                              return BlocBuilder<ChatCubit, ChatState>(
                                builder: (context, chatState) {
                                  if (chatState.isLoading &&
                                      chatState.messages.isEmpty) {
                                    return const Center(
                                        child: CircularProgressIndicator());
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
                                        return const TypingIndicator();
                                      }

                                      return ChatMessageWidget(
                                        message: message,
                                        showMetrics: _showPerformanceMetrics,
                                        onMetricsToggle: () {
                                          setState(() {
                                            _showPerformanceMetrics =
                                                !_showPerformanceMetrics;
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
                    // Bottom input field
                    ChatInputField(
                      messageController: _messageController,
                      selectedImageBytes: _selectedImageBytes,
                      selectedDocument: _selectedDocument,
                      isWaitingForAiResponse: _isWaitingForAiResponse,
                      selectedModel: _selectedModel,
                      onSendMessage: _sendMessage,
                      onPickImage: _pickImage,
                      onPickDocument: _pickDocument,
                      onClearSelectedImage: _clearSelectedImage,
                      onClearSelectedDocument: _clearSelectedDocument,
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
                    onPressed: () =>
                        context.go('/auth', extra: {'mode': 'login'}),
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
      _showErrorSnackBar(
          'Please select a vision-capable model to analyze images');
      return;
    }

    // Check if we're using the correct provider for image analysis
    if (_selectedImageBytes != null &&
        context.read<LlmCubit>().currentProvider != LlmProvider.gemini) {
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
      orElse: () =>
          throw Exception('User must be authenticated to send messages'),
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
    context
        .read<ChatCubit>()
        .sendMessage(
          senderId: userId,
          content: prompt,
          isAI: false,
          senderName: userName,
        )
        .then((_) {
      // Add a placeholder message for the AI response
      final placeholderId =
          'placeholder-${DateTime.now().millisecondsSinceEpoch}';
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
      try {
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
      } catch (e) {
        _handleApiError(e);
      }

      _messageController.clear();
      _scrollToBottom();
    }).catchError((error) {
      _handleApiError(error);
    });
  }

  void _handleApiError(dynamic error) {
    setState(() {
      _isWaitingForAiResponse = false;
      if (_placeholderMessageId != null) {
        context
            .read<ChatCubit>()
            .removePlaceholderMessage(_placeholderMessageId!);
        _placeholderMessageId = null;
      }
    });

    String errorMessage = 'Failed to generate response';

    // Check for quota errors
    if (error.toString().contains('429') ||
        error.toString().contains('RESOURCE_EXHAUSTED') ||
        error.toString().contains('quota')) {
      errorMessage =
          'API quota exceeded. Please try again later or switch to a different model.';

      // Show a more detailed error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Quota Exceeded'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have reached the usage limit for the Gemini API.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Suggestions:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text('• Try using gemini-1.0-pro model instead'),
              Text('• Wait a few minutes before trying again'),
              Text('• Switch to a different provider if available'),
              const SizedBox(height: 16),
              Text(
                'Error details: ${error.toString()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showModelSelection = true;
                  // Auto-select the most reliable model
                  _selectedModel = _selectedImageBytes != null
                      ? 'gemini-1.0-pro-vision'
                      : 'gemini-1.0-pro';
                });
              },
              child: const Text('Use Reliable Model'),
            ),
          ],
        ),
      );
    } else {
      _showErrorSnackBar('$errorMessage: $error');
    }
  }

  void _sendInitialGreeting() {
    final greeting =
        'Hello! I\'m Devio your AI development assistant. I can help you with:\n\n'
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
      orElse: () =>
          throw Exception('User must be authenticated to send messages'),
    );

    // Send initial greeting with the authenticated user's ID
    context.read<ChatCubit>().sendMessage(
          senderId: userId, // Using authenticated user's ID
          content: greeting,
          isAI: true, // Mark as AI message
          senderName: _kAiUserName, // Still use AI name for display
        );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, String? currentChatId,
      bool isDark, BuildContext context) {
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
            : (isDark
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7)),
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
      onRename: (id, newTitle) =>
          context.read<ChatCubit>().renameChat(id, newTitle),
    );
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
        // Handle any other model names by formatting them nicely
        if (model.startsWith('gemini-')) {
          // Remove the 'gemini-' prefix and replace hyphens with spaces
          final formattedName = model.substring(7).replaceAll('-', ' ');
          // Capitalize each word
          final words = formattedName.split(' ');
          final capitalizedWords = words.map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '');
          return 'Gemini ${capitalizedWords.join(' ')}';
        }
        return model;
    }
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

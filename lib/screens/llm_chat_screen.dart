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
  final Uint8List? imageBytes;
  final String? documentPath;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.senderName,
    DateTime? timestamp,
    this.imageBytes,
    this.documentPath,
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
    // Set local as default provider
    context.read<LlmCubit>().setProvider(LlmProvider.local);
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
          _availableModels = models;

          // Filter models based on current context
          final filteredModels = _getFilteredModels();

          // Ensure we have at least one model available
          if (filteredModels.isEmpty) {
            _availableModels = ['local-model'];
          }

          // Always select a default model if none is selected
          if (_selectedModel == null) {
            _selectedModel = filteredModels.firstOrNull;
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
          _availableModels = ['local-model'];
          _selectedModel = 'local-model';
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
      final XFile? pickedFile = await _picker.pickMedia(
        imageQuality: null,
        requestFullMetadata: true,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final extension = path.extension(file.path).toLowerCase();

        if (extension != '.pdf') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a PDF file')),
            );
          }
          return;
        }

        setState(() {
          _selectedDocument = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: $e')),
        );
      }
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
    final llmCubit = context.read<LlmCubit>();

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
            authenticated: (uid, displayName, email) {
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
                                      size: 32,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Error loading chats',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please try again later',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.black.withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.center,
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
                                        textAlign: TextAlign.center,
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
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : theme.colorScheme.primary
                                                .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 36,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Welcome to DevIO Chat',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32),
                                      child: Text(
                                        'Start your first conversation with our AI assistant',
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.black.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: () {
                                        context
                                            .read<ChatCubit>()
                                            .startNewChat();
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 18),
                                      label: Text(
                                        'New Chat',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isDark
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                        foregroundColor: isDark
                                            ? Colors.black
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
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
                              authenticated: (_, displayName, photoUrl) {
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
                    // Show Ollama config button if using local provider
                    if (context.watch<LlmCubit>().currentProvider ==
                        LlmProvider.local)
                      Tooltip(
                        message: context.read<LlmCubit>().customOllamaIp !=
                                    null &&
                                context
                                    .read<LlmCubit>()
                                    .customOllamaIp!
                                    .isNotEmpty
                            ? 'Ollama IP: ${context.read<LlmCubit>().customOllamaIp}'
                            : 'Configure Ollama Connection',
                        child: IconButton(
                          icon: const Icon(Icons.settings_ethernet),
                          onPressed: _showOllamaConfigDialog,
                        ),
                      ),
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
                body: Stack(
                  children: [
                    Column(
                      children: [
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
                                            totalDuration:
                                                response.totalDuration,
                                            loadDuration: response.loadDuration,
                                            promptEvalCount:
                                                response.promptEvalCount,
                                            promptEvalDuration:
                                                response.promptEvalDuration,
                                            promptEvalRate:
                                                response.promptEvalRate,
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
                                                  text: chatState.error
                                                      .toString(),
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
                                          final message =
                                              chatState.messages[index];
                                          final messageId = message.id;

                                          // Check if this is a placeholder message
                                          if (messageId ==
                                              _placeholderMessageId) {
                                            return const TypingIndicator();
                                          }

                                          return ChatMessageWidget(
                                            message: message,
                                            showMetrics:
                                                _showPerformanceMetrics,
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
                    // Model selection UI as an overlay
                    if (_showModelSelection)
                      Positioned.fill(
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
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                setState(() {
                                  _showModelSelection = false;
                                });
                              });
                            });
                          },
                          selectedImageBytes: _selectedImageBytes,
                          onProviderChanged: _onProviderChanged,
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
    if (_messageController.text.trim().isEmpty &&
        _selectedImageBytes == null &&
        _selectedDocument == null) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    // Add message to chat history
    final authState = context.read<AuthCubit>().state;
    final userId = authState.maybeWhen(
      authenticated: (uid, _, __) => uid,
      orElse: () => 'anonymous',
    );

    context.read<ChatCubit>().sendMessage(
          senderId: userId,
          content: message,
          isAI: false,
        );

    setState(() {
      _selectedImageBytes = null;
      _selectedDocument = null;
      _isWaitingForAiResponse = true;
    });

    _scrollToBottom();

    // Generate response based on the message
    if (_selectedDocument != null) {
      // Document analysis is not supported without Gemini
      _showErrorSnackBar(
          'Document analysis is not supported with local models');
      setState(() {
        _isWaitingForAiResponse = false;
      });
    } else if (_selectedImageBytes != null) {
      // Image analysis is not supported without Gemini
      _showErrorSnackBar('Image analysis is not supported with local models');
      setState(() {
        _isWaitingForAiResponse = false;
      });
    } else {
      // Text-only message
      context.read<LlmCubit>().generateResponse(
            prompt: message,
            modelName: _selectedModel,
          );
    }
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

    // Show a simple error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'There was an error connecting to the local AI model.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Suggestions:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('• Make sure Ollama is running on your machine'),
            Text('• Check the Ollama IP configuration'),
            Text('• Verify that the selected model is installed'),
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
              _showOllamaConfigDialog();
            },
            child: const Text('Configure Ollama'),
          ),
        ],
      ),
    );
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
    // For local models, just return the model name
    return model;
  }

  List<String> _getFilteredModels() {
    // Return all available models
    return _availableModels;
  }

  void _onProviderChanged(LlmProvider provider) {
    setState(() {
      _selectedImageBytes = null;
      _selectedDocument = null;
      _selectedModel = null;
    });

    context.read<LlmCubit>().setProvider(provider);
    _loadAvailableModels();

    // If switching to local provider, prompt for Ollama IP configuration
    // Wait for the state to update before showing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForOllamaIpIfNeeded();
    });
  }

  void _promptForOllamaIpIfNeeded() {
    final llmCubit = context.read<LlmCubit>();
    final customIp = llmCubit.customOllamaIp;

    // If no custom IP is set, show the configuration dialog
    if (customIp == null || customIp.isEmpty) {
      _showOllamaConfigDialog();
    }
  }

  void _showOllamaConfigDialog() {
    final llmCubit = context.read<LlmCubit>();
    final theme = Theme.of(context);

    final ipController =
        TextEditingController(text: llmCubit.customOllamaIp ?? '');

    showDialog(
      context: context,
      barrierDismissible: false, // User must take action
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.laptop,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Ollama Connection Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: _buildOllamaConfigContent(theme, ipController),
        actions: [
          // Only show Cancel if there's already a custom IP set
          if (llmCubit.customOllamaIp != null &&
              llmCubit.customOllamaIp!.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: () => _saveOllamaConfig(ipController.text, context),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildOllamaConfigContent(
      ThemeData theme, TextEditingController ipController) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Ollama server IP address and port',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ipController,
          decoration: InputDecoration(
            hintText: 'e.g., localhost:11434 or 192.168.1.100:11434',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: const Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 16),
        _buildConnectionGuide(theme),
      ],
    );
  }

  Widget _buildConnectionGuide(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connection Guide:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGuideItem(
            theme,
            '• Same device: use localhost:11434',
            theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 4),
          _buildGuideItem(
            theme,
            '• Different device: use your actual IP (192.168.x.x:11434)',
            theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 4),
          _buildGuideItem(
            theme,
            '• Do NOT use 0.0.0.0 (binding address)',
            theme.colorScheme.error,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(ThemeData theme, String text, Color color,
      {bool isBold = false}) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: isBold ? FontWeight.bold : null,
      ),
    );
  }

  Future<void> _saveOllamaConfig(String ipText, BuildContext context) async {
    final ipAddress = ipText.trim().isEmpty ? null : ipText.trim();
    await context.read<LlmCubit>().setCustomOllamaIp(ipAddress);
    _loadAvailableModels(); // Refresh model list
    Navigator.of(context).pop();
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

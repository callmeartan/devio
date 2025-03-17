import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:google_fonts/google_fonts.dart';

import '../blocs/auth/auth_cubit.dart';
import '../constants/assets.dart';
import '../cubits/chat/chat_cubit.dart';
import '../cubits/chat/chat_state.dart';
import '../features/llm/cubit/llm_cubit.dart';
import '../features/llm/cubit/llm_state.dart';
import '../models/chat_message.dart';
import '../services/demo_response_service.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/compact_model_indicator.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/drawer_menu_item.dart';
import '../widgets/model_selection_ui.dart';
import '../widgets/setup_required_view.dart';
import '../widgets/simple_drawer_menu_item.dart' as simple;
import '../widgets/typing_indicator.dart';

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

  // Connection status variables
  bool _hasConnectionError = false;
  String? _connectionErrorMessage;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    // Set local as default provider
    context.read<LlmCubit>().setProvider(LlmProvider.local);
    _loadAvailableModels();
    _chatScrollController.addListener(_scrollListener);

    // Start a new chat immediately
    context.read<ChatCubit>().startNewChat();

    // Check connection status
    _checkConnectionStatus();

    // Send initial greeting since we know we're authenticated (router ensures this)
    _sendInitialGreeting();

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

      // First test connection
      final connectionTest = await context.read<LlmCubit>().testConnection();
      if (connectionTest['status'] != 'connected') {
        if (mounted) {
          setState(() {
            _isLoadingModels = false;
            _availableModels = [];
            _selectedModel = null;
          });

          // Don't automatically show the dialog
          // _showOllamaConfigDialog();
        }
        return;
      }

      final models = await context.read<LlmCubit>().getAvailableModels();
      developer.log('Models loaded: $models');

      if (mounted) {
        setState(() {
          _isLoadingModels = false;
          _availableModels = models;

          // Filter models based on current context
          final filteredModels = _getFilteredModels();

          // Only set a default model if we have models available
          if (filteredModels.isNotEmpty) {
            _selectedModel ??= filteredModels.first;
          } else {
            _selectedModel = null;
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
          _availableModels = [];
          _selectedModel = null;
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

    // Add logging for current auth state
    final currentAuthState = context.read<AuthCubit>().state;
    developer.log('Current auth state: $currentAuthState');

    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
        // Log chat state changes
        developer.log(
            'Chat state changed - messages: ${state.messages.length}, currentChatId: ${state.currentChatId}');

        // Auto-scroll to bottom when new messages arrive if we're already near the bottom
        if (_chatScrollController.hasClients &&
            _chatScrollController.position.pixels >
                _chatScrollController.position.maxScrollExtent - 300) {
          _scrollToBottom();
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // Log auth state in builder
          developer.log('Building screen for auth state: $authState');

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
                                      'Start your first conversation with our AI assistant',
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.black.withOpacity(0.7),
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
                                  ...unpinnedChats
                                      .map(
                                        (chat) => _buildChatItem(
                                            chat,
                                            state.currentChatId,
                                            isDark,
                                            context),
                                      )
                                      .toList(),
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
                        // Connection status banner
                        if (_hasConnectionError)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ConnectionStatusBanner(
                              status: ConnectionStatus.error,
                              message: _connectionErrorMessage,
                              onTap: _showOllamaConfigDialog,
                            ),
                          ),

                        // Demo mode banner
                        if (_isDemoMode && !_hasConnectionError)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DemoModeBanner(
                              onSetupTap: _showOllamaConfigDialog,
                            ),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

    // Send user's message
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
      // Add a placeholder message for the AI response
      final placeholderId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _placeholderMessageId = placeholderId;
      });

      // Add the placeholder message to show typing indicator
      context.read<ChatCubit>().addPlaceholderMessage(
            id: placeholderId,
            senderId: 'ai',
            isAI: true,
            senderName: _kAiUserName,
          );

      // Check if we're in demo mode
      if (_isDemoMode) {
        _handleDemoResponse(message);
      } else {
        // Text-only message with real LLM
        context.read<LlmCubit>().generateResponse(
              prompt: message,
              modelName: _selectedModel,
            );
      }
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

      // Set connection error state
      _hasConnectionError = true;
      _connectionErrorMessage =
          "Configure Ollama server connection to continue";
      _isDemoMode = true;
    });

    // Add a system message about the connection configuration
    final chatCubit = context.read<ChatCubit>();

    // Send the configuration message
    chatCubit.sendMessage(
      senderId: 'system',
      content:
          'Please configure your Ollama server connection to continue using local models.',
      isAI: false,
      senderName: 'System',
    );

    // Show the setup required view as a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SetupRequiredView.fromError(
          context,
          errorMessage: "Configure your Ollama server connection to continue",
          onSetupComplete: () {
            Navigator.pop(context);
            // Test connection again after setup
            _testAndUpdateConnectionStatus();
          },
          onDismiss: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Add a new method to test connection and update status
  Future<void> _testAndUpdateConnectionStatus() async {
    try {
      final llmCubit = context.read<LlmCubit>();
      final result = await llmCubit.testConnection();

      if (result['status'] == 'connected') {
        setState(() {
          _hasConnectionError = false;
          _connectionErrorMessage = null;
          _isDemoMode = false;
        });

        // Load models since we're connected
        _loadAvailableModels();
      } else {
        setState(() {
          _hasConnectionError = true;
          _connectionErrorMessage =
              "Configure Ollama server connection to continue";
          _isDemoMode = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasConnectionError = true;
        _connectionErrorMessage =
            "Configure Ollama server connection to continue";
        _isDemoMode = true;
      });
    }
  }

  void _sendInitialGreeting() {
    // Get the authenticated user's ID
    final authState = context.read<AuthCubit>().state;
    final userId = authState.maybeWhen(
      authenticated: (uid, _, __) => uid,
      orElse: () => 'anonymous',
    );

    if (_isDemoMode) {
      // Use demo greeting in demo mode
      final demoGreeting = DemoResponseService().getInitialGreeting();

      context
          .read<ChatCubit>()
          .sendMessage(
            senderId: userId,
            content: demoGreeting,
            isAI: true,
            senderName: _kAiUserName,
          )
          .then((_) {
        // Ensure we scroll to bottom after the message is sent
        _scrollToBottom();
      }).catchError((error) {
        developer.log('Error sending initial greeting: $error');
        // Handle error if needed
      });
      return;
    }

    // Standard greeting for normal mode
    final greeting =
        'Hello! I\'m DevIO, your mobile interface for Local LLMs. I can help you with:\n\n'
        '• Connecting to local LLM servers\n'
        '• Processing AI requests privately\n'
        '• Code analysis and generation\n'
        '• Text and image processing\n'
        '• Maintaining data privacy and security\n\n'
        'How can I assist you today?';

    // Send the greeting message directly without a placeholder
    context
        .read<ChatCubit>()
        .sendMessage(
          senderId: userId,
          content: greeting,
          isAI: true,
          senderName: _kAiUserName,
        )
        .then((_) {
      // Ensure we scroll to bottom after the message is sent
      _scrollToBottom();
    }).catchError((error) {
      developer.log('Error sending initial greeting: $error');
      // Handle error if needed
    });
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
      chatId: chatId,
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

    // Don't automatically show the configuration dialog
    // if (customIp == null || customIp.isEmpty) {
    //   _showOllamaConfigDialog();
    // }
  }

  void _showOllamaConfigDialog() {
    final llmCubit = context.read<LlmCubit>();
    final theme = Theme.of(context);
    final advancedSettings = llmCubit.advancedSettings;

    final ipController =
        TextEditingController(text: llmCubit.customOllamaIp ?? '');
    final timeoutController =
        TextEditingController(text: advancedSettings['timeout'].toString());
    final contextSizeController =
        TextEditingController(text: advancedSettings['contextSize'].toString());
    final threadsController =
        TextEditingController(text: advancedSettings['threads'].toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Settings Section
                _buildSectionHeader(theme, 'Connection Settings'),
                const SizedBox(height: 8),
                TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'Server Address',
                    hintText: 'e.g., localhost:11434',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),

                // Test Connection Button
                Center(
                  child: FilledButton.icon(
                    onPressed: () async {
                      // First save the IP to test
                      await llmCubit
                          .setCustomOllamaIp(ipController.text.trim());

                      final result = await llmCubit.testConnection();
                      if (!context.mounted) return;

                      if (result['status'] == 'connected') {
                        // Load models after successful connection
                        _loadAvailableModels();

                        // Update connection status
                        if (mounted) {
                          this.setState(() {
                            _hasConnectionError = false;
                            _connectionErrorMessage = null;
                            _isDemoMode = false;
                          });
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Connected to Ollama v${result['version']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connection needs configuration'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.network_check),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(height: 24),

                // Advanced Settings Section
                _buildSectionHeader(theme, 'Advanced Settings'),
                const SizedBox(height: 8),
                TextField(
                  controller: timeoutController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Request Timeout (seconds)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.timer),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contextSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Context Size (tokens)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.memory),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: threadsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CPU Threads',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.developer_board),
                  ),
                ),
                const SizedBox(height: 24),

                // Model Management Section
                _buildSectionHeader(theme, 'Model Management'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPullModelDialog(context),
                        icon: Icon(
                          Icons.cloud_download,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          'Pull Model',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteModelDialog(context),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'Delete Model',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.error.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Server Status Section
                _buildSectionHeader(theme, 'Server Status'),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, dynamic>>(
                  future: llmCubit.getServerStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data?['status'] == 'error') {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Configure your Ollama server connection to continue",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showOllamaGuideDialog(context),
                            icon: Icon(
                              Icons.computer_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'How to Run Ollama?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final status = snapshot.data!;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusItem(
                              theme,
                              'Status',
                              status['status'] == 'ok'
                                  ? 'Connected'
                                  : 'Unknown'),
                          if (status['data'] != null) ...[
                            _buildStatusItem(theme, 'Memory Usage',
                                '${(status['data']['memory_usage'] ?? 0).toStringAsFixed(1)}%'),
                            _buildStatusItem(theme, 'CPU Usage',
                                '${(status['data']['cpu_usage'] ?? 0).toStringAsFixed(1)}%'),
                            if (status['data']['gpu_usage'] != null)
                              _buildStatusItem(theme, 'GPU Usage',
                                  '${(status['data']['gpu_usage'] ?? 0).toStringAsFixed(1)}%'),
                            _buildStatusItem(theme, 'Version',
                                status['data']['version'] ?? 'Unknown'),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
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
              onPressed: () async {
                // Save connection settings
                await llmCubit.setCustomOllamaIp(ipController.text.trim());

                // Save advanced settings
                await llmCubit.updateAdvancedSettings(
                  timeout: int.tryParse(timeoutController.text) ?? 120,
                  contextSize: int.tryParse(contextSizeController.text) ?? 4096,
                  threads: int.tryParse(threadsController.text) ?? 4,
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();

                // Test connection after saving settings
                _testAndUpdateConnectionStatus();
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPullModelDialog(BuildContext context) {
    final modelController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pull New Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: modelController,
              decoration: InputDecoration(
                labelText: 'Model Name',
                hintText: 'e.g., llama2:13b',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will download the model from Ollama. The process may take several minutes depending on the model size.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final modelName = modelController.text.trim();
              if (modelName.isEmpty) return;

              Navigator.of(context).pop();
              final result =
                  await context.read<LlmCubit>().pullModel(modelName);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      result['message'] ?? result['error'] ?? 'Unknown error'),
                  backgroundColor:
                      result['status'] == 'success' ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Pull Model'),
          ),
        ],
      ),
    );
  }

  void _showDeleteModelDialog(BuildContext context) {
    final modelController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: modelController,
              decoration: InputDecoration(
                labelText: 'Model Name',
                hintText: 'e.g., llama2:13b',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.errorContainer),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The model will need to be downloaded again if needed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final modelName = modelController.text.trim();
              if (modelName.isEmpty) return;

              Navigator.of(context).pop();
              final result =
                  await context.read<LlmCubit>().deleteModel(modelName);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      result['message'] ?? result['error'] ?? 'Unknown error'),
                  backgroundColor:
                      result['status'] == 'success' ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Delete Model'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final llmCubit = context.read<LlmCubit>();
      final result = await llmCubit.testConnection();

      setState(() {
        if (result['status'] == 'connected') {
          // Connection successful, ensure we're not in demo mode
          _hasConnectionError = false;
          _connectionErrorMessage = null;
          _isDemoMode = false;
        } else {
          _hasConnectionError = true;
          _connectionErrorMessage =
              "Configure Ollama server connection to continue";
          _isDemoMode = true;
        }
      });
    } catch (e) {
      setState(() {
        _hasConnectionError = true;
        _connectionErrorMessage =
            "Configure Ollama server connection to continue";
        _isDemoMode = true;
      });
    }
  }

  Future<void> _handleDemoResponse(String prompt) async {
    try {
      final demoService = DemoResponseService();
      final response = await demoService.getDemoResponse(prompt);

      // Remove placeholder message
      if (_placeholderMessageId != null) {
        context
            .read<ChatCubit>()
            .removePlaceholderMessage(_placeholderMessageId!);
        _placeholderMessageId = null;
      }

      // Add AI response
      final authState = context.read<AuthCubit>().state;
      final userId = authState.maybeWhen(
        authenticated: (uid, _, __) => uid,
        orElse: () => 'anonymous',
      );

      context.read<ChatCubit>().sendMessage(
            senderId: 'ai',
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
          );

      setState(() {
        _isWaitingForAiResponse = false;
      });
    } catch (e) {
      _handleApiError(e);
    }
  }

  void _showOllamaGuideDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF202123) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              Icons.computer_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'How to Run Ollama',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Install Ollama
              _buildOllamaStep(
                context,
                stepNumber: '1',
                title: 'Install Ollama',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit ollama.ai and download the installer for your operating system.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Step 2: Run Ollama Server
              _buildOllamaStep(
                context,
                stepNumber: '2',
                title: 'Run Ollama Server',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open terminal and run:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        'OLLAMA_HOST=0.0.0.0:11434 ollama serve',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Step 3: Find IP Address
              _buildOllamaStep(
                context,
                stepNumber: '3',
                title: 'Find Your IP Address',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run the appropriate command for your OS:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '# macOS/Linux:\n',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? Colors.grey : Colors.grey.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text:
                                  'ifconfig | grep "inet " | grep -v 127.0.0.1\n\n',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: '# Windows:\n',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? Colors.grey : Colors.grey.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: 'ipconfig',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Step 4: Connect in App
              _buildOllamaStep(
                context,
                stepNumber: '4',
                title: 'Connect in App',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your IP address with port in the app:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        '192.168.1.x:11434',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Replace 192.168.1.x with your actual IP address',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Important Notes
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Do NOT use 0.0.0.0 as the connection address\n'
                      '• Ensure port 11434 is allowed in your firewall\n'
                      '• Both devices must be on the same network\n'
                      '• Pull a model first using: ollama pull mistral',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOllamaStep(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                content,
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

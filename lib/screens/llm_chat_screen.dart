import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../blocs/auth/auth_cubit.dart';
import '../constants/assets.dart';
import '../cubits/chat/chat_cubit.dart';
import '../cubits/chat/chat_state.dart';
import '../features/llm/cubit/llm_cubit.dart';
import '../features/llm/cubit/llm_state.dart';
import '../features/llm/models/model_capabilities.dart';
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
import 'package:devio/utils/state_extension_helpers.dart';

const String _kAiUserName = 'AI Assistant';

class _IntroCopy {
  final String title;
  final String subtitle;

  const _IntroCopy({
    required this.title,
    required this.subtitle,
  });
}

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
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showPerformanceMetrics = false;
  bool _isWaitingForAiResponse = false;
  String? _placeholderMessageId;
  final ImagePicker _picker = ImagePicker();
  String? _selectedModel;
  List<String> _availableModels = [];
  Map<String, LlmModelInfo> _availableModelInfoById = {};
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
    _chatScrollController.addListener(_scrollListener);

    // Start a new chat immediately
    context.read<ChatCubit>().startNewChat();

    _initializeLlmSession();

    // Schedule scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Don't show model selection initially
    _showModelSelection = false;
  }

  Future<void> _initializeLlmSession() async {
    final llmCubit = context.read<LlmCubit>();
    await llmCubit.ready;
    if (!mounted) return;

    setState(() {
      _selectedModel = llmCubit.selectedModel;
    });

    await _loadAvailableModels();
    await _checkConnectionStatus();
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _historyScrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _messageFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_chatScrollController.positions.length != 1) return;
    final position = _chatScrollController.position;

    final showButton = position.pixels < position.maxScrollExtent - 300;

    if (_showScrollToBottom != showButton) {
      setState(() {
        _showScrollToBottom = showButton;
      });
    }
  }

  Future<void> _loadAvailableModels() async {
    try {
      final llmCubit = context.read<LlmCubit>();
      setState(() {
        _isLoadingModels = true;
      });

      developer.log('Loading available models...');

      // First test connection
      final connectionTest = await llmCubit.testConnection();
      if (connectionTest['status'] != 'connected') {
        if (mounted) {
          setState(() {
            _isLoadingModels = false;
            _availableModels = [];
            _availableModelInfoById = {};
            _selectedModel = null;
          });

          // Don't automatically show the dialog
          // _showOllamaConfigDialog();
        }
        return;
      }

      if (!mounted) return;
      final modelInfos = await llmCubit.getAvailableModelInfos();
      final models = modelInfos.map((model) => model.id).toList();
      developer.log('Models loaded: $models');

      if (mounted) {
        setState(() {
          _isLoadingModels = false;
          _availableModels = models;
          _availableModelInfoById = {
            for (final modelInfo in modelInfos) modelInfo.id: modelInfo,
          };

          // Filter models based on current context
          final filteredModels = _getFilteredModels();

          final savedModel = llmCubit.selectedModel;
          if (filteredModels.isNotEmpty) {
            if (savedModel != null && filteredModels.contains(savedModel)) {
              _selectedModel = savedModel;
            } else if (_selectedModel != null &&
                filteredModels.contains(_selectedModel)) {
              _selectedModel = _selectedModel;
            } else {
              _selectedModel = filteredModels.first;
              llmCubit.selectModel(_selectedModel);
            }
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
          _availableModelInfoById = {};
          _selectedModel = null;
        });
        _showErrorSnackBar('Failed to load models: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_chatScrollController.positions.length == 1) {
      final position = _chatScrollController.position;
      _chatScrollController.jumpTo(position.maxScrollExtent);
    }
  }

  Future<void> _pickImage() async {
    await _pickImageFromSource(ImageSource.gallery);
  }

  Future<void> _takePhoto() async {
    await _pickImageFromSource(ImageSource.camera);
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImageBytes = bytes;
          if (_selectedModelInfo?.capabilities.supportsVision != true) {
            _showModelSelection = true;
          }
        });
        if (_selectedModelInfo?.capabilitiesKnown == true &&
            _selectedModelInfo?.capabilities.supportsVision != true) {
          _showErrorSnackBar(
            'Selected LM Studio model does not report vision support',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error attaching image: $e')),
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

    // Add logging for current auth state
    final currentAuthState = context.read<AuthCubit>().state;
    developer.log('Current auth state: $currentAuthState');

    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
        // Log chat state changes
        developer.log(
            'Chat state changed - messages: ${state.messages.length}, currentChatId: ${state.currentChatId}');

        // Auto-scroll to bottom when new messages arrive if we're already near the bottom
        if (_chatScrollController.positions.length == 1) {
          final position = _chatScrollController.position;
          final extent = position.maxScrollExtent;
          if (extent > 0 && position.pixels > extent - 300) {
            _scrollToBottom();
          }
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
                backgroundColor: theme.scaffoldBackgroundColor,
                drawer: Drawer(
                  backgroundColor: isDark
                      ? theme.colorScheme.surface
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
                      BlocBuilder<ChatCubit, ChatState>(
                        builder: (context, state) {
                          final chatCubit = context.read<ChatCubit>();
                          final filteredChats =
                              chatCubit.getFilteredChatHistories();

                          if (filteredChats.isEmpty &&
                              state.searchQuery.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
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
                          );
                        },
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

                              return Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      'No chats yet',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.black.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32),
                                      child: Text(
                                        'Create a thread when you need one.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.black.withOpacity(0.7),
                                        ),
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
                              controller: _historyScrollController,
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
                  backgroundColor: theme.scaffoldBackgroundColor,
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
                    _buildProviderPill(theme),
                    const SizedBox(width: 8),
                    CompactModelIndicator(
                      selectedModel: _selectedModel,
                      capabilities: _selectedModelCapabilities,
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
                      color: theme.colorScheme.outlineVariant,
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
                              onTap: _showProviderConfigDialog,
                            ),
                          ),

                        // Demo mode banner
                        if (_isDemoMode && !_hasConnectionError)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DemoModeBanner(
                              onSetupTap: _showProviderConfigDialog,
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
                                        orElse: () => AuthCubit.localUserId,
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

                                      if (chatState.messages.isEmpty) {
                                        return _buildEmptyChatState(theme);
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
                          color: theme.colorScheme.outlineVariant,
                        ),
                        // Bottom input field
                        ChatInputField(
                          messageController: _messageController,
                          selectedImageBytes: _selectedImageBytes,
                          selectedDocument: _selectedDocument,
                          isWaitingForAiResponse: _isWaitingForAiResponse,
                          onSendMessage: _sendMessage,
                          onPickImage: _pickImage,
                          onTakePhoto: _takePhoto,
                          onPickDocument: _pickDocument,
                          onClearSelectedImage: _clearSelectedImage,
                          onClearSelectedDocument: _clearSelectedDocument,
                          focusNode: _messageFocusNode,
                        ),
                      ],
                    ),
                    // Model selection UI as an overlay
                    if (_showModelSelection)
                      Positioned.fill(
                        child: ModelSelectionUI(
                          availableModels: _availableModels,
                          modelInfoById: _availableModelInfoById,
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
                              context.read<LlmCubit>().selectModel(model);
                              // Auto-hide the model selection UI after selecting a model
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                if (!mounted) return;
                                setState(() {
                                  _showModelSelection = false;
                                });
                              });
                            });
                          },
                          selectedImageBytes: _selectedImageBytes,
                          onProviderChanged: _onProviderChanged,
                          onProviderConnectionRequested: _connectProvider,
                        ),
                      ),
                  ],
                ),
              );
            },
            unauthenticated: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AuthCubit>().signInAnonymously();
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
                    'Local Session Error',
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
                    onPressed: () {
                      context.read<AuthCubit>().signInAnonymously();
                      context.go('/llm');
                    },
                    child: const Text('Return to Chat'),
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

  Widget _buildEmptyChatState(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  (constraints.maxHeight - 38).clamp(0.0, 900.0).toDouble(),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCommandDashboardHeader(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandDashboardHeader(ThemeData theme) {
    final intro = _timeAwareIntro(DateTime.now());

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        Text(
          intro.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          intro.subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_hasConnectionError) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              'Connection needs setup',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  _IntroCopy _timeAwareIntro(DateTime now) {
    final hour = now.hour;
    final seed = now.year + now.month + now.day + now.hour;

    if (hour < 5) {
      return _pickIntro(seed, const [
        _IntroCopy(
          title: 'Hello, night owl.',
          subtitle: 'What can I help you work through tonight?',
        ),
        _IntroCopy(
          title: 'Still up?',
          subtitle: 'Tell me what you want to untangle.',
        ),
        _IntroCopy(
          title: 'Late night focus.',
          subtitle: 'What should we take care of before morning?',
        ),
        _IntroCopy(
          title: 'Quiet hours.',
          subtitle: 'What would you like help thinking through?',
        ),
      ]);
    }
    if (hour < 12) {
      return _pickIntro(seed, const [
        _IntroCopy(
          title: 'Good morning.',
          subtitle: 'How can I help you this morning?',
        ),
        _IntroCopy(
          title: 'Morning.',
          subtitle: 'What would you like to start with?',
        ),
        _IntroCopy(
          title: 'Ready when you are.',
          subtitle: 'What should we make progress on first?',
        ),
        _IntroCopy(
          title: 'A fresh start.',
          subtitle: 'What can I help you move forward today?',
        ),
      ]);
    }
    if (hour < 17) {
      return _pickIntro(seed, const [
        _IntroCopy(
          title: 'Good afternoon.',
          subtitle: 'What would you like to make progress on?',
        ),
        _IntroCopy(
          title: 'Back to it.',
          subtitle: 'What can I help you sort out?',
        ),
        _IntroCopy(
          title: 'Let\'s continue.',
          subtitle: 'What needs attention next?',
        ),
        _IntroCopy(
          title: 'What are we working on?',
          subtitle: 'Share the task and I\'ll help from there.',
        ),
      ]);
    }
    if (hour < 21) {
      return _pickIntro(seed, const [
        _IntroCopy(
          title: 'Good evening.',
          subtitle: 'What can I help you with this evening?',
        ),
        _IntroCopy(
          title: 'Evening.',
          subtitle: 'What would you like to wrap up?',
        ),
        _IntroCopy(
          title: 'Let\'s finish well.',
          subtitle: 'What should we focus on now?',
        ),
        _IntroCopy(
          title: 'Settling in?',
          subtitle: 'Tell me what you want to work through.',
        ),
      ]);
    }

    return _pickIntro(seed, const [
      _IntroCopy(
        title: 'Hello, night owl.',
        subtitle: 'What can I help you work through tonight?',
      ),
      _IntroCopy(
        title: 'Night mode.',
        subtitle: 'What should we make clearer before you call it?',
      ),
      _IntroCopy(
        title: 'Late evening.',
        subtitle: 'What can I help you finish?',
      ),
      _IntroCopy(
        title: 'One more thing?',
        subtitle: 'Tell me what needs attention.',
      ),
    ]);
  }

  _IntroCopy _pickIntro(int seed, List<_IntroCopy> intros) {
    return intros[seed % intros.length];
  }

  Widget _buildProviderPill(ThemeData theme) {
    return BlocBuilder<LlmCubit, LlmState>(
      builder: (context, _) {
        final provider = context.read<LlmCubit>().currentProvider;
        final accent = _providerAccent(provider, theme);

        return Tooltip(
          message: 'Configure ${_providerDisplayName(provider)}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showProviderConfigDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 128),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _providerIcon(provider),
                      color: accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _providerDisplayName(provider),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.tune_rounded,
                      color: accent,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _connectProvider(LlmProvider provider) {
    if (context.read<LlmCubit>().currentProvider != provider) {
      _onProviderChanged(provider);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showProviderConfigDialog();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty &&
        _selectedImageBytes == null &&
        _selectedDocument == null) {
      return;
    }

    final message = _messageController.text.trim();
    final prompt = message.isEmpty ? 'Describe this image.' : message;
    final selectedImageBytes = _selectedImageBytes;
    final selectedDocument = _selectedDocument;
    if (selectedImageBytes != null &&
        _selectedModelInfo?.capabilitiesKnown == true &&
        _selectedModelInfo?.capabilities.supportsVision != true) {
      setState(() {
        _showModelSelection = true;
      });
      _showErrorSnackBar(
        'Select a vision-capable LM Studio model before sending an image',
      );
      return;
    }
    _messageController.clear();

    // Add message to chat history
    final authState = context.read<AuthCubit>().state;
    final userId = authState.maybeWhen(
      authenticated: (uid, _, __) => uid,
      orElse: () => AuthCubit.localUserId,
    );

    // Send user's message
    context
        .read<ChatCubit>()
        .sendMessage(
          senderId: userId,
          content: prompt,
          isAI: false,
        )
        .catchError((error) {
      String errorMessage = error.toString();

      // Handle specific error cases
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied: Please try refreshing the page';
      } else if (errorMessage.contains('user-not-authenticated')) {
        errorMessage = 'Local session error: Please try again';
      }

      _showErrorSnackBar(errorMessage);
      setState(() {
        _isWaitingForAiResponse = false;
        // Remove placeholder if it exists
        if (_placeholderMessageId != null) {
          context
              .read<ChatCubit>()
              .removePlaceholderMessage(_placeholderMessageId!);
          _placeholderMessageId = null;
        }
      });
    });

    setState(() {
      _selectedImageBytes = null;
      _selectedDocument = null;
      _isWaitingForAiResponse = true;
    });

    _scrollToBottom();

    // Generate response based on the message
    if (selectedDocument != null) {
      _showErrorSnackBar(
          'Document analysis is not available for the selected provider yet');
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
        _handleDemoResponse(prompt);
      } else {
        // Use the streaming API for real-time responses
        final llmCubit = context.read<LlmCubit>();

        // Create a stream subscription for managing the response stream
        StreamSubscription<LlmState>? subscription;
        String accumulatedText = '';
        final messageId = DateTime.now().millisecondsSinceEpoch.toString();

        try {
          final responseStream = llmCubit.streamResponse(
            prompt: prompt,
            imageBytes: selectedImageBytes,
            modelName: _selectedModel,
          );

          // Remove the placeholder message
          if (_placeholderMessageId != null) {
            context
                .read<ChatCubit>()
                .removePlaceholderMessage(_placeholderMessageId!);
            _placeholderMessageId = null;
          }

          // Add AI message with empty content that will be updated
          context.read<ChatCubit>().sendMessage(
                senderId: 'ai',
                content: '', // Start with empty content
                isAI: true,
                id: messageId,
                senderName: _kAiUserName,
              );

          // Subscribe to the stream to update the message content in real-time
          subscription = responseStream.listen(
            (state) {
              state.maybeWhen(
                success: (response) {
                  // Update the message with the new content
                  if (response.text.isNotEmpty) {
                    accumulatedText += response.text;
                    context.read<ChatCubit>().updateMessageContent(
                          messageId: messageId,
                          newContent: accumulatedText,
                        );

                    // Keep the scroll at the bottom
                    _scrollToBottom();
                  }

                  // Since we can't access the isFinal field directly yet,
                  // Check if response has metrics which indicates it's final
                  final bool isFinalResponse = response.totalDuration != null ||
                      response.evalCount != null;

                  // Check if this is the final response with metrics
                  if (isFinalResponse) {
                    // Update metrics - do this silently without showing errors
                    try {
                      context.read<ChatCubit>().updateMessageMetrics(
                            messageId: messageId,
                            totalDuration: response.totalDuration,
                            loadDuration: response.loadDuration,
                            promptEvalCount: response.promptEvalCount,
                            promptEvalDuration: response.promptEvalDuration,
                            promptEvalRate: response.promptEvalRate,
                            evalCount: response.evalCount,
                            evalDuration: response.evalDuration,
                            evalRate: response.evalRate,
                          );
                    } catch (e) {
                      // Log but don't show error to user
                      developer
                          .log('Error updating metrics (non-critical): $e');
                    }

                    // Reset waiting state
                    setState(() {
                      _isWaitingForAiResponse = false;
                    });

                    // Cancel the subscription
                    subscription?.cancel();
                  }
                },
                error: (message) {
                  // Handle error
                  context.read<ChatCubit>().updateMessageContent(
                        messageId: messageId,
                        newContent: 'Error: $message',
                      );

                  setState(() {
                    _isWaitingForAiResponse = false;
                  });

                  _handleApiError(message);
                  subscription?.cancel();
                },
                orElse: () {
                  // Skip other states
                },
              );
            },
            onError: (error) {
              if (!mounted) {
                subscription?.cancel();
                return;
              }
              // Handle stream error
              context.read<ChatCubit>().updateMessageContent(
                    messageId: messageId,
                    newContent: 'Error: $error',
                  );

              setState(() {
                _isWaitingForAiResponse = false;
              });

              _handleApiError(error);
              subscription?.cancel();
            },
            onDone: () {
              if (mounted) {
                setState(() {
                  _isWaitingForAiResponse = false;
                });
                _messageFocusNode.requestFocus();
              }
              subscription?.cancel();
            },
          );
        } catch (e) {
          // Handle immediate errors
          developer.log('Error starting stream: $e');

          // Remove placeholder if it exists
          if (_placeholderMessageId != null) {
            context
                .read<ChatCubit>()
                .removePlaceholderMessage(_placeholderMessageId!);
            _placeholderMessageId = null;
          }

          // Send error message
          context.read<ChatCubit>().sendMessage(
                senderId: 'ai',
                content: 'Error: $e',
                isAI: true,
                senderName: _kAiUserName,
              );

          setState(() {
            _isWaitingForAiResponse = false;
          });

          _handleApiError(e);
        }
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
          "Configure ${_activeProviderDisplayName()} connection to continue";
      _isDemoMode = true;
    });

    // Add a system message about the connection configuration
    final chatCubit = context.read<ChatCubit>();

    // Send the configuration message
    chatCubit.sendMessage(
      senderId: 'system',
      content:
          'Please configure ${_activeProviderDisplayName()} to continue using real AI responses.',
      isAI: false,
      senderName: 'System',
    );

    if (context.read<LlmCubit>().currentProviderId != 'ollama') {
      _showProviderSetupSheet();
      return;
    }

    // Show the Ollama setup guide as a bottom sheet
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
          errorMessage:
              "Configure ${_activeProviderDisplayName()} connection to continue",
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

  void _showProviderSetupSheet() {
    final theme = Theme.of(context);
    final providerName = _activeProviderDisplayName();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _activeProviderIcon(),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$providerName Setup',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Configure the base URL${providerName == 'OpenAI-compatible' ? ' and API key' : ''}, then refresh models to continue.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showProviderConfigDialog();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure'),
                  ),
                ),
              ],
            ),
          ),
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
              "Configure ${_activeProviderDisplayName()} connection to continue";
          _isDemoMode = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasConnectionError = true;
        _connectionErrorMessage =
            "Configure ${_activeProviderDisplayName()} connection to continue";
        _isDemoMode = true;
      });
    }
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

  LlmModelInfo? get _selectedModelInfo =>
      _selectedModel == null ? null : _availableModelInfoById[_selectedModel!];

  ModelCapabilities get _selectedModelCapabilities =>
      _selectedModelInfo?.capabilities ??
      inferModelCapabilities(_selectedModel);

  void _onProviderChanged(LlmProvider provider) {
    setState(() {
      _selectedImageBytes = null;
      _selectedDocument = null;
      _selectedModel = null;
      _availableModelInfoById = {};
      _hasConnectionError = false;
      _connectionErrorMessage = null;
      _isDemoMode = false;
    });

    context.read<LlmCubit>().setProvider(provider);
    _loadAvailableModels();
  }

  void _showProviderConfigDialog() {
    final llmCubit = context.read<LlmCubit>();
    final theme = Theme.of(context);
    final advancedSettings = llmCubit.advancedSettings;
    final providerId = llmCubit.currentProviderId;
    final isOllama = providerId == 'ollama';
    final isOpenAiCompatible = providerId == 'openai';
    final providerName = _activeProviderDisplayName();

    final connectionController = TextEditingController(
      text: isOllama
          ? (llmCubit.customOllamaIp ?? '')
          : (llmCubit.baseUrl ?? _activeProviderDefaultEndpoint()),
    );
    final apiKeyController = TextEditingController(text: llmCubit.apiKey ?? '');
    final timeoutController =
        TextEditingController(text: advancedSettings['timeout'].toString());
    final contextSizeController =
        TextEditingController(text: advancedSettings['contextSize'].toString());
    final threadsController =
        TextEditingController(text: advancedSettings['threads'].toString());
    final maxTokensController =
        TextEditingController(text: (llmCubit.maxTokens ?? 1000).toString());
    final temperatureController =
        TextEditingController(text: llmCubit.temperature.toString());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                _activeProviderIcon(),
                size: 20,
                color: _providerAccent(llmCubit.currentProvider, theme),
              ),
              const SizedBox(width: 8),
              Text(
                'Connection',
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
                _buildProviderSettingsHero(
                  theme: theme,
                  providerName: providerName,
                  provider: llmCubit.currentProvider,
                ),
                const SizedBox(height: 20),
                // Connection Settings Section
                _buildSectionHeader(theme, 'Connection Settings'),
                const SizedBox(height: 8),
                TextField(
                  controller: connectionController,
                  decoration: InputDecoration(
                    labelText: isOllama ? 'Server Address' : 'Base URL',
                    hintText: isOllama
                        ? 'e.g., localhost:11434'
                        : _activeProviderDefaultEndpoint(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                if (isOpenAiCompatible) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Optional bearer token',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                Center(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await llmCubit.updateProviderConnection(
                        baseUrl: connectionController.text.trim(),
                        apiKey: apiKeyController.text.trim(),
                        maxTokens: int.tryParse(maxTokensController.text),
                        temperature:
                            double.tryParse(temperatureController.text),
                      );

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
                            content: Text(_connectionSuccessMessage(result)),
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

                _buildSectionHeader(theme, 'Advanced Settings'),
                const SizedBox(height: 8),
                if (isOllama) ...[
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
                ] else ...[
                  TextField(
                    controller: maxTokensController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Output Tokens',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.format_list_numbered),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: temperatureController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Temperature',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.tune),
                    ),
                  ),
                ],
                if (isOllama) ...[
                  const SizedBox(height: 24),
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
                ],
                if (isOllama) ...[
                  const SizedBox(height: 24),
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
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.3),
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
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.5),
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
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Model management is handled in $providerName. Use Refresh Models after changing the running model server.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
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
                await llmCubit.updateProviderConnection(
                  baseUrl: connectionController.text.trim(),
                  apiKey: apiKeyController.text.trim(),
                  maxTokens: int.tryParse(maxTokensController.text),
                  temperature: double.tryParse(temperatureController.text),
                );

                if (isOllama) {
                  await llmCubit.updateAdvancedSettings(
                    timeout: int.tryParse(timeoutController.text) ?? 120,
                    contextSize:
                        int.tryParse(contextSizeController.text) ?? 4096,
                    threads: int.tryParse(threadsController.text) ?? 4,
                  );
                }

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

  Widget _buildProviderSettingsHero({
    required ThemeData theme,
    required String providerName,
    required LlmProvider provider,
  }) {
    final accent = _providerAccent(provider, theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _providerIcon(provider),
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  providerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _providerEndpoint(provider),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle_rounded,
            color: accent,
            size: 18,
          ),
        ],
      ),
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

  String _providerDisplayName(LlmProvider provider) {
    return switch (provider) {
      LlmProvider.local || LlmProvider.ollama => 'Ollama',
      LlmProvider.lmstudio => 'LM Studio',
      LlmProvider.openai => 'OpenAI-compatible',
    };
  }

  IconData _providerIcon(LlmProvider provider) {
    return switch (provider) {
      LlmProvider.local || LlmProvider.ollama => Icons.computer_rounded,
      LlmProvider.lmstudio => Icons.dns_rounded,
      LlmProvider.openai => Icons.hub_rounded,
    };
  }

  Color _providerAccent(LlmProvider provider, ThemeData theme) {
    return switch (provider) {
      LlmProvider.local || LlmProvider.ollama => theme.colorScheme.tertiary,
      LlmProvider.lmstudio => theme.brightness == Brightness.dark
          ? const Color(0xFF8AB4CF)
          : const Color(0xFF3B6F8F),
      LlmProvider.openai => theme.colorScheme.secondary,
    };
  }

  String _providerEndpoint(LlmProvider provider) {
    final llmCubit = context.read<LlmCubit>();
    final isCurrent = llmCubit.currentProvider == provider ||
        (provider == LlmProvider.ollama &&
            llmCubit.currentProvider == LlmProvider.local);

    return switch (provider) {
      LlmProvider.local || LlmProvider.ollama => isCurrent
          ? (llmCubit.customOllamaIp ?? 'localhost:11434')
          : 'localhost:11434',
      LlmProvider.lmstudio => isCurrent
          ? (llmCubit.baseUrl ?? 'http://localhost:1234')
          : 'http://localhost:1234',
      LlmProvider.openai => isCurrent
          ? (llmCubit.baseUrl ?? 'https://api.openai.com')
          : 'https://api.openai.com',
    };
  }

  String _activeProviderDisplayName() {
    return _providerDisplayName(context.read<LlmCubit>().currentProvider);
  }

  IconData _activeProviderIcon() {
    return _providerIcon(context.read<LlmCubit>().currentProvider);
  }

  String _activeProviderDefaultEndpoint() {
    final providerId = context.read<LlmCubit>().currentProviderId;
    return switch (providerId) {
      'lmstudio' => 'http://localhost:1234',
      'openai' => 'https://api.openai.com',
      _ => 'localhost:11434',
    };
  }

  String _connectionSuccessMessage(Map<String, dynamic> result) {
    final providerName = _activeProviderDisplayName();
    if (context.read<LlmCubit>().currentProviderId == 'ollama') {
      return 'Connected to Ollama v${result['version'] ?? 'unknown'}';
    }
    final modelCount = result['models'];
    return modelCount is int
        ? 'Connected to $providerName ($modelCount models)'
        : 'Connected to $providerName';
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
              "Configure ${_activeProviderDisplayName()} connection to continue";
          _isDemoMode = true;
        }
      });
    } catch (e) {
      setState(() {
        _hasConnectionError = true;
        _connectionErrorMessage =
            "Configure ${_activeProviderDisplayName()} connection to continue";
        _isDemoMode = true;
      });
    }
  }

  void _handleDemoResponse(String message) {
    // Simulate AI response for demo mode
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      try {
        // Generate a simple demo response
        final demoResponse =
            "This is a demo response. To use real AI features, configure ${_activeProviderDisplayName()} using the connection button in the top-right corner.";

        // Remove placeholder message
        if (_placeholderMessageId != null) {
          context
              .read<ChatCubit>()
              .removePlaceholderMessage(_placeholderMessageId!);
          _placeholderMessageId = null;
        }

        // Send the AI message
        context
            .read<ChatCubit>()
            .sendMessage(
              senderId: 'ai',
              content: demoResponse,
              isAI: true,
              senderName: _kAiUserName,
            )
            .then((_) {
          setState(() {
            _isWaitingForAiResponse = false;
          });
          _scrollToBottom();
        }).catchError((error) {
          setState(() {
            _isWaitingForAiResponse = false;
          });
          // Only show error message if not a permission issue
          if (!error.toString().contains('permission-denied')) {
            _showErrorSnackBar(
                'Error sending demo response: ${error.toString()}');
          } else {
            developer.log(
                'Permission denied error in demo mode (suppressed): $error');
          }
        });
      } catch (e) {
        setState(() {
          _isWaitingForAiResponse = false;
        });
        _showErrorSnackBar('Error generating demo response: $e');
      }
    });
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

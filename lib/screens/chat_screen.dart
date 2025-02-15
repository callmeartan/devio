import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/message.dart';
import '../services/ai_service.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <Message>[];
  final _scrollController = ScrollController();
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addAIMessage(AIService().getInitialGreeting());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addAIMessage(String content) {
    setState(() {
      _messages.add(Message.ai(content));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    setState(() {
      _messages.add(Message.user(text));
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await AIService().getAIResponse(text);
    _addAIMessage(response);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.smart_toy,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'AI Development Guide',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatMessage(
                  message: message.content,
                  role: message.isUserMessage 
                      ? MessageRole.user 
                      : MessageRole.assistant,
                  timestamp: message.timestamp,
                );
              },
            ),
          ),
          Divider(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 768),
                child: ChatInput(
                  onSubmit: _handleSubmitted,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
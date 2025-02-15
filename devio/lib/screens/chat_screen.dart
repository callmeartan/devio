import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/message.dart';
import '../services/ai_service.dart';
import '../widgets/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <Message>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addAIMessage(AIService().getInitialGreeting());
  }

  @override
  void dispose() {
    _textController.dispose();
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
    if (text.trim().isEmpty) return;

    _textController.clear();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devio Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatMessage(message: _messages[index]);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: _isLoading ? null : _handleSubmitted,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading
                          ? null
                          : () => _handleSubmitted(_textController.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
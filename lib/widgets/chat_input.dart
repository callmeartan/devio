import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  var _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {
      _isComposing = _textController.text.isNotEmpty;
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || widget.isLoading) return;
    widget.onSubmit(text.trim());
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 6,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onSubmitted: (text) {
                if (_isComposing) {
                  _handleSubmitted(text);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
            child: IconButton(
              onPressed: _isComposing && !widget.isLoading
                  ? () => _handleSubmitted(_textController.text)
                  : null,
              icon: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _isComposing
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

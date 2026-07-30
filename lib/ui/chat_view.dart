import 'package:flutter/material.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.content, this.isUser = true}) : timestamp = DateTime.now();
}

class ChatView extends StatefulWidget {
  final Future<String> Function(String message)? onSubmit;

  const ChatView({super.key, this.onSubmit});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: text));
      _isLoading = true;
    });
    _controller.clear();

    if (widget.onSubmit != null) {
      widget.onSubmit!(text).then((response) {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(content: response, isUser: false));
            _isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        _messages.add(ChatMessage(content: 'Echo: $text', isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          const Divider(height: 1),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(msg.content),
      ),
    );
  }

  Widget _buildInputBar() {
    final canSend = _controller.text.trim().isNotEmpty && !_isLoading;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '描述你想要的设计操作...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
              enabled: !_isLoading,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            onPressed: canSend ? _send : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.content, this.isUser = true}) : timestamp = DateTime.now();
}

class SoftwareOption {
  final String id;
  final String name;
  final String icon;

  const SoftwareOption({required this.id, required this.name, required this.icon});
}

class ChatView extends StatefulWidget {
  final Future<String> Function(String message)? onSubmit;
  final List<SoftwareOption> softwareOptions;
  final String selectedSoftware;
  final ValueChanged<String>? onSoftwareChanged;

  const ChatView({
    super.key,
    this.onSubmit,
    this.softwareOptions = const [],
    this.selectedSoftware = '',
    this.onSoftwareChanged,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  bool _isLoading = false;

  static const _maxMessages = 500;

  void _trimMessages() {
    while (_messages.length > _maxMessages) {
      _messages.removeAt(0);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: text));
      _trimMessages();
      _isLoading = true;
    });
    _scrollToBottom();
    _controller.clear();

    if (widget.onSubmit != null) {
      widget.onSubmit!(text).then((response) {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(content: response, isUser: false));
            _trimMessages();
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }).catchError((error) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _messages.add(ChatMessage(content: '❌ ${l10n?.errorPrefix ?? 'Error'}: $error', isUser: false));
            _trimMessages();
            _isLoading = false;
          });
          _scrollToBottom();
        }
      });
    } else {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _messages.add(ChatMessage(content: '${l10n?.echoPrefix ?? 'Echo'}: $text', isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.softwareOptions.isNotEmpty) _buildSoftwareBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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

  Widget _buildSoftwareBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(l10n?.targetSoftware ?? 'Target Software:', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedSoftware.isNotEmpty &&
                        widget.softwareOptions.any((o) => o.id == widget.selectedSoftware)
                    ? widget.selectedSoftware
                    : widget.softwareOptions.first.id,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: widget.softwareOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt.id,
                    child: Text('${opt.icon} ${opt.name}', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) widget.onSoftwareChanged?.call(value);
                },
              ),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.hintText ?? 'Describe the design operation you want...',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
              enabled: !_isLoading,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final canSend = _controller.text.trim().isNotEmpty && !_isLoading;
              return IconButton(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                onPressed: canSend ? _send : null,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

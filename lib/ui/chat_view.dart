import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  /// 任务产物文件路径；响应到达后由 onArtifacts 异步补充。
  List<String> artifacts = const [];

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
  /// 加载中停止按钮的回调：中止在途请求（由外层接到取消链路）。
  final VoidCallback? onCancel;
  /// 任务完成后取产物路径：异步补充到对应消息，失败静默忽略。
  final Future<List<String>> Function(String message)? onArtifacts;
  final List<SoftwareOption> softwareOptions;
  final String selectedSoftware;
  final ValueChanged<String>? onSoftwareChanged;
  final int conversationEpoch;

  const ChatView({
    super.key,
    this.onSubmit,
    this.onCancel,
    this.onArtifacts,
    this.softwareOptions = const [],
    this.selectedSoftware = '',
    this.onSoftwareChanged,
    this.conversationEpoch = 0,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final FocusNode _inputFocus = FocusNode(onKeyEvent: _handleInputKey);
  final _messages = <ChatMessage>[];
  bool _isLoading = false;

  KeyEventResult _handleInputKey(FocusNode node, KeyEvent event) {
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (isEnter &&
        event is KeyDownEvent &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static const _maxMessages = 500;

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationEpoch != oldWidget.conversationEpoch) {
      _messages.clear();
      _controller.clear();
      // 旧会话的在途请求已无意义：复位 loading，避免输入框永久禁用。
      _isLoading = false;
    }
  }

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
    _controller.clear();
    // 引擎/IME 可能在 Enter 事件后补插一个换行符，下一帧前清掉残留。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.text.trim().isEmpty) _controller.clear();
    });
    _sendText(text);
  }

  void _sendText(String text) {
    if (text.isEmpty) return;
    final submittedEpoch = widget.conversationEpoch;

    setState(() {
      _messages.add(ChatMessage(content: text));
      _trimMessages();
      _isLoading = true;
    });
    _scrollToBottom();

    if (widget.onSubmit != null) {
      widget.onSubmit!(text).then((response) {
        // 请求在途时会话已切换（epoch 变化）：旧响应丢弃，不得追加进新会话。
        if (!mounted || widget.conversationEpoch != submittedEpoch) return;
        late ChatMessage msg;
        setState(() {
          msg = ChatMessage(content: response, isUser: false);
          _messages.add(msg);
          _trimMessages();
          _isLoading = false;
        });
        _scrollToBottom();
        // 产物路径异步补充：先显示文本，图片/文件随后渲染，失败不影响消息。
        if (widget.onArtifacts != null) {
          widget.onArtifacts!(text).then((paths) {
            if (!mounted || widget.conversationEpoch != submittedEpoch) return;
            setState(() => msg.artifacts = paths);
          }).catchError((_) {});
        }
      }).catchError((error) {
        if (!mounted || widget.conversationEpoch != submittedEpoch) return;
        final l10n = AppLocalizations.of(context);
        setState(() {
          _messages.add(ChatMessage(content: '❌ ${l10n?.errorPrefix ?? 'Error'}: $error', isUser: false));
          _trimMessages();
          _isLoading = false;
        });
        _scrollToBottom();
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

  static const _imageExtensions = {'png', 'jpg', 'jpeg', 'webp', 'gif'};

  bool _isImage(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return false;
    return _imageExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  Widget _buildArtifact(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    if (_isImage(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 240),
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                _artifactFallback(Icons.broken_image, name),
          ),
        ),
      );
    }
    return _artifactFallback(Icons.insert_drive_file, name);
  }

  Widget _artifactFallback(IconData icon, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: msg.isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(msg.content),
          if (!msg.isUser && msg.artifacts.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final path in msg.artifacts) _buildArtifact(path),
          ],
        ],
      ),
    );
    if (!msg.isUser) {
      return Align(alignment: Alignment.centerLeft, child: bubble);
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bubble,
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)?.retry ?? 'Retry',
              onPressed: _isLoading ? null : () => _sendText(msg.content),
            ),
          ),
        ],
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
              focusNode: _inputFocus,
              enabled: !_isLoading,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_isLoading) {
                // 加载中：发送键切换为停止键，点击中止在途请求。
                return IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: 'Stop',
                  onPressed: widget.onCancel,
                );
              }
              final canSend = _controller.text.trim().isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.send),
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
    _inputFocus.dispose();
    super.dispose();
  }
}

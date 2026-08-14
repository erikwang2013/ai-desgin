import 'dart:convert';
import 'dart:io';
import 'package:fast_gbk/fast_gbk.dart';

/// 解码子进程控制台输出：优先严格 UTF-8；失败时 Windows 上回退 GBK
/// （Blender/FreeCAD 等中文环境输出 GBK 字节），其他平台宽容 UTF-8。
String decodeConsoleOutput(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    if (Platform.isWindows) return gbk.decode(bytes, allowMalformed: true);
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// Agent 子进程输出缓冲上限：超过时丢弃头部只保留尾部，防止失控输出耗尽
/// 内存；截断后 [truncated] 置位，调用方据此提示或报错。
const kMaxAgentOutputBytes = 8 * 1024 * 1024;

/// 带截断的输出收集器（tail-retention，仿 LocalScriptExecutor._drainOutput）。
class CappedOutputBuffer {
  CappedOutputBuffer({this.maxBytes = kMaxAgentOutputBytes});

  final int maxBytes;
  final List<int> _buffer = [];
  bool _truncated = false;

  void add(List<int> chunk) {
    _buffer.addAll(chunk);
    // 超过两倍上限时丢弃头部只保留尾部，均摊拷贝成本。
    if (_buffer.length > maxBytes * 2) {
      _truncated = true;
      _buffer.removeRange(0, _buffer.length - maxBytes);
    }
  }

  bool get truncated => _truncated;

  List<int> takeBytes() {
    final bytes = List<int>.from(_buffer);
    _buffer.clear();
    return bytes;
  }
}

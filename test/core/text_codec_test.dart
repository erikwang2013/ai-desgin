// test/core/text_codec_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/text_codec.dart';

void main() {
  test('decodes valid UTF-8 unchanged', () {
    final bytes = utf8.encode('创建矩形 with ASCII');
    expect(decodeConsoleOutput(bytes), '创建矩形 with ASCII');
  });

  test('decodes empty input to empty string', () {
    expect(decodeConsoleOutput(const []), '');
  });

  test('never throws on invalid UTF-8 bytes', () {
    // 0xFF/0xFE 不是合法 UTF-8 起始字节；解码必须容错而非抛异常。
    final bytes = <int>[0xff, 0xfe, 0x80, 0x41, 0x42];
    String? result;
    expect(() => result = decodeConsoleOutput(bytes), returnsNormally);
    expect(result, isNotNull);
    expect(result, isNotEmpty);
    expect(result!.contains('AB'), isTrue);
  });

  test('recovers the valid tail after malformed bytes', () {
    final bytes = <int>[
      0xc3, 0x28, // 非法 UTF-8 序列（0xC3 后应接 0x80-0xBF）
      ...utf8.encode('正常文本'),
    ];
    final result = decodeConsoleOutput(bytes);
    expect(result, contains('正常文本'));
  });
}

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

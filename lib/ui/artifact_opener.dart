// lib/ui/artifact_opener.dart
import 'dart:convert';
import 'dart:io';

/// 用系统默认应用打开产物文件（isFile=true）或其所在目录（isFile=false）。
/// Windows 走 PowerShell Start-Process（UTF-16LE EncodedCommand 防路径转义），
/// macOS 走 open，其余走 xdg-open；启动失败返回 false。
Future<bool> openArtifactWithSystem(String path, {required bool isFile}) async {
  final target = isFile ? path : File(path).parent.path;
  final List<String> cmd;
  if (Platform.isWindows) {
    final script = 'Start-Process -LiteralPath \'${target.replaceAll("'", "''")}\'';
    // PowerShell -EncodedCommand 要求 UTF-16LE base64；codeUnits 即 UTF-16 码元。
    final utf16le = <int>[];
    for (final unit in script.codeUnits) {
      utf16le.add(unit & 0xFF);
      utf16le.add((unit >> 8) & 0xFF);
    }
    cmd = [
      'powershell',
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand',
      base64.encode(utf16le),
    ];
  } else if (Platform.isMacOS) {
    cmd = ['open', target];
  } else {
    cmd = ['xdg-open', target];
  }
  final result = await Process.start(cmd.first, cmd.sublist(1));
  final code = await result.exitCode;
  return code == 0;
}

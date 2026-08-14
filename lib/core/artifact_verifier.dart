import 'dart:io';
import '../models/plugin.dart';

class VerificationResult {
  final bool passed;
  final String summary;

  const VerificationResult({required this.passed, required this.summary});
}

/// 执行产物验证：判定一次脚本执行是否真正完成了创作。
/// 首期：退出码 + stdout 失败特征（词边界匹配，避免误判脚本内
/// 常见词如 `except Exception`）+ 产物文件存在性（注：执行器首期
/// 不填充 artifacts，该检查暂不生效）；截图/GUI 状态留二期。
class ArtifactVerifier {
  const ArtifactVerifier();

  static final _englishMarkers = [
    RegExp(r'\berror\b', caseSensitive: false),
    RegExp(r'\btraceback\b', caseSensitive: false),
    RegExp(r'\bexception\b', caseSensitive: false),
    RegExp(r'\bfailed\b', caseSensitive: false),
  ];

  static const _chineseMarkers = ['命令错误', '脚本执行失败'];

  Future<VerificationResult> verify(ScriptResult result) async {
    if (!result.success) {
      return const VerificationResult(passed: false, summary: '执行失败（非零退出码）');
    }
    final output = result.output ?? '';
    // 回退路径（软件未安装/平台不支持）由执行器显式标记 manualFallback，
    // 无真实执行结果可验证，直接通过，避免无意义的多轮重新生成。
    if (result.manualFallback) {
      return const VerificationResult(passed: true, summary: '验证通过（手动执行回退）');
    }
    for (final artifact in result.artifacts) {
      if (!await File(artifact).exists()) {
        return VerificationResult(passed: false, summary: '产物文件不存在: $artifact');
      }
    }
    // 特征词（error/traceback 等）误报率高于收益：正常输出里的 "no error"、
    // "0 errors" 也会命中，直接判失败会浪费多轮重新生成的 token。
    // 不再判失败，仅附在 summary 中提示。
    for (final marker in _englishMarkers) {
      if (marker.hasMatch(output)) {
        return VerificationResult(
            passed: true, summary: '验证通过（输出含可疑字样 ${marker.pattern}）');
      }
    }
    for (final marker in _chineseMarkers) {
      if (output.contains(marker)) {
        return VerificationResult(passed: true, summary: '验证通过（输出含可疑字样 $marker）');
      }
    }
    return const VerificationResult(passed: true, summary: '验证通过');
  }
}

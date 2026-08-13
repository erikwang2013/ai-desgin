import 'dart:io';
import '../models/plugin.dart';

class VerificationResult {
  final bool passed;
  final String summary;

  const VerificationResult({required this.passed, required this.summary});
}

/// 执行产物验证：判定一次脚本执行是否真正完成了创作。
/// 首期：退出码 + stdout 失败特征 + 产物文件存在性；截图/GUI 状态留二期。
class ArtifactVerifier {
  const ArtifactVerifier();

  static const _failureMarkers = [
    'error',
    'traceback',
    'exception',
    'failed',
    '命令错误',
    '脚本执行失败',
  ];

  Future<VerificationResult> verify(ScriptResult result) async {
    if (!result.success) {
      return const VerificationResult(passed: false, summary: '执行失败（非零退出码）');
    }
    final output = (result.output ?? '').toLowerCase();
    final marker = _failureMarkers
        .firstWhere((m) => output.contains(m.toLowerCase()), orElse: () => '');
    if (marker.isNotEmpty) {
      return VerificationResult(passed: false, summary: '输出包含失败特征: $marker');
    }
    for (final artifact in result.artifacts) {
      if (!await File(artifact).exists()) {
        return VerificationResult(passed: false, summary: '产物文件不存在: $artifact');
      }
    }
    return const VerificationResult(passed: true, summary: '验证通过');
  }
}

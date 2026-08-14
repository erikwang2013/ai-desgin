import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/artifact_verifier.dart';
import 'package:ai_design_studio/models/plugin.dart';

void main() {
  const verifier = ArtifactVerifier();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('artifact_verifier_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('execution failure', () {
    test('non-zero exit fails verification immediately', () async {
      final result = await verifier.verify(ScriptResult.failure(error: 'exit 1'));
      expect(result.passed, isFalse);
      expect(result.summary, contains('执行失败'));
    });
  });

  group('output failure markers', () {
    test('english markers downgrade to hints instead of failing', () async {
      for (final output in [
        'ERROR: cannot open file',
        'Traceback (most recent call last):',
        'Exception thrown during run',
        'task failed after retry',
      ]) {
        final result = await verifier.verify(ScriptResult.success(output: output));
        // "no error" 等正常输出也会命中特征词，直接判失败会浪费重生成 token。
        expect(result.passed, isTrue, reason: 'marker should be a hint: $output');
        expect(result.summary, contains('可疑字样'), reason: 'hint should surface: $output');
      }
    });

    test('english markers do not match inside words', () async {
      for (final output in [
        'errorless run completed',
        'the terminal is ready',
        'exceptional output saved',
      ]) {
        final result = await verifier.verify(ScriptResult.success(output: output));
        expect(result.passed, isTrue, reason: 'word boundary should prevent match: $output');
      }
    });

    test('chinese markers downgrade to hints instead of failing', () async {
      final result1 = await verifier.verify(ScriptResult.success(output: '命令错误：未知命令'));
      expect(result1.passed, isTrue);
      expect(result1.summary, contains('可疑字样'));

      final result2 = await verifier.verify(ScriptResult.success(output: '脚本执行失败，请检查环境'));
      expect(result2.passed, isTrue);
      expect(result2.summary, contains('可疑字样'));
    });

    test('clean output passes', () async {
      final result = await verifier.verify(ScriptResult.success(output: 'done in 2.3s, 12 nodes created'));
      expect(result.passed, isTrue);
      expect(result.summary, '验证通过');
    });
  });

  group('manual fallback', () {
    test('manual fallback skips marker and artifact checks', () async {
      final result = await verifier.verify(ScriptResult.success(
        output: '请手动执行以下步骤... ERROR note',
        manualFallback: true,
        artifacts: ['${tempDir.path}/never-created.png'],
      ));
      expect(result.passed, isTrue);
      expect(result.summary, contains('手动执行回退'));
    });
  });

  group('artifact existence', () {
    test('missing artifact fails verification', () async {
      final missing = '${tempDir.path}/missing.png';
      final result = await verifier.verify(ScriptResult.success(output: 'ok', artifacts: [missing]));
      expect(result.passed, isFalse);
      expect(result.summary, contains('产物文件不存在'));
    });

    test('existing artifact passes verification', () async {
      final file = File('${tempDir.path}/output.png');
      await file.writeAsString('data');
      final result = await verifier.verify(ScriptResult.success(output: 'ok', artifacts: [file.path]));
      expect(result.passed, isTrue);
    });
  });
}

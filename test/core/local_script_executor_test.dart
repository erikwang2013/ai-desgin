import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/artifact_verifier.dart';
import 'package:ai_design_studio/core/local_script_executor.dart';
import 'package:ai_design_studio/core/script_executor_configs.dart';
import 'package:ai_design_studio/models/plugin.dart';

/// 生成一个可独立执行的假 CLI shell 脚本，body 可用 $AI_DESIGN_SCRIPT
/// 环境变量定位本次执行的临时目录（dirname 即脚本所在目录）。
Future<Directory> _makeFakeCli(String body) async {
  final dir = await Directory.systemTemp.createTemp('fake_cli_');
  final bin = File('${dir.path}/fake_cli.sh')
    ..writeAsStringSync('#!/bin/sh\n$body\n');
  await Process.run('chmod', ['+x', bin.path]);
  return dir;
}

ScriptExecutorConfig _blenderConfig(String executable) => ScriptExecutorConfig(
      pluginId: 'blender',
      executable: executable,
      scriptExtension: 'py',
      args: (scriptPath, _) => ['--background', '--python', scriptPath],
    );

void main() {
  test('hasCommand only for CLI-capable plugins', () {
    final executor = LocalScriptExecutor();
    expect(executor.hasCommand('blender'), isTrue);
    expect(executor.hasCommand('freecad'), isTrue);
    expect(executor.hasCommand('openscad'), isTrue);
    // 新增 CLI 执行软件（创作闭环首批）
    expect(executor.hasCommand('autocad'), isTrue);
    expect(executor.hasCommand('rhino'), isTrue);
    expect(executor.hasCommand('photoshop'), isTrue);
    expect(executor.hasCommand('illustrator'), isTrue);
    expect(executor.hasCommand('fusion360'), isTrue);
    expect(executor.hasCommand('sketchup'), isTrue);
    expect(executor.hasCommand('sketch'), isTrue);
    // Slicers: CLI accepts model files — wired for direct model slicing
    expect(executor.hasCommand('cura'), isTrue);
    expect(executor.hasCommand('prusaslicer'), isTrue);
    expect(executor.hasCommand('orcaslicer'), isTrue);
    expect(executor.hasCommand('chitubox'), isTrue);
    expect(executor.hasCommand('lychee'), isTrue);
    expect(executor.hasCommand('simplify3d'), isTrue);
    // SolidWorks via cscript COM wrapper (Windows-only)
    expect(executor.hasCommand('solidworks'), isTrue);
    // Revit has no real CLI — honest manual-execution fallback
    expect(executor.hasCommand('revit'), isFalse);
    expect(executor.hasCommand('figma'), isFalse);
  });

  test('slicer args pass model path straight to CLI', () {
    final configs = defaultExecutorConfigs();
    final cura = configs.firstWhere((c) => c.pluginId == 'cura');
    final tempDir = Directory.systemTemp.createTempSync('test_');
    try {
      final script = File('${tempDir.path}/model.stl')
        ..writeAsStringSync('/models/cube.stl');
      final args = cura.args(script.path, tempDir);
      expect(args, contains('slice'));
      expect(args, contains('/models/cube.stl'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('execute falls back to generated script for non-CLI plugins', () async {
    final executor = LocalScriptExecutor();
    final result = await executor.execute('figma', 'Figma', 'console.log("hi");');
    expect(result.success, isTrue);
    expect(result.manualFallback, isTrue);
    expect(result.output, contains('脚本已生成'));
    expect(result.output, contains('console.log("hi");'));
  });

  test('fallback when executable missing carries manualFallback flag', () async {
    final executor = LocalScriptExecutor(
      configs: {
        'blender': ScriptExecutorConfig(
          pluginId: 'blender',
          executable: '/nonexistent/ai_design_tool',
          scriptExtension: 'py',
          args: (scriptPath, _) => [scriptPath],
        ),
      },
    );
    final result = await executor.execute('blender', 'Blender', 'print(1)');
    expect(result.success, isTrue);
    expect(result.manualFallback, isTrue);
    expect(result.output, contains('未检测到 Blender'));
  });

  test('verifier reads manualFallback flag instead of output magic string', () async {
    const verifier = ArtifactVerifier();
    final flagged = await verifier.verify(
      ScriptResult.success(output: 'no failure markers', manualFallback: true),
    );
    expect(flagged.passed, isTrue);
    expect(flagged.summary, contains('手动执行回退'));
    // 未置位时不再按文案判定回退，走常规失败特征与产物检查。
    final plain = await verifier.verify(
      ScriptResult.success(output: '未检测到 某工具 可执行文件'),
    );
    expect(plain.passed, isTrue);
    expect(plain.summary, isNot(contains('手动执行回退')));
  });

  group('fake CLI process', () {
    test('success collects whitelisted artifacts', () async {
      final dir = await _makeFakeCli(r'''
outdir="$(dirname "$AI_DESIGN_SCRIPT")"
printf 'PNGFAKE' > "$outdir/out.png"
printf 'note' > "$outdir/readme.txt"
''');
      addTearDown(() => dir.deleteSync(recursive: true));
      final executor = LocalScriptExecutor(
        configs: {'blender': _blenderConfig('${dir.path}/fake_cli.sh')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts, hasLength(1));
      expect(result.artifacts.single, endsWith('out.png'));
      expect(File(result.artifacts.single).existsSync(), isTrue);
      expect(File(result.artifacts.single).parent.path,
          contains('ai_design_artifacts'));
    });

    test('no artifacts returns empty list', () async {
      final dir = await _makeFakeCli('exit 0');
      addTearDown(() => dir.deleteSync(recursive: true));
      final executor = LocalScriptExecutor(
        configs: {'blender': _blenderConfig('${dir.path}/fake_cli.sh')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts, isEmpty);
    });

    test('symlinked artifact pointing outside temp dir is skipped', () async {
      final secretDir = await Directory.systemTemp.createTemp('secret_');
      addTearDown(() => secretDir.deleteSync(recursive: true));
      final secret = File('${secretDir.path}/secret.png')
        ..writeAsStringSync('SENSITIVE');
      final dir = await _makeFakeCli(r'''
outdir="$(dirname "$AI_DESIGN_SCRIPT")"
ln -s "''' +
          secret.path +
          r'" "$outdir/leak.png"');
      addTearDown(() => dir.deleteSync(recursive: true));
      final executor = LocalScriptExecutor(
        configs: {'blender': _blenderConfig('${dir.path}/fake_cli.sh')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts, isEmpty);
      expect(secret.readAsStringSync(), 'SENSITIVE');
    });

    test('oversized artifact is skipped', () async {
      final dir = await _makeFakeCli(r'''
outdir="$(dirname "$AI_DESIGN_SCRIPT")"
truncate -s 60M "$outdir/big.png"
printf 'ok' > "$outdir/small.png"
''');
      addTearDown(() => dir.deleteSync(recursive: true));
      final executor = LocalScriptExecutor(
        configs: {'blender': _blenderConfig('${dir.path}/fake_cli.sh')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts, hasLength(1));
      expect(result.artifacts.single, endsWith('small.png'));
    });

    test('cancel kills running process', () async {
      final dir = await _makeFakeCli('exec sleep 30');
      addTearDown(() => dir.deleteSync(recursive: true));
      final executor = LocalScriptExecutor(
        configs: {'blender': _blenderConfig('${dir.path}/fake_cli.sh')},
      );
      final future = executor.execute('blender', 'Blender', 'print(1)', key: 't-1');
      // 轮询 cancel：等待进程注册后 kill（最多约 2.5s）。
      await Future.delayed(const Duration(milliseconds: 300));
      for (var i = 0; i < 20; i++) {
        executor.cancel('t-1');
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final result = await future.timeout(const Duration(seconds: 10));
      expect(result.success, isFalse);
      expect(result.error, contains('已取消'));
    });

    test('cancel unknown key is a harmless no-op', () async {
      final executor = LocalScriptExecutor(
        configs: {'blender': _blenderConfig('/nonexistent/fake')},
      );
      executor.cancel('never-registered');
      expect(executor.hasCommand('blender'), isTrue);
    });
  }, skip: Platform.isWindows ? 'fake shell CLI 仅 POSIX 可用' : false);

  test('supportsPlatform gates the availability probe', () async {
    final dir = await _makeFakeCli('exit 0');
    final cli = '${dir.path}/fake_cli.sh';
    final executor = LocalScriptExecutor(configs: {
      'winonly': ScriptExecutorConfig(
        pluginId: 'winonly',
        executable: cli,
        scriptExtension: 'py',
        platforms: {'windows'},
        args: (s, p) => ['--version'],
      ),
      'linuxok': ScriptExecutorConfig(
        pluginId: 'linuxok',
        executable: cli,
        scriptExtension: 'py',
        args: (s, p) => ['--version'],
      ),
    });
    // 平台不匹配时不执行 probe，直接不可用。
    expect(await executor.checkAvailable('winonly'), isFalse);
    expect(await executor.checkAvailable('linuxok'), isTrue);
  });

  test('checkAvailable caches probe result per plugin within TTL', () async {
    final dir = await Directory.systemTemp.createTemp('probe_count_');
    final countFile = File('${dir.path}/count');
    final cli = await _makeFakeCli('echo x >> ${countFile.path}');
    final executor = LocalScriptExecutor(
      configs: {'blender': _blenderConfig('${cli.path}/fake_cli.sh')},
    );
    await executor.checkAvailable('blender');
    await executor.checkAvailable('blender');
    final probes = countFile
        .readAsStringSync()
        .trim()
        .split('\n')
        .where((l) => l.isNotEmpty)
        .length;
    expect(probes, 1, reason: 'second call must hit the per-plugin cache');
  });

  test('probe timeout kills the orphan subprocess', () async {
    final dir = await Directory.systemTemp.createTemp('probe_kill_');
    final pidFile = File('${dir.path}/pid');
    final cli = await _makeFakeCli('echo \$\$ > ${pidFile.path}; exec sleep 30');
    final executor = LocalScriptExecutor(
      configs: {'blender': _blenderConfig('${cli.path}/fake_cli.sh')},
      probeTimeout: const Duration(milliseconds: 300),
    );
    await executor.checkAvailable('blender');
    expect(pidFile.existsSync(), isTrue);
    final pid = int.parse((await pidFile.readAsString()).trim());
    final alive = await Process.run('kill', ['-0', '$pid']);
    expect(alive.exitCode, isNot(0), reason: 'probe subprocess should have been killed');
  });
}

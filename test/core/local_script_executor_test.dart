import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// 生成带 shebang 的可执行假 CLI（绝对路径），body 用 $AI_DESIGN_SCRIPT
/// 环境变量定位本次执行的临时目录。
Future<File> _makeExecutableScript(
  Directory parent,
  String name,
  String body,
) async {
  final file = File('${parent.path}/$name')..writeAsStringSync('#!/bin/sh\n$body\n');
  await Process.run('chmod', ['+x', file.path]);
  return file;
}

/// 生成安装目录探测用的假软件目录（含版本通配目录），返回其可执行文件。
Future<File> _makeInstalledFake(Directory tmp, String dirName, String exeName,
    String artifactName) async {
  final dir = Directory('${tmp.path}/$dirName')..createSync(recursive: true);
  return _makeExecutableScript(dir, exeName,
      'outdir="\$(dirname "\$AI_DESIGN_SCRIPT")"\nprintf x > "\$outdir/$artifactName"');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  group('executable resolution order', () {
    // 所有用例共用：PATH 命中、安装目录命中、覆盖命中各写不同产物名，
    // 用实际运行的产物文件区分“哪个来源胜出”。
    ScriptExecutorConfig resolutionConfig(String installPattern) =>
        ScriptExecutorConfig(
          pluginId: 'blender',
          executable: 'zzz_ai_blender_fake',
          scriptExtension: 'py',
          installPaths: {'linux': [installPattern]},
          args: (scriptPath, _) => ['--background', '--python', scriptPath],
        );

    test('user path override wins over PATH and install dirs', () async {
      final tmp = await Directory.systemTemp.createTemp('ovr_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final override = await _makeExecutableScript(
          tmp, 'override_cli.sh', 'outdir="\$(dirname "\$AI_DESIGN_SCRIPT")"\nprintf O > "\$outdir/override.png"');
      final installed =
          await _makeInstalledFake(tmp, 'Blender 4.2', 'blender', 'installed.png');
      SharedPreferences.setMockInitialValues({
        executorPathOverrideKey('blender'): override.path,
      });
      final executor = LocalScriptExecutor(
        environment: {'PATH': tmp.path},
        configs: {'blender': resolutionConfig('${tmp.path}/Blender*/blender')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts.single, endsWith('override.png'));
      expect(installed.existsSync(), isTrue, reason: 'install dir fake untouched');
    });

    test('PATH hit wins over install dir probe', () async {
      final tmp = await Directory.systemTemp.createTemp('path_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final pathDir = Directory('${tmp.path}/bin')..createSync(recursive: true);
      final pathCli =
          await _makeExecutableScript(pathDir, 'zzz_ai_blender_fake',
              'outdir="\$(dirname "\$AI_DESIGN_SCRIPT")"\nprintf P > "\$outdir/path.png"');
      final installed =
          await _makeInstalledFake(tmp, 'Blender 4.2', 'blender', 'installed.png');
      expect(installed.existsSync(), isTrue);
      final executor = LocalScriptExecutor(
        environment: {'PATH': pathDir.path},
        configs: {'blender': resolutionConfig('${tmp.path}/Blender*/blender')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts.single, endsWith('path.png'));
      expect(pathCli.existsSync(), isTrue);
    });

    test('install dir probe hits when PATH and override miss', () async {
      final tmp = await Directory.systemTemp.createTemp('inst_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final installed =
          await _makeInstalledFake(tmp, 'Blender 4.2', 'blender', 'installed.png');
      final executor = LocalScriptExecutor(
        environment: {'PATH': ''},
        configs: {'blender': resolutionConfig('${tmp.path}/Blender*/blender')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.artifacts.single, endsWith('installed.png'));
      expect(installed.existsSync(), isTrue);
    });

    test('all resolution paths miss keeps manual fallback', () async {
      final tmp = await Directory.systemTemp.createTemp('miss_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final executor = LocalScriptExecutor(
        environment: {'PATH': ''},
        configs: {'blender': resolutionConfig('${tmp.path}/NoSuch*/blender')},
      );
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.manualFallback, isTrue);
      expect(result.output, contains('未检测到 Blender'));
    });

    test('install dir probe results are cached within the session', () async {
      final tmp = await Directory.systemTemp.createTemp('cached_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final installed =
          await _makeInstalledFake(tmp, 'Blender 4.2', 'blender', 'installed.png');
      final executor = LocalScriptExecutor(
        environment: {'PATH': ''},
        configs: {'blender': resolutionConfig('${tmp.path}/Blender*/blender')},
      );
      await executor.execute('blender', 'Blender', 'print(1)');
      // 删除命中目录后，会话缓存仍指向原路径（不重复扫描磁盘），
      // 再次执行因缓存路径失效走 manualFallback，而不是重新探测。
      installed.deleteSync();
      final result = await executor.execute('blender', 'Blender', 'print(1)');
      expect(result.success, isTrue);
      expect(result.manualFallback, isTrue);
      expect(result.output, contains('未检测到 Blender'));
    });
  });

  group('path probing helpers', () {
    test('lookupExecutableInPath finds executable in PATH dirs', () async {
      final tmp = await Directory.systemTemp.createTemp('pathlk_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final bin = await _makeExecutableScript(tmp, 'mytool', 'exit 0');
      expect(LocalScriptExecutor.lookupExecutableInPath('mytool', tmp.path),
          bin.path);
      expect(LocalScriptExecutor.lookupExecutableInPath('mytool', ''), isNull);
      expect(
          LocalScriptExecutor.lookupExecutableInPath('missing_tool', tmp.path),
          isNull);
      // 无执行位文件不算 PATH 命中。
      final noExec = File('${tmp.path}/noexec')..writeAsStringSync('data');
      expect(
          LocalScriptExecutor.lookupExecutableInPath('noexec', tmp.path),
          isNull);
      expect(noExec.existsSync(), isTrue);
    });

    test('expandEnvPattern expands %VAR% and skips missing vars', () {
      const env = {
        'ProgramFiles': r'C:\Program Files',
        'LOCALAPPDATA': r'C:\Users\t\AppData\Local',
      };
      expect(
        LocalScriptExecutor.expandEnvPattern(
            r'%ProgramFiles%\Blender Foundation\Blender*\blender.exe', env),
        r'C:\Program Files\Blender Foundation\Blender*\blender.exe',
      );
      expect(
        LocalScriptExecutor.expandEnvPattern(r'%MISSING%\x\y.exe', env),
        isNull,
      );
      expect(
        LocalScriptExecutor.expandEnvPattern(
            '/Applications/Blender.app/Contents/MacOS/Blender', env),
        '/Applications/Blender.app/Contents/MacOS/Blender',
      );
    });

    test('globFirstMatch picks first sorted match across wildcard dirs', () async {
      final tmp = await Directory.systemTemp.createTemp('glob_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final v36 = await _makeInstalledFake(tmp, 'Blender 3.6', 'blender.exe', 'x.png');
      final v42 = await _makeInstalledFake(tmp, 'Blender 4.2', 'blender.exe', 'x.png');
      expect(
        LocalScriptExecutor.globFirstMatch('${tmp.path}/Blender*/blender.exe'),
        v36.path,
        reason: '目录条目按名称排序取首个（3.6 < 4.2）',
      );
      expect(
        LocalScriptExecutor.globFirstMatch('${tmp.path}/NoSuch*/blender.exe'),
        isNull,
      );
      expect(v42.existsSync(), isTrue);
    });

    test('default configs carry install dir candidates for GUI installs', () {
      final configs = {
        for (final c in defaultExecutorConfigs()) c.pluginId: c,
      };
      expect(configs['blender']!.installPaths['windows'], isNotEmpty);
      expect(configs['blender']!.installPaths['macos'], isNotEmpty);
      expect(configs['freecad']!.installPaths['windows'], isNotEmpty);
      expect(configs['openscad']!.installPaths['macos'], isNotEmpty);
      // 其余软件不参与安装目录探测。
      expect(configs['autocad']!.installPaths, isEmpty);
      expect(configs['cura']!.installPaths, isEmpty);
    });
  });
}

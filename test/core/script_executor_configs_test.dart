import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/script_executor_configs.dart';

void main() {
  final configs = defaultExecutorConfigs();
  late Directory tempDir;

  ScriptExecutorConfig cfg(String pluginId) =>
      configs.firstWhere((c) => c.pluginId == pluginId);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('exec_configs_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('registry', () {
    test('registers every supported plugin with unique ids', () {
      final ids = configs.map((c) => c.pluginId).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, containsAll([
        'blender', 'freecad', 'openscad', 'autocad', 'rhino', 'photoshop',
        'illustrator', 'fusion360', 'sketchup', 'sketch', 'cura',
        'prusaslicer', 'chitubox', 'lychee', 'orcaslicer', 'simplify3d',
        'solidworks',
      ]));
    });
  });

  group('platform gating', () {
    test('autocad/solidworks/simplify3d are windows-only', () {
      for (final id in ['autocad', 'solidworks', 'simplify3d']) {
        final c = cfg(id);
        expect(c.supportsPlatform('windows'), isTrue, reason: id);
        expect(c.supportsPlatform('macos'), isFalse, reason: id);
        expect(c.supportsPlatform('linux'), isFalse, reason: id);
      }
    });

    test('sketch is macos-only', () {
      expect(cfg('sketch').supportsPlatform('macos'), isTrue);
      expect(cfg('sketch').supportsPlatform('windows'), isFalse);
    });

    test('blender/freecad/cura run on every platform', () {
      for (final id in ['blender', 'freecad', 'cura']) {
        final c = cfg(id);
        expect(c.supportsPlatform('windows'), isTrue, reason: id);
        expect(c.supportsPlatform('macos'), isTrue, reason: id);
        expect(c.supportsPlatform('linux'), isTrue, reason: id);
      }
    });
  });

  group('install paths probing', () {
    test('blender probes windows version dirs and the macos app bundle', () {
      final blender = cfg('blender').installPaths;
      expect(blender['windows']!.first, contains('%ProgramFiles%'));
      expect(blender['windows']!.first, contains('Blender*'));
      expect(blender['macos'], ['/Applications/Blender.app/Contents/MacOS/Blender']);
      expect(blender.containsKey('linux'), isFalse);
    });

    test('freecad and openscad probe windows install dirs', () {
      expect(cfg('freecad').installPaths['windows']!.first, contains('%ProgramFiles%'));
      expect(cfg('openscad').installPaths['windows'],
          [r'%ProgramFiles%\OpenSCAD\openscad.exe']);
    });

    test('PATH-installed CLIs need no install-dir probing', () {
      expect(cfg('cura').installPaths, isEmpty);
      expect(cfg('rhino').installPaths, isEmpty);
      expect(cfg('sketch').installPaths, isEmpty);
      expect(cfg('blender').installPaths, isNotEmpty);
    });
  });

  group('probe args', () {
    test('defaults to --version', () {
      expect(cfg('blender').probeArgs, ['--version']);
      expect(cfg('rhino').probeArgs, ['--version']);
    });

    test('windows CLIs use their own help flags', () {
      expect(cfg('autocad').probeArgs, ['/?']);
      expect(cfg('solidworks').probeArgs, ['//?']);
    });

    test('slicers probe with version/help', () {
      expect(cfg('cura').probeArgs, ['version']);
      expect(cfg('chitubox').probeArgs, ['--help']);
      expect(cfg('lychee').probeArgs, ['--help']);
    });
  });

  group('args builders', () {
    test('blender passes the python script as --python', () {
      expect(cfg('blender').args('x.py', tempDir), ['--background', '--python', 'x.py']);
    });

    test('openscad writes output stl into the temp dir', () {
      expect(cfg('openscad').args('x.scad', tempDir),
          ['-o', '${tempDir.path}/out.stl', 'x.scad']);
    });

    test('freecad injects the script via AI_DESIGN_SCRIPT env', () {
      final args = cfg('freecad').args('x.py', tempDir);
      expect(args.first, '-c');
      expect(args[1], contains('AI_DESIGN_SCRIPT'));
    });

    test('autocad writes a .scr loader with forward-slashed script path', () {
      final script = r'C:\tmp\floor plan.lsp';
      final args = cfg('autocad').args(script, tempDir);
      final loader = File(args[1]);
      expect(loader.existsSync(), isTrue);
      expect(args, ['/b', loader.path]);
      expect(loader.readAsStringSync(),
          '(load "C:/tmp/floor plan.lsp")\nquit\n');
    });
  });

  group('slicers read the model path from the script file', () {
    test('cura slices the model to out.gcode', () async {
      final script = File('${tempDir.path}/model.obj');
      await script.writeAsString('model.obj\n');
      expect(cfg('cura').args(script.path, tempDir),
          ['slice', '-v', 'model.obj', '-o', '${tempDir.path}/out.gcode']);
    });

    test('prusaslicer and orcaslicer export gcode from the model', () async {
      final script = File('${tempDir.path}/model.stl');
      await script.writeAsString('model.stl\n');
      expect(cfg('prusaslicer').args(script.path, tempDir),
          ['--export-gcode', 'model.stl', '-o', '${tempDir.path}/out.gcode']);
      expect(cfg('orcaslicer').args(script.path, tempDir),
          ['--slice', '--output', '${tempDir.path}/out.gcode', 'model.stl']);
    });

    test('chitubox and lychee slice to their own formats', () async {
      final script = File('${tempDir.path}/model.stl');
      await script.writeAsString('model.stl\n');
      expect(cfg('chitubox').args(script.path, tempDir),
          ['--slice', '--output', '${tempDir.path}/out.ctb', 'model.stl']);
      expect(cfg('lychee').args(script.path, tempDir),
          ['--slice', '--output', '${tempDir.path}/out.gcode', 'model.stl']);
    });

    test('simplify3d escapes XML special chars in the factory file', () async {
      final script = File('${tempDir.path}/model.stl');
      await script.writeAsString('a<b&c"d\'e>.stl\n');
      final args = cfg('simplify3d').args(script.path, tempDir);
      final factory = File(args[1]);
      expect(factory.existsSync(), isTrue);
      final xml = factory.readAsStringSync();
      expect(xml, contains('&lt;'));
      expect(xml, contains('&amp;'));
      expect(xml, contains('&quot;'));
      expect(xml, contains('&apos;'));
      expect(xml, contains('&gt;'));
      expect(xml, contains('<setting key="outputDirectory">${tempDir.path}'));
    });
  });

  group('solidworks vbs wrapper', () {
    test('wraps the script and returns cscript args', () async {
      final script = File('${tempDir.path}/macro.vbs');
      await script.writeAsString('MsgBox "hi"');
      final args = cfg('solidworks').args(script.path, tempDir);
      final wrapper = File(args[1]);
      expect(args, ['//nologo', wrapper.path]);
      final content = wrapper.readAsStringSync();
      expect(content, contains('MsgBox "hi"'));
      expect(content, contains('MACRO_COMPLETE'));
      expect(content, contains('SldWorks.Application'));
    });
  });

  group('simple pass-through CLIs', () {
    test('pass the script path through with the expected flag', () {
      expect(cfg('rhino').args('x.py', tempDir), ['-runscript', 'x.py']);
      expect(cfg('sketchup').args('x.rb', tempDir), ['-RubyStartup', 'x.rb']);
      expect(cfg('sketch').args('x.js', tempDir), ['run', 'x.js']);
      expect(cfg('photoshop').args('x.jsx', tempDir), ['x.jsx']);
      expect(cfg('illustrator').args('x.jsx', tempDir), ['x.jsx']);
      expect(cfg('fusion360').args('x.py', tempDir), ['-p', 'x.py']);
    });
  });

  test('executorPathOverrideKey derives from the plugin id', () {
    expect(executorPathOverrideKey('blender'), 'executor_path_override_blender');
    expect(executorPathOverrideKey('freecad'), 'executor_path_override_freecad');
  });
}

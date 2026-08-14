import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/session.dart';

class StubPlugin extends DesignPlugin {
  final String _id;
  StubPlugin(this._id);

  @override String get id => _id;
  @override String get name => 'Stub $_id';
  @override String get version => '0.0.1';
  @override DesignCategory get category => DesignCategory.web;
  @override String get scriptLanguage => 'javascript';
  @override SoftwareCapabilities get capabilities => const SoftwareCapabilities(actions: [], fileFormats: []);

  @override Future<bool> initialize(PluginContext ctx) async => true;
  @override Future<void> dispose() async {}
  @override Future<ConnectionStatus> checkConnection() async => ConnectionStatus.disconnected;
  @override Future<bool> connect(ConnectionConfig config) async => true;
  @override Future<ScriptResult> execute(String script, {ProgressCallback? onProgress, String? key}) async => ScriptResult.success();
  @override Future<ScriptResult> preview(String script) async => ScriptResult.success();
  @override Future<SoftwareState> getCurrentState() async => const SoftwareState();
}

void main() {
  test('register adds plugin to registry', () {
    final manager = PluginManager();
    manager.register(StubPlugin('test.1'));
    expect(manager.getAll().length, 1);
  });

  test('get returns plugin by id', () {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    expect(manager.get('b')?.id, 'b');
  });

  test('get returns null for unknown id', () {
    final manager = PluginManager();
    expect(manager.get('nonexistent'), isNull);
  });

  test('getByCategory filters plugins', () {
    final manager = PluginManager();
    manager.register(StubPlugin('web.1'));
    manager.register(StubPlugin('web.2'));
    expect(manager.getByCategory(DesignCategory.web).length, 2);
  });

  test('unregister removes plugin', () {
    final manager = PluginManager();
    final plugin = StubPlugin('to.remove');
    manager.register(plugin);
    manager.unregister('to.remove');
    expect(manager.getAll().length, 0);
  });

  test('initializeAll calls initialize on all plugins', () async {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    await manager.initializeAll(const PluginContext(pluginPath: '/tmp'));
  });

  test('disposeAll disposes all plugins and clears registry', () async {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    await manager.initializeAll(const PluginContext(pluginPath: '/tmp'));
    await manager.disposeAll();
    expect(manager.getAll().length, 0);
  });

  test('disposeAll disposes each plugin once and clears registry', () async {
    final manager = PluginManager();
    final disposed = <String>[];
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    manager.register(_RecordingDisposePlugin('c', disposed));
    manager.register(StubPlugin('d'));
    await manager.disposeAll();

    expect(disposed, ['c']);
    expect(manager.getAll().length, 0);
    expect(manager.get('c'), isNull);
  });

  test('disposeAll continues when a plugin dispose throws', () async {
    final manager = PluginManager();
    final disposed = <String>[];
    manager.register(_ThrowingDisposePlugin('bad'));
    manager.register(_RecordingDisposePlugin('good', disposed));
    await manager.disposeAll();

    // 坏插件的异常被吞掉，其余插件照常清理。
    expect(disposed, ['good']);
    expect(manager.getAll().length, 0);
  });

  test('registerExternal registers script-file plugin with package dir', () {
    final manager = PluginManager();
    final manifest = ExternalPluginManifest(
      id: 'ext.1',
      name: 'Ext One',
      version: '1.0.0',
      scriptLanguage: 'python',
      scripts: const ['scripts/run.py'],
    );
    manager.registerExternal(manifest, '/tmp/pkg/ext.1');
    expect(manager.get('ext.1'), isA<ExternalScriptPlugin>());
    expect(manager.externalPackageDir('ext.1'), '/tmp/pkg/ext.1');
    expect(manager.get('ext.1')?.name, 'Ext One');
  });

  test('registerExternal rejects empty id', () {
    final manager = PluginManager();
    expect(
      () => manager.registerExternal(
        const ExternalPluginManifest(id: '', name: '', version: '0', scriptLanguage: ''),
        '/tmp/x',
      ),
      throwsArgumentError,
    );
  });

  test('ExternalPluginManifest.fromJson parses plugin.json', () {
    final m = ExternalPluginManifest.fromJson({
      'id': 'p1',
      'name': 'P1',
      'version': '2.0.0',
      'category': 'ad',
      'script_language': 'js',
      'capabilities': {'actions': ['export'], 'file_formats': ['png']},
      'scripts': ['a.js'],
    });
    expect(m.id, 'p1');
    expect(m.category, DesignCategory.ad);
    expect(m.scriptLanguage, 'js');
    expect(m.capabilities.actions, ['export']);
    expect(m.scripts, ['a.js']);
  });

  test('ExternalPluginManifest.fromYaml parses pubspec with design_plugin section', () {
    final m = ExternalPluginManifest.fromYaml('''
name: my_plugin
version: 1.0.0
description: A test plugin
design_plugin:
  category: threeD
  script_language: python
  scripts: [scripts/a.py]
''');
    expect(m.id, 'my_plugin');
    expect(m.description, 'A test plugin');
    expect(m.category, DesignCategory.threeD);
    expect(m.scriptLanguage, 'python');
    expect(m.scripts, ['scripts/a.py']);
  });

  test('PluginPackageCodec export/import round-trip', () async {
    final temp = await Directory.systemTemp.createTemp('plugin_pkg');
    addTearDown(() => temp.delete(recursive: true));
    final pkgDir = '${temp.path}/pkg';
    final scriptFile = File('$pkgDir/scripts/run.py');
    await scriptFile.create(recursive: true);
    await scriptFile.writeAsString('print("hi")');

    final zipPath = '${temp.path}/out.zip';
    await PluginPackageCodec.exportToZip(
      StubPlugin('ext_pkg_1'),
      packageDir: pkgDir,
      description: 'Round trip plugin',
      zipPath: zipPath,
    );

    final result = await PluginPackageCodec.importFromZip(zipPath, '${temp.path}/imported');
    expect(result.manifest.id, 'ext_pkg_1');
    expect(result.manifest.name, 'Stub ext_pkg_1');
    expect(result.manifest.description, 'Round trip plugin');
    expect(result.manifest.scripts, ['scripts/run.py']);
    expect(
      await File('${result.packageDir}/scripts/run.py').readAsString(),
      'print("hi")',
    );

    final manager = PluginManager();
    manager.registerExternal(result.manifest, result.packageDir);
    expect(manager.get('ext_pkg_1'), isA<ExternalScriptPlugin>());
    expect(manager.externalPackageDir('ext_pkg_1'), result.packageDir);
  });

  test('PluginPackageCodec rejects zip without manifest', () async {
    final temp = await Directory.systemTemp.createTemp('plugin_pkg_bad');
    addTearDown(() => temp.delete(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile('readme.txt', 9, utf8.encode('no plugin')));
    final bytes = ZipEncoder().encode(archive);
    final zipPath = '${temp.path}/bad.zip';
    await File(zipPath).writeAsBytes(bytes);

    expect(
      () => PluginPackageCodec.importFromZip(zipPath, '${temp.path}/dest'),
      throwsA(isA<FormatException>()),
    );
  });

  test('PluginPackageCodec skips backslash zip-slip traversal entries', () async {
    final temp = await Directory.systemTemp.createTemp('plugin_zip_slip');
    addTearDown(() => temp.delete(recursive: true));
    final archive = Archive()
      ..addFile(
        ArchiveFile('plugin.json', 0, utf8.encode(jsonEncode({
          'id': 'safe_plugin',
          'name': 'Safe',
          'version': '1.0.0',
        }))),
      )
      ..addFile(ArchiveFile('..\\evil.txt', 4, utf8.encode('evil')))
      ..addFile(ArchiveFile('..\\..\\escape.py', 6, utf8.encode('print')))
      ..addFile(ArchiveFile('C:\\win32\\pwn.py', 6, utf8.encode('print')))
      ..addFile(ArchiveFile('/abs/root.py', 7, utf8.encode('print')));
    final zipPath = '${temp.path}/slip.zip';
    await File(zipPath).writeAsBytes(ZipEncoder().encode(archive));

    final result =
        await PluginPackageCodec.importFromZip(zipPath, '${temp.path}/dest');
    expect(await File('${temp.path}/evil.txt').exists(), isFalse);
    expect(await File('${temp.path}/escape.py').exists(), isFalse);
    expect(await File('${temp.path}/win32/pwn.py').exists(), isFalse);
    expect(await File('${temp.path}/abs/root.py').exists(), isFalse);
    expect(await File('${result.packageDir}/evil.txt').exists(), isFalse);
    expect(result.manifest.id, 'safe_plugin');
  });

  test('PluginPackageCodec rejects manifest id with unsafe characters', () async {
    final temp = await Directory.systemTemp.createTemp('plugin_bad_id');
    addTearDown(() => temp.delete(recursive: true));
    final archive = Archive()
      ..addFile(
        ArchiveFile('plugin.json', 0, utf8.encode(jsonEncode({
          'id': '../evil',
          'name': 'Evil',
          'version': '1.0.0',
        }))),
      );
    final zipPath = '${temp.path}/bad_id.zip';
    await File(zipPath).writeAsBytes(ZipEncoder().encode(archive));

    await expectLater(
      PluginPackageCodec.importFromZip(zipPath, '${temp.path}/dest'),
      throwsA(isA<FormatException>()),
    );
    expect(await Directory('${temp.path}/dest').exists(), isFalse);
  });

  test('PluginPackageCodec rejects zip with too many entries', () async {
    final temp = await Directory.systemTemp.createTemp('plugin_zip_bomb');
    addTearDown(() => temp.delete(recursive: true));
    final archive = Archive();
    for (var i = 0; i < 201; i++) {
      archive.addFile(ArchiveFile('f$i.txt', 0, utf8.encode('x')));
    }
    final zipPath = '${temp.path}/bomb.zip';
    await File(zipPath).writeAsBytes(ZipEncoder().encode(archive));

    await expectLater(
      PluginPackageCodec.importFromZip(zipPath, '${temp.path}/dest'),
      throwsA(isA<FormatException>()),
    );
  });

  test('registerExternal rejects id already in use', () {
    final manager = PluginManager();
    const manifest =
        ExternalPluginManifest(id: 'dup_1', name: 'A', version: '0', scriptLanguage: '');
    manager.registerExternal(manifest, '/tmp/a');
    expect(
      () => manager.registerExternal(manifest, '/tmp/b'),
      throwsArgumentError,
    );
  });
}

class _RecordingDisposePlugin extends StubPlugin {
  final List<String> disposed;
  _RecordingDisposePlugin(super.id, this.disposed);

  @override
  Future<void> dispose() async {
    disposed.add(id);
  }
}

class _ThrowingDisposePlugin extends StubPlugin {
  _ThrowingDisposePlugin(super.id);

  @override
  Future<void> dispose() async {
    throw Exception('dispose failed');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/artifact_verifier.dart';
import 'package:ai_design_studio/models/plugin.dart';

void main() {
  group('ScriptResult.success', () {
    test('creates a successful result with defaults', () {
      final r = ScriptResult.success();
      expect(r.success, isTrue);
      expect(r.output, isNull);
      expect(r.error, isNull);
      expect(r.artifacts, isEmpty);
      expect(r.metadata, isNull);
      expect(r.manualFallback, isFalse);
    });

    test('forwards output, artifacts and metadata', () {
      final r = ScriptResult.success(
        output: 'done in 2s',
        artifacts: ['a.png', 'b.png'],
        metadata: {'nodes': 3},
      );
      expect(r.output, 'done in 2s');
      expect(r.artifacts, ['a.png', 'b.png']);
      expect(r.metadata, {'nodes': 3});
    });

    test('manualFallback flag is forwarded', () {
      final r = ScriptResult.success(manualFallback: true);
      expect(r.manualFallback, isTrue);
    });
  });

  group('ScriptResult.failure', () {
    test('creates a failure with the error and no artifacts', () {
      final r = ScriptResult.failure(error: 'exit 1');
      expect(r.success, isFalse);
      expect(r.error, 'exit 1');
      expect(r.output, isNull);
      expect(r.artifacts, isEmpty);
      expect(r.metadata, isNull);
      expect(r.manualFallback, isFalse);
    });
  });

  group('manualFallback drives ArtifactVerifier skip semantics', () {
    test('manual fallback success skips marker and artifact checks', () async {
      const verifier = ArtifactVerifier();
      final result = await verifier.verify(ScriptResult.success(
        output: '请手动执行以下步骤... ERROR note',
        manualFallback: true,
        artifacts: ['/nonexistent/never-created.png'],
      ));
      expect(result.passed, isTrue);
      expect(result.summary, contains('手动执行回退'));
    });
  });

  group('PluginMeta', () {
    test('is a const value object with all fields', () {
      const meta = PluginMeta(
        id: 'blender',
        name: 'Blender',
        version: '4.2',
        scriptLanguage: 'python',
      );
      expect(meta.id, 'blender');
      expect(meta.name, 'Blender');
      expect(meta.version, '4.2');
      expect(meta.scriptLanguage, 'python');
    });
  });

  group('ConnectionConfig', () {
    test('is a const value object with optional extra', () {
      const config = ConnectionConfig(host: '127.0.0.1', port: 8080);
      expect(config.host, '127.0.0.1');
      expect(config.port, 8080);
      expect(config.extra, isNull);

      const withExtra = ConnectionConfig(
        host: 'h', port: 1, extra: {'token': 'abc'});
      expect(withExtra.extra, {'token': 'abc'});
    });
  });

  test('ConnectionStatus has all connection states', () {
    expect(ConnectionStatus.values, [
      ConnectionStatus.disconnected,
      ConnectionStatus.connecting,
      ConnectionStatus.connected,
      ConnectionStatus.error,
    ]);
  });
}

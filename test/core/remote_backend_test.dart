import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ai_design_studio/core/remote_backend.dart';

void main() {
  const caps = <String, dynamic>{'actions': ['创建矩形']};
  const state = <String, dynamic>{'activeDocument': 'test.fig'};

  test('extracts script from markdown code block', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example.com/v1/chat/completions');
      expect(request.headers['Authorization'], 'Bearer test-key');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect((body['messages'] as List).length, 2);
      expect((body['messages'][0] as Map)['role'], 'system');
      return http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': '```javascript\ncreateRectangle();\n```'}}
          ]
        }),
        200,
      );
    });
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1/',
      apiKey: 'test-key',
      model: 'gpt-4o-mini',
      client: client,
    );
    final result = await backend.execute(
      task: 'create a rectangle',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isTrue);
    expect(result.script, 'createRectangle();');
    expect(result.modelUsed, 'gpt-4o-mini');
  });

  test('keeps URL already ending with /chat/completions', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example.com/v1/chat/completions');
      return http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': 'plain text script'}}
          ]
        }),
        200,
      );
    });
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1/chat/completions',
      apiKey: '',
      client: client,
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isTrue);
    expect(result.script, 'plain text script');
  });

  test('fails on HTTP error status', () async {
    final client = MockClient((request) async {
      return http.Response('{"error": {"message": "invalid api key"}}', 401);
    });
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1',
      apiKey: 'wrong-key',
      client: client,
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isFalse);
    expect(result.error, contains('Remote endpoint error 401'));
  });

  test('fails when response has no choices content', () async {
    final client = MockClient((request) async {
      return http.Response('{"error": "model not found"}', 200);
    });
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      client: client,
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isFalse);
    expect(result.error, contains('no script'));
  });

  test('fails on timeout', () async {
    final client = MockClient((request) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return http.Response('{"choices": []}', 200);
    });
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      timeout: const Duration(milliseconds: 10),
      client: client,
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isFalse);
    expect(result.error, contains('request failed'));
  });

  test('isAvailable only needs a configured URL', () async {
    final configured = RemoteBackend(endpointUrl: 'https://api.example.com/v1', apiKey: '');
    final empty = RemoteBackend(endpointUrl: '', apiKey: '');
    expect(await configured.isAvailable(), isTrue);
    expect(await empty.isAvailable(), isFalse);
  });

  test('cancel before execute returns failure', () async {
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1',
      apiKey: '',
      client: MockClient((request) async => http.Response('{}', 200)),
    );
    backend.cancel();
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isFalse);
    expect(result.error, contains('cancelled'));
  });

  test('cancel with key only affects that task, new task still runs', () async {
    final backend = RemoteBackend(
      endpointUrl: 'https://api.example.com/v1',
      apiKey: '',
      client: MockClient((request) async => http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'ok();'}}
              ]
            }),
            200,
          )),
    );
    backend.cancel(key: 'task-1');
    final cancelled = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
      key: 'task-1',
    );
    expect(cancelled.success, isFalse);
    expect(cancelled.error, contains('cancelled'));

    final fresh = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
      key: 'task-2',
    );
    expect(fresh.success, isTrue);
    expect(fresh.script, 'ok();');
  });

  test('rejects non-https endpoint outside loopback', () async {
    final backend = RemoteBackend(
      endpointUrl: 'http://api.example.com/v1',
      apiKey: 'key',
      client: MockClient((request) async => http.Response('{}', 200)),
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isFalse);
    expect(result.error, contains('HTTPS'));
  });

  test('allows http on loopback address', () async {
    final backend = RemoteBackend(
      endpointUrl: 'http://127.0.0.1:8787/v1',
      apiKey: '',
      client: MockClient((request) async => http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': 'local();'}}
              ]
            }),
            200,
          )),
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: caps,
      state: state,
    );
    expect(result.success, isTrue);
    expect(result.script, 'local();');
  });

  test('dispose closes the underlying http client', () {
    final backend = RemoteBackend(endpointUrl: 'https://api.example.com/v1', apiKey: '');
    expect(() => backend.dispose(), returnsNormally);
  });
}

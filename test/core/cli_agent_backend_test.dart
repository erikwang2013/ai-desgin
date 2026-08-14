// test/core/cli_agent_backend_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/agent_backend.dart';
import 'package:ai_design_studio/core/cli_agent_backend.dart';

/// 用可注入的 fake 可执行文件做端到端测试：
/// CliAgentBackend 的 command/args 可注入，无需安装 opencode/openclaw 等真实 CLI。
File _writeFakeCli(String name, String body) {
  final dir = Directory.systemTemp.createTempSync('cli_agent_');
  final file = File('${dir.path}/$name');
  file.writeAsStringSync('#!/bin/sh\n$body\n');
  Process.runSync('chmod', ['+x', file.path]);
  return file;
}

Future<void> _waitForFile(File file, {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!file.existsSync()) {
    if (DateTime.now().isAfter(deadline)) fail('expected $file was never created');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('success path extracts script from markdown code block', () async {
    final cli = _writeFakeCli(
      'ok.sh',
      'printf \'%s\\n\' \'```javascript\' \'alert(1);\' \'```\'',
    );
    final backend = CliAgentBackend(
      id: 'fake',
      displayName: 'FakeAgent',
      command: cli.path,
      args: (p) => ['run', p],
    );
    final result = await backend.execute(
      task: 'make an alert',
      software: 'figma',
      capabilities: const {'actions': ['alert']},
      state: const {},
      scriptLanguage: 'javascript',
    );
    expect(result.success, isTrue);
    expect(result.script, 'alert(1);');
  });

  test('fails with stderr when the CLI exits non-zero', () async {
    final cli = _writeFakeCli(
      'fail.sh',
      'cat > /dev/null\nprintf "boom: bad args" >&2\nexit 3',
    );
    final backend = CliAgentBackend(
      id: 'fake',
      displayName: 'FakeAgent',
      command: cli.path,
      args: (p) => [p],
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: const {},
      state: const {},
    );
    expect(result.success, isFalse);
    expect(result.error, contains('exited with code 3'));
    expect(result.error, contains('boom: bad args'));
  });

  test('cancel with key kills the running process', () async {
    final dir = Directory.systemTemp.createTempSync('cli_agent_cancel_');
    final pidFile = File('${dir.path}/pid');
    final cli = _writeFakeCli(
      'slow.sh',
      'cat > /dev/null\necho \$\$ > ${pidFile.path}\nexec sleep 60',
    );
    final backend = CliAgentBackend(
      id: 'fake',
      displayName: 'FakeAgent',
      command: cli.path,
      args: (p) => [p],
    );
    final exec = backend.execute(
      task: 'slow',
      software: 'figma',
      capabilities: const {},
      state: const {},
      key: 'k',
    );
    await _waitForFile(pidFile);
    backend.cancel(key: 'k');

    final result = await exec;
    expect(result.success, isFalse);
    final pid = int.parse((await pidFile.readAsString()).trim());
    final alive = await Process.run('kill', ['-0', '$pid']);
    expect(alive.exitCode, isNot(0), reason: 'subprocess should have been killed');
  });

  test('replacing a task with the same key kills the old process', () async {
    final dir = Directory.systemTemp.createTempSync('cli_agent_replace_');
    final pidFile = File('${dir.path}/pid');
    // 同 key 替换：旧任务（prompt 含 'old'）挂起，新任务（含 'new'）立即成功。
    final cli = _writeFakeCli(
      'branch.sh',
      'case "\$*" in\n'
      '  *old*) echo \$\$ > ${pidFile.path}; exec sleep 60 ;;\n'
      '  *new*) printf \'%s\\n\' \'```javascript\' \'ok();\' \'```\' ;;\n'
      'esac',
    );
    final backend = CliAgentBackend(
      id: 'fake',
      displayName: 'FakeAgent',
      command: cli.path,
      args: (p) => [p],
    );
    final first = backend.execute(
      task: 'old',
      software: 'figma',
      capabilities: const {},
      state: const {},
      key: 'k',
    );
    await _waitForFile(pidFile);
    final oldPid = int.parse((await pidFile.readAsString()).trim());
    await pidFile.delete();

    // 同 key 新任务应替换旧任务；旧任务必须失败而非挂起。
    final second = backend.execute(
      task: 'new',
      software: 'figma',
      capabilities: const {},
      state: const {},
      key: 'k',
    );
    final firstResult = await first;
    expect(firstResult.success, isFalse, reason: 'replaced task must fail');
    final alive = await Process.run('kill', ['-0', '$oldPid']);
    expect(alive.exitCode, isNot(0), reason: 'old subprocess should have been killed');
    final secondResult = await second;
    expect(secondResult.success, isTrue);
  });

  test('injects modelArgs when a model is given', () async {
    final cli = _writeFakeCli(
      'echo_args.sh',
      'cat > /dev/null\nprintf "%s" "\$@"',
    );
    final backend = CliAgentBackend(
      id: 'fake',
      displayName: 'FakeAgent',
      command: cli.path,
      args: (p) => ['run', p],
      modelArgs: (m) => m == null ? const [] : ['--model', m],
    );
    final result = await backend.execute(
      task: 't',
      software: 'figma',
      capabilities: const {},
      state: const {},
      model: 'haiku',
    );
    expect(result.success, isTrue);
    expect(result.script, contains('--model'));
    expect(result.script, contains('haiku'));
    expect(result.script, contains('TASK: t'));
  });

  group('shared prompt/script helpers (Codex/Gemini/CLI common)', () {
    test('buildCodeBlockPrompt embeds software, capabilities and state', () {
      final prompt = buildCodeBlockPrompt(
        task: 'draw a square',
        software: 'freecad',
        capabilities: const {'actions': ['create_sketch']},
        state: const {'activeDocument': 'part.fcstd'},
        scriptLanguage: 'python',
      );
      expect(prompt, contains('draw a square'));
      expect(prompt, contains('freecad'));
      expect(prompt, contains('create_sketch'));
      expect(prompt, contains('part.fcstd'));
      expect(prompt, contains('python'));
    });

    test('extractScriptFromMarkdown returns block content or null', () {
      expect(
        extractScriptFromMarkdown('prefix\n```python\nprint(1)\n```\nsuffix'),
        'print(1)',
      );
      expect(extractScriptFromMarkdown('no code block here'), isNull);
      expect(extractScriptFromMarkdown('```\n```'), isNull,
          reason: 'empty block is not a script');
    });
  });
}

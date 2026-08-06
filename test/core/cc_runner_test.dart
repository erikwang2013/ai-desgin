// test/core/cc_runner_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/cc_runner.dart';

void main() {
  test('CCRunner builds correct prompt', () {
    final runner = CCRunner();

    final prompt = runner.buildPromptForTest(
      task: 'create a blue rectangle',
      software: 'figma',
      capabilities: {'actions': ['创建矩形', '设置填充色'], 'fileFormats': ['png']},
      state: {'activeDocument': 'test.fig'},
    );

    expect(prompt, contains('create a blue rectangle'));
    expect(prompt, contains('figma'));
    expect(prompt, contains('创建矩形'));
    expect(prompt, contains('test.fig'));
  });

  test('CCResult.fromJson parses correctly', () {
    final json = {
      'script': 'createRectangle()',
      'scriptLanguage': 'javascript',
      'explanation': '创建一个矩形',
      'modelUsed': 'claude-sonnet-4-6',
    };
    final result = CCResult.fromJson(json);
    expect(result.script, 'createRectangle()');
    expect(result.scriptLanguage, 'javascript');
    expect(result.explanation, '创建一个矩形');
    expect(result.success, true);
  });

  test('CCResult.failure has error and success=false', () {
    final result = CCResult.failure('timeout');
    expect(result.success, false);
    expect(result.error, 'timeout');
  });

  test('prompt includes response language instruction when set', () {
    CCRunner.responseLanguage = '请使用中文回复。';
    final runner = CCRunner();

    final prompt = runner.buildPromptForTest(
      task: 'create a button',
      software: 'figma',
      capabilities: const {'actions': ['创建按钮']},
      state: const {},
    );

    expect(prompt, contains('请使用中文回复。'));
    CCRunner.responseLanguage = null;
  });

  test('prompt omits language instruction when not set', () {
    CCRunner.responseLanguage = null;
    final prompt = CCRunner().buildPromptForTest(
      task: 'create a button',
      software: 'figma',
      capabilities: const {},
      state: const {},
    );
    expect(prompt.contains('请使用中文回复。'), isFalse);
  });

  test('execute kills the subprocess on timeout instead of leaking it', () async {
    final dir = Directory.systemTemp.createTempSync('cc_runner_timeout_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final pidFile = File('${dir.path}/pid');
    final fakeCli = File('${dir.path}/fake_claude.sh');
    fakeCli.writeAsStringSync(
        '#!/bin/sh\necho \$\$ > ${pidFile.path}\nexec sleep 30\n');
    Process.runSync('chmod', ['+x', fakeCli.path]);

    final runner = CCRunner(
      claudeCliPath: fakeCli.path,
      timeout: const Duration(seconds: 1),
    );
    final result = await runner.execute(
      task: 'slow task',
      software: 'figma',
      capabilities: const {},
      state: const {},
    );

    expect(result.success, isFalse);
    final pid = int.parse((await pidFile.readAsString()).trim());
    final alive = await Process.run('kill', ['-0', '$pid']);
    expect(alive.exitCode, isNot(0), reason: 'subprocess should have been killed');
  });
}

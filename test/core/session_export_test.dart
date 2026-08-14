import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/session_store.dart';
import 'package:ai_design_studio/models/session.dart';
import 'package:ai_design_studio/models/task_record.dart';

void main() {
  test('exportSessionsToJson writes sessions with records to a file', () async {
    final session = Session(
      domain: DesignCategory.interior,
      softwareName: 'blender',
      context: SessionContext(
        softwareState: {'zoom': 1.5},
        userPreferences: {'theme': 'dark'},
        recentActions: const ['rotate', 'scale'],
      ),
    );
    session.addRecord(
      task: 'create sofa',
      script: 'bpy.ops.mesh.primitive_cube_add()',
      scriptLanguage: 'python',
      modelUsed: 'claude-sonnet-4-6',
      status: TaskStatus.completed,
    );

    final dir = await Directory.systemTemp.createTemp('ai_design_export_test');
    final file = File('${dir.path}/history.json');
    try {
      await file.writeAsString(SessionStore.exportSessionsToJson([session]));

      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(data['app'], 'ai-design');
      expect(data['exportedAt'], isNotEmpty);

      final sessions = data['sessions'] as List;
      expect(sessions, hasLength(1));
      final s = sessions.first as Map<String, dynamic>;
      expect(s['id'], session.id);
      expect(s['domain'], 'interior');
      expect(s['softwareName'], 'blender');
      expect(s['createdAt'], session.createdAt.toIso8601String());

      final ctx = s['context'] as Map<String, dynamic>;
      expect(ctx['softwareState'], {'zoom': 1.5});
      expect(ctx['userPreferences'], {'theme': 'dark'});
      expect(ctx['recentActions'], ['rotate', 'scale']);

      final records = s['records'] as List;
      expect(records, hasLength(1));
      final r = records.first as Map<String, dynamic>;
      expect(r['id'], session.history.first.id);
      expect(r['sessionId'], session.id);
      expect(r['task'], 'create sofa');
      expect(r['script'], 'bpy.ops.mesh.primitive_cube_add()');
      expect(r['scriptLanguage'], 'python');
      expect(r['modelUsed'], 'claude-sonnet-4-6');
      expect(r['status'], 'completed');
      expect(r['artifacts'], isEmpty);
      expect(r['iterations'], 1);
      expect(r['maxIterations'], 1);
      expect(r['completedAt'], isNull);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('exportSessionsToJson covers nullable record fields', () {
    final session = Session(domain: DesignCategory.web, softwareName: 'figma');
    session.history.add(TaskRecord(
      sessionId: session.id,
      task: 'rename layer',
      status: TaskStatus.failed,
      error: 'timeout',
      artifacts: const ['/tmp/a.png'],
      iterations: 3,
      maxIterations: 5,
      iterationLog: const ['step1', 'step2'],
    ));

    final data =
        jsonDecode(SessionStore.exportSessionsToJson([session])) as Map<String, dynamic>;
    final records =
        ((data['sessions'] as List).first as Map<String, dynamic>)['records'] as List;
    expect(records, hasLength(1));
    final r = records.first as Map<String, dynamic>;
    expect(r['status'], 'failed');
    expect(r['error'], 'timeout');
    expect(r['artifacts'], ['/tmp/a.png']);
    expect(r['iterations'], 3);
    expect(r['maxIterations'], 5);
    expect(r['iterationLog'], ['step1', 'step2']);
    expect(r['script'], isNull);
    expect(r['scriptLanguage'], isNull);
    expect(r['completedAt'], isNull);
  });

  test('exportSessionsToJson handles empty session list', () {
    final data = jsonDecode(SessionStore.exportSessionsToJson([])) as Map<String, dynamic>;
    expect(data['sessions'], isEmpty);
  });
}

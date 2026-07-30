import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/models/session.dart';
import 'package:ai_design_studio/models/task_record.dart';

void main() {
  test('Session should generate unique id on creation', () {
    final s1 = Session(domain: DesignCategory.web, softwareName: 'Figma');
    final s2 = Session(domain: DesignCategory.web, softwareName: 'Figma');
    expect(s1.id, isNot(s2.id));
  });

  test('Session should record createdAt on creation', () {
    final before = DateTime.now();
    final s = Session(domain: DesignCategory.industrial, softwareName: 'Blender');
    expect(s.createdAt.isAfter(before), true);
  });

  test('addRecord appends to history and returns record', () {
    final s = Session(domain: DesignCategory.threeD, softwareName: 'Blender');
    final record = s.addRecord(
      task: 'create a cube',
      script: 'import bpy; bpy.ops.mesh.primitive_cube_add()',
      scriptLanguage: 'python',
      modelUsed: 'claude-sonnet-4-6',
    );
    expect(s.history.length, 1);
    expect(record.task, 'create a cube');
    expect(record.status, TaskStatus.completed);
  });
}

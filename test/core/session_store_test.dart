import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ai_design_studio/core/session_store.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  late SessionStore store;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: SessionStore.onCreate,
    );
    store = SessionStore(db);
  });

  tearDown(() async => db.close());

  test('save and load session preserves data', () async {
    final session = Session(domain: DesignCategory.web, softwareName: 'figma');
    session.addRecord(task: 'create button', script: 'createNode("BUTTON")', scriptLanguage: 'javascript', modelUsed: 'claude-sonnet-4-6');
    await store.save(session);
    final loaded = await store.load(session.id);
    expect(loaded, isNotNull);
    expect(loaded!.id, session.id);
    expect(loaded.domain, DesignCategory.web);
  });

  test('load returns null for unknown id', () async {
    final result = await store.load('nonexistent');
    expect(result, isNull);
  });

  test('listBySoftware filters sessions', () async {
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    await store.save(Session(domain: DesignCategory.threeD, softwareName: 'blender'));
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    final figmas = await store.listBySoftware('figma');
    expect(figmas.length, 2);
  });

  test('search finds sessions by task content', () async {
    final s = Session(domain: DesignCategory.web, softwareName: 'figma');
    s.addRecord(task: 'create a blue login button', script: '', scriptLanguage: '', modelUsed: '');
    await store.save(s);
    final results = await store.search('login');
    expect(results.length, 1);
  });

  test('delete removes session', () async {
    final s = Session(domain: DesignCategory.web, softwareName: 'figma');
    await store.save(s);
    await store.delete(s.id);
    expect(await store.load(s.id), isNull);
  });
}

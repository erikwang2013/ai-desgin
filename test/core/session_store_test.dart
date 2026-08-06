import 'package:flutter_test/flutter_test.dart';
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

  test('load tolerates corrupt task records instead of throwing', () async {
    final session = Session(domain: DesignCategory.web, softwareName: 'figma');
    session.addRecord(task: 'good', script: '', scriptLanguage: '', modelUsed: 'haiku');
    await store.save(session);
    // 注入坏记录：坏 artifacts JSON + 坏日期。
    await db.rawInsert(
      'INSERT INTO task_records (id, session_id, task, status, artifacts_json, created_at) '
      "VALUES ('bad1', ?, 'corrupt', 'completed', '{bad json', 'bad-date')",
      [session.id],
    );
    final loaded = await store.load(session.id);
    expect(loaded, isNotNull);
    expect(loaded!.history, hasLength(1));
  });

  test('listRecent tolerates corrupt session rows', () async {
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    await db.rawInsert(
      "INSERT INTO sessions (id, domain, software_name, context_json, created_at) "
      "VALUES ('s2', 'web', 'figma', '{bad json', 'bad-date')",
    );
    final recent = await store.listRecent(limit: 10);
    expect(recent, hasLength(2));
    final corrupted = recent.firstWhere((s) => s.id == 's2');
    expect(corrupted.history, isEmpty);
  });

  test('listBySoftware filters sessions', () async {
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    await store.save(Session(domain: DesignCategory.threeD, softwareName: 'blender'));
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    final figmas = await store.listBySoftware('figma');
    expect(figmas.length, 2);
  });

  test('listRecent returns sessions with history newest first', () async {
    final s1 = Session(domain: DesignCategory.web, softwareName: 'figma');
    s1.addRecord(task: 'task one', script: '', scriptLanguage: '', modelUsed: 'haiku');
    await store.save(s1);
    final s2 = Session(domain: DesignCategory.threeD, softwareName: 'blender');
    s2.addRecord(task: 'task two', script: '', scriptLanguage: '', modelUsed: 'opus');
    await store.save(s2);

    final recent = await store.listRecent(limit: 10);
    expect(recent.length, 2);
    final ids = recent.map((s) => s.id).toList();
    expect(ids.contains(s1.id), isTrue);
    expect(ids.contains(s2.id), isTrue);
    expect(recent.first.softwareName, s2.softwareName);
    expect(recent.first.history.single.task, 'task two');
    expect(recent.first.history.single.modelUsed, 'opus');
  });

  test('search finds sessions by task content', () async {
    final s = Session(domain: DesignCategory.web, softwareName: 'figma');
    s.addRecord(task: 'create a blue login button', script: '', scriptLanguage: '', modelUsed: '');
    await store.save(s);
    final results = await store.search('login');
    expect(results.length, 1);
  });

  test('search treats % and _ literally (LIKE escaping)', () async {
    final withPercent = Session(domain: DesignCategory.web, softwareName: 'figma');
    withPercent.addRecord(task: 'export 50%_off image', script: '', scriptLanguage: '', modelUsed: '');
    await store.save(withPercent);
    final noUnderscore = Session(domain: DesignCategory.web, softwareName: 'figma');
    noUnderscore.addRecord(task: 'turn off light', script: '', scriptLanguage: '', modelUsed: '');
    await store.save(noUnderscore);

    final byPercent = await store.search('50%');
    expect(byPercent.length, 1);
    expect(byPercent.single.id, withPercent.id);

    // '_off' must match the literal underscore, not any character before 'off'.
    final byUnderscore = await store.search('_off');
    expect(byUnderscore.length, 1);
    expect(byUnderscore.single.id, withPercent.id);
  });

  test('delete removes session', () async {
    final s = Session(domain: DesignCategory.web, softwareName: 'figma');
    await store.save(s);
    await store.delete(s.id);
    expect(await store.load(s.id), isNull);
  });
}

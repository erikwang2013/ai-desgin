import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' hide Session;
import 'package:ai_design_studio/core/db_opener.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String docPath;
  final String supportPath;

  _FakePathProvider({required this.docPath, required this.supportPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => docPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

void main() {
  late Directory docDir;
  late Directory supportDir;
  late PathProviderPlatform original;

  setUp(() async {
    docDir = await Directory.systemTemp.createTemp('db_opener_doc');
    supportDir = await Directory.systemTemp.createTemp('db_opener_support');
    original = PathProviderPlatform.instance;
    PathProviderPlatform.instance =
        _FakePathProvider(docPath: docDir.path, supportPath: supportDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = original;
    await docDir.delete(recursive: true);
    await supportDir.delete(recursive: true);
  });

  // 探测测试环境里 sqlite3 原生库是否带 SQLCipher（与 SUT 用同一库，判定一致）。
  bool sqlcipherAvailable() {
    final db = sqlite3.openInMemory();
    try {
      final rows = db.select('PRAGMA cipher_version');
      return rows.isNotEmpty && (rows.first.values.first?.toString().isNotEmpty ?? false);
    } catch (_) {
      return false;
    } finally {
      db.close();
    }
  }

  String readAuthFile() => File('${supportDir.path}/auth.json').readAsStringSync();

  test('first open creates a 64-hex password in auth.json', () async {
    final db = await openEncryptedSessionDb();
    db?.close();
    final saved = jsonDecode(readAuthFile()) as Map<String, dynamic>;
    expect(saved['password'], matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('reuses the existing auth password across opens', () async {
    final db1 = await openEncryptedSessionDb();
    db1?.close();
    final first = readAuthFile();
    final db2 = await openEncryptedSessionDb();
    db2?.close();
    expect(readAuthFile(), first);
  });

  test('backs up corrupt auth.json and regenerates the password', () async {
    File('${supportDir.path}/auth.json').writeAsStringSync('{not json');
    final db = await openEncryptedSessionDb();
    db?.close();
    final backups = supportDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('.corrupt-'))
        .toList();
    expect(backups, hasLength(1));
    final saved = jsonDecode(readAuthFile()) as Map<String, dynamic>;
    expect(saved['password'], matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('restricts auth file permissions to owner-only on POSIX', () async {
    if (Platform.isWindows) return;
    final db = await openEncryptedSessionDb();
    db?.close();
    final mode = File('${supportDir.path}/auth.json').statSync().mode & 0x1FF;
    expect(mode, 0x180);
  });

  test('opens a migrated db with correct key when SQLCipher is available', () async {
    final db = await openEncryptedSessionDb();
    if (!sqlcipherAvailable()) {
      // SQLCipher 构建缺失时契约是禁用历史会话，绝不静默降级明文。
      expect(db, isNull, reason: 'SQLCipher unavailable must return null');
      return;
    }
    expect(db, isNotNull);
    // 能查通 sqlite_master 说明密钥探测通过；表已建说明迁移执行了。
    final rows = db!.select("SELECT count(*) FROM sqlite_master WHERE type = 'table'");
    expect(rows.single.values.first, greaterThan(0));
    expect(File('${docDir.path}/sessions.db').existsSync(), isTrue);
    db.close();
  });

  test('backs up a corrupt db file and rebuilds a fresh one', () async {
    if (!sqlcipherAvailable()) return;
    // 预写垃圾字节模拟损坏库（非 SQLCipher 格式，密钥探测必然失败）。
    File('${docDir.path}/sessions.db').writeAsStringSync('not a sqlite database');
    final db = await openEncryptedSessionDb();
    expect(db, isNotNull, reason: 'corrupt db must be rebuilt, not permanently disabled');
    final backups = docDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('.corrupt-'))
        .toList();
    expect(backups, hasLength(1));
    // 损坏原样保留在备份中，供手动恢复。
    expect(backups.first.readAsStringSync(), 'not a sqlite database');
    final rows = db!.select("SELECT count(*) FROM sqlite_master WHERE type = 'table'");
    expect(rows.single.values.first, greaterThan(0));
    db.close();
  });
}

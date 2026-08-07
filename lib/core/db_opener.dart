import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' hide Session;
import 'session_store.dart';

final _log = Logger('DbOpener');

const _authFileName = 'auth.json';
const _dbFileName = 'sessions.db';
const _dbVersion = 1;

/// 首次创建数据库时生成随机密码并保存到本地 auth 文件，之后复用该密码。
/// 密码为 32 字节随机数转 64 位 hex，仅含 [0-9a-f]，可直接内嵌 SQL 字符串。
Future<String> _loadOrCreatePassword(String dir) async {
  final file = File('$dir/$_authFileName');
  if (file.existsSync()) {
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final saved = data['password'] as String?;
      if (saved != null && saved.isNotEmpty) return saved;
    } catch (_) {
      // 损坏的 auth 文件按不存在处理，重新生成。
    }
  }
  final rng = Random.secure();
  final password = List.generate(
    32,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  file.writeAsStringSync(jsonEncode({'password': password, 'version': 1}));
  return password;
}

void _migrate(Database db) {
  final version = db.userVersion;
  if (version < 1) {
    SessionStore.onCreate(db, _dbVersion);
    db.userVersion = _dbVersion;
  } else if (version < _dbVersion) {
    SessionStore.onUpgrade(db, version, _dbVersion);
    db.userVersion = _dbVersion;
  }
}

/// 打开 SQLCipher 加密的会话数据库：首次生成随机密码写入本地 auth 文件。
/// 加密不可用（例如未启用 SQLCipher 构建）时回退明文打开，保证功能不回归。
Future<Database?> openEncryptedSessionDb() async {
  try {
    final docDir = await getApplicationDocumentsDirectory();
    final supportDir = await getApplicationSupportDirectory();
    await Directory(supportDir.path).create(recursive: true);
    final password = await _loadOrCreatePassword(supportDir.path);
    final db = sqlite3.open('${docDir.path}/$_dbFileName');
    db.execute("PRAGMA key = '$password'");
    _migrate(db);
    return db;
  } catch (e) {
    _log.warning('Encrypted session DB open failed, falling back to plain: $e');
  }
  try {
    final docDir = await getApplicationDocumentsDirectory();
    final db = sqlite3.open('${docDir.path}/$_dbFileName');
    _migrate(db);
    return db;
  } catch (e) {
    _log.warning('Session DB open failed: $e');
    return null;
  }
}

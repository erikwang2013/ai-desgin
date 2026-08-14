import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' hide Session;
import 'session_store.dart';

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
      // 损坏的 auth 文件备份为独立文件再重新生成：旧文件可能仍包含原密钥，
      // 直接覆盖会使旧库永久不可恢复。
      try {
        final backup = File(
            '$dir/$_authFileName.corrupt-${DateTime.now().millisecondsSinceEpoch}');
        file.renameSync(backup.path);
        debugPrint('Corrupt auth file backed up to ${backup.path}');
      } catch (e) {
        debugPrint('Failed to back up corrupt auth file: $e');
      }
    }
  }
  final rng = Random.secure();
  final password = List.generate(
    32,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  file.writeAsStringSync(jsonEncode({'password': password, 'version': 1}));
  await _restrictFilePermissions(file);
  return password;
}

/// POSIX 下将密码文件权限收紧为 0600（仅当前用户可读写）；Windows 无此概念，忽略。
Future<void> _restrictFilePermissions(File file) async {
  if (Platform.isWindows) return;
  try {
    await Process.run('chmod', ['600', file.absolute.path]);
  } catch (e) {
    debugPrint('Failed to restrict auth file permissions: $e');
  }
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

/// 用指定 key 打开库后立即校验：SQLCipher 的 PRAGMA key 延迟生效，
/// 错误密钥要到首次查询才报错，这里显式探测，避免把失败掩盖到后续操作。
bool _verifyKey(Database db) {
  try {
    db.select('SELECT count(*) FROM sqlite_master');
    return true;
  } catch (_) {
    return false;
  }
}

/// SQLCipher 是否可用：PRAGMA cipher_version 在普通 sqlite3 构建上
/// 抛错或返回空，据此区分，避免明文存储被静默接受。
bool _sqlcipherAvailable(Database db) {
  try {
    final rows = db.select('PRAGMA cipher_version');
    final version = rows.isEmpty ? '' : rows.first.values.first?.toString() ?? '';
    return version.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// 打开 SQLCipher 加密的会话数据库：首次生成随机密码写入本地 auth 文件。
/// 加密不可用时返回 null 禁用历史会话，绝不静默降级明文存储。
Future<Database?> openEncryptedSessionDb() async {
  try {
    final docDir = await getApplicationDocumentsDirectory();
    final supportDir = await getApplicationSupportDirectory();
    await Directory(supportDir.path).create(recursive: true);
    final password = await _loadOrCreatePassword(supportDir.path);
    final db = sqlite3.open('${docDir.path}/$_dbFileName');
    db.execute("PRAGMA key = '$password'");
    if (!_verifyKey(db)) {
      db.close();
      // 密钥不匹配（库可能是明文或旧密钥）：保留 auth 文件供手动恢复，
      // 不静默覆盖密钥，也不创建空明文库掩盖问题。
      debugPrint('Session DB key mismatch: auth file kept for recovery');
      return null;
    }
    if (!_sqlcipherAvailable(db)) {
      db.close();
      // SQLCipher 构建缺失时宁可禁用历史会话，也不静默降级明文存储。
      debugPrint('SQLCipher unavailable: session history disabled');
      return null;
    }
    _migrate(db);
    return db;
  } catch (e) {
    debugPrint('Encrypted session DB open failed: $e');
    return null;
  }
}

import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/software_capabilities.dart';
import 'cc_runner.dart';

const _uuid = Uuid();

class CCSession {
  final String id;
  final String software;
  final SoftwareCapabilities capabilities;
  final SoftwareState state;
  final DateTime createdAt;
  DateTime lastActivity;

  CCSession({
    String? id,
    required this.software,
    required this.capabilities,
    required this.state,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastActivity = DateTime.now();
}

class CCProcessManager {
  final int maxProcesses;
  final int idleTimeoutSeconds;
  final Map<String, CCSession> _sessions = {};

  CCProcessManager({this.maxProcesses = 3, this.idleTimeoutSeconds = 300});

  CCSession createSession({
    required String software,
    required SoftwareCapabilities capabilities,
    required SoftwareState state,
  }) {
    _evictIdleSessions();

    if (_sessions.length >= maxProcesses && _sessions.isNotEmpty) {
      final oldest = _sessions.entries
          .reduce((a, b) => a.value.lastActivity.isBefore(b.value.lastActivity) ? a : b);
      _sessions.remove(oldest.key);
    }

    final session = CCSession(software: software, capabilities: capabilities, state: state);
    _sessions[session.id] = session;
    return session;
  }

  CCSession? getSession(String sessionId) => _sessions[sessionId];

  void closeSession(String sessionId) {
    _sessions.remove(sessionId);
  }

  int get activeSessionCount => _sessions.length;

  Map<String, dynamic> buildRequest({
    required String sessionId,
    required String task,
    required String model,
  }) {
    final session = _sessions[sessionId];
    session?.lastActivity = DateTime.now();

    return {
      'id': 'msg_${_uuid.v4().substring(0, 8)}',
      'method': 'design.execute',
      'params': {
        'sessionId': sessionId,
        'software': session?.software ?? '',
        'capabilities': session?.capabilities.toJson() ?? {},
        'state': session?.state.toJson() ?? {},
        'task': task,
        'model': model,
      },
    };
  }

  String serializeRequest(Map<String, dynamic> request) {
    return '${jsonEncode(request)}\n';
  }

  /// Execute a task by actually calling Claude Code CLI
  Future<Map<String, dynamic>> executeWithClaude({
    required String sessionId,
    required String task,
    required String model,
    CCRunner? runner,
    String? scriptLanguage,
    String? taskKey,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) {
      return {'error': 'Session not found: $sessionId'};
    }

    final effectiveRunner = runner ?? CCRunner();
    final result = await effectiveRunner.execute(
      task: task,
      software: session.software,
      capabilities: session.capabilities.toJson(),
      state: session.state.toJson(),
      model: model,
      scriptLanguage: scriptLanguage,
      key: taskKey,
    );

    session.lastActivity = DateTime.now();

    if (result.success) {
      return {
        'success': true,
        'script': result.script,
        'scriptLanguage': result.scriptLanguage,
        'explanation': result.explanation,
        'modelUsed': result.modelUsed ?? model,
      };
    } else {
      return {
        'success': false,
        'error': result.error,
      };
    }
  }

  void _evictIdleSessions() {
    final now = DateTime.now();
    _sessions.removeWhere((_, session) {
      return now.difference(session.lastActivity).inSeconds > idleTimeoutSeconds;
    });
  }
}

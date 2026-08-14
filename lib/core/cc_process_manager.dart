import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../models/software_capabilities.dart';
import 'agent_backend.dart';
import 'cc_runner.dart';

final _log = Logger('CCProcessManager');

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
  final Map<String, List<String>> _taskKeysBySession = {};
  Timer? _evictionTimer;

  /// 每个 session 使用的 runner 实例：取消/驱逐时只 cancel 该 session 的 runner，
  /// 避免多 session 各自换 runner 时只保留了最后一份引用。
  final Map<String, AgentBackend> _runnersBySession = {};

  CCProcessManager({this.maxProcesses = 3, this.idleTimeoutSeconds = 300});

  /// Periodically evict idle sessions so stale sessions are reclaimed even
  /// when the app is otherwise idle. Stops itself when no sessions remain.
  void _ensureEvictionTimer() {
    if (_evictionTimer != null) return;
    _evictionTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _evictIdleSessions();
      if (_sessions.isEmpty && _taskKeysBySession.isEmpty) {
        _evictionTimer?.cancel();
        _evictionTimer = null;
      }
    });
  }

  /// Cancel running tasks and drop all session state. Call on app teardown.
  void dispose() {
    _evictionTimer?.cancel();
    _evictionTimer = null;
    for (final entry in _taskKeysBySession.entries) {
      final runner = _runnersBySession[entry.key];
      for (final key in entry.value) {
        runner?.cancel(key: key);
      }
    }
    _taskKeysBySession.clear();
    _sessions.clear();
    _runnersBySession.clear();
  }

  CCSession createSession({
    required String software,
    required SoftwareCapabilities capabilities,
    required SoftwareState state,
  }) {
    _evictIdleSessions();

    if (_sessions.length >= maxProcesses && _sessions.isNotEmpty) {
      // 满员时只驱逐空闲会话，不杀正在执行任务的任务会话。
      final idleCandidates = _sessions.entries
          .where((e) => !(_taskKeysBySession[e.key]?.isNotEmpty ?? false))
          .toList();
      if (idleCandidates.isNotEmpty) {
        final oldest = idleCandidates
            .reduce((a, b) => a.value.lastActivity.isBefore(b.value.lastActivity) ? a : b);
        _evictSession(oldest.key);
      } else if (_sessions.length >= maxProcesses) {
        throw StateError('All $maxProcesses sessions are busy');
      }
    }

    _ensureEvictionTimer();
    final session = CCSession(software: software, capabilities: capabilities, state: state);
    _sessions[session.id] = session;
    return session;
  }

  CCSession? getSession(String sessionId) => _sessions[sessionId];

  void closeSession(String sessionId) {
    _taskKeysBySession.remove(sessionId);
    _runnersBySession.remove(sessionId);
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
    AgentBackend? runner,
    String? scriptLanguage,
    String? taskKey,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) {
      return {'error': 'Session not found: $sessionId'};
    }

    final effectiveRunner = runner ?? CCRunner();
    _runnersBySession[sessionId] = effectiveRunner;
    if (taskKey != null) {
      _taskKeysBySession.putIfAbsent(sessionId, () => []).add(taskKey);
    }

    try {
      final result = await effectiveRunner.execute(
        task: task,
        software: session.software,
        capabilities: session.capabilities.toJson(),
        state: session.state.toJson(),
        model: model,
        scriptLanguage: scriptLanguage,
        key: taskKey,
      );

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
    } finally {
      // execute 抛异常时也要清理 taskKey，否则会话被误认为"正在执行"
      // 而永远不会被驱逐；lastActivity 同步刷新为执行结束时间。
      _taskKeysBySession[sessionId]?.remove(taskKey);
      session.lastActivity = DateTime.now();
    }
  }

  void _evictIdleSessions() {
    final now = DateTime.now();
    final expired = _sessions.entries
        .where((e) =>
            now.difference(e.value.lastActivity).inSeconds > idleTimeoutSeconds &&
            // 正在执行任务（taskKey 非空）的会话不驱逐，与 createSession 的满员策略一致。
            !(_taskKeysBySession[e.key]?.isNotEmpty ?? false))
        .map((e) => e.key)
        .toList();
    for (final id in expired) {
      _evictSession(id);
    }
  }

  /// Remove a session and cancel any Claude processes still tracked for it.
  void _evictSession(String sessionId) {
    _log.info('Evicting session $sessionId (max sessions reached or idle timeout)');
    final runner = _runnersBySession[sessionId];
    for (final key in _taskKeysBySession.remove(sessionId) ?? const <String>[]) {
      runner?.cancel(key: key);
    }
    _runnersBySession.remove(sessionId);
    _sessions.remove(sessionId);
  }
}

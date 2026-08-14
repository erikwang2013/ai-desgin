import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:uuid/uuid.dart';
import 'l10n/app_localizations.dart';
import 'models/session.dart';
import 'models/task_record.dart';
import 'core/plugin_manager.dart';
import 'core/cc_process_manager.dart';
import 'core/cc_runner.dart';
import 'core/codex_backend.dart';
import 'core/gemini_backend.dart';
import 'core/cli_agent_backend.dart';
import 'core/remote_backend.dart';
import 'core/model_router.dart';
import 'core/task_orchestrator.dart';
import 'core/artifact_verifier.dart';
import 'core/session_store.dart';
import 'core/db_opener.dart';
import 'core/builtin_plugins.dart';
import 'core/local_script_executor.dart';
import 'core/locale_provider.dart';
import 'ui/shell.dart';
import 'ui/chat_view.dart';
import 'ui/task_dashboard.dart';
import 'ui/history_view.dart';
import 'ui/software_panel.dart';
import 'ui/settings_view.dart';

class AiDesignApp extends StatefulWidget {
  const AiDesignApp({super.key});

  @override
  State<AiDesignApp> createState() => _AiDesignAppState();
}

class _AiDesignAppState extends State<AiDesignApp> {
  final _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _localeProvider.loadSavedLocale();
  }

  @override
  void dispose() {
    _localeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _localeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'AI Design',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          locale: _localeProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _MainShell(localeProvider: _localeProvider),
          routes: {'/settings': (_) => SettingsView(localeProvider: _localeProvider)},
        );
      },
    );
  }
}

class _MainShell extends StatefulWidget {
  final LocaleProvider localeProvider;
  const _MainShell({required this.localeProvider});
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentTab = 0;
  int _conversationEpoch = 0;
  DesignCategory _currentDomain = DesignCategory.web;
  String _currentSoftware = '';

  late PluginManager _pluginManager;
  late final TaskOrchestrator _orchestrator;
  CCProcessManager? _ccManager;
  SessionStore? _sessionStore;
  final _dashboardKey = GlobalKey<TaskDashboardState>();
  final _historyKey = GlobalKey<HistoryViewState>();
  final Map<String, bool> _connectionStatus = {};
  final Map<DesignCategory, String> _lastSoftwarePerDomain = {};
  final Map<DesignCategory, List<SoftwareOption>> _cachedOptions = {};
  final Map<DesignCategory, String> _cachedOptionsSignature = {};
  String? _openaiKey;
  String? _geminiKey;
  String? _remoteUrl;
  String? _remoteKey;
  bool _ready = false;

  /// 聊天面板在途任务 id：加载中停止按钮取消的目标。
  /// 聊天一次只允许一个在途请求（_isLoading 期间输入禁用），单值足够。
  String? _activeTaskId;

  /// 供所有 RemoteBackend 复用的单例 client，避免切换后端时泄漏连接。
  final http.Client _httpClient = http.Client();

  /// dashboard/history 启动列表查询的共享加载器：并发期间合并为一次查询，
  /// 完成后释放缓存，后续 reload 重新查询。
  Future<List<Session>>? _sharedHistoryLoad;

  @override
  void initState() {
    super.initState();
    _initOrchestrator();
  }

  @override
  void dispose() {
    _ccManager?.dispose();
    _httpClient.close();
    super.dispose();
  }

  Future<List<Session>> _sharedHistoryLoader() {
    final pending = _sharedHistoryLoad;
    if (pending != null) return pending;
    final store = _sessionStore;
    if (store == null) return Future.value(const []);
    final future = store.listRecent(limit: 500);
    _sharedHistoryLoad = future;
    future.whenComplete(() => _sharedHistoryLoad = null);
    return future;
  }

  Future<void> _initOrchestrator() async {
    // 同步占位避免 await 期间 build 访问未初始化字段；create() 完成后替换。
    _pluginManager = PluginManager();
    final ccManager = CCProcessManager();
    _ccManager = ccManager;
    final modelRouter = ModelRouter();
    final ccRunner = CCRunner();

    // 相互独立的重活并行启动：插件加载、SQLCipher 开库、prefs 读取、路由配置。
    final pluginFuture = PluginManager.create();
    final dbFuture = openEncryptedSessionDb();
    final prefsFuture = SharedPreferences.getInstance();
    final routingFuture = _loadModelRouting(modelRouter);

    _pluginManager = await pluginFuture;

    // 市场卸载的插件跨重启保持卸载状态，启动时不注册。
    final uninstalledIds = <String>{};
    SharedPreferences? prefs;
    try {
      prefs = await prefsFuture;
      uninstalledIds.addAll(prefs.getStringList('uninstalled_plugin_ids') ?? const []);
    } catch (_) {
      // No persistence available; all plugins default to installed
    }

    // 外部导入的插件跨重启恢复注册（市场卸载的仍由下方 uninstalled 过滤移除）。
    try {
      final supportDir = await getApplicationSupportDirectory();
      _pluginManager.restoreExternalPlugins(supportDir.path);
    } catch (_) {}

    // create() 已注册 Rust 权威源（或 Dart 回退）的全部插件，这里只做卸载过滤。
    for (final p in _pluginManager.getAll()) {
      if (uninstalledIds.contains(p.id)) {
        _pluginManager.unregister(p.id);
      }
    }

    LocalScriptExecutor.instance ??= LocalScriptExecutor();

    try {
      final savedModel = prefs?.getString('default_model');
      if (savedModel != null && savedModel.isNotEmpty) {
        modelRouter.setDefaultModel(savedModel);
      }
      final proxyHost = prefs?.getString('proxy_host');
      final proxyPort = prefs?.getString('proxy_port');
      if (proxyHost != null && proxyHost.isNotEmpty) {
        final scheme = prefs?.getString('proxy_scheme') ?? 'http';
        final base = proxyPort != null && proxyPort.isNotEmpty
            ? '$scheme://$proxyHost:$proxyPort'
            : '$scheme://$proxyHost';
        CCRunner.proxyEnvironment = {
          'HTTP_PROXY': base,
          'HTTPS_PROXY': base,
        };
      }
      CCRunner.apiBaseUrl = prefs?.getString('api_endpoint');
      CCRunner.apiAuthToken = prefs?.getString('api_key');
    } catch (_) {
      // Saved settings are optional; defaults apply otherwise
    }
    await routingFuture;
    // 启动时先等已保存语言加载完成再取指令：responseLanguage 与 UI 语言
    // 同源，否则 saved locale 为英文时提示语仍按默认中文下发。
    await widget.localeProvider.loadSavedLocale();
    CCRunner.responseLanguage = widget.localeProvider.languageInstruction;
    String backendId = 'claude';
    try {
      _openaiKey = prefs?.getString('openai_api_key');
      _geminiKey = prefs?.getString('gemini_api_key');
      _remoteUrl = prefs?.getString('remote_endpoint_url');
      _remoteKey = prefs?.getString('remote_endpoint_key');
      backendId = prefs?.getString('agent_backend') ?? 'claude';
    } catch (_) {
      // Defaults to Claude
    }
    final backend = switch (backendId) {
      'codex' => CodexBackend(apiKey: _openaiKey),
      'gemini' => GeminiBackend(apiKey: _geminiKey),
      'opencode' => openCodeBackend,
      'openclaw' => openClawBackend,
      'hermes' => hermesBackend,
      'reasonix' => reasonixBackend,
      'remote' => RemoteBackend(endpointUrl: _remoteUrl ?? '', apiKey: _remoteKey ?? '', client: _httpClient),
      _ => ccRunner,
    };
    _orchestrator = TaskOrchestrator(
      pluginManager: _pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: backend,
    );

    // 探活不阻塞 _ready：结果为纯展示性状态，完成后经 setState 刷新面板。
    unawaited(_runConnectionProbes().catchError((_) {}));

    _currentSoftware = _defaultSoftwareFor(_currentDomain);
    _lastSoftwarePerDomain[_currentDomain] = _currentSoftware;

    // P3 两阶段：插件/路由/locale 就绪即开放聊天；SQLCipher 开库不阻塞首屏，
    // 完成后把 sessionStore 补交给 dashboard/history 并加载历史。
    if (mounted) setState(() => _ready = true);
    unawaited(_openSessionStore(dbFuture));
  }

  /// P3 第二阶段：开库完成后注入 store 并补载历史列表。
  Future<void> _openSessionStore(Future<Database?> dbFuture) async {
    try {
      final db = await dbFuture;
      if (db == null || !mounted) return;
      setState(() => _sessionStore = SessionStore(db));
      _dashboardKey.currentState?.reloadHistory();
      _historyKey.currentState?.reload();
    } catch (_) {
      // Non-critical; app works without persistence
    }
  }

  Future<void> _loadModelRouting(ModelRouter modelRouter) async {
    const inlineRouting = '''
    default: claude-sonnet-4-6
    routes:
      - complexity: simple
        model: claude-haiku-4-5
      - domains: [web, ad]
        complexity: creative
        model: claude-opus-4-7
      - domains: [industrial, threeD, arch, interior]
        model: claude-opus-4-7
    ''';
    try {
      final yaml = await rootBundle.loadString('config/model-routing.yaml');
      await modelRouter.loadConfigFromString(yaml);
    } catch (_) {
      await modelRouter.loadConfigFromString(inlineRouting);
    }
  }

  /// Probe CLI availability for every plugin and publish connection status.
  /// 分批并发（每批 6 个）而不是一次性 18 个：探测是进程启动类 IO，
  /// 全并发会拖慢启动期的进程调度。
  Future<void> _runConnectionProbes() async {
    for (final p in _pluginManager.getAll()) {
      _connectionStatus[p.id] = false;
    }
    final executor = LocalScriptExecutor.instance;
    if (executor == null) return;
    final probes = <String, Future<bool>>{};
    for (final p in _pluginManager.getAll()) {
      if (executor.hasCommand(p.id)) {
        probes[p.id] = executor.checkAvailable(p.id);
      }
    }
    const batchSize = 6;
    final ids = probes.keys.toList();
    final results = <String, bool>{};
    for (var i = 0; i < ids.length; i += batchSize) {
      final batch = ids.sublist(i, math.min(i + batchSize, ids.length));
      final batchResults = await Future.wait(batch.map((id) => probes[id]!));
      for (var j = 0; j < batch.length; j++) {
        results[batch[j]] = batchResults[j];
      }
    }
    if (mounted) {
      setState(() => _connectionStatus.addAll(results));
    }
  }

  void _onTabSelected(int tab) => setState(() => _currentTab = tab);

  /// 最新一次后端切换请求：remote 分支异步生效，期间再切换时旧回调作废。
  String? _pendingBackendRequest;

  /// 切换 Agent 后端：立即生效并持久化，重启后保持。
  void _onBackendChanged(String id) {
    _pendingBackendRequest = id;
    if (id == 'remote') {
      // remote 的 URL/key 在 prefs 中，需异步读取后再生效。
      SharedPreferences.getInstance().then((prefs) {
        // 过期回调不得覆盖用户已切换到的其他后端。
        if (_pendingBackendRequest != 'remote') return;
        _orchestrator.backend = RemoteBackend(
          endpointUrl: prefs.getString('remote_endpoint_url') ?? '',
          apiKey: prefs.getString('remote_endpoint_key') ?? '',
          client: _httpClient,
        );
        prefs.setString('agent_backend', id);
      }).catchError((_) {});
      return;
    }
    _orchestrator.backend = switch (id) {
      'codex' => CodexBackend(apiKey: _openaiKey),
      'gemini' => GeminiBackend(apiKey: _geminiKey),
      'opencode' => openCodeBackend,
      'openclaw' => openClawBackend,
      'hermes' => hermesBackend,
      'reasonix' => reasonixBackend,
      _ => CCRunner(),
    };
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('agent_backend', id);
    }).catchError((_) {});
  }
  /// 设置页保存的 Codex/Gemini API Key：更新启动缓存并重建当前后端，
  /// 使修改无需重启或切换后端即可生效。空 key 保留 CLI 自身登录凭证。
  void _onCredentialsSaved(String openaiApiKey, String geminiApiKey) {
    _openaiKey = openaiApiKey;
    _geminiKey = geminiApiKey;
    if (!_ready) return;
    final backend = _orchestrator.backend;
    if (backend is CodexBackend) {
      _orchestrator.backend = CodexBackend(apiKey: _openaiKey);
    } else if (backend is GeminiBackend) {
      _orchestrator.backend = GeminiBackend(apiKey: _geminiKey);
    }
  }

  void _onDomainChanged(DesignCategory domain) {
    final remembered = _lastSoftwarePerDomain[domain];
    final domainPlugins = _pluginManager.getByCategory(domain);
    final firstId = domainPlugins.isNotEmpty ? domainPlugins.first.id : '';
    final restored = remembered != null && domainPlugins.any((p) => p.id == remembered)
        ? remembered
        : firstId;
    setState(() {
      _currentDomain = domain;
      _currentSoftware = restored;
      _currentTab = 0;
      _conversationEpoch++;
    });
  }

  void _onSoftwareChanged(String id) {
    _lastSoftwarePerDomain[_currentDomain] = id;
    setState(() => _currentSoftware = id);
  }

  /// Resolve the effective software, falling back to the first available
  /// plugin of the current domain if the selected one was uninstalled.
  String _resolveSoftware() {
    var sw = _currentSoftware.isNotEmpty ? _currentSoftware : _defaultSoftwareFor(_currentDomain);
    if (_pluginManager.get(sw) == null) {
      final domainPlugins = _pluginManager.getByCategory(_currentDomain);
      sw = domainPlugins.isNotEmpty ? domainPlugins.first.id : '';
    }
    return sw;
  }

  /// Cancel a task and persist the cancellation so it survives a restart.
  /// 返回取消后的最新状态供 UI 回填：任务已先完成时 cancelTask 是 no-op，
  /// UI 不得把已完成记录误标成 cancelled。
  TaskStatus? _cancelAndPersist(String id) {
    _orchestrator.cancelTask(id);
    final record = _orchestrator.getTask(id);
    final session =
        record == null ? null : _orchestrator.getCurrentSession(record.sessionId);
    if (session != null && _sessionStore != null) {
      _sessionStore!.save(session).catchError((_) {});
    }
    return record?.status;
  }

  /// 聊天/重试面板共用的提交入口。聊天面板的停止按钮据此取消在途任务。
  void _cancelActiveChatTask() {
    final id = _activeTaskId;
    if (id == null) return;
    _activeTaskId = null;
    _cancelAndPersist(id);
  }

  Future<String> _onSubmit(String task) async {
    final sw = _resolveSoftware();
    // 预置 pending 占位卡片，让生成/执行阶段的进度回调有归属。
    final taskId = const Uuid().v4();
    _activeTaskId = taskId;
    _dashboardKey.currentState?.addTask(TaskItem(
      id: taskId,
      title: task,
      software: _pluginManager.get(sw)?.name ?? sw,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
    ));
    final result = await _orchestrator.submitTask(
      domain: _currentDomain,
      softwareName: sw,
      task: task,
      taskId: taskId,
      verifier: const ArtifactVerifier(),
      onProgress: (stage, description) {
        _dashboardKey.currentState?.updateTaskProgress(taskId, stage);
      },
    );

    _dashboardKey.currentState?.addTask(TaskItem(
      id: result.id,
      title: result.task,
      software: _pluginManager.get(sw)?.name ?? sw,
      status: result.status,
      createdAt: result.createdAt,
      modelUsed: result.modelUsed,
      script: result.script,
      artifacts: result.artifacts,
    ));

    final session = _orchestrator.getCurrentSession(sw);
    if (session != null && _sessionStore != null) {
      // 写库不阻塞响应：fire-and-forget 静默失败；历史列表增量替换该会话，
      // 避免每次任务完成后整表重查。
      _sessionStore!.save(session).catchError((_) {});
      _historyKey.currentState?.updateSession(session);
    }

    if (!mounted) return '';
    final l10n = AppLocalizations.of(context);
    if (result.status == TaskStatus.completed) {
      return '✅ ${l10n?.taskCompleted ?? 'Task completed'}\n\n${result.script ?? l10n?.noOutput ?? '(no output)'}';
    }
    if (result.status == TaskStatus.cancelled) {
      return '⚠️ ${result.task} — ${l10n?.cancel ?? 'Cancelled'}';
    }
    return '❌ ${l10n?.taskFailed ?? 'Task failed'}: ${result.error ?? l10n?.unknownError ?? 'Unknown error'}';
  }

  String _defaultSoftwareFor(DesignCategory domain) {
    return switch (domain) {
      DesignCategory.web => 'figma',
      DesignCategory.ad => 'photoshop',
      DesignCategory.industrial => 'fusion360',
      DesignCategory.threeD => 'blender',
      DesignCategory.arch => 'autocad',
      DesignCategory.interior => 'sketchup',
    };
  }

  List<SoftwareOption> _buildSoftwareOptions() {
    // Invalidate the per-domain cache when the plugin set changes
    // (e.g. uninstall/install from the marketplace).
    final plugins = _pluginManager.getByCategory(_currentDomain);
    final signature = plugins.map((p) => p.id).join(',');
    if (_cachedOptionsSignature[_currentDomain] != signature) {
      _cachedOptionsSignature[_currentDomain] = signature;
      _cachedOptions[_currentDomain] = plugins.map((p) {
        return SoftwareOption(id: p.id, name: p.name, icon: softwareIcons[p.id] ?? '🔌');
      }).toList();
    }
    return _cachedOptions[_currentDomain] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedDomain: _currentDomain,
      selectedTabIndex: _currentTab,
      onDomainChanged: _onDomainChanged,
      onTabSelected: _onTabSelected,
      pluginManager: _pluginManager,
      localeProvider: widget.localeProvider,
      modelRouter: _ready ? _orchestrator.modelRouter : null,
      currentBackendId: _ready ? _orchestrator.backend.id : null,
      onBackendChanged: _ready ? _onBackendChanged : null,
      onCredentialsSaved: _ready ? _onCredentialsSaved : null,
      child: IndexedStack(
        index: _currentTab,
        children: [
          ChatView(
            onSubmit: _ready ? _onSubmit : null,
            onCancel: _ready ? _cancelActiveChatTask : null,
            softwareOptions: _ready ? _buildSoftwareOptions() : [],
            selectedSoftware: _currentSoftware,
            onSoftwareChanged: _onSoftwareChanged,
            conversationEpoch: _conversationEpoch,
          ),
          TaskDashboard(
            key: _dashboardKey,
            sessionStore: _sessionStore,
            // IndexedStack 双视图共享一次启动加载，避免各查一次。
            loadSessions: _sharedHistoryLoader,
            onCancel: _ready ? _cancelAndPersist : null,
            // 失败任务重试：原样重提任务描述（新 taskId），复用 _onSubmit 链路。
            onRetry: _ready ? _onSubmit : null,
            resolveSoftwareName: (id) => _pluginManager.get(id)?.name ?? id,
          ),
          HistoryView(
            key: _historyKey,
            sessionStore: _sessionStore,
            loadSessions: _sharedHistoryLoader,
            resolveSoftwareName: (id) => _pluginManager.get(id)?.name ?? id,
          ),
          SoftwarePanel(
            pluginManager: _pluginManager,
            connectionStatus: _connectionStatus,
            onRefresh: _ready ? _runConnectionProbes : null,
          ),
        ],
      ),
    );
  }
}

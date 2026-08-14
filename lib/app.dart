import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _initOrchestrator();
  }

  @override
  void dispose() {
    _ccManager?.dispose();
    super.dispose();
  }

  Future<void> _initOrchestrator() async {
    // 同步占位避免 await 期间 build 访问未初始化字段；create() 完成后替换。
    _pluginManager = PluginManager();
    _pluginManager = await PluginManager.create();
    final ccManager = CCProcessManager();
    _ccManager = ccManager;
    final modelRouter = ModelRouter();
    final ccRunner = CCRunner();

    // 市场卸载的插件跨重启保持卸载状态，启动时不注册。
    final uninstalledIds = <String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      uninstalledIds.addAll(prefs.getStringList('uninstalled_plugin_ids') ?? const []);
    } catch (_) {
      // No persistence available; all plugins default to installed
    }

    // create() 已注册 Rust 权威源（或 Dart 回退）的全部插件，这里只做卸载过滤。
    for (final p in _pluginManager.getAll()) {
      if (uninstalledIds.contains(p.id)) {
        _pluginManager.unregister(p.id);
      }
    }

    LocalScriptExecutor.instance ??= LocalScriptExecutor();

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModel = prefs.getString('default_model');
      if (savedModel != null && savedModel.isNotEmpty) {
        modelRouter.setDefaultModel(savedModel);
      }
      final proxyHost = prefs.getString('proxy_host');
      final proxyPort = prefs.getString('proxy_port');
      if (proxyHost != null && proxyHost.isNotEmpty) {
        final scheme = prefs.getString('proxy_scheme') ?? 'http';
        final base = proxyPort != null && proxyPort.isNotEmpty
            ? '$scheme://$proxyHost:$proxyPort'
            : '$scheme://$proxyHost';
        CCRunner.proxyEnvironment = {
          'HTTP_PROXY': base,
          'HTTPS_PROXY': base,
        };
      }
      CCRunner.apiBaseUrl = prefs.getString('api_endpoint');
      CCRunner.apiAuthToken = prefs.getString('api_key');
    } catch (_) {
      // Saved settings are optional; defaults apply otherwise
    }
    CCRunner.responseLanguage = widget.localeProvider.languageInstruction;
    String backendId = 'claude';
    try {
      final prefs = await SharedPreferences.getInstance();
      backendId = prefs.getString('agent_backend') ?? 'claude';
      _openaiKey = prefs.getString('openai_api_key');
      _geminiKey = prefs.getString('gemini_api_key');
      _remoteUrl = prefs.getString('remote_endpoint_url');
      _remoteKey = prefs.getString('remote_endpoint_key');
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
      'remote' => RemoteBackend(endpointUrl: _remoteUrl ?? '', apiKey: _remoteKey ?? ''),
      _ => ccRunner,
    };
    _orchestrator = TaskOrchestrator(
      pluginManager: _pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: backend,
    );

    try {
      final db = await openEncryptedSessionDb();
      if (db != null) _sessionStore = SessionStore(db);
    } catch (_) {
      // Non-critical; app works without persistence
    }

    await _runConnectionProbes();

    _currentSoftware = _defaultSoftwareFor(_currentDomain);
    _lastSoftwarePerDomain[_currentDomain] = _currentSoftware;

    if (mounted) setState(() => _ready = true);
  }

  /// Probe CLI availability for every plugin and publish connection status.
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
    final results = await Future.wait(probes.values);
    if (mounted) {
      setState(() => _connectionStatus.addAll(
        Map<String, bool>.fromIterables(probes.keys, results),
      ));
    }
  }

  void _onTabSelected(int tab) => setState(() => _currentTab = tab);

  /// 切换 Agent 后端：立即生效并持久化，重启后保持。
  void _onBackendChanged(String id) {
    if (id == 'remote') {
      // remote 的 URL/key 在 prefs 中，需异步读取后再生效。
      SharedPreferences.getInstance().then((prefs) {
        _orchestrator.backend = RemoteBackend(
          endpointUrl: prefs.getString('remote_endpoint_url') ?? '',
          apiKey: prefs.getString('remote_endpoint_key') ?? '',
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
  void _cancelAndPersist(String id) {
    _orchestrator.cancelTask(id);
    final record = _orchestrator.getTask(id);
    final session =
        record == null ? null : _orchestrator.getCurrentSession(record.sessionId);
    if (session != null && _sessionStore != null) {
      _sessionStore!.save(session).catchError((_) {});
    }
  }

  Future<String> _onSubmit(String task) async {
    final sw = _resolveSoftware();
    // 预置 pending 占位卡片，让生成/执行阶段的进度回调有归属。
    final taskId = const Uuid().v4();
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
    ));

    final session = _orchestrator.getCurrentSession(sw);
    if (session != null && _sessionStore != null) {
      try {
        await _sessionStore!.save(session);
        _historyKey.currentState?.reload();
      } catch (_) {}
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
      child: IndexedStack(
        index: _currentTab,
        children: [
          ChatView(
            onSubmit: _ready ? _onSubmit : null,
            softwareOptions: _ready ? _buildSoftwareOptions() : [],
            selectedSoftware: _currentSoftware,
            onSoftwareChanged: _onSoftwareChanged,
            conversationEpoch: _conversationEpoch,
          ),
          TaskDashboard(
            key: _dashboardKey,
            sessionStore: _sessionStore,
            onCancel: _ready ? _cancelAndPersist : null,
            resolveSoftwareName: (id) => _pluginManager.get(id)?.name ?? id,
          ),
          HistoryView(
            key: _historyKey,
            sessionStore: _sessionStore,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';
import 'models/session.dart';
import 'models/task_record.dart';
import 'core/plugin_manager.dart';
import 'core/cc_process_manager.dart';
import 'core/cc_runner.dart';
import 'core/model_router.dart';
import 'core/task_orchestrator.dart';
import 'core/session_store.dart';
import 'core/builtin_plugins.dart';
import 'core/local_script_executor.dart';
import 'core/locale_provider.dart';
import 'ui/shell.dart';
import 'ui/chat_view.dart';
import 'ui/task_dashboard.dart';
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
  final Map<String, bool> _connectionStatus = {};
  final Map<DesignCategory, String> _lastSoftwarePerDomain = {};
  final Map<DesignCategory, List<SoftwareOption>> _cachedOptions = {};
  final Map<DesignCategory, String> _cachedOptionsSignature = {};
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
    _orchestrator = TaskOrchestrator(
      pluginManager: _pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      ccRunner: ccRunner,
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final db = await openDatabase(
        '${dir.path}/sessions.db',
        version: 1,
        onCreate: SessionStore.onCreate,
        onUpgrade: SessionStore.onUpgrade,
      );
      _sessionStore = SessionStore(db);
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
    final result = await _orchestrator.submitTask(
      domain: _currentDomain,
      softwareName: sw,
      task: task,
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
      try { await _sessionStore!.save(session); } catch (_) {}
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

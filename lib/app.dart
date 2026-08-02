import 'package:flutter/material.dart';
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
          home: const _MainShell(),
          routes: {'/settings': (_) => const SettingsView()},
        );
      },
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentTab = 0;
  DesignCategory _currentDomain = DesignCategory.web;
  String _currentSoftware = '';

  late final PluginManager _pluginManager;
  late final TaskOrchestrator _orchestrator;
  SessionStore? _sessionStore;
  final _dashboardKey = GlobalKey<TaskDashboardState>();
  final Map<String, bool> _connectionStatus = {};
  final Map<DesignCategory, String> _lastSoftwarePerDomain = {};
  final Map<DesignCategory, List<SoftwareOption>> _cachedOptions = {};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initOrchestrator();
  }

  Future<void> _initOrchestrator() async {
    _pluginManager = PluginManager();
    final ccManager = CCProcessManager();
    final modelRouter = ModelRouter();
    final ccRunner = CCRunner();

    for (final p in builtInPlugins) {
      _pluginManager.register(p);
    }

    await modelRouter.loadConfigFromString('''
    default: claude-sonnet-4-6
    routes:
      - complexity: simple
        model: claude-haiku-4-5
      - domains: [web, ad]
        complexity: creative
        model: claude-opus-4-7
      - domains: [industrial, threeD, arch, interior]
        model: claude-opus-4-7
    ''');
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

    for (final p in _pluginManager.getAll()) {
      _connectionStatus[p.id] = false;
    }

    _currentSoftware = _defaultSoftwareFor(_currentDomain);
    _lastSoftwarePerDomain[_currentDomain] = _currentSoftware;

    if (mounted) setState(() => _ready = true);
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
    });
  }

  void _onSoftwareChanged(String id) {
    _lastSoftwarePerDomain[_currentDomain] = id;
    setState(() => _currentSoftware = id);
  }

  Future<String> _onSubmit(String task) async {
    final sw = _currentSoftware.isNotEmpty ? _currentSoftware : _defaultSoftwareFor(_currentDomain);
    final result = await _orchestrator.submitTask(
      domain: _currentDomain,
      softwareName: sw,
      task: task,
    );

    _dashboardKey.currentState?.addTask(TaskItem(
      id: result.id,
      title: result.task,
      software: result.sessionId,
      status: result.status,
      createdAt: result.createdAt,
      modelUsed: result.modelUsed,
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
    return _cachedOptions.putIfAbsent(_currentDomain, () {
      return _pluginManager.getByCategory(_currentDomain).map((p) {
        return SoftwareOption(id: p.id, name: p.name, icon: softwareIcons[p.id] ?? '🔌');
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedDomain: _currentDomain,
      selectedTabIndex: _currentTab,
      onDomainChanged: _onDomainChanged,
      onTabSelected: _onTabSelected,
      pluginManager: _pluginManager,
      child: IndexedStack(
        index: _currentTab,
        children: [
          ChatView(
            onSubmit: _ready ? _onSubmit : null,
            softwareOptions: _ready ? _buildSoftwareOptions() : [],
            selectedSoftware: _currentSoftware,
            onSoftwareChanged: _onSoftwareChanged,
          ),
          TaskDashboard(key: _dashboardKey),
          SoftwarePanel(
            pluginManager: _pluginManager,
            connectionStatus: _connectionStatus,
          ),
        ],
      ),
    );
  }
}

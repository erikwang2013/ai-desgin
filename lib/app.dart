import 'package:flutter/material.dart';
import 'models/session.dart';
import 'models/task_record.dart';
import 'core/plugin_manager.dart';
import 'core/cc_process_manager.dart';
import 'core/model_router.dart';
import 'core/task_orchestrator.dart';
import 'ui/shell.dart';
import 'ui/chat_view.dart';
import 'ui/task_dashboard.dart';
import 'ui/software_panel.dart';
import 'ui/settings_view.dart';

class AiDesignApp extends StatelessWidget {
  const AiDesignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Design Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _MainShell(),
      routes: {'/settings': (_) => const SettingsView()},
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

  late final TaskOrchestrator _orchestrator;
  final _dashboardKey = GlobalKey<TaskDashboardState>();
  final Map<String, bool> _connectionStatus = {};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initOrchestrator();
  }

  Future<void> _initOrchestrator() async {
    final pluginManager = PluginManager();
    final ccManager = CCProcessManager();
    final modelRouter = ModelRouter();
    await modelRouter.loadConfigFromString('''
default: claude-sonnet-4-6
routes:
  - domains: [web, ad]
    complexity: creative
    model: claude-opus-4-7
  - domains: [industrial, threeD, arch, interior]
    model: claude-opus-4-7
  - complexity: simple
    model: claude-haiku-4-5
''');
    _orchestrator = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
    );
    if (mounted) setState(() => _ready = true);
  }

  void _onTabSelected(int tab) => setState(() => _currentTab = tab);
  void _onDomainChanged(DesignCategory domain) => setState(() => _currentDomain = domain);

  Future<String> _onSubmit(String task) async {
    final sw = _softwareNameFor(_currentDomain);
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

    if (result.status == TaskStatus.completed) {
      return '✅ 任务完成\n\n${result.script ?? '(无输出)'}';
    }
    return '❌ 任务失败: ${result.error ?? '未知错误'}';
  }

  String _softwareNameFor(DesignCategory domain) {
    return switch (domain) {
      DesignCategory.web => 'figma',
      DesignCategory.ad => 'photoshop',
      DesignCategory.industrial => 'fusion360',
      DesignCategory.threeD => 'blender',
      DesignCategory.arch => 'autocad',
      DesignCategory.interior => 'sketchup',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedDomain: _currentDomain,
      selectedTabIndex: _currentTab,
      onDomainChanged: _onDomainChanged,
      onTabSelected: _onTabSelected,
      child: IndexedStack(
        index: _currentTab,
        children: [
          ChatView(
            key: ValueKey('chat_${_currentDomain.name}'),
            onSubmit: _ready ? _onSubmit : null,
          ),
          TaskDashboard(key: _dashboardKey),
          SoftwarePanel(connectionStatus: _connectionStatus),
        ],
      ),
    );
  }
}

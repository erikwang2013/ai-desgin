import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'models/session.dart';
import 'models/task_record.dart';
import 'models/software_capabilities.dart';
import 'core/plugin_manager.dart';
import 'core/cc_process_manager.dart';
import 'core/model_router.dart';
import 'core/task_orchestrator.dart';
import 'core/session_store.dart';
import 'plugin_sdk/design_plugin.dart';
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
  SessionStore? _sessionStore;
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

    for (final p in _builtInPlugins) {
      pluginManager.register(p);
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
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final db = await openDatabase(
        '${dir.path}/sessions.db',
        version: 1,
        onCreate: SessionStore.onCreate,
      );
      _sessionStore = SessionStore(db);
    } catch (_) {
      // Non-critical; app works without persistence
    }

    for (final p in pluginManager.getAll()) {
      _connectionStatus[p.id] = false;
    }

    if (mounted) setState(() => _ready = true);
  }

  static const _builtInPlugins = [
    BuiltInPlugin(id: 'figma', name: 'Figma', category: DesignCategory.web, scriptLanguage: 'javascript',
      capabilities: SoftwareCapabilities(actions: ['create_canvas','add_rectangle','add_text','set_fill','export_png'], fileFormats: ['fig','png','svg'])),
    BuiltInPlugin(id: 'sketch', name: 'Sketch', category: DesignCategory.web, scriptLanguage: 'javascript',
      capabilities: SoftwareCapabilities(actions: ['创建画板','添加形状','导出切片','创建组件'], fileFormats: ['sketch','png','svg','pdf'])),
    BuiltInPlugin(id: 'photoshop', name: 'Photoshop', category: DesignCategory.ad, scriptLanguage: 'javascript',
      capabilities: SoftwareCapabilities(actions: ['图层操作','滤镜','批处理','导出'], fileFormats: ['psd','png','jpg','tiff'])),
    BuiltInPlugin(id: 'illustrator', name: 'Illustrator', category: DesignCategory.ad, scriptLanguage: 'javascript',
      capabilities: SoftwareCapabilities(actions: ['创建画板','添加形状','路径操作','导出SVG'], fileFormats: ['ai','eps','svg','pdf'])),
    BuiltInPlugin(id: 'blender', name: 'Blender', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['create_cube','create_sphere','export_fbx','render_image'], fileFormats: ['blend','fbx','obj','glb'])),
    BuiltInPlugin(id: 'sketchup', name: 'SketchUp', category: DesignCategory.interior, scriptLanguage: 'ruby',
      capabilities: SoftwareCapabilities(actions: ['推拉','材质','场景','剖面'], fileFormats: ['skp','dae','kmz','obj'])),
    BuiltInPlugin(id: 'autocad', name: 'AutoCAD', category: DesignCategory.arch, scriptLanguage: 'lisp',
      capabilities: SoftwareCapabilities(actions: ['draw_line','draw_circle','create_layer','export_dwg'], fileFormats: ['dwg','dxf','pdf'])),
    BuiltInPlugin(id: 'revit', name: 'Revit', category: DesignCategory.arch, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建墙体','创建楼板','放置族','导出IFC'], fileFormats: ['rvt','rfa','ifc','dwg'])),
    BuiltInPlugin(id: 'fusion360', name: 'Fusion 360', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建草图','拉伸','倒角','导出STEP'], fileFormats: ['f3d','step','iges','stl'])),
  ];

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

    final session = _orchestrator.getCurrentSession(sw);
    if (session != null && _sessionStore != null) {
      try { await _sessionStore!.save(session); } catch (_) {}
    }

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
            onSubmit: _ready ? _onSubmit : null,
          ),
          TaskDashboard(key: _dashboardKey),
          SoftwarePanel(connectionStatus: _connectionStatus),
        ],
      ),
    );
  }
}

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
    BuiltInPlugin(id: 'maya', name: 'Maya', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建模型','绑定骨骼','动画制作','渲染输出','导出FBX'], fileFormats: ['ma','mb','fbx','obj','alembic'])),
    BuiltInPlugin(id: '3dsmax', name: '3ds Max', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建几何体','修改器','材质编辑','MassFX动力学','导出FBX'], fileFormats: ['max','fbx','obj','3ds'])),
    BuiltInPlugin(id: 'cinema4d', name: 'Cinema 4D', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建对象','MoGraph','动力学模拟','Redshift渲染','导出FBX'], fileFormats: ['c4d','fbx','obj','alembic'])),
    BuiltInPlugin(id: 'indesign', name: 'InDesign', category: DesignCategory.ad, scriptLanguage: 'javascript',
      capabilities: SoftwareCapabilities(actions: ['创建文档','文本排版','图像置入','主页设置','导出PDF'], fileFormats: ['indd','idml','pdf','epub'])),
    BuiltInPlugin(id: 'zw3d', name: '中望3D', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建草图','特征建模','装配设计','工程图','导出STEP'], fileFormats: ['zw3d','step','iges','stl','dwg'])),
    BuiltInPlugin(id: '3done', name: '3D One系列', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建模型','拉伸','旋转','阵列','导出STL'], fileFormats: ['3done','stl','obj'])),
    BuiltInPlugin(id: 'voxeldance', name: 'VoxelDance Additive', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型导入','支撑生成','切片','路径规划','导出GCode'], fileFormats: ['vda','stl','gcode','3mf'])),
    BuiltInPlugin(id: 'happy3d', name: 'Happy3D', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建模型','场景编辑','材质贴图','渲染','导出GLB'], fileFormats: ['h3d','glb','stl','obj'])),
    BuiltInPlugin(id: 'maodou3d', name: '毛豆科技3D建模软件', category: DesignCategory.threeD, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['创建模型','场景搭建','材质编辑','导出STL'], fileFormats: ['md3d','stl','obj'])),
    BuiltInPlugin(id: 'makerlab', name: 'MakerLab', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型导入','切片','打印管理','模型库','导出GCode'], fileFormats: ['stl','3mf','gcode'])),
    BuiltInPlugin(id: 'crealitycloud', name: 'Creality Cloud', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型上传','云端切片','远程打印','模型库','导出GCode'], fileFormats: ['stl','3mf','gcode'])),
    BuiltInPlugin(id: 'flashprint', name: 'FlashPrint', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型导入','切片配置','支撑编辑','打印预览','导出GCode'], fileFormats: ['stl','obj','3mf','gcode','fpp'])),
    BuiltInPlugin(id: 'flashstudio', name: 'Flash Studio', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型编辑','支撑生成','切片','打印管理','导出GCode'], fileFormats: ['stl','obj','gcode'])),
    BuiltInPlugin(id: 'snapmakerluban', name: 'Snapmaker Luban', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型导入','CNC雕刻','激光切割','3D打印','导出GCode'], fileFormats: ['stl','svg','nc','gcode'])),
    BuiltInPlugin(id: 'snapmakerorca', name: 'Snapmaker Orca', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型导入','切片配置','校准工具','打印管理','导出GCode'], fileFormats: ['stl','3mf','gcode'])),
    BuiltInPlugin(id: 'buildplanner', name: 'Build Planner', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['模型排布','打印队列','材料估算','时间预估','导出布局'], fileFormats: ['stl','layout','gcode'])),
    BuiltInPlugin(id: 'flashdental', name: 'FlashDental', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['牙模导入','模型编辑','支撑生成','切片','导出GCode'], fileFormats: ['stl','3mf','gcode'])),
    BuiltInPlugin(id: 'waxjetprint', name: 'WaxJetPrint', category: DesignCategory.industrial, scriptLanguage: 'python',
      capabilities: SoftwareCapabilities(actions: ['蜡模导入','模型优化','支撑生成','切片','导出GCode'], fileFormats: ['stl','wax','gcode'])),
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

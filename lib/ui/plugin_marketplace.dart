import 'package:flutter/material.dart';
import '../models/session.dart';
import '../core/plugin_manager.dart';
import '../core/version.dart';
import '../core/builtin_plugins.dart';

class PluginInfo {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool installed;
  final String version;

  const PluginInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.installed = false,
    this.version = appVersion,
  });
}

PluginManager _createDefaultPluginManager() {
  final pm = PluginManager();
  for (final p in builtInPlugins) {
    pm.register(p);
  }
  return pm;
}

class PluginMarketplace extends StatefulWidget {
  final PluginManager pluginManager;

  PluginMarketplace({super.key, PluginManager? pluginManager})
      : pluginManager = pluginManager ?? _createDefaultPluginManager();

  @override
  State<PluginMarketplace> createState() => _PluginMarketplaceState();
}

class _PluginMarketplaceState extends State<PluginMarketplace> {
  late final List<PluginInfo> _plugins;

  static const _descriptions = <String, String>{
    'figma': 'UI 设计软件插件，支持创建画布、图层操作、导出等',
    'blender': '3D 建模软件插件，支持建模、渲染、导出等',
    'autocad': 'CAD 软件插件，支持绘图、标注、图层管理',
    'photoshop': '图像处理软件插件，支持图层、滤镜、批处理',
    'sketch': 'macOS UI 设计工具插件，支持画板、图层、导出',
    'revit': 'BIM 建筑设计软件插件，支持墙体、楼板、族、参数',
    'sketchup': '3D 建模软件插件，推拉、材质、场景、剖面',
    'illustrator': '矢量图形设计软件插件，支持画板、路径、效果',
    'fusion360': '工业设计CAD/CAM软件插件，支持草图、建模、装配',
    'maya': '3D动画与建模软件插件，支持建模、绑定、动画、渲染',
    '3dsmax': '3D建模与渲染软件插件，支持几何体、修改器、动力学',
    'cinema4d': '3D动态图形软件插件，支持MoGraph、动力学、Redshift渲染',
    'indesign': '桌面出版软件插件，支持文档排版、主页、导出PDF/EPUB',
    'zw3d': '国产CAD/CAM软件插件，支持草图、特征建模、装配、工程图',
    '3done': '青少年3D设计软件插件，支持建模、拉伸、旋转、阵列',
    'voxeldance': '增材制造数据准备软件插件，支撑生成、切片、路径规划',
    'happy3d': '3D建模软件插件，支持场景编辑、材质贴图、渲染导出',
    'maodou3d': '教育3D建模软件插件，支持模型创建、场景搭建、材质编辑',
    'makerlab': '3D打印管理平台插件，支持切片、打印管理、模型库',
    'crealitycloud': '云端3D打印平台插件，支持模型上传、云端切片、远程打印',
    'flashprint': '3D打印切片软件插件，支持切片配置、支撑编辑、打印预览',
    'flashstudio': '3D打印管理软件插件，支持模型编辑、支撑生成、打印管理',
    'snapmakerluban': '多功能CAM软件插件，支持CNC雕刻、激光切割、3D打印',
    'snapmakerorca': '3D打印切片软件插件，基于OrcaSlicer，支持校准、打印管理',
    'buildplanner': '3D打印排布软件插件，支持模型排布、材料估算、时间预估',
    'flashdental': '牙科3D打印软件插件，支持牙模导入、模型编辑、切片',
    'waxjetprint': '蜡模3D打印软件插件，支持蜡模导入、模型优化、切片',
  };

  @override
  void initState() {
    super.initState();
    _plugins = _buildPluginsFromManager();
  }

  List<PluginInfo> _buildPluginsFromManager() {
    return widget.pluginManager.getAll().map((p) {
      final icon = softwareIcons[p.id] ?? '🔌';
      final categoryLabel = switch (p.category) {
        DesignCategory.web => 'Web 设计',
        DesignCategory.ad => '广告设计',
        DesignCategory.industrial => '工业设计',
        DesignCategory.threeD => '3D 设计',
        DesignCategory.arch => '建筑设计',
        DesignCategory.interior => '装修设计',
      };
      return PluginInfo(
        id: p.id,
        name: p.name,
        description: _descriptions[p.id] ?? '${p.name} 插件',
        icon: icon,
        category: categoryLabel,
        installed: true,
        version: p.version,
      );
    }).toList();
  }

  void _toggleInstall(PluginInfo plugin) {
    setState(() {
      final idx = _plugins.indexWhere((p) => p.id == plugin.id);
      if (idx >= 0) {
        _plugins[idx] = PluginInfo(
          id: plugin.id,
          name: plugin.name,
          description: plugin.description,
          icon: plugin.icon,
          category: plugin.category,
          installed: !plugin.installed,
          version: plugin.version,
        );
      }
    });

    if (!plugin.installed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plugin.name} 安装成功'), duration: const Duration(seconds: 2)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plugin.name} 已卸载'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = _plugins.where((p) => p.installed).toList();
    final available = _plugins.where((p) => !p.installed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('插件市场')),
      body: ListView(
        children: [
          if (installed.isNotEmpty) ...[
            _sectionHeader('已安装 (${installed.length})'),
            ...installed.map(_buildPluginTile),
          ],
          if (available.isNotEmpty) ...[
            _sectionHeader('可安装 (${available.length})'),
            ...available.map(_buildPluginTile),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildPluginTile(PluginInfo plugin) {
    return ListTile(
      leading: Text(plugin.icon, style: const TextStyle(fontSize: 28)),
      title: Row(
        children: [
          Text(plugin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(plugin.category, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(plugin.description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ),
      trailing: plugin.installed
          ? OutlinedButton(
              onPressed: () => _toggleInstall(plugin),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('卸载'),
            )
          : ElevatedButton(
              onPressed: () => _toggleInstall(plugin),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('安装'),
            ),
    );
  }
}

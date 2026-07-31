import 'package:flutter/material.dart';
import '../core/version.dart';

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

class PluginMarketplace extends StatefulWidget {
  const PluginMarketplace({super.key});

  @override
  State<PluginMarketplace> createState() => _PluginMarketplaceState();
}

class _PluginMarketplaceState extends State<PluginMarketplace> {
  final List<PluginInfo> _plugins = [
    const PluginInfo(id: 'figma', name: 'Figma', description: 'UI 设计软件插件，支持创建画布、图层操作、导出等', icon: '🎨', category: 'Web 设计', installed: true),
    const PluginInfo(id: 'blender', name: 'Blender', description: '3D 建模软件插件，支持建模、渲染、导出等', icon: '🔷', category: '3D 设计', installed: true),
    const PluginInfo(id: 'autocad', name: 'AutoCAD', description: 'CAD 软件插件，支持绘图、标注、图层管理', icon: '📐', category: '建筑设计', installed: true),
    const PluginInfo(id: 'photoshop', name: 'Photoshop', description: '图像处理软件插件，支持图层、滤镜、批处理', icon: '🖼️', category: '广告设计', installed: true),
    const PluginInfo(id: 'sketch', name: 'Sketch', description: 'macOS UI 设计工具插件，支持画板、图层、导出', icon: '✏️', category: 'Web 设计', installed: true),
    const PluginInfo(id: 'revit', name: 'Revit', description: 'BIM 建筑设计软件插件，支持墙体、楼板、族、参数', icon: '🏗️', category: '建筑设计', installed: true),
    const PluginInfo(id: 'sketchup', name: 'SketchUp', description: '3D 建模软件插件，推拉、材质、场景、剖面', icon: '🏠', category: '装修设计', installed: true),
    const PluginInfo(id: 'illustrator', name: 'Illustrator', description: '矢量图形设计软件插件，支持画板、路径、效果', icon: '🖋️', category: '广告设计', installed: true),
    const PluginInfo(id: 'fusion360', name: 'Fusion 360', description: '工业设计CAD/CAM软件插件，支持草图、建模、装配', icon: '⚙️', category: '工业设计', installed: true),
    const PluginInfo(id: 'maya', name: 'Maya', description: '3D动画与建模软件插件，支持建模、绑定、动画、渲染', icon: '🎬', category: '3D 设计', installed: true),
    const PluginInfo(id: '3dsmax', name: '3ds Max', description: '3D建模与渲染软件插件，支持几何体、修改器、动力学', icon: '🏢', category: '3D 设计', installed: true),
    const PluginInfo(id: 'cinema4d', name: 'Cinema 4D', description: '3D动态图形软件插件，支持MoGraph、动力学、Redshift渲染', icon: '🎥', category: '3D 设计', installed: true),
    const PluginInfo(id: 'indesign', name: 'InDesign', description: '桌面出版软件插件，支持文档排版、主页、导出PDF/EPUB', icon: '📰', category: '广告设计', installed: true),
    const PluginInfo(id: 'zw3d', name: '中望3D', description: '国产CAD/CAM软件插件，支持草图、特征建模、装配、工程图', icon: '🔧', category: '工业设计', installed: true),
    const PluginInfo(id: '3done', name: '3D One系列', description: '青少年3D设计软件插件，支持建模、拉伸、旋转、阵列', icon: '🧒', category: '3D 设计', installed: true),
    const PluginInfo(id: 'voxeldance', name: 'VoxelDance Additive', description: '增材制造数据准备软件插件，支撑生成、切片、路径规划', icon: '🦴', category: '工业设计', installed: true),
    const PluginInfo(id: 'happy3d', name: 'Happy3D', description: '3D建模软件插件，支持场景编辑、材质贴图、渲染导出', icon: '😊', category: '3D 设计', installed: true),
    const PluginInfo(id: 'maodou3d', name: '毛豆科技3D建模', description: '教育3D建模软件插件，支持模型创建、场景搭建、材质编辑', icon: '🫘', category: '3D 设计', installed: true),
    const PluginInfo(id: 'makerlab', name: 'MakerLab', description: '3D打印管理平台插件，支持切片、打印管理、模型库', icon: '🧪', category: '工业设计', installed: true),
    const PluginInfo(id: 'crealitycloud', name: 'Creality Cloud', description: '云端3D打印平台插件，支持模型上传、云端切片、远程打印', icon: '☁️', category: '工业设计', installed: true),
    const PluginInfo(id: 'flashprint', name: 'FlashPrint', description: '3D打印切片软件插件，支持切片配置、支撑编辑、打印预览', icon: '⚡', category: '工业设计', installed: true),
    const PluginInfo(id: 'flashstudio', name: 'Flash Studio', description: '3D打印管理软件插件，支持模型编辑、支撑生成、打印管理', icon: '💡', category: '工业设计', installed: true),
    const PluginInfo(id: 'snapmakerluban', name: 'Snapmaker Luban', description: '多功能CAM软件插件，支持CNC雕刻、激光切割、3D打印', icon: '🖨️', category: '工业设计', installed: true),
    const PluginInfo(id: 'snapmakerorca', name: 'Snapmaker Orca', description: '3D打印切片软件插件，基于OrcaSlicer，支持校准、打印管理', icon: '🐋', category: '工业设计', installed: true),
    const PluginInfo(id: 'buildplanner', name: 'Build Planner', description: '3D打印排布软件插件，支持模型排布、材料估算、时间预估', icon: '📋', category: '工业设计', installed: true),
    const PluginInfo(id: 'flashdental', name: 'FlashDental', description: '牙科3D打印软件插件，支持牙模导入、模型编辑、切片', icon: '🦷', category: '工业设计', installed: true),
    const PluginInfo(id: 'waxjetprint', name: 'WaxJetPrint', description: '蜡模3D打印软件插件，支持蜡模导入、模型优化、切片', icon: '🕯️', category: '工业设计', installed: true),
  ];

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

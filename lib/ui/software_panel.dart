// lib/ui/software_panel.dart
import 'package:flutter/material.dart';
import '../models/session.dart';
import 'plugin_marketplace.dart';

class SoftwareInfo {
  final String id;
  final String name;
  final String icon;
  final DesignCategory category;
  final bool connected;
  final String? version;

  const SoftwareInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    this.connected = false,
    this.version,
  });
}

class SoftwarePanel extends StatelessWidget {
  const SoftwarePanel({super.key});

  static const List<SoftwareInfo> _defaultSoftware = [
    SoftwareInfo(id: 'figma', name: 'Figma', icon: '🎨', category: DesignCategory.web, connected: false),
    SoftwareInfo(id: 'blender', name: 'Blender', icon: '🔷', category: DesignCategory.threeD, connected: false),
    SoftwareInfo(id: 'autocad', name: 'AutoCAD', icon: '📐', category: DesignCategory.arch, connected: false),
    SoftwareInfo(id: 'photoshop', name: 'Photoshop', icon: '🖼️', category: DesignCategory.ad, connected: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('已安装插件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('安装插件'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PluginMarketplace())),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _defaultSoftware.length,
            itemBuilder: (context, index) => _buildSoftwareCard(context, _defaultSoftware[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSoftwareCard(BuildContext context, SoftwareInfo software) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(software.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(software.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    _categoryLabel(software.category),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  if (software.version != null)
                    Text('v${software.version}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            _buildStatusIndicator(software.connected),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: connected ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? '已连接' : '未连接',
            style: TextStyle(
              fontSize: 12,
              color: connected ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(DesignCategory cat) {
    return switch (cat) {
      DesignCategory.web => 'Web 设计',
      DesignCategory.ad => '广告设计',
      DesignCategory.industrial => '工业设计',
      DesignCategory.threeD => '3D 设计',
      DesignCategory.arch => '建筑设计',
      DesignCategory.interior => '装修设计',
    };
  }
}

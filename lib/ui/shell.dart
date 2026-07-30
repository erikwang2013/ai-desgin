import 'package:flutter/material.dart';
import '../models/session.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final DesignCategory selectedDomain;
  final int selectedTabIndex;
  final ValueChanged<DesignCategory>? onDomainChanged;
  final ValueChanged<int>? onTabSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedDomain,
    this.selectedTabIndex = 0,
    this.onDomainChanged,
    this.onTabSelected,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _domains = [
    (DesignCategory.web, 'Web 设计', Icons.language),
    (DesignCategory.ad, '广告设计', Icons.campaign),
    (DesignCategory.industrial, '工业设计', Icons.precision_manufacturing),
    (DesignCategory.threeD, '3D 设计', Icons.view_in_ar),
    (DesignCategory.arch, '建筑设计', Icons.architecture),
    (DesignCategory.interior, '装修设计', Icons.chair),
  ];

  static const _tabs = [
    (Icons.chat, '对话'),
    (Icons.list_alt, '任务'),
    (Icons.extension, '插件'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'AI Design Studio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '设计领域',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ..._domains.map(_buildDomainTile),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '导航',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ...List.generate(_tabs.length, _buildNavTile),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int index) {
    final (icon, label) = _tabs[index];
    final isSelected = index == widget.selectedTabIndex;
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
      selected: isSelected,
      onTap: () => widget.onTabSelected?.call(index),
    );
  }

  Widget _buildDomainTile((DesignCategory, String, IconData) domain) {
    final (cat, label, icon) = domain;
    final isSelected = cat == widget.selectedDomain;
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      selected: isSelected,
      dense: true,
      onTap: () => widget.onDomainChanged?.call(cat),
    );
  }
}

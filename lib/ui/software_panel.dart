import 'package:flutter/material.dart';
import '../models/session.dart';
import '../core/plugin_manager.dart';
import '../core/builtin_plugins.dart';
import '../plugin_sdk/design_plugin.dart';
import 'plugin_marketplace.dart';

class SoftwarePanel extends StatelessWidget {
  final PluginManager pluginManager;
  final Map<String, bool>? connectionStatus;

  const SoftwarePanel({super.key, required this.pluginManager, this.connectionStatus});

  @override
  Widget build(BuildContext context) {
    final plugins = pluginManager.getAll();
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PluginMarketplace(pluginManager: pluginManager))),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plugins.length,
            itemBuilder: (context, index) => _buildSoftwareCard(context, plugins[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSoftwareCard(BuildContext context, DesignPlugin plugin) {
    final status = connectionStatus?[plugin.id];
    final icon = softwareIcons[plugin.id] ?? '🔌';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plugin.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    plugin.category.label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text('v${plugin.version}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            _buildStatusIndicator(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool? connected) {
    if (connected == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text('检测中...', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
      );
    }
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
}

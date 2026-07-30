import 'package:flutter/material.dart';
import 'plugin_marketplace.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('模型配置'),
            subtitle: const Text('管理 API endpoint 和密钥'),
            onTap: () => _showComingSoon(context, '模型配置'),
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('插件市场'),
            subtitle: const Text('浏览和安装插件'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PluginMarketplace())),
          ),
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('代理设置'),
            subtitle: const Text('配置网络代理'),
            onTap: () => _showComingSoon(context, '代理设置'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('AI Design Studio v0.1.0'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - 即将推出'), duration: const Duration(seconds: 2)),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Design Studio'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: v0.1.0'),
            SizedBox(height: 8),
            Text('一款 AI 驱动的设计软件自动化工具。'),
            SizedBox(height: 8),
            Text('支持 Figma、Blender、AutoCAD、Photoshop 等主流设计软件的脚本生成与执行。'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }
}

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
          const ListTile(
            leading: Icon(Icons.api),
            title: Text('模型配置'),
            subtitle: Text('管理 API endpoint 和密钥'),
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('插件市场'),
            subtitle: const Text('浏览和安装插件'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PluginMarketplace())),
          ),
          const ListTile(
            leading: Icon(Icons.wifi),
            title: Text('代理设置'),
            subtitle: Text('配置网络代理'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('AI Design Studio v0.1.0'),
          ),
        ],
      ),
    );
  }
}

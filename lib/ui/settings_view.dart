import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: const [
          ListTile(title: Text('模型配置'), subtitle: Text('管理 API endpoint 和密钥')),
          ListTile(title: Text('插件市场'), subtitle: Text('浏览和安装插件')),
          ListTile(title: Text('代理设置'), subtitle: Text('配置网络代理')),
          ListTile(title: Text('关于'), subtitle: Text('AI Design Studio v0.1.0')),
        ],
      ),
    );
  }
}

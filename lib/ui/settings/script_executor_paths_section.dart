import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/script_executor_configs.dart';

/// “脚本执行路径”设置区：Blender/FreeCAD/OpenSCAD 每行一个可选填的
/// 自定义可执行文件路径，留空 = 自动探测。改动即保存到 SharedPreferences，
/// key 与执行器共用（`executor_path_override_<pluginId>`），无需单独按钮。
class ScriptExecutorPathsSection extends StatefulWidget {
  const ScriptExecutorPathsSection({super.key});

  @override
  State<ScriptExecutorPathsSection> createState() =>
      _ScriptExecutorPathsSectionState();
}

class _ScriptExecutorPathsSectionState
    extends State<ScriptExecutorPathsSection> {
  static const _entries = [
    ('blender', 'Blender'),
    ('freecad', 'FreeCAD'),
    ('openscad', 'OpenSCAD'),
  ];

  final Map<String, TextEditingController> _ctrls = {
    for (final e in _entries) e.$1: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      for (final e in _entries) {
        _ctrls[e.$1]?.text =
            prefs.getString(executorPathOverrideKey(e.$1)) ?? '';
      }
    } catch (_) {}
  }

  Future<void> _save(String pluginId, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(executorPathOverrideKey(pluginId), value.trim());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 2),
          child: Text('脚本执行路径',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('自动探测顺序：自定义路径 → PATH → 常见安装目录',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        for (final e in _entries)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _ctrls[e.$1],
              onChanged: (v) => _save(e.$1, v),
              decoration: InputDecoration(
                labelText: e.$2,
                hintText: '留空自动探测',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
      ],
    );
  }
}

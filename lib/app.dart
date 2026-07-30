import 'package:flutter/material.dart';
import 'models/session.dart';
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

  void _onTabSelected(int tab) => setState(() => _currentTab = tab);
  void _onDomainChanged(DesignCategory domain) => setState(() => _currentDomain = domain);

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedDomain: _currentDomain,
      onDomainChanged: _onDomainChanged,
      onTabSelected: _onTabSelected,
      child: IndexedStack(
        index: _currentTab,
        children: [
          ChatView(
            key: ValueKey('chat_${_currentDomain.name}'),
            onSubmit: (_) async {
              await Future.delayed(const Duration(seconds: 1));
              return '任务已提交，正在通过 Claude Code 生成脚本...';
            },
          ),
          const TaskDashboard(),
          const SoftwarePanel(),
        ],
      ),
    );
  }
}

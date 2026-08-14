import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import 'category_labels.dart';
import '../core/plugin_manager.dart';
import '../core/model_router.dart';
import '../core/locale_provider.dart';
import 'settings_view.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final DesignCategory selectedDomain;
  final int selectedTabIndex;
  final ValueChanged<DesignCategory>? onDomainChanged;
  final ValueChanged<int>? onTabSelected;
  final PluginManager? pluginManager;
  final LocaleProvider? localeProvider;
  final ModelRouter? modelRouter;
  final String? currentBackendId;
  final ValueChanged<String>? onBackendChanged;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedDomain,
    this.selectedTabIndex = 0,
    this.onDomainChanged,
    this.onTabSelected,
    this.pluginManager,
    this.localeProvider,
    this.modelRouter,
    this.currentBackendId,
    this.onBackendChanged,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _domains = [
    (DesignCategory.web, Icons.language),
    (DesignCategory.ad, Icons.campaign),
    (DesignCategory.industrial, Icons.precision_manufacturing),
    (DesignCategory.threeD, Icons.view_in_ar),
    (DesignCategory.arch, Icons.architecture),
    (DesignCategory.interior, Icons.chair),
  ];

  static const _tabIcons = [Icons.list_alt, Icons.extension, Icons.history];
  // 导航项 → IndexedStack 实际 index（app.dart children: Chat=0, Tasks=1, History=2, Plugins=3）。
  static const _tabStackIndices = [1, 3, 2];

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)?.appTitle ?? 'AI Design',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    AppLocalizations.of(context)?.designDomains ?? 'Design Domains',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ..._domains.map(_buildDomainTile),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    AppLocalizations.of(context)?.navigation ?? 'Navigation',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ...List.generate(_tabIcons.length, _buildNavTile),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsView(
                  pluginManager: widget.pluginManager,
                  localeProvider: widget.localeProvider,
                  modelRouter: widget.modelRouter,
                  currentBackendId: widget.currentBackendId,
                  onBackendChanged: widget.onBackendChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int i) {
    final icon = _tabIcons[i];
    final stackIndex = _tabStackIndices[i];
    final l10n = AppLocalizations.of(context);
    final labels = [l10n?.tabTasks, l10n?.tabPlugins, l10n?.tabHistory];
    final label = labels[i] ?? ['Tasks', 'Plugins', 'History'][i];
    final isSelected = stackIndex == widget.selectedTabIndex;
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
      selected: isSelected,
      onTap: () => widget.onTabSelected?.call(stackIndex),
    );
  }

  Widget _buildDomainTile((DesignCategory, IconData) domain) {
    final (cat, icon) = domain;
    final isSelected = cat == widget.selectedDomain;
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(cat.localizedLabel(l10n), style: const TextStyle(fontSize: 14)),
      selected: isSelected,
      dense: true,
      onTap: () => widget.onDomainChanged?.call(cat),
    );
  }
}

import 'package:yaml/yaml.dart';
import '../models/session.dart';

enum TaskComplexity { simple, moderate, creative }

class ModelRoute {
  final List<DesignCategory>? domains;
  final TaskComplexity? complexity;
  final String model;

  const ModelRoute({this.domains, this.complexity, required this.model});

  bool matches(DesignCategory domain, TaskComplexity taskComplexity) {
    if (domains != null && !domains!.contains(domain)) return false;
    if (complexity != null && complexity != taskComplexity) return false;
    return true;
  }
}

class ModelRouter {
  String _defaultModel = 'claude-sonnet-4-6';
  final List<ModelRoute> _routes = [];

  Future<void> loadConfigFromString(String yamlContent) async {
    final doc = loadYaml(yamlContent);
    _defaultModel = doc['default'] as String? ?? _defaultModel;
    _routes.clear();

    final routes = doc['routes'] as YamlList? ?? [];
    for (final r in routes) {
      final domainsRaw = r['domains'] as YamlList?;
      final domains = domainsRaw?.map((d) {
        switch (d.toString()) {
          case 'web':
            return DesignCategory.web;
          case 'ad':
            return DesignCategory.ad;
          case 'industrial':
            return DesignCategory.industrial;
          case 'threeD':
            return DesignCategory.threeD;
          case 'arch':
            return DesignCategory.arch;
          case 'interior':
            return DesignCategory.interior;
          default:
            return DesignCategory.web;
        }
      }).toList();

      TaskComplexity? complexity;
      final comp = r['complexity']?.toString();
      if (comp == 'simple') {
        complexity = TaskComplexity.simple;
      } else if (comp == 'moderate') {
        complexity = TaskComplexity.moderate;
      } else if (comp == 'creative') {
        complexity = TaskComplexity.creative;
      }

      _routes.add(ModelRoute(
        domains: domains,
        complexity: complexity,
        model: r['model'].toString(),
      ));
    }
  }

  String route({
    required DesignCategory domain,
    required String task,
    TaskComplexity? forceComplexity,
    String? overrideModel,
  }) {
    if (overrideModel != null) return overrideModel;
    final complexity = forceComplexity ?? _inferComplexity(task);
    for (final route in _routes) {
      if (route.matches(domain, complexity)) return route.model;
    }
    return _defaultModel;
  }

  TaskComplexity _inferComplexity(String task) {
    final creativeKeywords = ['设计', '创意', '方案', '风格', 'layout', 'design'];
    final simpleKeywords = [
      '改名',
      '导出',
      '删除',
      '列表',
      'rename',
      'export',
      'delete',
      'list',
    ];
    for (final kw in creativeKeywords) {
      if (task.contains(kw)) return TaskComplexity.creative;
    }
    for (final kw in simpleKeywords) {
      if (task.contains(kw)) return TaskComplexity.simple;
    }
    return TaskComplexity.moderate;
  }
}

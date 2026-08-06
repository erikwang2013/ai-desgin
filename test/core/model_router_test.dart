import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/model_router.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  late ModelRouter router;

  setUp(() async {
    router = ModelRouter();
    await router.loadConfigFromString('''
default: claude-sonnet-4-6
routes:
  - domains: [web, ad]
    complexity: creative
    model: claude-opus-4-7
  - domains: [industrial, threeD, arch, interior]
    model: claude-opus-4-7
  - complexity: simple
    model: claude-haiku-4-5
''');
  });

  test('routes web creative task to opus', () {
    final model = router.route(domain: DesignCategory.web, task: '创意 layout 方案');
    expect(model, 'claude-opus-4-7');
  });

  test('routes architectural task to opus', () {
    final model = router.route(domain: DesignCategory.arch, task: '设计立面图');
    expect(model, 'claude-opus-4-7');
  });

  test('routes simple task to haiku', () {
    final model = router.route(
      domain: DesignCategory.web, task: 'rename layers',
      forceComplexity: TaskComplexity.simple,
    );
    expect(model, 'claude-haiku-4-5');
  });

  test('falls back to default', () {
    final model = router.route(domain: DesignCategory.web, task: 'some task');
    expect(model, 'claude-sonnet-4-6');
  });

  test('allows override model', () {
    final model = router.route(
      domain: DesignCategory.web, task: 'design page',
      overrideModel: 'gemini-pro',
    );
    expect(model, 'gemini-pro');
  });

  test('setDefaultModel overrides routing fallback', () {
    router.setDefaultModel('custom-model');
    expect(router.defaultModel, 'custom-model');
    final model = router.route(domain: DesignCategory.web, task: 'some task');
    expect(model, 'custom-model');
  });

  test('routes without a model key are skipped', () async {
    final custom = ModelRouter();
    await custom.loadConfigFromString('''
default: claude-sonnet-4-6
routes:
  - domains: [web]
  - complexity: simple
    model: claude-haiku-4-5
''');
    // Route without a model must not match; creative task falls back to default.
    expect(custom.route(domain: DesignCategory.web, task: '创意方案'),
        'claude-sonnet-4-6');
    // Routes with a model still work.
    expect(custom.route(domain: DesignCategory.web, task: 'rename layers',
        forceComplexity: TaskComplexity.simple), 'claude-haiku-4-5');
  });

  test('failed config load rolls back previous routes and default', () async {
    router.setDefaultModel('custom-model');
    await router.loadConfigFromString('default: [x, y]\nroutes: []');
    expect(router.defaultModel, 'custom-model');
    final model = router.route(
      domain: DesignCategory.web, task: 'rename layers',
      forceComplexity: TaskComplexity.simple,
    );
    expect(model, 'claude-haiku-4-5');
  });

  test('keywords config overrides built-in complexity inference', () async {
    final custom = ModelRouter();
    await custom.loadConfigFromString('''
default: claude-sonnet-4-6
keywords:
  simple: [copy]
  creative: [paint]
routes:
  - complexity: simple
    model: claude-haiku-4-5
  - complexity: creative
    model: claude-opus-4-7
''');

    expect(custom.route(domain: DesignCategory.web, task: 'copy this layer'),
        'claude-haiku-4-5');
    expect(custom.route(domain: DesignCategory.web, task: 'paint the scene'),
        'claude-opus-4-7');
    // Built-in keyword '改名' is no longer recognized after override.
    expect(custom.route(domain: DesignCategory.web, task: '改名导出'),
        'claude-sonnet-4-6');
  });
}

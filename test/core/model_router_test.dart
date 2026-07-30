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
    final model = router.route(domain: DesignCategory.web, task: '设计一个landing page');
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
}

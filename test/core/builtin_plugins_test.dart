import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/builtin_plugins.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  group('builtInPlugins smoke tests', () {
    test('all plugins have non-empty id, name, and icon', () {
      for (final p in builtInPlugins) {
        expect(p.id, isNotEmpty, reason: 'Plugin $p has empty id');
        expect(p.name, isNotEmpty, reason: 'Plugin ${p.id} has empty name');
        expect(softwareIcons.containsKey(p.id), true,
            reason: 'Plugin ${p.id} missing icon');
      }
    });

    test('all plugins have valid category', () {
      for (final p in builtInPlugins) {
        expect(DesignCategory.values.contains(p.category), true,
            reason: 'Plugin ${p.id} has invalid category');
      }
    });

    test('all plugins have valid scriptLanguage', () {
      for (final p in builtInPlugins) {
        expect(p.scriptLanguage, isNotEmpty,
            reason: 'Plugin ${p.id} has empty scriptLanguage');
      }
    });

    test('all plugins have at least one action and file format', () {
      for (final p in builtInPlugins) {
        expect(p.capabilities.actions, isNotEmpty,
            reason: 'Plugin ${p.id} has no actions');
        expect(p.capabilities.fileFormats, isNotEmpty,
            reason: 'Plugin ${p.id} has no fileFormats');
      }
    });

    test('all plugins have a description', () {
      for (final p in builtInPlugins) {
        expect(softwareDescriptions.containsKey(p.id), true,
            reason: 'Plugin ${p.id} missing description');
        expect(softwareDescriptions[p.id], isNotEmpty,
            reason: 'Plugin ${p.id} has empty description');
      }
    });

    test('no duplicate plugin IDs', () {
      final ids = builtInPlugins.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate plugin IDs found');
    });

    test('plugin count matches icon and description map sizes', () {
      expect(builtInPlugins.length, softwareIcons.length,
          reason: 'Icon map size mismatch');
      expect(builtInPlugins.length, softwareDescriptions.length,
          reason: 'Description map size mismatch');
    });

    test('all actions are in Chinese (not English)', () {
      for (final p in builtInPlugins) {
        for (final action in p.capabilities.actions) {
          final hasChinese = action.contains(RegExp(r'[一-鿿]'));
          expect(hasChinese, true,
              reason: 'Plugin ${p.id} has non-Chinese action: "$action"');
        }
      }
    });
  });
}

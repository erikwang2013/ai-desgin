import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/version.dart';

void main() {
  test('appVersion is a semver string', () {
    expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
  });

  test('appVersion is not a placeholder', () {
    expect(appVersion, isNot('0.0.0'));
  });

  test('appVersion matches the version declared in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml must declare a version');
    expect(match!.group(1), appVersion);
  });
}

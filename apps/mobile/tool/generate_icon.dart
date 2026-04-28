// Run with: dart run tool/generate_icon.dart
// Generates assets/icons/app_icon.png (1024x1024) and app_icon_foreground.png
// Requires: dart:ui (run via `flutter test --plain-name generate` or as a Flutter test)

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  // This must be run as a Flutter integration test or via flutter run
  // because dart:ui requires the Flutter engine.
  print('Run this as: flutter test tool/generate_icon_test.dart');
  print('Or use any image editor to create a 1024x1024 PNG:');
  print('  Background: #0D4A2E (forest green)');
  print('  Foreground: scan frame brackets (white), leaf shape (mint #4EE890)');
  print('  Place the resulting PNG at: assets/icons/app_icon.png');
  print('');
  print('Then run: dart run flutter_launcher_icons');
  exit(0);
}

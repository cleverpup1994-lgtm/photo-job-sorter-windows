// Helpers for the README screenshots. Not part of the app.
//
// Widget tests normally draw text with a placeholder font and no shadows.
// These helpers load real fonts and turn shadows back on, so the images
// rendered by tool/screenshots look like the running app.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _fontsDir = 'tool/screenshots/fonts';

Future<void> loadScreenshotFonts() async {
  final files = Directory(_fontsDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.otf') || f.path.endsWith('.ttf'))
      .toList();

  ByteData bytesOf(File f) => ByteData.sublistView(Uint8List.fromList(f.readAsBytesSync()));

  for (final family in ['Roboto', 'Segoe UI', '.AppleSystemUIFont', 'FlutterTest', 'Ahem']) {
    final loader = FontLoader(family);
    for (final f in files.where((f) => f.path.contains('Inter-'))) {
      loader.addFont(Future.value(bytesOf(f)));
    }
    await loader.load();
  }
  for (final f in files.where((f) => f.path.contains('MaterialIcons'))) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(bytesOf(f)))).load();
  }
}

/// Phone screen (390 x 844 points, 3x like a modern phone).
void usePhoneScreen(WidgetTester tester) => _screen(tester, const Size(390, 844), 3);

/// Laptop window (1280 x 800 points at 1.5x).
void useDesktopScreen(WidgetTester tester) => _screen(tester, const Size(1280, 800), 1.5);

void _screen(WidgetTester tester, Size logical, double dpr) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);
}

/// Writes the current screen to tool/screenshots/out/<name>.png
/// (run with --update-goldens).
Future<void> capture(WidgetTester tester, String name) async {
  // Tests hide shadows by default; show them for the picture, then restore
  // the default before the test ends (the framework checks it).
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
  for (final r in tester.allRenderObjects) {
    r.markNeedsPaint();
  }
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('out/$name.png'),
  );
  debugDisableShadows = true;
}

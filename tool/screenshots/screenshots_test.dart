// Renders README screenshots of the desktop window using the drawn sample
// photos in tool/screenshots/sample_photos (made by make_sample_photos.py).
// Run: flutter test tool/screenshots/screenshots_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_job_sorter/logic/grouping.dart';
import 'package:photo_job_sorter/logic/sorter_controller.dart';
import 'package:photo_job_sorter/main.dart';

import 'shot_helpers.dart';

const _folder = 'tool/screenshots/sample_photos';

/// Sample photos with the times a tech would take them: a few seconds
/// apart on one car, then several minutes while they walk to the next.
List<PhotoItem> _samplePhotos() {
  final files = Directory(_folder)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg'))
      .map((f) => f.absolute.path)
      .toList()
    ..sort();
  var t = DateTime(2026, 11, 20, 8, 12);
  final photos = <PhotoItem>[];
  for (final path in files) {
    // Every plate close-up opens a new car (see make_sample_photos.py).
    final opensCar = const {0, 5, 9, 14, 18}.contains(photos.length);
    t = t.add(opensCar && photos.isNotEmpty ? const Duration(minutes: 9) : const Duration(seconds: 25));
    photos.add(PhotoItem(path, t));
  }
  return photos;
}

void main() {
  setUpAll(loadScreenshotFonts);

  testWidgets('screenshot: empty window', (tester) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(PhotoJobSorterApp(controller: SorterController()));
    await capture(tester, 'sorter_empty');
  });

  testWidgets('screenshot: photos grouped by vehicle', (tester) async {
    useDesktopScreen(tester);
    final controller = SorterController()
      ..load(r'D:\Camera\2026-11-20', _samplePhotos());
    final names = ['HBX-4821 windshield', 'KLM-3307 door glass', 'RTX-9152 windshield'];
    for (var i = 0; i < names.length && i < controller.groups.length; i++) {
      controller.rename(controller.groups[i], names[i]);
    }
    await warmImages(tester, [
      for (final g in controller.groups)
        for (final photo in g.photos) ResizeImage(FileImage(File(photo.path)), width: 284),
    ]);
    await tester.pumpWidget(PhotoJobSorterApp(controller: controller));
    await tester.pump();
    await capture(tester, 'sorter_grouped');
  });
}

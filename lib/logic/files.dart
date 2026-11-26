import 'dart:io';

import 'package:path/path.dart' as p;

import 'grouping.dart';

/// File types the app can preview on Windows.
const photoExtensions = {'.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp'};

/// Lists photos in [folder] (not subfolders). "Taken at" comes from the file's
/// modified time, which cameras and Windows Explorer copies keep intact.
Future<List<PhotoItem>> scanFolder(String folder) async {
  final photos = <PhotoItem>[];
  await for (final entity in Directory(folder).list(followLinks: false)) {
    if (entity is! File) continue;
    if (!photoExtensions.contains(p.extension(entity.path).toLowerCase())) continue;
    photos.add(PhotoItem(entity.path, await entity.lastModified()));
  }
  return photos;
}

class ExportResult {
  final int copied;
  final List<String> errors;

  const ExportResult(this.copied, this.errors);
}

/// Copies files according to [steps]. Originals are never moved or deleted,
/// and an existing file at a destination is never overwritten.
Future<ExportResult> runExport(
  List<CopyStep> steps, {
  void Function(int done, int total)? onProgress,
}) async {
  var copied = 0;
  final errors = <String>[];

  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    try {
      final target = File(step.to);
      if (await target.exists()) {
        errors.add('Skipped ${p.basename(step.to)}: already exists in ${p.basename(p.dirname(step.to))}');
      } else {
        await target.parent.create(recursive: true);
        await File(step.from).copy(step.to);
        copied++;
      }
    } on FileSystemException catch (e) {
      errors.add('${p.basename(step.from)}: ${e.osError?.message ?? e.message}');
    }
    onProgress?.call(i + 1, steps.length);
  }
  return ExportResult(copied, errors);
}

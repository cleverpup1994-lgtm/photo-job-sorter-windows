import 'package:path/path.dart' as p;

/// One photo on disk and when it was taken.
class PhotoItem {
  final String path;
  final DateTime takenAt;

  const PhotoItem(this.path, this.takenAt);

  String get fileName => p.basename(path);
}

/// A run of photos that belong to one vehicle or job.
class PhotoGroup {
  final List<PhotoItem> photos;

  /// Folder name the group will be exported to, e.g. a plate number.
  String name;

  PhotoGroup(this.photos, this.name);

  PhotoItem get first => photos.first;
}

/// Splits photos into groups. Pure logic: no files, no Flutter, fully tested.
///
/// How a new group starts:
///  1. Automatically, when the time gap since the previous photo is longer
///     than [gap] (the tech moved on to the next car).
///  2. Manually, at any photo whose path is in [manualStarts]
///     (e.g. the licence-plate close-up that opens each vehicle).
///  3. A path in [manualJoins] cancels an automatic split at that photo,
///     for when someone paused mid-job.
List<PhotoGroup> groupPhotos(
  List<PhotoItem> photos, {
  required Duration gap,
  Set<String> manualStarts = const {},
  Set<String> manualJoins = const {},
  String namePrefix = 'Vehicle',
}) {
  final sorted = [...photos]..sort((a, b) {
      final byTime = a.takenAt.compareTo(b.takenAt);
      return byTime != 0 ? byTime : a.fileName.compareTo(b.fileName);
    });

  final groups = <PhotoGroup>[];
  PhotoItem? previous;
  for (final photo in sorted) {
    final timeSplit = previous != null && photo.takenAt.difference(previous.takenAt) > gap;
    final startsNew = groups.isEmpty ||
        manualStarts.contains(photo.path) ||
        (timeSplit && !manualJoins.contains(photo.path));

    if (startsNew) {
      groups.add(PhotoGroup([photo], '$namePrefix ${groups.length + 1}'));
    } else {
      groups.last.photos.add(photo);
    }
    previous = photo;
  }
  return groups;
}

/// Windows-safe folder name: strips characters Windows forbids, trims dots and
/// spaces, and avoids reserved device names like CON or COM1.
String safeFolderName(String raw, {String fallback = 'Unnamed'}) {
  var name = raw.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ');
  name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  name = name.replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');
  if (name.isEmpty) return fallback;
  const reserved = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
  };
  if (reserved.contains(name.toUpperCase())) name = '_$name';
  return name.length > 80 ? name.substring(0, 80).trim() : name;
}

/// One file copy the export will perform.
class CopyStep {
  final String from;
  final String to;

  const CopyStep(this.from, this.to);
}

/// Works out every copy up front, so the user can see the result before
/// anything touches the disk. Duplicate group names get " (2)", " (3)"...
/// and two photos with the same file name never overwrite each other.
List<CopyStep> planExport(List<PhotoGroup> groups, String destinationRoot) {
  final usedFolders = <String, int>{};
  final steps = <CopyStep>[];

  for (final group in groups) {
    final base = safeFolderName(group.name);
    final key = base.toLowerCase(); // Windows paths are case-insensitive.
    final seen = usedFolders[key] ?? 0;
    usedFolders[key] = seen + 1;
    final folder = seen == 0 ? base : '$base (${seen + 1})';

    final usedFiles = <String>{};
    for (final photo in group.photos) {
      var fileName = photo.fileName;
      var n = 2;
      while (!usedFiles.add(fileName.toLowerCase())) {
        fileName = '${p.basenameWithoutExtension(photo.fileName)} ($n)${p.extension(photo.fileName)}';
        n++;
      }
      steps.add(CopyStep(photo.path, p.join(destinationRoot, folder, fileName)));
    }
  }
  return steps;
}

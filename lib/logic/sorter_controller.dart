import 'package:flutter/foundation.dart';

import 'grouping.dart';

/// Holds the session: loaded photos, grouping settings, manual splits and the
/// names typed for each group. Screens listen and rebuild on change.
class SorterController extends ChangeNotifier {
  List<PhotoItem> _photos = const [];
  String? sourceFolder;
  Duration gap = const Duration(minutes: 3);
  final Set<String> _manualStarts = {};
  final Set<String> _manualJoins = {};

  /// Names typed by the user, keyed by the first photo of the group, so a
  /// name sticks to its vehicle even when other groups change around it.
  final Map<String, String> _names = {};

  List<PhotoGroup> _groups = const [];
  List<PhotoGroup> get groups => _groups;
  int get photoCount => _photos.length;
  bool get hasPhotos => _photos.isNotEmpty;

  void load(String folder, List<PhotoItem> photos) {
    sourceFolder = folder;
    _photos = photos;
    _manualStarts.clear();
    _manualJoins.clear();
    _names.clear();
    _regroup();
  }

  void setGap(Duration value) {
    gap = value;
    _regroup();
  }

  /// Is this photo the first of its group?
  bool startsGroup(PhotoItem photo) => _groups.any((g) => g.first.path == photo.path);

  /// Tap on a photo: make it start a new vehicle, or merge it back into the
  /// previous one if it already starts a group.
  void toggleSplit(PhotoItem photo) {
    if (_groups.isNotEmpty && _groups.first.first.path == photo.path) return;
    if (startsGroup(photo)) {
      _manualStarts.remove(photo.path);
      _manualJoins.add(photo.path);
      _names.remove(photo.path);
    } else {
      _manualJoins.remove(photo.path);
      _manualStarts.add(photo.path);
    }
    _regroup();
  }

  void rename(PhotoGroup group, String name) {
    _names[group.first.path] = name;
    group.name = name;
    // No regroup needed; the text field already shows the new name.
  }

  void _regroup() {
    _groups = groupPhotos(
      _photos,
      gap: gap,
      manualStarts: _manualStarts,
      manualJoins: _manualJoins,
    );
    for (final g in _groups) {
      final saved = _names[g.first.path];
      if (saved != null && saved.trim().isNotEmpty) g.name = saved;
    }
    notifyListeners();
  }
}

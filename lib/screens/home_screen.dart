import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../logic/files.dart';
import '../logic/grouping.dart';
import '../logic/sorter_controller.dart';

/// Single-window desktop layout: toolbar on top, one section per vehicle below.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final SorterController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  SorterController get c => widget.controller;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openFolder() async {
    final folder = await getDirectoryPath(confirmButtonText: 'Open photos');
    if (folder == null) return;
    setState(() => _busy = true);
    try {
      final photos = await scanFolder(folder);
      c.load(folder, photos);
      if (photos.isEmpty) _snack('No photos found in that folder.');
    } on FileSystemException catch (e) {
      _snack("Couldn't read that folder: ${e.message}");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final dest = await getDirectoryPath(confirmButtonText: 'Export here');
    if (dest == null || !mounted) return;

    if (c.sourceFolder != null && p.equals(dest, c.sourceFolder!)) {
      _snack('Pick a different folder than the one the photos are in.');
      return;
    }

    final steps = planExport(c.groups, dest);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export photos?'),
        content: Text(
          'Copy ${steps.length} photos into ${c.groups.length} folders inside\n$dest\n\n'
          'Your original photos stay where they are.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Copy photos')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final progress = ValueNotifier<double>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Copying…'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, v, __) => LinearProgressIndicator(value: v),
        ),
      ),
    );

    final result = await runExport(
      steps,
      onProgress: (done, total) => progress.value = done / total,
    );
    if (!mounted) return;
    Navigator.of(context).pop(); // close progress dialog
    progress.dispose();

    if (result.errors.isEmpty) {
      _snack('Done: copied ${result.copied} photos into ${c.groups.length} folders.');
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Copied ${result.copied}, ${result.errors.length} skipped'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: Text(result.errors.join('\n'))),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Photo Job Sorter'),
          actions: [
            if (c.hasPhotos) ...[
              const Text('New vehicle after a gap of '),
              DropdownButton<int>(
                value: c.gap.inMinutes,
                underline: const SizedBox.shrink(),
                items: [1, 2, 3, 5, 10, 15, 30]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                    .toList(),
                onChanged: (m) => c.setGap(Duration(minutes: m ?? 3)),
              ),
              const SizedBox(width: 16),
            ],
            OutlinedButton.icon(
              onPressed: _busy ? null : _openFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open folder'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _busy || !c.hasPhotos ? null : _export,
              icon: const Icon(Icons.drive_file_move_outline),
              label: const Text('Export to folders'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : !c.hasPhotos
                ? const _EmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryBar(controller: c),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: c.groups.length,
                          itemBuilder: (context, i) => _GroupSection(
                            key: ValueKey(c.groups[i].first.path),
                            group: c.groups[i],
                            controller: c,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Sort a day of job photos in minutes', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              '1. Open the folder from your camera.\n'
              '2. Photos are grouped by vehicle automatically, using time gaps.\n'
              '3. Click any photo (like a plate close-up) to start a new vehicle there.\n'
              '4. Type the plate or job name on each group.\n'
              '5. Export: each group is copied into its own folder.',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.controller});

  final SorterController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        '${controller.photoCount} photos · ${controller.groups.length} vehicles · '
        'from ${controller.sourceFolder}    Tip: click a photo to start or merge a vehicle.',
        style: TextStyle(color: scheme.onSurfaceVariant),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _GroupSection extends StatefulWidget {
  const _GroupSection({super.key, required this.group, required this.controller});

  final PhotoGroup group;
  final SorterController controller;

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  late final _name = TextEditingController(text: widget.group.name);

  @override
  void didUpdateWidget(covariant _GroupSection old) {
    super.didUpdateWidget(old);
    if (widget.group.name != _name.text) _name.text = widget.group.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final first = g.first.takenAt;
    final last = g.photos.last.takenAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Folder name (plate or job #)',
                      isDense: true,
                    ),
                    onChanged: (v) => widget.controller.rename(g, v),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${g.photos.length} photos · ${_time(first)}–${_time(last)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in g.photos)
                  _Thumb(
                    photo: photo,
                    startsGroup: identical(photo, g.first),
                    onTap: () => widget.controller.toggleSplit(photo),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.startsGroup, required this.onTap});

  final PhotoItem photo;
  final bool startsGroup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: startsGroup
          ? '${photo.fileName}\nClick to merge into the previous vehicle'
          : '${photo.fileName}\nClick to start a new vehicle here',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: startsGroup ? scheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.file(
                  File(photo.path),
                  width: 142,
                  height: 106,
                  fit: BoxFit.cover,
                  cacheWidth: 284, // decode small: keeps 500+ photos fast
                  errorBuilder: (_, __, ___) => Container(
                    width: 142,
                    height: 106,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _time(photo.takenAt),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _time(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

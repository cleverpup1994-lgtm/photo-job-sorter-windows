import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photo_job_sorter/logic/files.dart';
import 'package:photo_job_sorter/logic/grouping.dart';

void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('sorter_test'));
  tearDown(() async => tmp.delete(recursive: true));

  Future<File> makeFile(String name, DateTime modified) async {
    final f = File(p.join(tmp.path, 'in', name));
    await f.parent.create(recursive: true);
    await f.writeAsString(name);
    await f.setLastModified(modified);
    return f;
  }

  test('scan finds photos only and reads their time', () async {
    await makeFile('a.JPG', DateTime(2026, 11, 26, 8, 0));
    await makeFile('b.png', DateTime(2026, 11, 26, 8, 5));
    await makeFile('notes.txt', DateTime(2026, 11, 26, 8, 6));

    final photos = await scanFolder(p.join(tmp.path, 'in'));

    expect(photos.map((x) => x.fileName).toSet(), {'a.JPG', 'b.png'});
    expect(photos.firstWhere((x) => x.fileName == 'a.JPG').takenAt.hour, 8);
  });

  test('export copies into folders and keeps originals', () async {
    final a = await makeFile('a.jpg', DateTime(2026, 11, 26, 8, 0));
    final b = await makeFile('b.jpg', DateTime(2026, 11, 26, 9, 0));
    final groups = [
      PhotoGroup([PhotoItem(a.path, DateTime(2026))], 'Car 1'),
      PhotoGroup([PhotoItem(b.path, DateTime(2026))], 'Car 2'),
    ];
    final out = p.join(tmp.path, 'out');
    var lastProgress = 0;

    final result = await runExport(
      planExport(groups, out),
      onProgress: (done, total) => lastProgress = done,
    );

    expect(result.copied, 2);
    expect(result.errors, isEmpty);
    expect(lastProgress, 2);
    expect(File(p.join(out, 'Car 1', 'a.jpg')).existsSync(), isTrue);
    expect(File(p.join(out, 'Car 2', 'b.jpg')).existsSync(), isTrue);
    expect(a.existsSync(), isTrue, reason: 'originals are never moved');
  });

  test('export never overwrites an existing file', () async {
    final a = await makeFile('a.jpg', DateTime(2026));
    final target = File(p.join(tmp.path, 'out', 'Car', 'a.jpg'));
    await target.parent.create(recursive: true);
    await target.writeAsString('keep me');

    final result = await runExport([CopyStep(a.path, target.path)]);

    expect(result.copied, 0);
    expect(result.errors.single, contains('already exists'));
    expect(await target.readAsString(), 'keep me');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photo_job_sorter/logic/grouping.dart';

PhotoItem photo(String name, int hour, int minute, [int second = 0]) =>
    PhotoItem(p.join('cam', name), DateTime(2026, 11, 26, hour, minute, second));

void main() {
  group('groupPhotos', () {
    test('splits on time gaps longer than the setting', () {
      final groups = groupPhotos([
        photo('a.jpg', 8, 0),
        photo('b.jpg', 8, 1),
        photo('c.jpg', 8, 2),
        photo('d.jpg', 8, 20), // next car
        photo('e.jpg', 8, 21),
      ], gap: const Duration(minutes: 3));

      expect(groups.length, 2);
      expect(groups[0].photos.map((x) => x.fileName), ['a.jpg', 'b.jpg', 'c.jpg']);
      expect(groups[1].photos.map((x) => x.fileName), ['d.jpg', 'e.jpg']);
      expect(groups[1].name, 'Vehicle 2');
    });

    test('sorts by time even if files arrive out of order', () {
      final groups = groupPhotos([
        photo('late.jpg', 9, 0),
        photo('early.jpg', 8, 0),
      ], gap: const Duration(hours: 2));

      expect(groups.single.photos.first.fileName, 'early.jpg');
    });

    test('a manual start splits back-to-back photos (plate close-up)', () {
      final plate = photo('plate2.jpg', 8, 1, 30);
      final groups = groupPhotos(
        [photo('plate1.jpg', 8, 0), photo('chip.jpg', 8, 1), plate, photo('crack.jpg', 8, 2)],
        gap: const Duration(minutes: 10),
        manualStarts: {plate.path},
      );

      expect(groups.length, 2);
      expect(groups[1].first.fileName, 'plate2.jpg');
    });

    test('a manual join cancels an automatic split (lunch break mid-job)', () {
      final afterLunch = photo('after.jpg', 13, 0);
      final groups = groupPhotos(
        [photo('before.jpg', 12, 0), afterLunch],
        gap: const Duration(minutes: 3),
        manualJoins: {afterLunch.path},
      );

      expect(groups.length, 1);
    });

    test('empty input gives no groups', () {
      expect(groupPhotos([], gap: const Duration(minutes: 3)), isEmpty);
    });
  });

  group('safeFolderName', () {
    test('removes characters Windows does not allow', () {
      expect(safeFolderName('ABC/123:"Truck"?'), 'ABC 123 Truck');
    });

    test('blank becomes a fallback and reserved names are escaped', () {
      expect(safeFolderName('   '), 'Unnamed');
      expect(safeFolderName('con'), '_con');
      expect(safeFolderName('...plate.'), 'plate');
    });
  });

  group('planExport', () {
    test('one folder per group, files keep their names', () {
      final g1 = PhotoGroup([photo('a.jpg', 8, 0), photo('b.jpg', 8, 1)], 'TX ABC-1234');
      final steps = planExport([g1], 'out');

      expect(steps.map((s) => s.to), [
        p.join('out', 'TX ABC-1234', 'a.jpg'),
        p.join('out', 'TX ABC-1234', 'b.jpg'),
      ]);
    });

    test('duplicate group names get numbered folders', () {
      final steps = planExport([
        PhotoGroup([photo('a.jpg', 8, 0)], 'Ford'),
        PhotoGroup([photo('b.jpg', 9, 0)], 'ford'),
      ], 'out');

      expect(p.basename(p.dirname(steps[1].to)), 'ford (2)');
    });

    test('same file name twice in a group never overwrites', () {
      final steps = planExport([
        PhotoGroup([
          PhotoItem(p.join('cam1', 'IMG_1.jpg'), DateTime(2026)),
          PhotoItem(p.join('cam2', 'IMG_1.jpg'), DateTime(2026)),
        ], 'Job'),
      ], 'out');

      expect(steps.map((s) => p.basename(s.to)), ['IMG_1.jpg', 'IMG_1 (2).jpg']);
    });
  });
}

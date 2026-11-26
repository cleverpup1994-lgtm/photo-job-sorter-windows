import 'package:flutter_test/flutter_test.dart';
import 'package:photo_job_sorter/logic/grouping.dart';
import 'package:photo_job_sorter/logic/sorter_controller.dart';

void main() {
  final photos = [
    PhotoItem('a.jpg', DateTime(2026, 11, 26, 8, 0)),
    PhotoItem('b.jpg', DateTime(2026, 11, 26, 8, 1)),
    PhotoItem('c.jpg', DateTime(2026, 11, 26, 8, 2)),
    PhotoItem('d.jpg', DateTime(2026, 11, 26, 9, 0)),
  ];

  test('loads and groups by gap', () {
    final c = SorterController()..load('cam', photos);
    expect(c.groups.length, 2);
  });

  test('clicking a photo splits, clicking again merges back', () {
    final c = SorterController()..load('cam', photos);
    final b = photos[1];

    c.toggleSplit(b);
    expect(c.groups.length, 3);
    expect(c.startsGroup(b), isTrue);

    c.toggleSplit(b);
    expect(c.groups.length, 2);
  });

  test('the very first photo cannot be merged away', () {
    final c = SorterController()..load('cam', photos);
    c.toggleSplit(photos.first);
    expect(c.groups.length, 2);
  });

  test('typed names survive regrouping', () {
    final c = SorterController()..load('cam', photos);
    c.rename(c.groups[1], 'TX ABC-1234');

    c.setGap(const Duration(minutes: 30)); // regroup
    c.toggleSplit(photos[1]); // regroup again

    expect(c.groups.last.name, 'TX ABC-1234');
  });

  test('a wider gap merges groups', () {
    final c = SorterController()..load('cam', photos);
    c.setGap(const Duration(hours: 2));
    expect(c.groups.length, 1);
  });
}

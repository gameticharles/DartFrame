import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('DataCube Selection', () {
    test('selectFrames filters frames by condition', () {
      final cube = DataCube.generate(5, 3, 2, (d, r, c) => d);
      final selected = cube.selectFrames((frame) => frame.rowCount == 3);

      expect(selected.depth, equals(5));
    });

    test('selectByIndices selects specific frames', () {
      final cube = DataCube.generate(10, 3, 2, (d, r, c) => d);
      final selected = cube.selectByIndices([0, 2, 4]);

      expect(selected.depth, equals(3));
      // Get actual column name
      final colName = selected.getFrame(0).columns.first.toString();
      expect(selected.getFrame(0)[colName].data[0], equals(0));
      expect(selected.getFrame(1)[colName].data[0], equals(2));
      expect(selected.getFrame(2)[colName].data[0], equals(4));
    });

    test('selectByIndices throws on invalid index', () {
      final cube = DataCube.generate(5, 3, 2, (d, r, c) => d);

      expect(
        () => cube.selectByIndices([10]),
        throwsRangeError,
      );
    });

    test('selectDepthRange selects frame range', () {
      final cube = DataCube.generate(10, 3, 2, (d, r, c) => d);
      final selected = cube.selectDepthRange(2, 5);

      expect(selected.depth, equals(4)); // 2, 3, 4, 5
    });

    test('countFrames counts matching frames', () {
      final cube = DataCube.generate(10, 3, 2, (d, r, c) => d);
      final count = cube.countFrames((frame) => frame.rowCount == 3);

      expect(count, equals(10));
    });

    test('anyFrame returns true if any frame matches', () {
      final cube = DataCube.generate(5, 3, 2, (d, r, c) => d);
      expect(cube.anyFrame((frame) => frame.rowCount == 3), isTrue);
      expect(cube.anyFrame((frame) => frame.rowCount == 10), isFalse);
    });

    test('allFrames returns true if all frames match', () {
      final cube = DataCube.generate(5, 3, 2, (d, r, c) => d);
      expect(cube.allFrames((frame) => frame.rowCount == 3), isTrue);
      expect(cube.allFrames((frame) => frame.rowCount == 10), isFalse);
    });

    test('findFirstFrame returns first matching index', () {
      final cube = DataCube.generate(10, 3, 2, (d, r, c) => d);
      final index = cube.findFirstFrame((frame) => frame.rowCount == 3);

      expect(index, equals(0));
    });

    test('findFirstFrame returns null if no match', () {
      final cube = DataCube.generate(5, 3, 2, (d, r, c) => d);
      final index = cube.findFirstFrame((frame) => frame.rowCount == 10);

      expect(index, isNull);
    });

    test('findLastFrame returns last matching index', () {
      final cube = DataCube.generate(10, 3, 2, (d, r, c) => d);
      final index = cube.findLastFrame((frame) => frame.rowCount == 3);

      expect(index, equals(9));
    });

    test('selectColumns selects specific columns', () {
      final cube = DataCube.generate(3, 5, 4, (d, r, c) => c);
      // Get actual column names from the cube
      final frame = cube.getFrame(0);
      final columnNames = frame.columns.cast<String>().take(2).toList();

      final selected = cube.selectColumns(columnNames);

      expect(selected.columns, equals(2));
      expect(selected.getFrame(0).columns.contains(columnNames[0]), isTrue);
      expect(selected.getFrame(0).columns.contains(columnNames[1]), isTrue);
    });

    test('selectColumns throws on invalid column', () {
      final cube = DataCube.generate(3, 5, 2, (d, r, c) => c);

      expect(
        () => cube.selectColumns(['invalid_column']),
        throwsArgumentError,
      );
    });

    test('filterValues filters across all frames', () {
      final cube = DataCube.generate(3, 3, 2, (d, r, c) => d + r + c);
      final filtered = cube.filterValues((x) => x > 2);

      // Values <= 2 should be null
      final frame0 = filtered.getFrame(0);
      final columnName = frame0.columns.first.toString();
      expect(frame0[columnName].data[0], isNull); // 0+0+0 = 0

      final frame2 = filtered.getFrame(2);
      final col1Name = frame2.columns.toList()[1].toString();
      expect(frame2[col1Name].data[2], isNotNull); // 2+2+1 = 5
    });

    test('whereColumn selects frames by column condition', () {
      final cube = DataCube.generate(5, 3, 2, (d, r, c) => d);
      // Get actual column name
      final columnName = cube.getFrame(0).columns.first.toString();
      final selected = cube.whereColumn(columnName, (x) => x >= 0);

      expect(selected.depth, greaterThan(0));
    });
  });
}

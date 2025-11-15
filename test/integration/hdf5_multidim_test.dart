import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('HDF5 Multi-dimensional Dataset Tests', () {
    test('Read 3D dataset with shape information', () async {
      // This test requires a 3D HDF5 file
      // Create one with Python first if needed
      final testFile = 'test_data/test_3d.h5';

      if (!FileIO().fileExistsSync(testFile)) {
        print('Skipping test - $testFile not found');
        print('Create with: python3 scripts/create_multidim_test_data.py');
        return;
      }

      final df = await FileReader.readHDF5(testFile, dataset: '/volume');

      // Check shape information
      expect(df.columns.contains('_shape'), isTrue);
      expect(df.columns.contains('_ndim'), isTrue);
      expect(df['_shape'][0], equals('2x3x4'));
      expect(df['_ndim'][0], equals(3));

      // Parse shape
      final shape =
          (df['_shape'][0] as String).split('x').map(int.parse).toList();
      expect(shape, equals([2, 3, 4]));

      // Check data
      final data = df['data'].data; // Get underlying list from Series
      expect(data.length, equals(24)); // 2*3*4

      // Verify flattened data (row-major order)
      expect(data[0], equals(0));
      expect(data[23], equals(23));
    });

    test('Read 4D dataset with shape information', () async {
      final testFile = 'test_data/test_4d.h5';

      if (!FileIO().fileExistsSync(testFile)) {
        print('Skipping test - $testFile not found');
        print('Create with: python3 scripts/create_multidim_test_data.py');
        return;
      }

      final df = await FileReader.readHDF5(testFile, dataset: '/tensor');

      // Check shape information
      expect(df['_shape'][0], equals('2x3x4x5'));
      expect(df['_ndim'][0], equals(4));

      // Parse shape
      final shape =
          (df['_shape'][0] as String).split('x').map(int.parse).toList();
      expect(shape, equals([2, 3, 4, 5]));

      // Check data
      final data = df['data'].data; // Get underlying list from Series
      expect(data.length, equals(120)); // 2*3*4*5
    });

    test('1D and 2D datasets still work as before', () async {
      // Ensure backward compatibility
      final testFile1D = 'test_data/test_1d.h5';
      final testFile2D = 'test_data/test_2d.h5';

      if (FileIO().fileExistsSync(testFile1D)) {
        final df1d = await FileReader.readHDF5(testFile1D, dataset: '/data');
        expect(df1d.columns.contains('data'), isTrue);
        // 1D datasets should not have shape columns
        expect(df1d.columns.contains('_shape'), isFalse);
      }

      if (FileIO().fileExistsSync(testFile2D)) {
        final df2d = await FileReader.readHDF5(testFile2D, dataset: '/data');
        expect(df2d.columns.length, greaterThan(1));
        // 2D datasets should not have shape columns
        expect(df2d.columns.contains('_shape'), isFalse);
      }
    });
  });
}

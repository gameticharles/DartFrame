import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

void main() async {
  setHdf5DebugMode(true);
  try {
    final hdf5File = await Hdf5File.open('example/data/test_attributes.h5');
    final dataset = await hdf5File.dataset('/data');
    final attributes = dataset.header.findAttributes();

    print('Dart reads ${attributes.length} attributes:\n');

    final expectedValues = {
      'units': 'meters',
      'description': 'Test dataset with attributes',
      'version': 1.0,
      'count': 100,
      'range': [0.0, 100.0],
      'dimensions': [10, 10],
      'author': 'Test Suite',
      'date': '2024-01-01',
    };

    for (final attr in attributes) {
      final expected = expectedValues[attr.name];
      final match = _valuesMatch(attr.value, expected);
      final status = match ? '✓' : '✗';

      print('$status ${attr.name}:');
      print('  Expected: $expected');
      print('  Got:      ${attr.value}');
      print('');
    }

    await hdf5File.close();
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack: $stackTrace');
  }
}

bool _valuesMatch(dynamic actual, dynamic expected) {
  if (actual == expected) return true;
  if (actual is List && expected is List) {
    if (actual.length != expected.length) return false;
    for (int i = 0; i < actual.length; i++) {
      if (actual[i] is double && expected[i] is double) {
        if ((actual[i] - expected[i]).abs() > 0.001) return false;
      } else if (actual[i] != expected[i]) {
        return false;
      }
    }
    return true;
  }
  if (actual is double && expected is double) {
    return (actual - expected).abs() < 0.001;
  }
  return false;
}

import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  test('Series extension methods work', () {
    // Create a Series directly
    var s1 = Series([1, 2, 3], name: 'test');
    print('Direct Series sum: ${s1.sum()}');

    // Create from DataFrame
    var df = DataFrame([
      ['A', 1],
      ['B', 2],
    ], columns: [
      'group',
      'value'
    ]);

    var s2 = df['value'];
    print('Series from DataFrame type: ${s2.runtimeType}');
    print('Series from DataFrame: $s2');

    // Try to call sum
    try {
      var result = s2.sum();
      print('Sum result: $result');
    } catch (e) {
      print('Error calling sum: $e');
    }

    // Try explicit cast
    try {
      Series s3 = s2 as Series;
      var result = s3.sum();
      print('Sum with cast: $result');
    } catch (e) {
      print('Error with cast: $e');
    }
  });
}

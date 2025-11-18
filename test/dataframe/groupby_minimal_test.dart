import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  test('Series sum method exists', () {
    var df = DataFrame([
      ['A', 1],
      ['A', 2],
      ['B', 3],
    ], columns: [
      'group',
      'value'
    ]);

    var series = df['value'];
    print('Series type: ${series.runtimeType}');
    print('Series has sum: ${series.sum()}');

    expect(series.sum(), equals(6));
  });

  test('Series isEqual method exists', () {
    var df = DataFrame([
      ['A', 1],
      ['A', 2],
      ['B', 3],
    ], columns: [
      'group',
      'value'
    ]);

    var series = df['group'];
    var mask = series.isEqual('A');
    print('Mask: ${mask.toList()}');

    expect(mask.toList(), equals([true, true, false]));
  });

  test('GroupBy basic sum', () {
    var df = DataFrame([
      ['A', 1],
      ['A', 2],
      ['B', 3],
    ], columns: [
      'group',
      'value'
    ]);

    var result = df.groupBy2(['group']).sum();
    print('Result: $result');

    expect(result.rowCount, equals(2));
  });
}

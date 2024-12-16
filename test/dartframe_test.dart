import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  test('DataFrame', () {
    DataFrame df = DataFrame(
      columns: ['A', 'B'],
      data: [
        [1, 2],
        [3, 4],
      ],
    );
    expect(df.toString(), 'A  B\n1  2\n3  4');
  });
}

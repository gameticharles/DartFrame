import 'package:dartframe/dartframe.dart';

void main(List<String> arguments) {
  DataFrame df = DataFrame(
    columns: ['A', 'B'],
     [
      [1, 2],
      [3, 4],
    ],
  );
  print(df.toString());
}

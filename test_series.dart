import 'package:dartframe/dartframe.dart';

void main() {
  var s = Series([1, 2, 3, 4, 5], name: 'test');
  print('Series: $s');
  
  try {
    print('Median: ${s.median()}');
  } catch (e) {
    print('Median error: $e');
  }
  
  try {
    print('Quantile: ${s.quantile(0.25)}');
  } catch (e) {
    print('Quantile error: $e');
  }
  
  try {
    print('Std: ${s.std()}');
  } catch (e) {
    print('Std error: $e');
  }
}
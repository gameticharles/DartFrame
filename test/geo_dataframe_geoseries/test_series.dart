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

  print('\n=== Basic Statistics ===');
  print('Count: ${s.count()}');
  print('Mean: ${s.mean()}');
  print('Min: ${s.min()}');
  print('Max: ${s.max()}');
  print('Sum: ${s.sum()}');

  print('\n=== Describe ===');
  var desc = s.describe();
  desc.forEach((key, value) => print('$key: $value'));

  // Test with missing values
  print('\n=== With Missing Values ===');
  var s2 = Series([1, null, 3, null, 5], name: 'with_nulls');
  print('Series with nulls: $s2');

  print('Count (skipna=true): ${s2.count(skipna: true)}');
  print('Count (skipna=false): ${s2.count(skipna: false)}');
  print('Mean: ${s2.mean()}');
  print('Min: ${s2.min()}');
  print('Max: ${s2.max()}');
  print('Sum: ${s2.sum()}');

  print('\n=== Empty Series ===');
  var s3 = Series([], name: 'empty');
  print('Empty series describe:');
  var emptyDesc = s3.describe();
  emptyDesc.forEach((key, value) => print('$key: $value'));
}
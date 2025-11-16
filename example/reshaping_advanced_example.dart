import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Advanced Reshaping Operations Examples ===\n');

  // Example 1: Wide to Long Transformation
  print('1. Wide to Long Transformation:');
  var wideData = DataFrame([
    [1, 'A', 100, 110, 200, 210],
    [2, 'B', 150, 160, 250, 260],
  ], columns: [
    'id',
    'group',
    'sales_2020',
    'sales_2021',
    'profit_2020',
    'profit_2021'
  ]);

  print('\nWide Format:');
  print(wideData);

  var longData = wideData.wideToLong(
    stubnames: ['sales', 'profit'],
    i: ['id', 'group'],
    j: 'year',
    sep: '_',
  );

  print('\nLong Format:');
  print(longData);

  // Example 2: Get Dummies (One-Hot Encoding)
  print('\n2. Get Dummies - One-Hot Encoding:');
  var categories = DataFrame([
    ['Red', 'Small', 10],
    ['Blue', 'Large', 20],
    ['Red', 'Medium', 15],
    ['Green', 'Small', 12],
  ], columns: [
    'Color',
    'Size',
    'Value'
  ]);

  print('\nOriginal Data:');
  print(categories);

  var dummies = categories.getDummiesEnhanced(
    columns: ['Color', 'Size'],
  );

  print('\nWith Dummy Variables:');
  print(dummies);

  // Example 3: Get Dummies with Drop First
  print('\n3. Get Dummies with Drop First (Avoid Multicollinearity):');
  var data = DataFrame([
    ['A', 100],
    ['B', 200],
    ['C', 150],
  ], columns: [
    'Category',
    'Value'
  ]);

  var dummiesDropFirst = data.getDummiesEnhanced(
    columns: ['Category'],
    dropFirst: true,
  );

  print(dummiesDropFirst);

  // Example 4: Get Dummies with Boolean Type
  print('\n4. Get Dummies with Boolean Type:');
  var boolData = DataFrame([
    ['Yes'],
    ['No'],
    ['Yes'],
  ], columns: [
    'Response'
  ]);

  var boolDummies = boolData.getDummiesEnhanced(
    columns: ['Response'],
    dtype: 'bool',
  );

  print(boolDummies);

  // Example 5: Get Dummies with Custom Prefix
  print('\n5. Get Dummies with Custom Prefix:');
  var prefixData = DataFrame([
    ['Male'],
    ['Female'],
    ['Male'],
  ], columns: [
    'Gender'
  ]);

  var customPrefix = prefixData.getDummiesEnhanced(
    columns: ['Gender'],
    prefix: 'is',
    prefixSep: '_',
  );

  print(customPrefix);

  // Example 6: Get Dummies with NA Indicator
  print('\n6. Get Dummies with NA Indicator:');
  var naData = DataFrame([
    ['A'],
    [null],
    ['B'],
    ['A'],
  ], columns: [
    'Category'
  ]);

  var naIndicator = naData.getDummiesEnhanced(
    columns: ['Category'],
    dummyNa: true,
  );

  print(naIndicator);

  // Example 7: Swap Levels in MultiIndex
  print('\n7. Swap Levels in MultiIndex:');
  var multiIndex = DataFrame([
    [100],
    [200],
    [300],
  ], columns: [
    'Value'
  ]);

  multiIndex = DataFrame.fromMap(
    {'Value': multiIndex['Value'].toList()},
    index: ['level0_level1', 'level0_level2', 'level1_level1'],
  );

  print('\nOriginal MultiIndex:');
  print(multiIndex);

  var swapped = multiIndex.swapLevel(0, 1);
  print('\nSwapped Levels:');
  print(swapped);

  // Example 8: Reorder Levels
  print('\n8. Reorder Levels in MultiIndex:');
  var reorderData = DataFrame([
    [1],
    [2],
  ], columns: [
    'Value'
  ]);

  reorderData = DataFrame.fromMap(
    {'Value': reorderData['Value'].toList()},
    index: ['a_b_c', 'd_e_f'],
  );

  print('\nOriginal Order (a_b_c):');
  print(reorderData);

  var reordered = reorderData.reorderLevels([2, 0, 1]);
  print('\nReordered (c_a_b):');
  print(reordered);

  // Example 9: Wide to Long with Non-Numeric Suffixes
  print('\n9. Wide to Long with Text Suffixes:');
  var textSuffixData = DataFrame([
    [1, 10, 20, 30, 40],
    [2, 15, 25, 35, 45],
  ], columns: [
    'id',
    'score_pre',
    'score_post',
    'rank_pre',
    'rank_post'
  ]);

  print('\nWide Format:');
  print(textSuffixData);

  var longTextSuffix = textSuffixData.wideToLong(
    stubnames: ['score', 'rank'],
    i: ['id'],
    j: 'time',
    sep: '_',
    suffix: r'\w+', // Match word characters
  );

  print('\nLong Format:');
  print(longTextSuffix);

  print('\n=== Advanced Reshaping Examples Complete ===');
}

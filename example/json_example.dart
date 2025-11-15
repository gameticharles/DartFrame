import 'package:dartframe/dartframe.dart';

void main() async {
  print('=== JSON File I/O Example ===\n');

  // Create a sample DataFrame
  final df = DataFrame.fromMap({
    'product': ['Widget', 'Gadget', 'Doohickey', 'Thingamajig'],
    'quantity': [100, 150, 75, 200],
    'price': [9.99, 19.99, 14.99, 24.99],
    'in_stock': [true, true, false, true],
  });

  print('Original DataFrame:');
  print(df);
  print('\n');

  // === Records Format (Default) ===
  print('--- Records Format ---');
  print('Format: [{"col1": val1, "col2": val2}, ...]\n');

  await FileWriter.writeJson(df, 'output_records.json', orient: 'records');
  print('✓ Written to output_records.json');

  final dfRecords = await FileReader.readJson('output_records.json');
  print('Read back:');
  print(dfRecords);
  print('\n');

  // === Columns Format ===
  print('--- Columns Format ---');
  print('Format: {"col1": [val1, val2, ...], "col2": [...]}\n');

  await FileWriter.writeJson(df, 'output_columns.json', orient: 'columns');
  print('✓ Written to output_columns.json');

  final dfColumns =
      await FileReader.readJson('output_columns.json', orient: 'columns');
  print('Read back:');
  print(dfColumns);
  print('\n');

  // === Index Format ===
  print('--- Index Format ---');
  print('Format: {"0": {"col1": val1, "col2": val2}, "1": {...}}\n');

  await FileWriter.writeJson(df, 'output_index.json', orient: 'index');
  print('✓ Written to output_index.json');

  final dfIndex =
      await FileReader.readJson('output_index.json', orient: 'index');
  print('Read back:');
  print(dfIndex);
  print('\n');

  // === Values Format ===
  print('--- Values Format ---');
  print('Format: [[val1, val2, ...], [val3, val4, ...]]\n');

  await FileWriter.writeJson(df, 'output_values.json', orient: 'values');
  print('✓ Written to output_values.json');

  final dfValues = await FileReader.readJson('output_values.json',
      orient: 'values', columns: ['product', 'quantity', 'price', 'in_stock']);
  print('Read back:');
  print(dfValues);
  print('\n');

  // === Pretty Printing ===
  print('--- Pretty Printing ---');

  await FileWriter.writeJson(df, 'output_pretty.json',
      orient: 'records', indent: 2);
  print('✓ Written to output_pretty.json with indentation');
  print('\n');

  // === Auto-detect Format ===
  print('--- Auto-detect Format ---');

  await FileWriter.write(df, 'output_auto.json');
  print('✓ Written using generic FileWriter');

  final dfAuto = await FileReader.read('output_auto.json');
  print('Read using generic FileReader:');
  print(dfAuto);
  print('\n');

  // === Working with Nested Data ===
  print('--- Complex Data Types ---');

  final complexDf = DataFrame.fromMap({
    'id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie'],
    'score': [95.5, 87.3, 92.1],
    'passed': [true, true, true],
  });

  await FileWriter.writeJson(complexDf, 'output_complex.json',
      orient: 'records', indent: 2);
  print('✓ Written complex data with multiple types');

  final dfComplex = await FileReader.readJson('output_complex.json');
  print('Read back:');
  print(dfComplex);
  print('\n');

  print('=== All JSON operations completed successfully! ===');
}

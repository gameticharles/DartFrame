import 'package:dartframe/dartframe.dart';

void main() async {
  print('=== CSV and Excel File I/O Example ===\n');

  // Create a sample DataFrame
  final df = DataFrame.fromMap({
    'name': ['Alice', 'Bob', 'Charlie', 'David'],
    'age': [25, 30, 35, 28],
    'salary': [50000.0, 60000.0, 75000.0, 55000.0],
    'active': [true, true, false, true],
  });

  print('Original DataFrame:');
  print(df);
  print('\n');

  // === CSV Examples ===
  print('--- CSV Operations ---');

  // Write to CSV
  await FileWriter.writeCsv(df, 'example_output.csv');
  print('✓ Written to example_output.csv');

  // Write CSV with custom options
  await FileWriter.writeCsv(
    df,
    'example_output_custom.csv',
    fieldDelimiter: ';',
    includeIndex: true,
  );
  print('✓ Written to example_output_custom.csv (with semicolon delimiter)');

  // Read from CSV
  final dfFromCsv = await FileReader.readCsv('example_output.csv');
  print('\nRead from CSV:');
  print(dfFromCsv);

  // Read CSV with custom options
  final dfFromCsvCustom = await FileReader.readCsv(
    'example_output_custom.csv',
    fieldDelimiter: ';',
  );
  print('\nRead from CSV (custom delimiter):');
  print(dfFromCsvCustom);

  print('\n--- Excel Operations ---');

  // Write to Excel
  await FileWriter.writeExcel(df, 'example_output.xlsx');
  print('✓ Written to example_output.xlsx');

  // Write Excel with custom options
  await FileWriter.writeExcel(
    df,
    'example_output_custom.xlsx',
    sheetName: 'Employees',
    includeIndex: true,
  );
  print('✓ Written to example_output_custom.xlsx (sheet: Employees)');

  // Read from Excel
  final dfFromExcel = await FileReader.readExcel('example_output.xlsx');
  print('\nRead from Excel:');
  print(dfFromExcel);

  // Read Excel with custom options
  final dfFromExcelCustom = await FileReader.readExcel(
    'example_output_custom.xlsx',
    sheetName: 'Employees',
  );
  print('\nRead from Excel (custom sheet):');
  print(dfFromExcelCustom);

  // List sheets in Excel file
  final sheets = await FileReader.listExcelSheets('example_output.xlsx');
  print('\nSheets in example_output.xlsx: $sheets');

  print('\n--- Generic FileReader/FileWriter ---');

  // Generic read/write (auto-detects format by extension)
  await FileWriter.write(df, 'auto_output.csv');
  print('✓ Written using generic FileWriter');

  final dfAuto = await FileReader.read('auto_output.csv');
  print('\nRead using generic FileReader:');
  print(dfAuto);

  print('\n=== All operations completed successfully! ===');
}

# CSV and Excel File I/O

DartFrame now supports reading and writing CSV and Excel files using industry-standard packages:
- **CSV**: Uses the `csv` package (v6.0.0)
- **Excel**: Uses the `excel` package (v4.0.6)

## Quick Start

### Reading Files

```dart
import 'package:dartframe/dartframe.dart';

// Read CSV file
final df = await FileReader.readCsv('data.csv');

// Read Excel file
final df = await FileReader.readExcel('data.xlsx');

// Auto-detect format by extension
final df = await FileReader.read('data.csv');
```

### Writing Files

```dart
// Write to CSV
await FileWriter.writeCsv(df, 'output.csv');

// Write to Excel
await FileWriter.writeExcel(df, 'output.xlsx');

// Auto-detect format by extension
await FileWriter.write(df, 'output.csv');
```

## CSV Operations

### Reading CSV Files

```dart
// Basic read
final df = await FileReader.readCsv('data.csv');

// Custom delimiter
final df = await FileReader.readCsv(
  'data.csv',
  fieldDelimiter: ';',
);

// Skip rows and limit data
final df = await FileReader.readCsv(
  'data.csv',
  skipRows: 2,
  maxRows: 100,
);

// No header row
final df = await FileReader.readCsv(
  'data.csv',
  hasHeader: false,
  columnNames: ['col1', 'col2', 'col3'],
);

// Custom text delimiters
final df = await FileReader.readCsv(
  'data.csv',
  textDelimiter: "'",
  fieldDelimiter: '\t',
);
```

### Writing CSV Files

```dart
// Basic write
await FileWriter.writeCsv(df, 'output.csv');

// Custom delimiter
await FileWriter.writeCsv(
  df,
  'output.csv',
  fieldDelimiter: ';',
);

// Include row index
await FileWriter.writeCsv(
  df,
  'output.csv',
  includeIndex: true,
);

// Without header
await FileWriter.writeCsv(
  df,
  'output.csv',
  includeHeader: false,
);

// Custom line endings (Windows)
await FileWriter.writeCsv(
  df,
  'output.csv',
  eol: '\r\n',
);
```

### CSV Options

#### Read Options
- `fieldDelimiter`: Field separator (default: `,`)
- `textDelimiter`: Text quote character (default: `"`)
- `textEndDelimiter`: Ending text delimiter (default: same as textDelimiter)
- `eol`: Line ending character (default: auto-detect)
- `hasHeader`: Whether first row is header (default: `true`)
- `skipRows`: Number of rows to skip (default: `0`)
- `maxRows`: Maximum rows to read (default: all)
- `columnNames`: Custom column names when no header

#### Write Options
- `fieldDelimiter`: Field separator (default: `,`)
- `textDelimiter`: Text quote character (default: `"`)
- `textEndDelimiter`: Ending text delimiter (default: same as textDelimiter)
- `eol`: Line ending character (default: `\n`)
- `includeHeader`: Include header row (default: `true`)
- `includeIndex`: Include row index column (default: `false`)

## Excel Operations

### Reading Excel Files

```dart
// Basic read (first sheet)
final df = await FileReader.readExcel('data.xlsx');

// Specific sheet
final df = await FileReader.readExcel(
  'data.xlsx',
  sheetName: 'Sheet2',
);

// Skip rows and limit data
final df = await FileReader.readExcel(
  'data.xlsx',
  skipRows: 1,
  maxRows: 50,
);

// No header row
final df = await FileReader.readExcel(
  'data.xlsx',
  hasHeader: false,
  columnNames: ['A', 'B', 'C'],
);

// List all sheets
final sheets = await FileReader.listExcelSheets('data.xlsx');
print('Available sheets: $sheets');
```

### Writing Excel Files

```dart
// Basic write
await FileWriter.writeExcel(df, 'output.xlsx');

// Custom sheet name
await FileWriter.writeExcel(
  df,
  'output.xlsx',
  sheetName: 'MyData',
);

// Include row index
await FileWriter.writeExcel(
  df,
  'output.xlsx',
  includeIndex: true,
);

// Without header
await FileWriter.writeExcel(
  df,
  'output.xlsx',
  includeHeader: false,
);
```

### Excel Options

#### Read Options
- `sheetName`: Name of sheet to read (default: first sheet)
- `hasHeader`: Whether first row is header (default: `true`)
- `skipRows`: Number of rows to skip (default: `0`)
- `maxRows`: Maximum rows to read (default: all)
- `columnNames`: Custom column names when no header

#### Write Options
- `sheetName`: Name of sheet to create (default: `'Sheet1'`)
- `includeHeader`: Include header row (default: `true`)
- `includeIndex`: Include row index column (default: `false`)

### Multi-Sheet Operations

Excel files often contain multiple sheets. DartFrame provides convenient methods to work with all sheets at once.

#### Reading All Sheets

```dart
// Read all sheets into a Map
final sheets = await FileReader.readAllExcelSheets('workbook.xlsx');

// Access individual sheets
final salesDf = sheets['Sales'];
final inventoryDf = sheets['Inventory'];

// Process all sheets
for (final entry in sheets.entries) {
  print('Sheet: ${entry.key}');
  print('Rows: ${entry.value.shape.rows}');
}

// Get sheet names
print('Available sheets: ${sheets.keys.toList()}');
```

#### Writing Multiple Sheets

```dart
// Create multiple DataFrames
final salesDf = DataFrame.fromMap({...});
final inventoryDf = DataFrame.fromMap({...});
final summaryDf = DataFrame.fromMap({...});

// Write all sheets at once
final sheets = {
  'Sales': salesDf,
  'Inventory': inventoryDf,
  'Summary': summaryDf,
};

await FileWriter.writeExcelSheets(sheets, 'report.xlsx');
```

#### Complete Multi-Sheet Example

```dart
// Read entire workbook
final workbook = await FileReader.readAllExcelSheets('data.xlsx');

// Process each sheet
final results = <String, DataFrame>{};
for (final entry in workbook.entries) {
  final sheetName = entry.key;
  final df = entry.value;
  
  // Perform some analysis
  final analyzed = df.describe();
  results['${sheetName}_Analysis'] = analyzed;
}

// Write results to new workbook
await FileWriter.writeExcelSheets(results, 'analysis_results.xlsx');
```

### Supported Excel Cell Types

The Excel reader automatically handles:
- **Text**: String values
- **Numbers**: Integer and double values
- **Booleans**: true/false values
- **Dates**: DateTime objects
- **Times**: Time values (as strings)
- **Formulas**: Formula text

## Generic File I/O

The `FileReader` and `FileWriter` classes automatically detect file format by extension:

```dart
// Reads CSV
final df1 = await FileReader.read('data.csv');

// Reads Excel
final df2 = await FileReader.read('data.xlsx');

// Reads HDF5
final df3 = await FileReader.read('data.h5');

// Writes based on extension
await FileWriter.write(df, 'output.csv');   // CSV
await FileWriter.write(df, 'output.xlsx');  // Excel
await FileWriter.write(df, 'output.json');  // JSON
```

### Supported Formats

| Extension | Format | Reader | Writer |
|-----------|--------|--------|--------|
| `.csv` | CSV | ✓ | ✓ |
| `.xlsx`, `.xls` | Excel | ✓ | ✓ |
| `.h5`, `.hdf5` | HDF5 | ✓ | ✗ |
| `.json` | JSON | ✗ | ✓ |
| `.parquet`, `.pq` | Parquet | ✓* | ✓* |

*Parquet support is basic/placeholder

## Complete Example

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create sample data
  final df = DataFrame.fromMap({
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35],
    'salary': [50000.0, 60000.0, 75000.0],
  });

  // Save to CSV
  await FileWriter.writeCsv(df, 'employees.csv');
  
  // Save to Excel with custom sheet name
  await FileWriter.writeExcel(
    df,
    'employees.xlsx',
    sheetName: 'Staff',
  );

  // Read back from CSV
  final dfCsv = await FileReader.readCsv('employees.csv');
  print('From CSV:');
  print(dfCsv);

  // Read back from Excel
  final dfExcel = await FileReader.readExcel(
    'employees.xlsx',
    sheetName: 'Staff',
  );
  print('\nFrom Excel:');
  print(dfExcel);

  // List sheets in Excel file
  final sheets = await FileReader.listExcelSheets('employees.xlsx');
  print('\nSheets: $sheets');
}
```

## Error Handling

```dart
try {
  final df = await FileReader.readCsv('data.csv');
} on CsvReadError catch (e) {
  print('CSV read error: $e');
} catch (e) {
  print('Unexpected error: $e');
}

try {
  final df = await FileReader.readExcel('data.xlsx');
} on ExcelReadError catch (e) {
  print('Excel read error: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Migration from Old API

If you were using the old placeholder implementations:

### Old CSV API
```dart
// Old (basic CSV-like parsing)
await FileWriter.writeCsv(df, 'output.csv',
  separator: ',',
  quoteChar: '"',
);
```

### New CSV API
```dart
// New (using csv package)
await FileWriter.writeCsv(df, 'output.csv',
  fieldDelimiter: ',',
  textDelimiter: '"',
);
```

### Old Excel API
```dart
// Old (CSV-like, not real Excel)
await FileReader.readExcel('data.xlsx',
  skipRows: 1,
  nRows: 100,
);
```

### New Excel API
```dart
// New (using excel package, real Excel files)
await FileReader.readExcel('data.xlsx',
  skipRows: 1,
  maxRows: 100,
  sheetName: 'Sheet1',
);
```

## Performance Tips

1. **Large CSV files**: Use `maxRows` to limit memory usage
2. **Excel files**: Specify `sheetName` to avoid reading all sheets
3. **Skip unnecessary rows**: Use `skipRows` to skip headers/metadata
4. **Batch processing**: Read in chunks using `skipRows` and `maxRows`

```dart
// Process large CSV in chunks
const chunkSize = 1000;
for (int i = 0; i < totalRows; i += chunkSize) {
  final chunk = await FileReader.readCsv(
    'large_file.csv',
    skipRows: i,
    maxRows: chunkSize,
  );
  // Process chunk
}
```

## See Also

- [DataFrame Documentation](dataframe.md)
- [HDF5 Documentation](hdf5.md)
- [csv package](https://pub.dev/packages/csv)
- [excel package](https://pub.dev/packages/excel)

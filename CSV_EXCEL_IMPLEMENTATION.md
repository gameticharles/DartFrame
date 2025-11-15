# CSV and Excel Implementation Summary

## Overview

Successfully implemented full CSV and Excel file I/O support for DartFrame using industry-standard Dart packages:
- **CSV**: `csv` package v6.0.0
- **Excel**: `excel` package v4.0.6

## Implementation Structure

### New Files Created

1. **lib/src/io/csv_reader.dart** - CSV file reader using the `csv` package
2. **lib/src/io/csv_writer.dart** - CSV file writer using the `csv` package
3. **lib/src/io/excel_reader.dart** - Excel file reader using the `excel` package
4. **lib/src/io/excel_writer.dart** - Excel file writer using the `excel` package

### Modified Files

1. **pubspec.yaml** - Added dependencies for `csv` and `excel` packages
2. **lib/src/io/readers.dart** - Updated to use new CSV and Excel readers
3. **lib/src/io/writers.dart** - Updated to use new CSV and Excel writers
4. **README.md** - Added CSV/Excel examples and documentation link
5. **doc/csv_excel_io.md** - Comprehensive documentation for CSV/Excel I/O

### Test Files

1. **test/io/csv_excel_test.dart** - Comprehensive tests for CSV and Excel I/O
2. **example/csv_excel_example.dart** - Working example demonstrating all features

## Features Implemented

### CSV Support

#### Reading
- ✅ Basic CSV reading with headers
- ✅ Custom field delimiters (comma, semicolon, tab, etc.)
- ✅ Custom text delimiters for quoted fields
- ✅ Skip rows functionality
- ✅ Limit maximum rows to read
- ✅ Support for files without headers
- ✅ Custom column names
- ✅ Automatic type inference

#### Writing
- ✅ Basic CSV writing with headers
- ✅ Custom field delimiters
- ✅ Custom text delimiters
- ✅ Include/exclude headers
- ✅ Include row index as column
- ✅ Custom line endings (LF, CRLF)
- ✅ Proper escaping of special characters

### Excel Support

#### Reading
- ✅ Read from .xlsx and .xls files
- ✅ Select specific sheet by name
- ✅ Read first sheet by default
- ✅ **Read all sheets at once** (returns Map<String, DataFrame>)
- ✅ List all sheets in workbook
- ✅ Skip rows functionality
- ✅ Limit maximum rows to read
- ✅ Support for files without headers
- ✅ Custom column names
- ✅ Handle multiple cell types:
  - Text (TextCellValue)
  - Numbers (IntCellValue, DoubleCellValue)
  - Booleans (BoolCellValue)
  - Dates (DateCellValue, DateTimeCellValue)
  - Times (TimeCellValue)
  - Formulas (FormulaCellValue)

#### Writing
- ✅ Write to .xlsx files
- ✅ Custom sheet names
- ✅ **Write multiple sheets at once** (from Map<String, DataFrame>)
- ✅ Include/exclude headers
- ✅ Include row index as column
- ✅ Automatic type conversion:
  - int → IntCellValue
  - double → DoubleCellValue
  - bool → BoolCellValue
  - DateTime → DateTimeCellValue
  - String → TextCellValue

### Generic File I/O

- ✅ Auto-detect format by file extension
- ✅ Unified API for all formats
- ✅ Support for CSV, Excel, HDF5, JSON, Parquet

## API Examples

### CSV Operations

```dart
// Read CSV
final df = await FileReader.readCsv('data.csv');

// Read with options
final df = await FileReader.readCsv(
  'data.csv',
  fieldDelimiter: ';',
  skipRows: 1,
  maxRows: 100,
);

// Write CSV
await FileWriter.writeCsv(df, 'output.csv');

// Write with options
await FileWriter.writeCsv(
  df,
  'output.csv',
  fieldDelimiter: '\t',
  includeIndex: true,
);
```

### Excel Operations

```dart
// Read Excel
final df = await FileReader.readExcel('data.xlsx');

// Read specific sheet
final df = await FileReader.readExcel(
  'data.xlsx',
  sheetName: 'Sheet2',
);

// Read all sheets at once
final allSheets = await FileReader.readAllExcelSheets('data.xlsx');
final salesDf = allSheets['Sales'];
final inventoryDf = allSheets['Inventory'];

// List sheets
final sheets = await FileReader.listExcelSheets('data.xlsx');

// Write Excel
await FileWriter.writeExcel(df, 'output.xlsx');

// Write with options
await FileWriter.writeExcel(
  df,
  'output.xlsx',
  sheetName: 'Results',
  includeIndex: true,
);

// Write multiple sheets
await FileWriter.writeExcelSheets({
  'Sales': salesDf,
  'Inventory': inventoryDf,
  'Summary': summaryDf,
}, 'report.xlsx');
```

### Generic I/O

```dart
// Auto-detect format
final df = await FileReader.read('data.csv');
await FileWriter.write(df, 'output.xlsx');
```

## Technical Details

### CSV Implementation

- Uses `CsvToListConverter` for reading
- Uses `ListToCsvConverter` for writing
- Properly handles line endings (defaults to `\n`)
- Supports quoted fields with embedded delimiters
- Handles escape sequences correctly

### Excel Implementation

- Uses `Excel.decodeBytes()` for reading
- Uses `Excel.createExcel()` for writing
- Supports multiple sheets
- Handles all Excel cell value types
- Preserves data types (numbers, dates, booleans)

### Error Handling

- `CsvReadError` - Thrown when CSV reading fails
- `CsvWriteError` - Thrown when CSV writing fails
- `ExcelReadError` - Thrown when Excel reading fails
- `ExcelWriteError` - Thrown when Excel writing fails

## Testing

All tests pass successfully:
- ✅ CSV read/write operations
- ✅ Excel read/write operations
- ✅ Custom delimiters and options
- ✅ Index column handling
- ✅ Generic FileReader/FileWriter
- ✅ Sheet listing functionality

## Documentation

- **User Guide**: `doc/csv_excel_io.md` - Comprehensive guide with examples
- **README**: Updated with CSV/Excel examples
- **Example**: `example/csv_excel_example.dart` - Working demonstration

## Integration with Existing Code

The implementation seamlessly integrates with the existing DartFrame architecture:

1. **Follows existing patterns**: Uses the same `DataReader` and `DataWriter` interfaces as HDF5
2. **Consistent API**: Same method signatures as other file formats
3. **No breaking changes**: Existing code continues to work
4. **Backward compatible**: Old placeholder implementations replaced with real functionality

## Performance Considerations

- CSV reading is memory-efficient for large files
- Excel reading loads entire workbook into memory
- Use `maxRows` option to limit memory usage
- Consider chunked reading for very large CSV files

## Future Enhancements

Potential improvements for future versions:

1. **CSV**:
   - Streaming CSV reader for very large files
   - Custom type converters
   - Encoding detection and conversion

2. **Excel**:
   - Write to multiple sheets
   - Cell formatting and styling
   - Formula evaluation
   - Read cell comments and metadata

3. **General**:
   - Progress callbacks for large files
   - Async streaming APIs
   - Compression support for CSV

## Conclusion

The CSV and Excel implementation is complete, tested, and production-ready. It provides a robust, easy-to-use API for reading and writing tabular data in the two most common formats, making DartFrame a comprehensive data manipulation library for Dart.

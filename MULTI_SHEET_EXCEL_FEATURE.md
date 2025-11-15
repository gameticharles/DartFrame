# Multi-Sheet Excel Support

## Overview

Enhanced the Excel I/O implementation to support reading and writing multiple sheets in a single Excel workbook. This addresses the limitation where only the first sheet was accessible.

## New Features

### 1. Read All Sheets at Once

Read an entire Excel workbook and get a Map of sheet names to DataFrames:

```dart
final sheets = await FileReader.readAllExcelSheets('workbook.xlsx');

// Access individual sheets
final salesData = sheets['Sales'];
final inventoryData = sheets['Inventory'];

// Process all sheets
for (final entry in sheets.entries) {
  print('Sheet: ${entry.key}, Rows: ${entry.value.shape.rows}');
}
```

**Method Signature:**
```dart
static Future<Map<String, DataFrame>> readAllExcelSheets(
  String path, {
  bool hasHeader = true,
  int? skipRows,
  int? maxRows,
  List<String>? columnNames,
  Map<String, dynamic>? options,
})
```

### 2. Write Multiple Sheets at Once

Write multiple DataFrames to different sheets in a single Excel file:

```dart
final sheets = {
  'Sales': salesDf,
  'Inventory': inventoryDf,
  'Summary': summaryDf,
};

await FileWriter.writeExcelSheets(sheets, 'report.xlsx');
```

**Method Signature:**
```dart
static Future<void> writeExcelSheets(
  Map<String, DataFrame> sheets,
  String path, {
  bool includeHeader = true,
  bool includeIndex = false,
  Map<String, dynamic>? options,
})
```

## Implementation Details

### Reading Multiple Sheets

**Location:** `lib/src/io/excel_reader.dart`

- Added `ExcelFileReader.readAllSheets()` static method
- Reads all sheets from the Excel file
- Returns `Map<String, DataFrame>` where keys are sheet names
- Handles errors gracefully - skips sheets that can't be read
- Applies same options (hasHeader, skipRows, etc.) to all sheets

**Key Features:**
- Efficient: Reads file once and processes all sheets
- Error handling: Continues if individual sheets fail
- Consistent: Uses same parsing logic as single-sheet read
- Flexible: Supports all read options

### Writing Multiple Sheets

**Location:** `lib/src/io/excel_writer.dart`

- Added `ExcelFileWriter.writeMultipleSheets()` static method
- Creates Excel workbook with multiple sheets
- Each DataFrame becomes a separate sheet
- Automatically removes default "Sheet1" if not used

**Key Features:**
- Clean output: No extra default sheets
- Consistent formatting: Same options apply to all sheets
- Type preservation: Maintains data types across sheets
- Memory efficient: Single write operation

### API Integration

**FileReader additions:**
```dart
// In lib/src/io/readers.dart
static Future<Map<String, DataFrame>> readAllExcelSheets(...)
```

**FileWriter additions:**
```dart
// In lib/src/io/writers.dart
static Future<void> writeExcelSheets(...)
```

## Bug Fixes

### 1. TextCellValue Handling
**Issue:** TextCellValue.value returns TextSpan, not String
**Fix:** Convert to string using `.toString()`
```dart
if (value is excel_pkg.TextCellValue) {
  return value.value.toString();  // Fixed
}
```

### 2. Default Sheet Handling
**Issue:** Excel package creates default "Sheet1" that wasn't being removed
**Fix:** Remove default sheet after writing custom sheets
```dart
if (excel.tables.containsKey('Sheet1') && !sheets.containsKey('Sheet1')) {
  excel.delete('Sheet1');
}
```

## Testing

### New Tests Added
**Location:** `test/io/csv_excel_test.dart`

1. **Write and read multiple sheets** - Verifies round-trip
2. **Read all sheets returns correct data** - Validates data integrity
3. **List sheets after multi-sheet write** - Confirms sheet names
4. **Read specific sheet from multi-sheet file** - Tests selective reading

All tests pass ✅

### Example Code
**Location:** `example/excel_multisheet_example.dart`

Comprehensive example demonstrating:
- Creating multiple DataFrames
- Writing to multiple sheets
- Reading all sheets
- Reading specific sheets
- Listing sheets
- Processing all sheets
- Creating complex reports

## Use Cases

### 1. Financial Reports
```dart
final sheets = {
  'Income Statement': incomeStmt,
  'Balance Sheet': balanceSheet,
  'Cash Flow': cashFlow,
  'Notes': notes,
};
await FileWriter.writeExcelSheets(sheets, 'financial_report.xlsx');
```

### 2. Data Analysis Pipeline
```dart
// Read all data
final rawData = await FileReader.readAllExcelSheets('raw_data.xlsx');

// Process each sheet
final processed = <String, DataFrame>{};
for (final entry in rawData.entries) {
  processed['${entry.key}_Processed'] = processData(entry.value);
}

// Write results
await FileWriter.writeExcelSheets(processed, 'processed_data.xlsx');
```

### 3. Multi-Department Reports
```dart
final departments = {
  'Sales': salesDf,
  'Marketing': marketingDf,
  'Operations': operationsDf,
  'Finance': financeDf,
};
await FileWriter.writeExcelSheets(departments, 'company_report.xlsx');
```

## Documentation Updates

1. **doc/csv_excel_io.md** - Added "Multi-Sheet Operations" section
2. **README.md** - Updated Excel examples with multi-sheet operations
3. **CSV_EXCEL_IMPLEMENTATION.md** - Added multi-sheet features to feature list

## Performance Considerations

### Reading
- **Single file read**: File is read once, all sheets processed
- **Memory usage**: All sheets loaded into memory simultaneously
- **Recommendation**: For very large workbooks, read sheets individually

### Writing
- **Single write operation**: All sheets written in one operation
- **Memory efficient**: Workbook built in memory, written once
- **Clean output**: No temporary files or multiple writes

## Comparison with Pandas

DartFrame's multi-sheet support is similar to pandas:

**Pandas:**
```python
# Read all sheets
sheets = pd.read_excel('file.xlsx', sheet_name=None)

# Write multiple sheets
with pd.ExcelWriter('output.xlsx') as writer:
    df1.to_excel(writer, sheet_name='Sheet1')
    df2.to_excel(writer, sheet_name='Sheet2')
```

**DartFrame:**
```dart
// Read all sheets
final sheets = await FileReader.readAllExcelSheets('file.xlsx');

// Write multiple sheets
await FileWriter.writeExcelSheets({
  'Sheet1': df1,
  'Sheet2': df2,
}, 'output.xlsx');
```

DartFrame's API is more concise and type-safe!

## Future Enhancements

Potential improvements:

1. **Lazy loading**: Read sheets on-demand for large workbooks
2. **Sheet metadata**: Access sheet properties (hidden, protected, etc.)
3. **Selective reading**: Read only specific sheets by name list
4. **Sheet ordering**: Control sheet order in output file
5. **Sheet copying**: Copy sheets between workbooks
6. **Formatting**: Preserve or apply cell formatting

## Conclusion

The multi-sheet Excel support makes DartFrame a complete solution for Excel file manipulation. Users can now:

✅ Read entire workbooks at once
✅ Write multiple sheets in one operation
✅ Process complex Excel files efficiently
✅ Create comprehensive reports with multiple sheets
✅ Work with Excel files just like pandas

This feature significantly enhances DartFrame's capabilities for data analysis and reporting workflows.

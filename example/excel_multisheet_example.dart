import 'package:dartframe/dartframe.dart';

void main() async {
  print('=== Excel Multi-Sheet Example ===\n');

  // Create sample DataFrames for different sheets
  final salesData = DataFrame.fromMap({
    'product': ['Widget', 'Gadget', 'Doohickey', 'Thingamajig'],
    'quantity': [100, 150, 75, 200],
    'price': [9.99, 19.99, 14.99, 24.99],
    'revenue': [999.0, 2998.5, 1124.25, 4998.0],
  });

  final inventoryData = DataFrame.fromMap({
    'product': ['Widget', 'Gadget', 'Doohickey', 'Thingamajig'],
    'in_stock': [500, 300, 150, 400],
    'reorder_level': [100, 100, 50, 150],
    'supplier': ['Acme Corp', 'TechCo', 'Acme Corp', 'GlobalParts'],
  });

  final summaryData = DataFrame.fromMap({
    'metric': [
      'Total Revenue',
      'Total Units Sold',
      'Average Price',
      'Products'
    ],
    'value': [10119.75, 525, 17.49, 4],
  });

  print('Created 3 DataFrames:');
  print('\n1. Sales Data:');
  print(salesData);
  print('\n2. Inventory Data:');
  print(inventoryData);
  print('\n3. Summary Data:');
  print(summaryData);

  // === Write Multiple Sheets ===
  print('\n--- Writing Multiple Sheets ---');

  final sheets = {
    'Sales': salesData,
    'Inventory': inventoryData,
    'Summary': summaryData,
  };

  await FileWriter.writeExcelSheets(sheets, 'multi_sheet_report.xlsx');
  print('✓ Written 3 sheets to multi_sheet_report.xlsx');

  // === Read All Sheets ===
  print('\n--- Reading All Sheets ---');

  final readSheets =
      await FileReader.readAllExcelSheets('multi_sheet_report.xlsx');
  print('✓ Read ${readSheets.length} sheets from file');
  print('Sheet names: ${readSheets.keys.toList()}');

  // Display each sheet
  for (final entry in readSheets.entries) {
    print(
        '\n${entry.key} (${entry.value.shape.rows} rows, ${entry.value.shape.columns} columns):');
    print(entry.value);
  }

  // === Read Specific Sheet ===
  print('\n--- Reading Specific Sheet ---');

  final salesSheet = await FileReader.readExcel(
    'multi_sheet_report.xlsx',
    sheetName: 'Sales',
  );
  print('Sales sheet:');
  print(salesSheet);

  // === List Sheets ===
  print('\n--- Listing Sheets ---');

  final sheetNames =
      await FileReader.listExcelSheets('multi_sheet_report.xlsx');
  print('Available sheets: $sheetNames');

  // === Process All Sheets ===
  print('\n--- Processing All Sheets ---');

  final allSheets =
      await FileReader.readAllExcelSheets('multi_sheet_report.xlsx');

  for (final entry in allSheets.entries) {
    final sheetName = entry.key;
    final df = entry.value;

    print('\n$sheetName Statistics:');
    print('  - Rows: ${df.shape.rows}');
    print('  - Columns: ${df.shape.columns}');
    print('  - Column names: ${df.columns}');
  }

  // === Create Report with Multiple Sheets ===
  print('\n--- Creating Complex Report ---');

  // Calculate some analytics
  final productAnalysis = DataFrame.fromMap({
    'product': salesData['product']!.toList(),
    'total_revenue': salesData['revenue']!.toList(),
    'units_sold': salesData['quantity']!.toList(),
    'stock_level': inventoryData['in_stock']!.toList(),
    'days_of_stock': [
      (inventoryData['in_stock']![0] as int) /
          (salesData['quantity']![0] as int),
      (inventoryData['in_stock']![1] as int) /
          (salesData['quantity']![1] as int),
      (inventoryData['in_stock']![2] as int) /
          (salesData['quantity']![2] as int),
      (inventoryData['in_stock']![3] as int) /
          (salesData['quantity']![3] as int),
    ],
  });

  final reportSheets = {
    'Sales': salesData,
    'Inventory': inventoryData,
    'Analysis': productAnalysis,
    'Summary': summaryData,
  };

  await FileWriter.writeExcelSheets(
    reportSheets,
    'comprehensive_report.xlsx',
    includeIndex: true,
  );
  print('✓ Created comprehensive_report.xlsx with 4 sheets');

  // Read and verify
  final reportData =
      await FileReader.readAllExcelSheets('comprehensive_report.xlsx');
  print('✓ Verified: ${reportData.length} sheets in comprehensive report');
  print('  Sheets: ${reportData.keys.toList()}');

  print('\n=== All multi-sheet operations completed successfully! ===');
}

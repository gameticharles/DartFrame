import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Web & API Examples ===');
  print('');

  // Sample DataFrame
  var employees = DataFrame([
    ['Alice', 'Engineering', 25, 90000],
    ['Bob', 'Sales', 30, 75000],
    ['Charlie', 'Engineering', 35, 95000],
  ], columns: [
    'Name',
    'Department',
    'Age',
    'Salary'
  ]);

  // Example 1: Export to HTML
  print('1. HTML Table Export:');
  print('=' * 50);
  var html = employees.toHtml(
    classes: 'table table-striped',
    tableId: 'employees',
  );
  print(html);
  print('');

  // Example 2: HTML with notebook styling
  print('2. HTML with Notebook Styling:');
  print('=' * 50);
  var htmlNotebook = employees.toHtml(
    notebook: true,
    index: false,
  );
  print(htmlNotebook);
  print('');

  // Example 3: Export to XML
  print('3. XML Export:');
  print('=' * 50);
  var xml = employees.toXml(
    rootName: 'employees',
    rowName: 'employee',
  );
  print(xml);
  print('');

  // Example 4: XML with attributes
  print('4. XML with Attributes:');
  print('=' * 50);
  var xmlAttrs = employees.toXml(
    rootName: 'company',
    rowName: 'employee',
    attrCols: ['Name'],
    index: false,
  );
  print(xmlAttrs);
  print('');

  // Example 5: Read HTML table
  print('5. Read HTML Table:');
  print('=' * 50);
  var htmlInput = '''
  <table>
    <tr><th>Product</th><th>Price</th><th>Stock</th></tr>
    <tr><td>Widget</td><td>19.99</td><td>100</td></tr>
    <tr><td>Gadget</td><td>29.99</td><td>50</td></tr>
  </table>
  ''';

  var dfs = DataFrame.readHtml(htmlInput);
  print('Found ${dfs.length} table(s)');
  print(dfs[0]);
  print('');

  // Example 6: Read XML data
  print('6. Read XML Data:');
  print('=' * 50);
  var xmlInput = '''
  <products>
    <product>
      <Name>Widget</Name>
      <Price>19.99</Price>
      <Stock>100</Stock>
    </product>
    <product>
      <Name>Gadget</Name>
      <Price>29.99</Price>
      <Stock>50</Stock>
    </product>
  </products>
  ''';

  var dfFromXml = DataFrame.readXml(xmlInput, rowName: 'product');
  print(dfFromXml);
  print('');

  // Example 7: Round-trip HTML
  print('7. HTML Round-trip:');
  print('=' * 50);
  var original = DataFrame([
    ['Item A', 100],
    ['Item B', 200],
  ], columns: [
    'Item',
    'Quantity'
  ]);

  var htmlExport = original.toHtml(index: false);
  var imported = DataFrame.readHtml(htmlExport)[0];

  print('Original:');
  print(original);
  print('');
  print('After round-trip:');
  print(imported);
  print('');

  // Example 8: Round-trip XML
  print('8. XML Round-trip:');
  print('=' * 50);
  var data = DataFrame([
    ['Product A', 50],
    ['Product B', 75],
  ], columns: [
    'Name',
    'Value'
  ]);

  var xmlExport = data.toXml(index: false);
  var xmlImported = DataFrame.readXml(xmlExport);

  print('Original:');
  print(data);
  print('');
  print('After round-trip:');
  print(xmlImported);
  print('');

  print('=== Web & API Examples Complete ===');
}

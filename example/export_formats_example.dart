import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Export Formats Examples ===');
  print('');

  // Sample DataFrame
  var employees = DataFrame([
    ['Alice', 'Engineering', 25, 90000.50],
    ['Bob', 'Sales', 30, 75000.75],
    ['Charlie', 'Engineering', 35, 95000.25],
    ['David', 'Marketing', 28, 70000.00],
  ], columns: [
    'Name',
    'Department',
    'Age',
    'Salary'
  ]);

  // Example 1: Export to LaTeX
  print('1. LaTeX Table Export:');
  print('=' * 50);
  var latex = employees.toLatex(
    caption: 'Employee Information',
    label: 'tab:employees',
    position: 'h',
  );
  print(latex);
  print('');

  // Example 2: Markdown table (GitHub-flavored)
  print('2. Markdown Table (Pipe Format):');
  print('=' * 50);
  var markdown = employees.toMarkdown(floatfmt: '.2f');
  print(markdown);
  print('');

  // Example 3: Formatted string representation
  print('3. Formatted String:');
  print('=' * 50);
  var formatted = employees.toStringFormatted(
    maxColWidth: 20,
    floatFormat: '.2f',
  );
  print(formatted);
  print('');

  // Example 4: Convert to records (list of maps)
  print('4. Convert to Records:');
  print('=' * 50);
  var records = employees.toRecords();
  for (var record in records) {
    print(record);
  }
  print('');

  // Example 5: Markdown without index
  print('5. Markdown Table (No Index):');
  print('=' * 50);
  var markdownNoIndex = employees.toMarkdown(
    index: false,
    floatfmt: '.2f',
  );
  print(markdownNoIndex);
  print('');

  // Example 6: LaTeX longtable for multi-page documents
  print('6. LaTeX Longtable:');
  print('=' * 50);
  var longtable = employees.toLatex(
    caption: 'Employee List',
    longtable: true,
  );
  print(longtable);
  print('');

  print('=== Export Formats Examples Complete ===');
}

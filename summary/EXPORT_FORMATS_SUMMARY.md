# Export Formats

This document provides a comprehensive overview of the export format methods implemented in DartFrame.

## Overview

Export format methods allow you to convert DataFrames into various text-based formats for documentation, reporting, and data interchange. All methods preserve data structure and provide extensive customization options.

## Features

### 1. toLatex() - LaTeX Table Export

Export DataFrame to LaTeX table format for academic papers and technical documents.

**Parameters:**
- `caption`: Table caption (optional)
- `label`: LaTeX label for referencing (optional)
- `position`: Table position specifier (default: 'h')
- `columnFormat`: Column format string (default: auto-generated)
- `index`: Include index column (default: true)
- `header`: Include header row (default: true)
- `escape`: Escape special LaTeX characters (default: true)
- `bold`: Bold header row (default: true)
- `longtable`: Use longtable environment for multi-page tables (default: false)

**Example:**
```dart
var df = DataFrame([
  ['Alice', 25, 50000],
  ['Bob', 30, 60000],
], columns: ['Name', 'Age', 'Salary']);

var latex = df.toLatex(
  caption: 'Employee Data',
  label: 'tab:employees',
  position: 'h',
);

// Output:
// \begin{table}[h]
// \caption{Employee Data}
// \label{tab:employees}
// \centering
// \begin{tabular}{lll}
// \hline
// \textbf{} & \textbf{Name} & \textbf{Age} & \textbf{Salary} \\
// \hline
// 0 & Alice & 25 & 50000 \\
// 1 & Bob & 30 & 60000 \\
// \hline
// \end{tabular}
// \end{table}
```

**Special Features:**
- Automatic escaping of LaTeX special characters (&, %, $, #, _, {, }, ~, ^)
- Support for longtable environment for multi-page tables
- Custom column format strings (l, c, r for left, center, right alignment)
- Bold headers for better readability

### 2. toMarkdown() - Markdown Table Export

Export DataFrame to Markdown table format for GitHub, documentation, and wikis.

**Parameters:**
- `index`: Include index column (default: true)
- `tablefmt`: Table format style (default: 'pipe')
  - `'pipe'`: GitHub-flavored markdown (default)
  - `'grid'`: Grid-style table
  - `'simple'`: Simple format without borders
- `align`: Column alignment ('left', 'center', 'right', or list per column)
- `floatfmt`: Format string for floating point numbers (e.g., '.2f')
- `maxColWidth`: Maximum column width (default: null = no limit)

**Example:**
```dart
var df = DataFrame([
  ['Alice', 25, 50000.50],
  ['Bob', 30, 60000.75],
], columns: ['Name', 'Age', 'Salary']);

var markdown = df.toMarkdown(
  floatfmt: '.2f',
  align: 'center',
);

// Output:
// |  | Name | Age | Salary |
// | :---: | :---: | :---: | :---: |
// | 0 | Alice | 25 | 50000.50 |
// | 1 | Bob | 30 | 60000.75 |
```

**Alignment Options:**
- `'left'`: Left-aligned (`:---`)
- `'center'`: Center-aligned (`:---:`)
- `'right'`: Right-aligned (`---:`)
- List: Per-column alignment `['left', 'center', 'right']`

### 3. toStringFormatted() - Formatted String Representation

Export DataFrame to a formatted string with intelligent truncation for large datasets.

**Parameters:**
- `maxRows`: Maximum number of rows to display (default: 60)
- `maxCols`: Maximum number of columns to display (default: 20)
- `maxColWidth`: Maximum column width (default: 50)
- `index`: Include index column (default: true)
- `header`: Include header row (default: true)
- `lineWidth`: Maximum line width (default: 80)
- `floatFormat`: Format string for floating point numbers
- `sparsify`: Sparsify MultiIndex display (default: true)

**Example:**
```dart
var df = DataFrame([
  ['Alice', 25, 50000],
  ['Bob', 30, 60000],
], columns: ['Name', 'Age', 'Salary']);

var formatted = df.toStringFormatted(
  maxColWidth: 20,
  floatFormat: '.2f',
);

// Output:
//      Name  Age  Salary
// ---  ----  ---  ------
// 0    Alice  25   50000
// 1    Bob    30   60000
//
// [2 rows x 3 columns]
```

**Truncation Features:**
- Automatically truncates large DataFrames
- Shows first and last rows with `...` in between
- Shows first and last columns with `...` in between
- Displays total shape at the bottom

### 4. toRecords() - Convert to Record Array

Convert DataFrame to a list of maps (records) for easy iteration and JSON serialization.

**Parameters:**
- `index`: Include index in records (default: false)
- `indexName`: Name for index column if included (default: 'index')

**Example:**
```dart
var df = DataFrame([
  ['Alice', 25],
  ['Bob', 30],
], columns: ['Name', 'Age']);

var records = df.toRecords();
// [
//   {'Name': 'Alice', 'Age': 25},
//   {'Name': 'Bob', 'Age': 30}
// ]

// With index
var recordsWithIndex = df.toRecords(index: true, indexName: 'id');
// [
//   {'id': 0, 'Name': 'Alice', 'Age': 25},
//   {'id': 1, 'Name': 'Bob', 'Age': 30}
// ]
```

**Use Cases:**
- JSON serialization
- API responses
- Iteration over rows
- Data transformation pipelines

## Use Cases

### 1. Academic Papers (LaTeX)
```dart
var results = DataFrame([
  ['Method A', 0.95, 0.02],
  ['Method B', 0.92, 0.03],
  ['Method C', 0.97, 0.01],
], columns: ['Method', 'Accuracy', 'Std Dev']);

var latex = results.toLatex(
  caption: 'Experimental Results',
  label: 'tab:results',
  floatfmt: '.3f',
);
// Ready for inclusion in LaTeX document
```

### 2. GitHub Documentation (Markdown)
```dart
var features = DataFrame([
  ['Feature A', 'Implemented', 'v1.0'],
  ['Feature B', 'In Progress', 'v1.1'],
  ['Feature C', 'Planned', 'v2.0'],
], columns: ['Feature', 'Status', 'Version']);

var markdown = features.toMarkdown(index: false);
// Ready for README.md or wiki
```

### 3. Console Output (Formatted String)
```dart
var data = DataFrame(
  List.generate(1000, (i) => [i, 'Item $i', i * 100]),
  columns: ['ID', 'Name', 'Value'],
);

print(data.toStringFormatted(maxRows: 20));
// Displays first 10 and last 10 rows with shape info
```

### 4. API Responses (Records)
```dart
var users = DataFrame([
  ['alice@example.com', 'Alice', 'Admin'],
  ['bob@example.com', 'Bob', 'User'],
], columns: ['Email', 'Name', 'Role']);

var records = users.toRecords();
// Convert to JSON for API response
var json = jsonEncode(records);
```

### 5. Data Export Pipeline
```dart
// Filter, transform, and export
var df = DataFrame.fromCSV('data.csv');
var filtered = df.query('value > 100');
var summary = filtered.groupBy(['category']).agg({'value': 'mean'});

// Export to multiple formats
var latex = summary.toLatex(caption: 'Summary Statistics');
var markdown = summary.toMarkdown(floatfmt: '.2f');
var records = summary.toRecords();
```

## Comparison with Pandas

| DartFrame Method | Pandas Equivalent | Notes |
|-----------------|-------------------|-------|
| `toLatex()` | `df.to_latex()` | Full feature parity |
| `toMarkdown()` | `df.to_markdown()` | GitHub-flavored markdown |
| `toStringFormatted()` | `df.to_string()` | Enhanced with truncation |
| `toRecords()` | `df.to_dict('records')` | Simplified API |

## Performance Considerations

- **toLatex():** O(n * m) where n = rows, m = columns
- **toMarkdown():** O(n * m) where n = rows, m = columns
- **toStringFormatted():** O(min(n, maxRows) * min(m, maxCols))
- **toRecords():** O(n * m) where n = rows, m = columns

All methods are memory-efficient and suitable for large datasets with appropriate truncation settings.

## Best Practices

### 1. LaTeX Export
- Use `escape=true` (default) to handle special characters
- Use `longtable=true` for tables spanning multiple pages
- Specify `caption` and `label` for proper referencing
- Use `columnFormat` for custom alignment (e.g., 'lrc' for left, right, center)

### 2. Markdown Export
- Use `floatfmt` to control decimal places
- Use `maxColWidth` to prevent wide tables
- Use `index=false` for cleaner tables in documentation
- Use `align='center'` for better readability

### 3. Formatted String
- Set `maxRows` and `maxCols` for large DataFrames
- Use `floatFormat` for consistent number formatting
- Set `maxColWidth` to prevent line wrapping
- Use for console output and logging

### 4. Records Conversion
- Use `index=false` (default) for cleaner records
- Use `index=true` when index is meaningful
- Perfect for JSON serialization
- Ideal for row-by-row processing

## Special Character Handling

### LaTeX Escaping
The following characters are automatically escaped when `escape=true`:
- `&` → `\&`
- `%` → `\%`
- `$` → `\$`
- `#` → `\#`
- `_` → `\_`
- `{` → `\{`
- `}` → `\}`
- `~` → `\textasciitilde{}`
- `^` → `\textasciicircum{}`
- `\` → `\textbackslash{}`

### Markdown
Markdown tables handle most characters naturally, but very long strings can be truncated using `maxColWidth`.

## Testing

All export format methods have been thoroughly tested with:
- 41 unit tests covering all methods and parameters
- Tests for empty DataFrames, single rows/columns, and edge cases
- Tests for special characters and escaping
- Tests for truncation and formatting
- Integration tests with filtering and transformations

## Examples

See the following example files for detailed usage:
- `example/export_formats_example.dart` - 16 comprehensive examples
- `test/export_formats_test.dart` - Test cases demonstrating usage

## See Also

- [DataFrame I/O Operations](IO_OPERATIONS_SUMMARY.md) - File reading and writing
- [DataFrame Display](DISPLAY_SUMMARY.md) - Display options and formatting
- [Data Transformation](TRANSFORMATION_SUMMARY.md) - Data manipulation methods

## References

- Pandas to_latex: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_latex.html
- Pandas to_markdown: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_markdown.html
- Pandas to_string: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_string.html
- Pandas to_dict: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_dict.html
- LaTeX Tables: https://www.overleaf.com/learn/latex/Tables
- Markdown Tables: https://www.markdownguide.org/extended-syntax/#tables

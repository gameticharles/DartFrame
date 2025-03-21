part of '../../dartframe.dart';

/// A `Series` class represents a one-dimensional array with a label.
///
/// The `Series` class is designed to hold a sequence of data of any type `T`,
/// where `T` can be anything from `int`, `double`, `String`, to custom objects.
/// Each `Series` object is associated with a name, typically representing the
/// column name when part of a DataFrame.
///
/// The class allows for future extensions where methods for common data
/// manipulations and analyses can be added, making it a fundamental building
/// block for handling tabular data.
///
/// Example usage:
/// ```dart
/// var numericSeries = Series<int>([1, 2, 3, 4], name: 'Numbers');
/// print(numericSeries); // Outputs: Numbers: [1, 2, 3, 4]
///
/// var stringSeries = Series<String>(['a', 'b', 'c'], name: 'Letters');
/// print(stringSeries); // Outputs: Letters: [a, b, c]
/// ```
class Series {
  /// The data of the series.
  ///
  /// This list holds the actual data points of the series. The generic type `T`
  /// allows the series to hold any type of data.
  List<dynamic> data;

  /// The name of the series.
  ///
  /// Typically represents the column name in a DataFrame and is used to
  /// identify the series.
  String name;

    // Add these fields to the Series class
   DataFrame? _parentDataFrame;
   String? _columnName;
   List<dynamic>? index;

  /// Sets the parent DataFrame reference
  void _setParent(DataFrame parent, String columnName) {
    _parentDataFrame = parent;
    _columnName = columnName;
  }
  
  /// Constructs a `Series` object with the given [data] and [name].
  ///
  /// The [data] parameter is a list containing the data points of the series,
  /// and the [name] parameter is a string representing the series' name.
  ///
  /// Parameters:
  /// - `data`: The data points of the series.
  /// - `name`: The name of the series. This parameter is required.
  /// - `index`: Optional list to use as index for the Series
  Series(this.data, {required this.name, this.index});

  /// Returns a string representation of the series.
  ///
  /// This method overrides the `toString` method to provide a meaningful
  /// string representation of the series in a tabular format.
  @override
  String toString({int columnSpacing = 2}) {
    if (data.isEmpty) {
      return 'Empty Series: $name';
    }

    // Calculate column width for values
    int maxValueWidth = 0;
    for (var value in data) {
      int valueWidth = value.toString().length;
      if (valueWidth > maxValueWidth) {
        maxValueWidth = valueWidth;
      }
    }

    // Calculate name width
    int nameWidth = name.length;
    
    // Calculate the maximum width needed for row headers/index
    int indexWidth = 0;
    List<dynamic> indexList = index ?? List.generate(data.length, (i) => i);
    
    for (var idx in indexList) {
      int headerWidth = idx.toString().length;
      if (headerWidth > indexWidth) {
        indexWidth = headerWidth;
      }
    }
    
    // Ensure index width is at least as wide as the word "index"
    indexWidth = max(indexWidth, 5);
    
    // Use the maximum of value width and name width for column width
    int columnWidth = max(maxValueWidth, nameWidth);
    
    // Add spacing
    columnWidth += columnSpacing;
    indexWidth += columnSpacing;

    // Construct the table string
    StringBuffer buffer = StringBuffer();

    // Add header
    buffer.write(' '.padRight(indexWidth));
    buffer.writeln(name.padRight(columnWidth));

    // Add data rows
    for (int i = 0; i < data.length; i++) {
      buffer.write(indexList[i].toString().padRight(indexWidth));
      buffer.writeln(data[i].toString().padRight(columnWidth));
    }

    // Add series information
    buffer.writeln();
    buffer.writeln('Length: ${data.length}');
    buffer.writeln('Type: ${data.isEmpty ? 'unknown' : data.first.runtimeType}');

    return buffer.toString();
  }

  /// Length of the data in the series
  int get length => data.length;

// Return the Series as a data frame
  DataFrame toDataFrame() => DataFrame.fromMap({name: data});
}

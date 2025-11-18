import '../../data_frame/data_frame.dart';
import '../../series/series.dart';
import '../../ndarray/ndarray.dart';
import 'hdf5_file_builder.dart';
import 'write_options.dart';

/// Writer for DataFrame objects using column-wise storage strategy
///
/// This class converts a DataFrame into an HDF5 group where each column
/// is stored as a separate dataset. This strategy is particularly efficient
/// for column-oriented access patterns and large DataFrames.
///
/// The column-wise approach:
/// - Creates a group at the specified path
/// - Stores each column as a separate 1D dataset
/// - Preserves column order as a group attribute
/// - Optionally stores the index as a separate dataset
/// - Efficient for column-oriented operations
/// - Compatible with pandas column-wise storage
///
/// Example usage:
/// ```dart
/// final df = DataFrame([
///   [1, 'Alice', 25.5],
///   [2, 'Bob', 30.0],
/// ], columns: ['id', 'name', 'age']);
///
/// final builder = HDF5FileBuilder();
/// final writer = DataFrameColumnWriter();
/// await writer.write(builder, '/data', df);
/// ```
class DataFrameColumnWriter {
  /// Write a DataFrame to HDF5 using column-wise storage
  ///
  /// This method creates a group at the specified path and writes each
  /// column as a separate dataset within that group.
  ///
  /// Parameters:
  /// - [builder]: The HDF5FileBuilder to write to
  /// - [path]: The group path where the DataFrame will be stored
  /// - [df]: The DataFrame to write
  /// - [options]: Optional write options for the column datasets
  ///
  /// The method performs these steps:
  /// 1. Create a group at the specified path
  /// 2. Write each column as a separate 1D dataset
  /// 3. Store column order as a group attribute
  /// 4. Store index as a separate dataset if named
  ///
  /// Group attributes:
  /// - 'columns': List of column names in order
  /// - 'pandas_type': 'frame' (for pandas compatibility)
  /// - 'pandas_version': '1.0.0' (for pandas compatibility)
  ///
  /// Throws:
  /// - [ArgumentError] if DataFrame is empty
  /// - [ArgumentError] if path is invalid
  ///
  /// Example:
  /// ```dart
  /// final writer = DataFrameColumnWriter();
  /// await writer.write(builder, '/mydata', df);
  /// // Creates group '/mydata' with datasets:
  /// //   /mydata/id
  /// //   /mydata/name
  /// //   /mydata/age
  /// ```
  Future<void> write(
    HDF5FileBuilder builder,
    String path,
    DataFrame df, {
    WriteOptions? options,
  }) async {
    // Validate DataFrame
    if (df.rowCount == 0) {
      throw ArgumentError('Cannot write empty DataFrame');
    }
    if (df.columns.isEmpty) {
      throw ArgumentError('DataFrame must have at least one column');
    }

    // Validate path
    _validatePath(path);

    // Create group attributes
    final columnNames = df.columns.map((c) => c.toString()).toList();
    final groupAttributes = {
      'columns': columnNames.join(','),
      'pandas_type': 'frame',
      'pandas_version': '1.0.0',
    };

    // Create the group
    await builder.createGroup(path, attributes: groupAttributes);

    // Write each column as a separate dataset
    for (final columnName in df.columns) {
      final colName = columnName.toString();
      final column = df[columnName] as Series;

      // Convert column to NDArray
      final columnArray = _columnToNDArray(column);

      // Determine dataset path
      final datasetPath = '$path/$colName';

      // Write the column dataset
      await builder.addDataset(datasetPath, columnArray, options: options);
    }

    // Note: DataFrame index in dartframe is a List<dynamic> without a name property
    // For now, we skip writing the index as a separate dataset
    // This can be enhanced in the future if index naming is added to DataFrame
  }

  /// Convert a Series column to an NDArray
  ///
  /// This method converts a DataFrame column (Series) into a 1D NDArray
  /// suitable for writing as an HDF5 dataset.
  ///
  /// The method handles:
  /// - Numeric types (int, double)
  /// - String types
  /// - Boolean types
  /// - Mixed types (converts to appropriate common type)
  ///
  /// Parameters:
  /// - [column]: The Series to convert
  ///
  /// Returns a 1D NDArray containing the column data.
  ///
  /// Throws:
  /// - [UnsupportedError] if the column contains unsupported types
  NDArray _columnToNDArray(Series column) {
    // Analyze column to determine datatype
    final datatype = _inferColumnDatatype(column);

    // Convert column data based on inferred type
    final List<dynamic> convertedData;

    if (datatype == _ColumnDatatype.integer) {
      convertedData = column.data.map((v) => _toInt(v)).toList();
    } else if (datatype == _ColumnDatatype.float) {
      convertedData = column.data.map((v) => _toDouble(v)).toList();
    } else if (datatype == _ColumnDatatype.string) {
      convertedData = column.data.map((v) => _toString(v)).toList();
    } else if (datatype == _ColumnDatatype.boolean) {
      convertedData = column.data.map((v) => _toBool(v)).toList();
    } else {
      // Mixed or unknown - convert to string
      convertedData = column.data.map((v) => _toString(v)).toList();
    }

    // Create 1D NDArray using fromFlat constructor
    return NDArray.fromFlat(convertedData, [column.length]);
  }

  /// Infer the datatype of a column
  ///
  /// This method scans the column to determine the most appropriate
  /// datatype for storage.
  ///
  /// Parameters:
  /// - [column]: The Series to analyze
  ///
  /// Returns the inferred column datatype.
  _ColumnDatatype _inferColumnDatatype(Series column) {
    bool hasInt = false;
    bool hasDouble = false;
    bool hasBool = false;
    bool hasString = false;
    bool hasOther = false;

    for (final value in column.data) {
      if (value != null) {
        if (value is int) {
          hasInt = true;
        } else if (value is double) {
          hasDouble = true;
        } else if (value is bool) {
          hasBool = true;
        } else if (value is String) {
          hasString = true;
        } else {
          hasOther = true;
        }
      }
    }

    // Determine datatype based on detected types
    if (hasString || hasOther) {
      return _ColumnDatatype.string;
    }

    if (hasBool && !hasInt && !hasDouble) {
      return _ColumnDatatype.boolean;
    }

    if (hasDouble || (hasInt && hasDouble)) {
      return _ColumnDatatype.float;
    }

    if (hasInt) {
      return _ColumnDatatype.integer;
    }

    // Default to float for all-null columns
    return _ColumnDatatype.float;
  }

  /// Convert value to integer
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Convert value to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convert value to string
  String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Convert value to boolean
  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  /// Validate the group path
  void _validatePath(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }
    if (!path.startsWith('/')) {
      throw ArgumentError('Path must start with "/"');
    }
    if (path.length > 1 && path.endsWith('/')) {
      throw ArgumentError('Path cannot end with "/"');
    }
    if (path.contains('//')) {
      throw ArgumentError('Path cannot contain consecutive slashes');
    }
  }
}

/// Internal enum for column datatypes
enum _ColumnDatatype {
  integer,
  float,
  string,
  boolean,
}

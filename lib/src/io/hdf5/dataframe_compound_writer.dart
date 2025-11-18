import '../../data_frame/data_frame.dart';
import '../../series/series.dart';
import 'datatype_writer.dart';
import 'datatype.dart';

/// Writer for DataFrame objects using compound datatype strategy
///
/// This class converts a DataFrame into an HDF5 dataset using a compound datatype,
/// where each row is stored as a struct-like record with fields for each column.
/// This is the default storage strategy for DataFrames with homogeneous or
/// mixed datatypes.
///
/// The compound datatype approach:
/// - Stores data row-by-row as compound records
/// - Each column becomes a field in the compound type
/// - Column names are stored as an attribute
/// - Efficient for row-oriented access patterns
/// - Compatible with pandas and h5py
///
/// Example usage:
/// ```dart
/// final df = DataFrame([
///   [1, 'Alice', 25.5],
///   [2, 'Bob', 30.0],
/// ], columns: ['id', 'name', 'age']);
///
/// final writer = DataFrameCompoundWriter();
/// final result = writer.createCompoundDataset(df);
/// ```
class DataFrameCompoundWriter {
  /// Create compound dataset information from a DataFrame
  ///
  /// This method analyzes the DataFrame columns, creates an appropriate
  /// compound datatype, and converts rows to compound records.
  ///
  /// Parameters:
  /// - [df]: The DataFrame to convert
  ///
  /// Returns a map containing:
  /// - 'datatypeWriter': The CompoundDatatypeWriter for the DataFrame structure
  /// - 'recordBytes': List of byte lists, one per row
  /// - 'columnNames': List of column names
  /// - 'shape': Dataset shape [numRows]
  ///
  /// The method performs these steps:
  /// 1. Analyze DataFrame columns to determine HDF5 datatypes
  /// 2. Create a compound datatype with fields for each column
  /// 3. Convert DataFrame rows to compound records
  /// 4. Return all necessary information for writing
  ///
  /// Throws:
  /// - [ArgumentError] if DataFrame is empty
  /// - [UnsupportedError] if a column datatype cannot be mapped to HDF5
  ///
  /// Example:
  /// ```dart
  /// final writer = DataFrameCompoundWriter();
  /// final result = writer.createCompoundDataset(df);
  /// final compoundWriter = result['datatypeWriter'] as CompoundDatatypeWriter;
  /// final recordBytes = result['recordBytes'] as List<List<int>>;
  /// ```
  Map<String, dynamic> createCompoundDataset(DataFrame df) {
    // Validate DataFrame
    if (df.rowCount == 0) {
      throw ArgumentError('Cannot write empty DataFrame');
    }
    if (df.columns.isEmpty) {
      throw ArgumentError('DataFrame must have at least one column');
    }

    // Analyze columns and create compound datatype
    final compoundWriter = _createCompoundDatatype(df);

    // Convert DataFrame rows to compound records
    final recordBytes = _convertRowsToRecords(df, compoundWriter);

    // Get column names
    final columnNames = df.columns.map((c) => c.toString()).toList();

    return {
      'datatypeWriter': compoundWriter,
      'recordBytes': recordBytes,
      'columnNames': columnNames,
      'shape': [df.rowCount],
      'recordSize': compoundWriter.getSize(),
    };
  }

  /// Create a compound datatype from DataFrame columns
  ///
  /// This method analyzes each column in the DataFrame to determine its
  /// HDF5 datatype and creates a CompoundDatatypeWriter with appropriate
  /// fields.
  ///
  /// The CompoundDatatypeWriter automatically handles:
  /// - Field offset calculation based on field sizes
  /// - Proper alignment (fields aligned to their size or 8 bytes, whichever is smaller)
  /// - Total compound size calculation
  ///
  /// Field offsets are calculated as follows:
  /// 1. Start at offset 0
  /// 2. For each field:
  ///    a. Calculate alignment (min(field_size, 8))
  ///    b. Add padding to align current offset
  ///    c. Place field at aligned offset
  ///    d. Move offset forward by field size
  /// 3. Total size is the final offset
  ///
  /// Example field layout for mixed types:
  /// ```
  /// Field 'id' (int64, size=8):    offset=0
  /// Field 'name' (string, size=20): offset=8 (aligned to 8)
  /// Field 'score' (float64, size=8): offset=28 (aligned to 8)
  /// Total size: 36 bytes
  /// ```
  ///
  /// Parameters:
  /// - [df]: The DataFrame to analyze
  ///
  /// Returns a CompoundDatatypeWriter configured for the DataFrame structure.
  CompoundDatatypeWriter _createCompoundDatatype(DataFrame df) {
    final fields = <String, DatatypeWriter>{};

    for (final columnName in df.columns) {
      final column = df[columnName] as Series;
      final fieldWriter = _inferColumnDatatype(column, columnName.toString());
      fields[columnName.toString()] = fieldWriter;
    }

    return CompoundDatatypeWriter.fromFields(fields);
  }

  /// Get field information for a DataFrame
  ///
  /// This method returns detailed information about how DataFrame columns
  /// are mapped to compound datatype fields, including offsets and sizes.
  ///
  /// Parameters:
  /// - [df]: The DataFrame to analyze
  ///
  /// Returns a map with field information:
  /// - 'fields': List of field info maps, each containing:
  ///   - 'name': Field name (column name)
  ///   - 'type': HDF5 datatype class name
  ///   - 'size': Field size in bytes
  ///   - 'offset': Field offset in compound record
  /// - 'totalSize': Total size of compound record in bytes
  ///
  /// Example:
  /// ```dart
  /// final writer = DataFrameCompoundWriter();
  /// final info = writer.getFieldInfo(df);
  /// print('Total record size: ${info['totalSize']} bytes');
  /// for (final field in info['fields']) {
  ///   print('${field['name']}: ${field['type']} at offset ${field['offset']}');
  /// }
  /// ```
  Map<String, dynamic> getFieldInfo(DataFrame df) {
    final compoundWriter = _createCompoundDatatype(df);
    final fieldInfoList = <Map<String, dynamic>>[];

    for (final columnName in df.columns) {
      final colName = columnName.toString();
      final fieldWriter = compoundWriter.getFieldWriter(colName)!;
      final offset = compoundWriter.getFieldOffset(colName)!;

      fieldInfoList.add({
        'name': colName,
        'type': fieldWriter.datatypeClass.name,
        'size': fieldWriter.getSize(),
        'offset': offset,
      });
    }

    return {
      'fields': fieldInfoList,
      'totalSize': compoundWriter.getSize(),
    };
  }

  /// Infer HDF5 datatype for a DataFrame column
  ///
  /// This method examines the column data to determine the appropriate
  /// HDF5 datatype. It handles:
  /// - Numeric types (int, double)
  /// - String types (fixed or variable length)
  /// - Boolean types
  /// - Mixed types (defaults to string)
  ///
  /// The method scans the column to detect mixed types and chooses the
  /// most appropriate representation:
  /// - If all non-null values are the same type, use that type
  /// - If mixed numeric types (int/double), use float64
  /// - If mixed types including strings, use variable-length string
  ///
  /// Parameters:
  /// - [column]: The Series representing the column
  /// - [columnName]: The column name (for error messages)
  ///
  /// Returns a DatatypeWriter appropriate for the column data.
  DatatypeWriter _inferColumnDatatype(Series column, String columnName) {
    // Scan column to detect types
    bool hasInt = false;
    bool hasDouble = false;
    bool hasBool = false;
    bool hasString = false;
    bool hasOther = false;

    dynamic sampleValue;

    for (int i = 0; i < column.length; i++) {
      final value = column.data[i];
      if (value != null) {
        if (sampleValue == null) {
          sampleValue = value;
        }

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

    if (sampleValue == null) {
      // All values are null - default to float64
      return NumericDatatypeWriter.float64();
    }

    // Determine datatype based on detected types
    // Priority: string > other > bool > numeric

    if (hasString || hasOther) {
      // If any strings or unknown types, use fixed-length string
      // Variable-length strings cannot be used directly in compound types
      // We need to determine an appropriate fixed length
      return _determineFixedStringLength(column);
    }

    if (hasBool && !hasInt && !hasDouble) {
      // Pure boolean column
      return BooleanDatatypeWriter();
    }

    if (hasDouble || (hasInt && hasDouble)) {
      // Any doubles, or mixed int/double -> use float64
      return NumericDatatypeWriter.float64();
    }

    if (hasInt) {
      // Pure integer column
      return NumericDatatypeWriter.int64();
    }

    // Fallback (shouldn't reach here)
    return NumericDatatypeWriter.float64();
  }

  /// Convert DataFrame rows to compound records
  ///
  /// This method converts each row of the DataFrame into a compound record
  /// (struct-like binary representation) according to the compound datatype.
  ///
  /// The method handles type conversion for mixed-type columns:
  /// - Converts values to match the inferred field datatype
  /// - Handles null values appropriately
  /// - Converts non-string values to strings when needed
  ///
  /// Parameters:
  /// - [df]: The DataFrame to convert
  /// - [compoundWriter]: The compound datatype writer defining the structure
  ///
  /// Returns a list of byte lists, where each inner list is one compound record.
  List<List<int>> _convertRowsToRecords(
    DataFrame df,
    CompoundDatatypeWriter compoundWriter,
  ) {
    final records = <List<int>>[];

    // Get field writers for type conversion
    final fieldWriters = <String, DatatypeWriter>{};
    for (final columnName in df.columns) {
      final colName = columnName.toString();
      fieldWriters[colName] = compoundWriter.getFieldWriter(colName)!;
    }

    for (int rowIdx = 0; rowIdx < df.rowCount; rowIdx++) {
      final rowValues = <String, dynamic>{};

      // Extract and convert values for each column
      for (final columnName in df.columns) {
        final colName = columnName.toString();
        final column = df[columnName] as Series;
        final value = column.data[rowIdx];

        // Convert value to match field datatype
        final fieldWriter = fieldWriters[colName]!;
        final convertedValue = _convertValueForField(value, fieldWriter);

        rowValues[colName] = convertedValue;
      }

      // Encode the row as a compound record
      final recordBytes = compoundWriter.encodeValues(rowValues);
      records.add(recordBytes);
    }

    return records;
  }

  /// Determine appropriate fixed-length string size for a column
  ///
  /// This method scans the column to find the maximum string length
  /// and returns a StringDatatypeWriter with appropriate fixed length.
  ///
  /// For compound datatypes, we must use fixed-length strings because
  /// variable-length strings require global heap references which add
  /// complexity to the compound record structure.
  ///
  /// Parameters:
  /// - [column]: The Series containing string or mixed data
  ///
  /// Returns a StringDatatypeWriter with fixed length.
  DatatypeWriter _determineFixedStringLength(Series column) {
    int maxLength = 0;

    for (final value in column.data) {
      if (value != null) {
        final strValue = value.toString();
        if (strValue.length > maxLength) {
          maxLength = strValue.length;
        }
      }
    }

    // Use at least 1 character, add 20% padding, cap at 1024
    final fixedLength = ((maxLength * 1.2).ceil()).clamp(1, 1024);

    return StringDatatypeWriter.fixedLength(
      length: fixedLength,
      paddingType: StringPaddingType.nullTerminate,
      characterSet: CharacterSet.utf8,
    );
  }

  /// Convert a value to match the target field datatype
  ///
  /// This method handles type conversion for mixed-type columns,
  /// ensuring values can be properly encoded in the compound record.
  ///
  /// Parameters:
  /// - [value]: The value to convert
  /// - [fieldWriter]: The target field's datatype writer
  ///
  /// Returns the converted value suitable for the field datatype.
  dynamic _convertValueForField(dynamic value, DatatypeWriter fieldWriter) {
    // Handle null values
    if (value == null) {
      // Return appropriate default for the field type
      if (fieldWriter is NumericDatatypeWriter) {
        return fieldWriter.datatypeClass == Hdf5DatatypeClass.float ? 0.0 : 0;
      } else if (fieldWriter is BooleanDatatypeWriter) {
        return false;
      } else if (fieldWriter is StringDatatypeWriter) {
        return '';
      }
      return value;
    }

    // Convert based on target field type
    if (fieldWriter is NumericDatatypeWriter) {
      if (fieldWriter.datatypeClass == Hdf5DatatypeClass.float) {
        // Target is float
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value) ?? 0.0;
        } else if (value is bool) {
          return value ? 1.0 : 0.0;
        }
        return 0.0;
      } else {
        // Target is integer
        if (value is num) {
          return value.toInt();
        } else if (value is String) {
          return int.tryParse(value) ?? 0;
        } else if (value is bool) {
          return value ? 1 : 0;
        }
        return 0;
      }
    } else if (fieldWriter is BooleanDatatypeWriter) {
      // Target is boolean
      if (value is bool) {
        return value;
      } else if (value is num) {
        return value != 0;
      } else if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return false;
    } else if (fieldWriter is StringDatatypeWriter) {
      // Target is string - convert everything to string
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    // Default: return as-is
    return value;
  }
}

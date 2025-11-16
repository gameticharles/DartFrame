/// Integration of dtype system with DataFrame and Series.
library;

import '../data_frame/data_frame.dart';
import '../series/series.dart';
import 'dtype.dart';

/// Extension to add dtype support to DataFrame.
extension DataFrameDType on DataFrame {
  /// Get the dtypes of all columns.
  ///
  /// Returns a map of column names to their inferred or assigned dtypes.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 'Alice', true],
  ///   [2, 'Bob', false],
  /// ], columns: ['ID', 'Name', 'Active']);
  ///
  /// var dtypes = df.dtypes;
  /// // {'ID': Int64, 'Name': String, 'Active': Boolean}
  /// ```
  Map<String, DType> get dtypesDetailed {
    final result = <String, DType>{};
    for (var col in columns) {
      result[col] = _inferDType(this[col].toList());
    }
    return result;
  }

  /// Convert column(s) to specified dtype.
  ///
  /// Parameters:
  /// - `dtype`: Either a single DType for all columns, or a Map of column names to DTypes/strings
  /// - `errors`: How to handle conversion errors ('raise', 'ignore', 'coerce')
  ///
  /// Example:
  /// ```dart
  /// // Convert single column
  /// var df2 = df.astype({'Age': DTypes.int32()});
  ///
  /// // Convert multiple columns
  /// var df3 = df.astype({
  ///   'Age': DTypes.int32(),
  ///   'Active': DTypes.boolean(),
  /// });
  ///
  /// // Convert to categorical
  /// var df4 = df.astype({'Category': 'category'});
  /// ```
  DataFrame astype(dynamic dtype, {String errors = 'raise'}) {
    if (dtype is DType) {
      // Apply same dtype to all columns
      final newData = <String, List<dynamic>>{};
      for (var col in columns) {
        newData[col] = _convertColumn(this[col].toList(), dtype, errors);
      }
      return DataFrame.fromMap(newData, index: List.from(index));
    } else if (dtype is Map<String, DType>) {
      // Apply specific dtypes to specific columns
      final newData = <String, List<dynamic>>{};
      for (var col in columns) {
        if (dtype.containsKey(col)) {
          newData[col] =
              _convertColumn(this[col].toList(), dtype[col]!, errors);
        } else {
          newData[col] = this[col].toList();
        }
      }
      return DataFrame.fromMap(newData, index: List.from(index));
    } else if (dtype is Map<String, String>) {
      // String dtype names - handle categorical specially
      final df = this;
      DataFrame result = df;

      for (var entry in dtype.entries) {
        final col = entry.key;
        final dtypeName = entry.value;

        if (!columns.contains(col)) {
          throw ArgumentError('Column $col does not exist');
        }

        if (dtypeName.toLowerCase() == 'category') {
          // Convert column to categorical using Series.astype
          final series = this[col];
          final categoricalSeries = series.astype('category');

          // Replace the column in the result
          final newData = <String, List<dynamic>>{};
          for (var c in result.columns) {
            if (c == col) {
              newData[c] = categoricalSeries.toList();
            } else {
              newData[c] = result[c].toList();
            }
          }
          result = DataFrame.fromMap(newData, index: List.from(result.index));
        } else {
          // Handle other dtype conversions
          final dtypeObj = DTypeRegistry().get(dtypeName);
          if (dtypeObj == null) {
            throw ArgumentError('Unknown dtype: $dtypeName');
          }

          final newData = <String, List<dynamic>>{};
          for (var c in result.columns) {
            if (c == col) {
              newData[c] = _convertColumn(result[c].toList(), dtypeObj, errors);
            } else {
              newData[c] = result[c].toList();
            }
          }
          result = DataFrame.fromMap(newData, index: List.from(result.index));
        }
      }

      return result;
    } else {
      throw ArgumentError(
          'dtype must be DType, Map<String, DType>, or Map<String, String>');
    }
  }

  /// Infer and optimize dtypes for all columns.
  ///
  /// Automatically converts columns to the most appropriate dtype,
  /// potentially reducing memory usage.
  ///
  /// Parameters:
  /// - `downcast`: Downcast to smallest possible dtype ('integer', 'float', 'all', or null)
  ///
  /// Example:
  /// ```dart
  /// var optimized = df.inferDTypes(downcast: 'all');
  /// ```
  DataFrame inferDTypes({String? downcast}) {
    final newData = <String, List<dynamic>>{};

    for (var col in columns) {
      final values = this[col].toList();
      var dtype = _inferDType(values);

      // Downcast if requested
      if (downcast != null) {
        dtype = _downcastDType(dtype, values, downcast);
      }

      newData[col] = _convertColumn(values, dtype, 'coerce');
    }

    return DataFrame.fromMap(newData, index: List.from(index));
  }

  /// Get memory usage per column with dtype information.
  ///
  /// Returns a map of column names to estimated memory usage in bytes.
  Map<String, int> memoryUsageByDType() {
    final result = <String, int>{};
    final dtypes = dtypesDetailed;

    for (var col in columns) {
      final dtype = dtypes[col]!;
      final values = this[col].toList();

      if (dtype.itemSize != null) {
        // Fixed-size type
        result[col] = (dtype.itemSize! * values.length).toInt();
      } else {
        // Variable-size type (estimate)
        var size = 0;
        for (var value in values) {
          if (value == null) {
            size += 8; // Pointer size
          } else if (value is String) {
            size += value.length * 2 + 16; // UTF-16 + overhead
          } else {
            size += 16; // Object overhead
          }
        }
        result[col] = size;
      }
    }

    return result;
  }

  // Helper methods

  DType _inferDType(List<dynamic> values) {
    if (values.isEmpty) return ObjectDType();

    var hasNull = false;
    var allInt = true;
    var allFloat = true;
    var allBool = true;
    var allString = true;
    var allDateTime = true;
    var allParsableInt = true;
    var allParsableFloat = true;

    var minInt = double.infinity;
    var maxInt = double.negativeInfinity;

    for (var value in values) {
      if (value == null) {
        hasNull = true;
        continue;
      }

      if (value is! int) allInt = false;
      if (value is! double && value is! int) allFloat = false;
      if (value is! bool) allBool = false;
      if (value is! String) allString = false;
      if (value is! DateTime) allDateTime = false;

      if (value is int) {
        if (value < minInt) minInt = value.toDouble();
        if (value > maxInt) maxInt = value.toDouble();
      }

      // Check if strings can be parsed as numbers
      if (value is String) {
        final intVal = int.tryParse(value);
        if (intVal != null) {
          if (intVal < minInt) minInt = intVal.toDouble();
          if (intVal > maxInt) maxInt = intVal.toDouble();
        } else {
          allParsableInt = false;
        }

        if (double.tryParse(value) == null) {
          allParsableFloat = false;
        }
      } else {
        allParsableInt = false;
        allParsableFloat = false;
      }
    }

    // Determine best type
    if (allBool) return BooleanDType(nullable: hasNull);
    if (allDateTime) return DateTimeDType(nullable: hasNull);

    if (allInt) {
      // Choose smallest int type that fits
      if (minInt >= -128 && maxInt <= 127) {
        return Int8DType(nullable: hasNull);
      } else if (minInt >= -32768 && maxInt <= 32767) {
        return Int16DType(nullable: hasNull);
      } else if (minInt >= -2147483648 && maxInt <= 2147483647) {
        return Int32DType(nullable: hasNull);
      } else {
        return Int64DType(nullable: hasNull);
      }
    }

    // Check if all strings can be parsed as integers
    if (allString && allParsableInt) {
      if (minInt >= -128 && maxInt <= 127) {
        return Int8DType(nullable: hasNull);
      } else if (minInt >= -32768 && maxInt <= 32767) {
        return Int16DType(nullable: hasNull);
      } else if (minInt >= -2147483648 && maxInt <= 2147483647) {
        return Int32DType(nullable: hasNull);
      } else {
        return Int64DType(nullable: hasNull);
      }
    }

    // Check if all strings can be parsed as floats
    if (allString && allParsableFloat) {
      return Float64DType(nullable: hasNull);
    }

    if (allFloat) return Float64DType(nullable: hasNull);
    if (allString) return StringDType(nullable: hasNull);

    return ObjectDType();
  }

  DType _downcastDType(DType dtype, List<dynamic> values, String downcast) {
    if (downcast == 'integer' || downcast == 'all') {
      if (dtype is Int64DType || dtype is Int32DType || dtype is Int16DType) {
        // Find actual range
        var minVal = double.infinity;
        var maxVal = double.negativeInfinity;

        for (var value in values) {
          if (value is int) {
            if (value < minVal) minVal = value.toDouble();
            if (value > maxVal) maxVal = value.toDouble();
          }
        }

        if (minVal >= -128 && maxVal <= 127) {
          return Int8DType(nullable: dtype.nullable);
        } else if (minVal >= -32768 && maxVal <= 32767) {
          return Int16DType(nullable: dtype.nullable);
        } else if (minVal >= -2147483648 && maxVal <= 2147483647) {
          return Int32DType(nullable: dtype.nullable);
        }
      }
    }

    if (downcast == 'float' || downcast == 'all') {
      if (dtype is Float64DType) {
        // Could downcast to Float32 if precision allows
        return Float32DType(nullable: dtype.nullable);
      }
    }

    return dtype;
  }

  List<dynamic> _convertColumn(
      List<dynamic> values, DType dtype, String errors) {
    final result = <dynamic>[];

    for (var value in values) {
      try {
        result.add(dtype.convert(value));
      } catch (e) {
        if (errors == 'raise') {
          rethrow;
        } else if (errors == 'coerce') {
          result.add(dtype.nullValue);
        } else {
          // ignore
          result.add(value);
        }
      }
    }

    return result;
  }
}

/// Extension to add dtype support to Series.
extension SeriesDType<T> on Series<T> {
  /// Get the DType of this Series.
  DType get dtypeInfo {
    final values = toList();
    return _inferDType(values);
  }

  /// Convert Series to specified dtype.
  ///
  /// Parameters:
  /// - `dtype`: Target dtype (DType object, string name, or 'category')
  /// - `categories`: For categorical conversion, optional explicit categories
  /// - `ordered`: For categorical conversion, whether categories are ordered
  /// - `errors`: How to handle conversion errors ('raise', 'ignore', 'coerce')
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 's');
  /// var s2 = s.astype(DTypes.int8());
  /// var s3 = s.astype('float32');
  /// var s4 = s.astype('category');
  /// var s5 = s.astype('category', categories: ['a', 'b', 'c'], ordered: true);
  /// ```
  Series<dynamic> astype(dynamic dtype,
      {List<dynamic>? categories,
      bool ordered = false,
      String errors = 'raise'}) {
    // Handle categorical conversion specially
    if (dtype is String && dtype.toLowerCase() == 'category') {
      // Convert in place for categorical
      toCategorical(categories: categories, ordered: ordered);
      return this as Series<dynamic>;
    }

    // Handle other dtype conversions
    if (dtype is String && dtype.toLowerCase() == 'object') {
      final values = toList();
      final newSeries = Series(values, index: List.from(index), name: name);
      newSeries.clearCategorical();
      newSeries.setDType('object');
      return newSeries;
    }

    if (dtype is String && dtype.toLowerCase() == 'int') {
      final values = toList();
      final converted = values.map((value) {
        if (value == null) return null;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
        return null;
      }).toList();
      final newSeries = Series(converted, index: List.from(index), name: name);
      newSeries.clearCategorical();
      newSeries.setDType('int64');
      return newSeries;
    }

    if (dtype is String && dtype.toLowerCase() == 'float') {
      final values = toList();
      final converted = values.map((value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      }).toList();
      final newSeries = Series(converted, index: List.from(index), name: name);
      newSeries.clearCategorical();
      newSeries.setDType('float64');
      return newSeries;
    }

    if (dtype is String && dtype.toLowerCase() == 'string') {
      final values = toList();
      final converted = values.map((value) {
        if (value == null) return null;
        return value.toString();
      }).toList();
      final newSeries = Series(converted, index: List.from(index), name: name);
      newSeries.clearCategorical();
      newSeries.setDType('object');
      return newSeries;
    }

    // Handle DType objects
    DType? dtypeObj;

    if (dtype is DType) {
      dtypeObj = dtype;
    } else if (dtype is String) {
      dtypeObj = DTypeRegistry().get(dtype);
      if (dtypeObj == null) {
        throw ArgumentError('Unknown dtype: $dtype');
      }
    } else {
      throw ArgumentError('dtype must be DType or String');
    }

    final values = toList();
    final converted = <dynamic>[];

    for (var value in values) {
      try {
        converted.add(dtypeObj.convert(value));
      } catch (e) {
        if (errors == 'raise') {
          rethrow;
        } else if (errors == 'coerce') {
          converted.add(dtypeObj.nullValue);
        } else {
          // ignore
          converted.add(value);
        }
      }
    }

    return Series(converted, index: List.from(index), name: name);
  }

  /// Get memory usage with dtype information.
  int memoryUsageByDType() {
    final dtypeObj = this.dtypeInfo;
    final values = toList();

    if (dtypeObj.itemSize != null) {
      return (dtypeObj.itemSize! * values.length).toInt();
    } else {
      var size = 0;
      for (var value in values) {
        if (value == null) {
          size += 8;
        } else if (value is String) {
          size += value.length * 2 + 16;
        } else {
          size += 16;
        }
      }
      return size;
    }
  }

  DType _inferDType(List<dynamic> values) {
    if (values.isEmpty) return ObjectDType();

    var hasNull = false;
    var allInt = true;
    var allFloat = true;
    var allBool = true;
    var allString = true;
    var allDateTime = true;

    var minInt = double.infinity;
    var maxInt = double.negativeInfinity;

    for (var value in values) {
      if (value == null) {
        hasNull = true;
        continue;
      }

      if (value is! int) allInt = false;
      if (value is! double && value is! int) allFloat = false;
      if (value is! bool) allBool = false;
      if (value is! String) allString = false;
      if (value is! DateTime) allDateTime = false;

      if (value is int) {
        if (value < minInt) minInt = value.toDouble();
        if (value > maxInt) maxInt = value.toDouble();
      }
    }

    if (allBool) return BooleanDType(nullable: hasNull);
    if (allDateTime) return DateTimeDType(nullable: hasNull);

    if (allInt) {
      // Choose smallest int type that fits
      if (minInt >= -128 && maxInt <= 127) {
        return Int8DType(nullable: hasNull);
      } else if (minInt >= -32768 && maxInt <= 32767) {
        return Int16DType(nullable: hasNull);
      } else if (minInt >= -2147483648 && maxInt <= 2147483647) {
        return Int32DType(nullable: hasNull);
      } else {
        return Int64DType(nullable: hasNull);
      }
    }

    if (allFloat) return Float64DType(nullable: hasNull);
    if (allString) return StringDType(nullable: hasNull);

    return ObjectDType();
  }
}

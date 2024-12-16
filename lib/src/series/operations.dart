part of '../../dart_frame.dart';

extension SeriesOperations on Series {
  /// Access elements by position or label using boolean indexing.
  ///
  /// Returns a new series containing only the elements for which the boolean condition is true.
  Series operator [](dynamic indices) {
    List<dynamic> selectedData = [];
    if (indices is List<bool>) {
      for (int i = 0; i < indices.length; i++) {
        if (indices[i]) {
          selectedData.add(data[i]);
        }
      }
    } else {
      // Handle single index
      selectedData.add(data[indices]);
    }
    return Series(selectedData, name: "$name (Selected)");
  }

  /// Sets the value for provided index or indices
  ///
  /// This method assigns the value or values to the Series as specified
  /// by the indices.
  ///
  /// Parameters:
  /// - indices: Represents which elements to modify. Can be a single index,
  ///   or potentially a list of indices for multiple assignments.
  /// - value: The value to assign. If multiple indices are provided, 'value'
  ///   should be an iterable such as a list or another Series.
  void operator []=(dynamic indices, dynamic value) {
    if (indices is int) {
      // Single Index Assignment
      if (indices < 0 || indices >= data.length) {
        throw IndexError.withLength(
          indices,
          data.length,
          indexable: this,
          name: 'Index out of range',
          message: null,
        );
      }
      data[indices] = value;
    } else if (indices is List<int>) {
      // Multiple Index Assignment
      if (value is! List || value.length != indices.length) {
        throw ArgumentError(
            "Value must be a list of the same length as the indices.");
      }
      for (int i = 0; i < indices.length; i++) {
        data[indices[i]] = value[i];
      }
    } else if (indices is List<bool> ||
        (indices is Series && indices.data is List<bool>)) {
      var dd = indices is Series ? indices.data : indices;
      if (value is List) {
        if (value.length != indices.length) {
          throw ArgumentError(
              "Value must be a list of the same length as the indices.");
        }
        for (int i = 0; i < indices.length; i++) {
          if (dd[i]) data[i] = value[i];
        }
      } else if (value is num) {
        for (int i = 0; i < indices.length; i++) {
          if (dd[i]) data[i] = value;
        }
      }
    } else {
      throw ArgumentError("Unsupported indices type.");
    }
  }

  /// **Addition (+) operator:**
  ///
  /// Adds the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator +(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for addition.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] + other.data[i]);
    }
    return Series(resultData, name: "($name + ${other.name})");
  }

  /// **Subtraction (-) operator:**
  ///
  /// Subtract the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator -(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for subtraction.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] - other.data[i]);
    }
    return Series(resultData, name: "($name - ${other.name})");
  }

  /// **Multiplication (*) operator:**
  ///
  /// Multiplies the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator *(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for multiplication.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] * other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// **Division (+) operator:**
  ///
  /// Divides the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator /(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for division.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      if (other.data[i] == 0) {
        throw Exception("Cannot divide by zero.");
      }
      resultData.add(data[i] / other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// **Floor Division (~/) operator:**
  ///
  /// Floor divides the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator ~/(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for floor division.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] ~/ other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// **Modulo (%) operator:**
  ///
  /// Mod the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator %(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for modulo operation.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] % other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// **Exponential (^) operator:**
  ///
  /// Take exponents of the corresponding elements of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator ^(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for exponentiation.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] ^ other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// Less than (<) operator:
  ///
  /// Compares the corresponding elements of this Series and another Series
  /// to check if each element of this Series is less than the corresponding
  /// element of the other Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator <(dynamic other) {
    List<bool> resultData = [];
    if (other is num) {
      for (int i = 0; i < length; i++) {
        resultData.add(data[i] < other);
      }

      return Series(resultData, name: "$name < $other");
    } else if (other is Series) {
      if (length != other.length) {
        throw Exception("Series must have the same length for comparison.");
      }

      for (int i = 0; i < length; i++) {
        resultData.add(data[i] < other.data[i]);
      }
      return Series(resultData, name: "$name < ${other.name}");
    }

    throw Exception("Can only compare Series to Series or num.");
  }

  /// Greater than (>) operator:
  ///
  /// Compares the corresponding elements of this Series and another Series
  /// to check if each element of this Series is greater than the corresponding
  /// element of the other Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator >(dynamic other) {
    List<bool> resultData = [];
    if (other is num) {
      for (int i = 0; i < length; i++) {
        resultData.add(data[i] > other);
      }

      return Series(resultData, name: "$name > $other");
    } else if (other is Series) {
      if (length != other.length) {
        throw Exception("Series must have the same length for comparison.");
      }

      for (int i = 0; i < length; i++) {
        resultData.add(data[i] > other.data[i]);
      }
      return Series(resultData, name: "$name > ${other.name}");
    }

    throw Exception("Can only compare Series to Series or num.");
  }

  /// Less than or equal to (<=) operator:
  ///
  /// Compares the corresponding elements of this Series and another Series
  /// to check if each element of this Series is less than or equal to the
  /// corresponding element of the other Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator <=(dynamic other) {
    List<bool> resultData = [];
    if (other is num) {
      for (int i = 0; i < length; i++) {
        resultData.add(data[i] <= other);
      }

      return Series(resultData, name: "$name <= $other");
    } else if (other is Series) {
      if (length != other.length) {
        throw Exception("Series must have the same length for comparison.");
      }

      for (int i = 0; i < length; i++) {
        resultData.add(data[i] <= other.data[i]);
      }
      return Series(resultData, name: "$name <= ${other.name}");
    }

    throw Exception("Can only compare Series to Series or num.");
  }

  /// Greater than or equal to (>=) operator:
  ///
  /// Compares the corresponding elements of this Series and another Series
  /// to check if each element of this Series is greater than or equal to the
  /// corresponding element of the other Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator >=(dynamic other) {
    List<bool> resultData = [];
    if (other is num) {
      for (int i = 0; i < length; i++) {
        resultData.add(data[i] >= other);
      }

      return Series(resultData, name: "$name >= $other");
    } else if (other is Series) {
      if (length != other.length) {
        throw Exception("Series must have the same length for comparison.");
      }

      for (int i = 0; i < length; i++) {
        resultData.add(data[i] >= other.data[i]);
      }
      return Series(resultData, name: "$name >= ${other.name}");
    }

    throw Exception("Can only compare Series to Series or num.");
  }

  /// Equal to (==) operator:
  ///
  /// Compares the corresponding elements of this Series and another Series
  /// to check if each element of this Series is equal to the corresponding
  /// element of the other Series.
  ///
  /// If [other] is a Series, it compares each element of this series with
  /// the corresponding element of the other series.
  ///
  /// If [other] is not a Series, it compares each element of this series with
  /// the single value [other].
  ///
  /// Returns a new Series with boolean values indicating the equality of each
  /// element with the corresponding element in [other] or with the single value.
  ///
  /// Throws an exception if the Series have different lengths.
  Series isEqual(Object other) {
    if (other is! Series) {
      // Compare each element with the single value 'other'
      return Series(
        data.map((element) => element == other).toList(),
        name: "$name == $other",
      );
    }

    // Check if 'other' is of type Series
    if (length != other.length) {
      throw Exception("Series must have the same length for comparison.");
    }

    // Compare each element with the corresponding element in 'other'
    List<bool> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] == other.data[i]);
    }

    return Series(resultData, name: "$name == ${other.name}");
  }

  // /// Override hashCode to be consistent with the overridden '==' operator
  // @override
  // int get hashCode => data.hashCode ^ name.hashCode;

  /// Bitwise AND (&) operator.
  ///
  /// Performs a bitwise AND operation between the corresponding elements
  /// of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator &(Series other) {
    if (length != other.length) {
      throw Exception(
          "Series must have the same length for bitwise AND operation.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] & other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// Bitwise OR (|) operator.
  ///
  /// Performs a bitwise OR operation between the corresponding elements
  /// of this Series and another Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series operator |(Series other) {
    if (length != other.length) {
      throw Exception(
          "Series must have the same length for bitwise OR operation.");
    }
    List<dynamic> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] | other.data[i]);
    }
    return Series(resultData, name: name);
  }

  /// Not equal to (!=) operator:
  ///
  /// Compares the corresponding elements of this Series and another Series
  /// to check if each element of this Series is not equal to the corresponding
  /// element of the other Series.
  ///
  /// Throws an exception if the Series have different lengths.
  Series notEqual(Series other) {
    if (length != other.length) {
      throw Exception("Series must have the same length for comparison.");
    }
    List<bool> resultData = [];
    for (int i = 0; i < length; i++) {
      resultData.add(data[i] != other.data[i]);
    }
    return Series(resultData, name: "$name != ${other.name}");
  }
}

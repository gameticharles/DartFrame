part of '../../dartframe.dart';

extension SeriesOperations on Series {
  dynamic _getMissingRepresentation(Series series) {
    return series._parentDataFrame?.replaceMissingValueWith;
  }

  bool _areIndexesEffectivelyIdentical(Series s1, Series s2) {
    final idx1 = s1.index;
    final idx2 = s2.index;
    final len1 = s1.length;
    final len2 = s2.length;

    bool s1IndexIsNullOrEmpty = idx1.isEmpty;
    bool s2IndexIsNullOrEmpty = idx2.isEmpty;

    if (s1IndexIsNullOrEmpty && s2IndexIsNullOrEmpty) {
      return len1 == len2; // If both are null/empty, rely on data length
    }

    if (s1IndexIsNullOrEmpty != s2IndexIsNullOrEmpty) {
      return false; // One has index, other doesn't
    }

    // Both have non-null, non-empty indexes
    if (idx1.length != idx2.length) {
      return false;
    }
    for (int i = 0; i < idx1.length; i++) {
      if (idx1[i] != idx2[i]) {
        return false;
      }
    }
    return true;
  }

  Series _performArithmeticOperation(
      Series other,
      dynamic Function(dynamic a, dynamic b) operation,
      String operationSymbol) {
    final self = this;
    final missingRep = _getMissingRepresentation(self);

    if (_areIndexesEffectivelyIdentical(self, other) &&
        self.length == other.length) {
      // Case 1: Indexes are null/empty/identical, and lengths match
      List<dynamic> resultData = [];
      for (int i = 0; i < self.length; i++) {
        dynamic val1 = self.data[i];
        dynamic val2 = other.data[i];
        if (val1 == missingRep || val2 == missingRep) {
          resultData.add(missingRep);
        } else {
          try {
            resultData.add(operation(val1, val2));
          } catch (e) {
            resultData.add(missingRep);
          }
        }
      }
      // Create a default index if both series have null indexes
      List<dynamic>? resultIndex = self.index.toList();

      return Series(resultData,
          name: "(${self.name} $operationSymbol ${other.name})",
          index: resultIndex);
    } else {
      // Case 2: Indexes are different or lengths differ (implying index use)
      List<dynamic> unionIndex = [];
      Set<dynamic> seenInUnion = {};

      void addToUnion(List<dynamic>? idxList) {
        if (idxList != null) {
          for (var label in idxList) {
            if (seenInUnion.add(label)) {
              unionIndex.add(label);
            }
          }
        }
      }

      // If one series has no index but the other does, treat un-indexed one as having default 0..N-1 index
      // However, the problem implies if indexes are different, we use union.
      // If one is null/empty, its effective index for union purposes is its default 0..N-1 range.

      List<dynamic> selfEffectiveIndex = self.index;
      List<dynamic> otherEffectiveIndex = other.index;

      addToUnion(selfEffectiveIndex);
      addToUnion(otherEffectiveIndex);

      if (unionIndex.isEmpty &&
          (self.length > 0 || other.length > 0) &&
          (self.index.isEmpty && other.index.isEmpty)) {
        // This case might arise if both have null indexes but different lengths.
        // The problem statement implies element-wise for identical indexes OR null/empty indexes IF lengths also match.
        // If lengths don't match and indexes are null, it's ambiguous.
        // For now, let's assume if _areIndexesEffectivelyIdentical is false, we MUST use union logic.
        // If unionIndex is still empty here, it implies both series might be empty or had null/empty incompatible indexes.
        // Let's default to using integer indices if union is empty but data isn't.
        int maxLen = max(self.length, other.length);
        if (maxLen > 0 && self.index.isEmpty && other.index.isEmpty) {
          unionIndex = List.generate(maxLen, (i) => i);
        }
      }

      Map<dynamic, int> selfIndexMap = {};
      for (int i = 0; i < selfEffectiveIndex.length; ++i) {
        selfIndexMap[selfEffectiveIndex[i]] = i;
      }
      Map<dynamic, int> otherIndexMap = {};
      for (int i = 0; i < otherEffectiveIndex.length; ++i) {
        otherIndexMap[otherEffectiveIndex[i]] = i;
      }

      List<dynamic> resultData = [];

      for (var label in unionIndex) {
        bool selfHasLabel = selfIndexMap.containsKey(label);
        bool otherHasLabel = otherIndexMap.containsKey(label);

        dynamic val1 = missingRep;
        dynamic val2 = missingRep;

        if (selfHasLabel) {
          int selfPos = selfIndexMap[label]!;
          if (selfPos < self.data.length) {
            // Check bounds
            val1 = self.data[selfPos];
          } else {
            // Label in index, but data out of bounds (should not happen with effectiveIndex)
            selfHasLabel = false;
          }
        }

        if (otherHasLabel) {
          int otherPos = otherIndexMap[label]!;
          if (otherPos < other.data.length) {
            // Check bounds
            val2 = other.data[otherPos];
          } else {
            otherHasLabel = false;
          }
        }

        if (!selfHasLabel ||
            !otherHasLabel ||
            val1 == missingRep ||
            val2 == missingRep) {
          resultData.add(missingRep);
        } else {
          try {
            resultData.add(operation(val1, val2));
          } catch (e) {
            resultData.add(missingRep);
          }
        }
      }
      return Series(resultData,
          name: "(${self.name} $operationSymbol ${other.name})",
          index: unionIndex);
    }
  }

  /// **Addition (+) operator:**
  ///
  /// Adds the corresponding elements of this Series and another Series or a numeric value.
  /// - If other is a Series, handles index alignment.
  /// - If other is a num, adds that value to each element in the Series.
  Series operator +(dynamic other) {
    if (other is num) {
      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val + other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name + $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) => a + b, '+');
    }
    throw Exception("Can only add Series to Series or num.");
  }

  /// **Subtraction (-) operator:**
  ///
  /// Subtracts a numeric value or another Series from this Series.
  /// - If other is a Series, handles index alignment.
  /// - If other is a num, subtracts that value from each element in the Series.
  Series operator -(dynamic other) {
    if (other is num) {
      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val - other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name - $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) => a - b, '-');
    }
    throw Exception("Can only subtract Series or num from Series.");
  }

  /// **Multiplication (*) operator:**
  ///
  /// Multiplies the elements of this Series by a numeric value or another Series.
  /// - If other is a Series, handles index alignment.
  /// - If other is a num, multiplies each element in the Series by that value.
  Series operator *(dynamic other) {
    if (other is num) {
      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val * other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name * $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) => a * b, '*');
    }
    throw Exception("Can only multiply Series by Series or num.");
  }

  /// **Division (/) operator:**
  ///
  /// Divides the elements of this Series by a numeric value or another Series.
  /// - If other is a Series, handles index alignment and division by zero.
  /// - If other is a num, divides each element in the Series by that value.
  Series operator /(dynamic other) {
    if (other is num) {
      if (other == 0) {
        // Return a Series filled with missing values for division by zero
        return Series(List.filled(length, _getMissingRepresentation(this)),
            name: "$name / $other", index: index.toList());
      }

      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val / other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name / $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) {
        if (b == 0) {
          // According to requirements, return missingRep for errors like division by zero
          return _getMissingRepresentation(this);
        }
        return a / b;
      }, '/');
    }
    throw Exception("Can only divide Series by Series or num.");
  }

  /// **Floor Division (~/) operator:**
  ///
  /// Floor divides the elements of this Series by a numeric value or another Series.
  /// - If other is a Series, handles index alignment and division by zero.
  /// - If other is a num, floor divides each element in the Series by that value.
  Series operator ~/(dynamic other) {
    if (other is num) {
      if (other == 0) {
        // Return a Series filled with missing values for division by zero
        return Series(List.filled(length, _getMissingRepresentation(this)),
            name: "$name ~/ $other", index: index.toList());
      }

      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val ~/ other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name ~/ $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) {
        if (b == 0) {
          return _getMissingRepresentation(this);
        }
        return a ~/ b;
      }, '~/');
    }
    throw Exception("Can only floor divide Series by Series or num.");
  }

  /// **Modulo (%) operator:**
  ///
  /// Computes the modulo of elements of this Series by a numeric value or another Series.
  /// - If other is a Series, handles index alignment and division by zero.
  /// - If other is a num, computes the modulo of each element in the Series by that value.
  Series operator %(dynamic other) {
    if (other is num) {
      if (other == 0) {
        // Return a Series filled with missing values for division by zero
        return Series(List.filled(length, _getMissingRepresentation(this)),
            name: "$name % $other", index: index.toList());
      }

      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val % other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name % $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) {
        if (b == 0) {
          return _getMissingRepresentation(this);
        }
        return a % b;
      }, '%');
    }
    throw Exception("Can only compute modulo of Series by Series or num.");
  }

  /// **Bitwise XOR (^) operator:**
  ///
  /// Performs bitwise XOR on elements of this Series with a numeric value or another Series.
  /// - If other is a Series, handles index alignment.
  /// - If other is a num, performs bitwise XOR of each element in the Series with that value.
  Series operator ^(dynamic other) {
    if (other is num) {
      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val ^ other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name ^ $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) => a ^ b, '^');
    }
    throw Exception(
        "Can only perform bitwise XOR on Series with Series or num.");
  }

  /// Bitwise AND (&) operator.
  ///
  /// Performs a bitwise AND operation between the elements of this Series and
  /// a numeric value or another Series.
  /// - If other is a Series, handles index alignment.
  /// - If other is a num, performs bitwise AND of each element with that value.
  Series operator &(dynamic other) {
    if (other is num) {
      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val & other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name & $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) => a & b, '&');
    }
    throw Exception(
        "Can only perform bitwise AND on Series with Series or num.");
  }

  /// Bitwise OR (|) operator.
  ///
  /// Performs a bitwise OR operation between the elements of this Series and
  /// a numeric value or another Series.
  /// - If other is a Series, handles index alignment.
  /// - If other is a num, performs bitwise OR of each element with that value.
  Series operator |(dynamic other) {
    if (other is num) {
      List<dynamic> resultData = [];
      for (int i = 0; i < length; i++) {
        var val = data[i];
        if (val == _getMissingRepresentation(this)) {
          resultData.add(_getMissingRepresentation(this));
        } else {
          try {
            resultData.add(val | other);
          } catch (e) {
            resultData.add(_getMissingRepresentation(this));
          }
        }
      }
      return Series(resultData, name: "$name | $other", index: index.toList());
    } else if (other is Series) {
      return _performArithmeticOperation(other, (a, b) => a | b, '|');
    }
    throw Exception(
        "Can only perform bitwise OR on Series with Series or num.");
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

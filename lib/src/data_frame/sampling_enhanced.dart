part of 'data_frame.dart';

/// Enhanced sampling and selection operations for DataFrame
extension DataFrameSamplingEnhanced on DataFrame {
  /// Sample with probability weights.
  ///
  /// Parameters:
  /// - `n`: Number of items to sample (mutually exclusive with frac)
  /// - `frac`: Fraction of items to sample (mutually exclusive with n)
  /// - `replace`: Sample with replacement (default: false)
  /// - `weights`: Column name or list of weights for sampling probability
  /// - `randomState`: Seed for random number generator for reproducibility
  ///
  /// Returns:
  /// DataFrame with sampled rows
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'item': ['A', 'B', 'C', 'D'],
  ///   'weight': [0.1, 0.2, 0.3, 0.4]
  /// });
  ///
  /// // Sample 2 items with weights
  /// var sampled = df.sampleWeighted(n: 2, weights: 'weight');
  ///
  /// // Sample 50% with custom weights
  /// var sampled2 = df.sampleWeighted(
  ///   frac: 0.5,
  ///   weights: [1, 2, 3, 4],
  ///   randomState: 42
  /// );
  /// ```
  DataFrame sampleWeighted({
    int? n,
    double? frac,
    bool replace = false,
    dynamic weights,
    int? randomState,
  }) {
    if (n == null && frac == null) {
      throw ArgumentError('Either n or frac must be specified');
    }

    if (n != null && frac != null) {
      throw ArgumentError('Cannot specify both n and frac');
    }

    if (_data.isEmpty) {
      return DataFrame._(List.from(_columns), [], index: []);
    }

    // Calculate sample size
    final sampleSize = n ?? (rowCount * frac!).round();

    if (sampleSize <= 0) {
      throw ArgumentError('Sample size must be positive');
    }

    if (!replace && sampleSize > rowCount) {
      throw ArgumentError(
          'Sample size ($sampleSize) cannot exceed DataFrame length ($rowCount) when sampling without replacement');
    }

    // Get weights
    final weightsList = _getWeights(weights);

    // Validate weights
    if (weightsList.length != rowCount) {
      throw ArgumentError(
          'Weights length (${weightsList.length}) must match DataFrame length ($rowCount)');
    }

    if (weightsList.any((w) => w < 0)) {
      throw ArgumentError('All weights must be non-negative');
    }

    final totalWeight = weightsList.reduce((a, b) => a + b);
    if (totalWeight <= 0) {
      throw ArgumentError('Total weight must be positive');
    }

    // Normalize weights
    final normalizedWeights = weightsList.map((w) => w / totalWeight).toList();

    // Create cumulative distribution
    final cumulativeWeights = <double>[];
    var cumSum = 0.0;
    for (var w in normalizedWeights) {
      cumSum += w;
      cumulativeWeights.add(cumSum);
    }

    // Sample indices
    final random = randomState != null ? Random(randomState) : Random();
    final sampledIndices = <int>[];
    final sampledData = <List<dynamic>>[];
    final sampledIndex = <dynamic>[];

    if (replace) {
      // Sample with replacement
      for (int i = 0; i < sampleSize; i++) {
        final r = random.nextDouble();
        final idx = _binarySearchCumulative(cumulativeWeights, r);
        sampledIndices.add(idx);
      }
    } else {
      // Sample without replacement using weighted reservoir sampling
      final availableIndices = List.generate(rowCount, (i) => i);
      final availableWeights = List<double>.from(normalizedWeights);

      for (int i = 0; i < sampleSize; i++) {
        // Recalculate cumulative weights
        final totalAvailable = availableWeights.reduce((a, b) => a + b);
        final cumulative = <double>[];
        var sum = 0.0;
        for (var w in availableWeights) {
          sum += w / totalAvailable;
          cumulative.add(sum);
        }

        // Sample one index
        final r = random.nextDouble();
        final localIdx = _binarySearchCumulative(cumulative, r);
        final actualIdx = availableIndices[localIdx];

        sampledIndices.add(actualIdx);

        // Remove from available
        availableIndices.removeAt(localIdx);
        availableWeights.removeAt(localIdx);
      }
    }

    // Build result
    for (int idx in sampledIndices) {
      sampledData.add(List<dynamic>.from(_data[idx]));
      sampledIndex.add(index[idx]);
    }

    return DataFrame._(
      List<dynamic>.from(_columns),
      sampledData,
      index: sampledIndex,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: _missingDataIndicator,
    );
  }

  /// Return elements at given positions.
  ///
  /// Parameters:
  /// - `indices`: List of integer positions to select
  /// - `axis`: 0 for rows (default), 1 for columns
  ///
  /// Returns:
  /// DataFrame with selected elements
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50]
  /// });
  ///
  /// // Take rows at positions 0, 2, 4
  /// var result = df.take([0, 2, 4]);
  /// // Returns rows 0, 2, 4
  ///
  /// // Take columns at positions 0
  /// var result2 = df.take([0], axis: 1);
  /// // Returns only column A
  ///
  /// // Take with negative indices (from end)
  /// var result3 = df.take([-1, -2]);
  /// // Returns last two rows
  /// ```
  DataFrame take(List<int> indices, {int axis = 0}) {
    if (indices.isEmpty) {
      if (axis == 0) {
        return DataFrame._(List.from(_columns), [], index: []);
      } else {
        return DataFrame._([], _data.map((row) => []).toList(), index: index);
      }
    }

    if (axis == 0) {
      // Take rows
      final selectedData = <List<dynamic>>[];
      final selectedIndex = <dynamic>[];

      for (var idx in indices) {
        // Handle negative indices
        final actualIdx = idx < 0 ? rowCount + idx : idx;

        if (actualIdx < 0 || actualIdx >= rowCount) {
          throw RangeError(
              'Index $idx is out of bounds for axis 0 with size $rowCount');
        }

        selectedData.add(List<dynamic>.from(_data[actualIdx]));
        selectedIndex.add(index[actualIdx]);
      }

      return DataFrame._(
        List<dynamic>.from(_columns),
        selectedData,
        index: selectedIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    } else if (axis == 1) {
      // Take columns
      final selectedColumns = <dynamic>[];
      final selectedData = <List<dynamic>>[];

      for (var idx in indices) {
        // Handle negative indices
        final actualIdx = idx < 0 ? columns.length + idx : idx;

        if (actualIdx < 0 || actualIdx >= columns.length) {
          throw RangeError(
              'Index $idx is out of bounds for axis 1 with size ${columns.length}');
        }

        selectedColumns.add(_columns[actualIdx]);
      }

      // Build data with selected columns
      for (var row in _data) {
        final newRow = <dynamic>[];
        for (var idx in indices) {
          final actualIdx = idx < 0 ? columns.length + idx : idx;
          newRow.add(row[actualIdx]);
        }
        selectedData.add(newRow);
      }

      return DataFrame._(
        selectedColumns,
        selectedData,
        index: index,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    } else {
      throw ArgumentError('axis must be 0 (rows) or 1 (columns)');
    }
  }

  /// Enhanced sample with frac parameter and random_state.
  ///
  /// This extends the basic sample() method with additional parameters.
  ///
  /// Parameters:
  /// - `n`: Number of items to sample (mutually exclusive with frac)
  /// - `frac`: Fraction of items to sample (mutually exclusive with n)
  /// - `replace`: Sample with replacement (default: false)
  /// - `randomState`: Seed for random number generator for reproducibility
  /// - `axis`: 0 for rows (default), 1 for columns
  ///
  /// Returns:
  /// DataFrame with sampled elements
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50]
  /// });
  ///
  /// // Sample 50% of rows
  /// var sampled = df.sampleFrac(frac: 0.5);
  ///
  /// // Sample 3 rows with reproducible results
  /// var sampled2 = df.sampleFrac(n: 3, randomState: 42);
  ///
  /// // Sample 2 columns
  /// var sampled3 = df.sampleFrac(n: 1, axis: 1);
  /// ```
  DataFrame sampleFrac({
    int? n,
    double? frac,
    bool replace = false,
    int? randomState,
    int axis = 0,
  }) {
    if (n == null && frac == null) {
      throw ArgumentError('Either n or frac must be specified');
    }

    if (n != null && frac != null) {
      throw ArgumentError('Cannot specify both n and frac');
    }

    if (axis == 0) {
      // Sample rows
      if (_data.isEmpty) {
        return DataFrame._(List.from(_columns), [], index: []);
      }

      final sampleSize = n ?? (rowCount * frac!).round();

      if (sampleSize <= 0) {
        throw ArgumentError('Sample size must be positive');
      }

      if (!replace && sampleSize > rowCount) {
        throw ArgumentError(
            'Sample size ($sampleSize) cannot exceed DataFrame length ($rowCount) when sampling without replacement');
      }

      final random = randomState != null ? Random(randomState) : Random();
      final sampledIndices = <int>[];

      if (replace) {
        for (int i = 0; i < sampleSize; i++) {
          sampledIndices.add(random.nextInt(rowCount));
        }
      } else {
        final availableIndices = List.generate(rowCount, (i) => i);
        for (int i = 0; i < sampleSize; i++) {
          final randomIdx = random.nextInt(availableIndices.length);
          sampledIndices.add(availableIndices.removeAt(randomIdx));
        }
      }

      final sampledData = <List<dynamic>>[];
      final sampledIndex = <dynamic>[];

      for (int idx in sampledIndices) {
        sampledData.add(List<dynamic>.from(_data[idx]));
        sampledIndex.add(index[idx]);
      }

      return DataFrame._(
        List<dynamic>.from(_columns),
        sampledData,
        index: sampledIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    } else if (axis == 1) {
      // Sample columns
      if (columns.isEmpty) {
        return DataFrame._([], _data.map((row) => []).toList(), index: index);
      }

      final sampleSize = n ?? (columns.length * frac!).round();

      if (sampleSize <= 0) {
        throw ArgumentError('Sample size must be positive');
      }

      if (!replace && sampleSize > columns.length) {
        throw ArgumentError(
            'Sample size ($sampleSize) cannot exceed number of columns (${columns.length}) when sampling without replacement');
      }

      final random = randomState != null ? Random(randomState) : Random();
      final sampledIndices = <int>[];

      if (replace) {
        for (int i = 0; i < sampleSize; i++) {
          sampledIndices.add(random.nextInt(columns.length));
        }
      } else {
        final availableIndices = List.generate(columns.length, (i) => i);
        for (int i = 0; i < sampleSize; i++) {
          final randomIdx = random.nextInt(availableIndices.length);
          sampledIndices.add(availableIndices.removeAt(randomIdx));
        }
      }

      return take(sampledIndices, axis: 1);
    } else {
      throw ArgumentError('axis must be 0 (rows) or 1 (columns)');
    }
  }

  /// Get weights from various input formats.
  List<double> _getWeights(dynamic weights) {
    if (weights == null) {
      // Uniform weights
      return List.filled(rowCount, 1.0);
    } else if (weights is String) {
      // Column name
      if (!columns.contains(weights)) {
        throw ArgumentError('Weight column "$weights" not found');
      }
      final series = this[weights];
      final result = <double>[];
      for (var v in series.data) {
        if (v is num) {
          result.add(v.toDouble());
        } else {
          throw ArgumentError('Weight column must contain numeric values');
        }
      }
      return result;
    } else if (weights is List) {
      // List of weights
      final result = <double>[];
      for (var v in weights) {
        if (v is num) {
          result.add(v.toDouble());
        } else {
          throw ArgumentError('Weights must be numeric');
        }
      }
      return result;
    } else {
      throw ArgumentError(
          'Weights must be a column name (String) or a List of numbers');
    }
  }

  /// Binary search in cumulative distribution.
  int _binarySearchCumulative(List<double> cumulative, double value) {
    int left = 0;
    int right = cumulative.length - 1;

    while (left < right) {
      final mid = (left + right) ~/ 2;
      if (cumulative[mid] < value) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }

    return left;
  }
}

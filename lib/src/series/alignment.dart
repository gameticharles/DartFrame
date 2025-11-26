part of 'series.dart';

/// Extension for Series alignment and reindexing methods
extension SeriesAlignment on Series {
  /// Conform Series to new index with optional filling logic.
  ///
  /// Places NA/NaN in locations having no value in the previous index.
  ///
  /// Parameters:
  ///   - `newIndex`: New labels for the index
  ///   - `method`: Method to use for filling holes
  ///     - null: don't fill gaps
  ///     - 'ffill'/'pad': propagate last valid observation forward
  ///     - 'bfill'/'backfill': use next valid observation to fill gap
  ///   - `fillValue`: Value to use for missing values
  ///   - `limit`: Maximum number of consecutive elements to forward/backward fill
  ///
  /// Returns:
  ///   Series with changed index
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 'data', index: ['a', 'b', 'c']);
  /// var reindexed = s.reindex(['a', 'b', 'c', 'd']);
  /// // Index 'd' will have null value
  ///
  /// var filled = s.reindex(['a', 'b', 'c', 'd'], fillValue: 0);
  /// // Index 'd' will have 0
  /// ```
  Series reindex(
    List<dynamic> newIndex, {
    String? method,
    dynamic fillValue,
    int? limit,
  }) {
    final oldIndexMap = <dynamic, int>{};

    // Create index lookup map
    for (int i = 0; i < index.length; i++) {
      oldIndexMap[index[i]] = i;
    }

    // Build new data
    final newData = <dynamic>[];
    for (final idx in newIndex) {
      if (oldIndexMap.containsKey(idx)) {
        newData.add(data[oldIndexMap[idx]!]);
      } else {
        newData.add(fillValue ?? _missingRepresentation);
      }
    }

    dynamic result = Series(newData, name: name, index: newIndex);

    // Apply fill method if specified
    if (method != null) {
      if (method == 'ffill' || method == 'pad') {
        result = result.ffill(limit: limit);
      } else if (method == 'bfill' || method == 'backfill') {
        result = result.bfill(limit: limit);
      }
    }

    return result as Series;
  }

  /// Align two Series with specified join method.
  ///
  /// Parameters:
  ///   - `other`: Series to align with
  ///   - `join`: Type of alignment to perform
  ///     - 'outer': Union of indices (default)
  ///     - 'inner': Intersection of indices
  ///     - 'left': Use calling Series' index
  ///     - 'right': Use other Series' index
  ///   - `fillValue`: Value to use for missing values
  ///
  /// Returns:
  ///   A list of [aligned_left, aligned_right] Series
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3], name: 'A', index: ['a', 'b', 'c']);
  /// var s2 = Series([4, 5, 6], name: 'B', index: ['b', 'c', 'd']);
  ///
  /// var aligned = s1.align(s2, join: 'outer');
  /// // Both Series will have index ['a', 'b', 'c', 'd']
  /// ```
  List<Series> align(
    Series other, {
    String join = 'outer',
    dynamic fillValue,
  }) {
    final newIndex = _computeAlignedIndex(index, other.index, join);

    final left = reindex(newIndex, fillValue: fillValue);
    final right = other.reindex(newIndex, fillValue: fillValue);

    return <Series>[left, right];
  }

  /// Compute aligned index based on join type
  List<dynamic> _computeAlignedIndex(
    List<dynamic> leftIndex,
    List<dynamic> rightIndex,
    String join,
  ) {
    switch (join) {
      case 'outer':
        // Union of indices
        final combined = <dynamic>{...leftIndex, ...rightIndex};
        return combined.toList();

      case 'inner':
        // Intersection of indices
        final leftSet = leftIndex.toSet();
        final rightSet = rightIndex.toSet();
        return leftSet.intersection(rightSet).toList();

      case 'left':
        return List.from(leftIndex);

      case 'right':
        return List.from(rightIndex);

      default:
        throw ArgumentError(
            'Invalid join type: $join. Must be one of: outer, inner, left, right');
    }
  }

  /// Rename the index of the Series.
  ///
  /// Parameters:
  ///   - `mapper`: Function or dict-like to transform index values
  ///   - `inplace`: Whether to modify the Series in place
  ///
  /// Returns:
  ///   Series with renamed index (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 'data', index: ['a', 'b', 'c']);
  ///
  /// // Using a function
  /// var renamed = s.renameAxis((idx) => idx.toString().toUpperCase());
  /// // Index: ['A', 'B', 'C']
  ///
  /// // Using a map
  /// var renamed2 = s.renameAxis({'a': 'x', 'b': 'y', 'c': 'z'});
  /// // Index: ['x', 'y', 'z']
  /// ```
  Series? renameAxis(
    dynamic mapper, {
    bool inplace = false,
  }) {
    List<dynamic> newIndex;

    if (mapper is Function) {
      newIndex = index.map((idx) => mapper(idx)).toList();
    } else if (mapper is Map) {
      newIndex = index.map((idx) => mapper[idx] ?? idx).toList();
    } else {
      throw ArgumentError('mapper must be a Function or Map');
    }

    if (inplace) {
      index = newIndex;
      return null;
    } else {
      return Series(List.from(data), name: name, index: newIndex);
    }
  }

  /// Return an object with matching indices as other object.
  ///
  /// Parameters:
  ///   - `other`: Object to use for reindexing
  ///   - `method`: Method to use for filling holes
  ///   - `fillValue`: Value to use for missing values
  ///   - `limit`: Maximum number of consecutive fills
  ///
  /// Returns:
  ///   Series with same index as other
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3, 4], name: 'data', index: ['a', 'b', 'c', 'd']);
  /// var s2 = Series([10, 20], name: 'other', index: ['a', 'b']);
  ///
  /// var result = s1.reindexLike(s2);
  /// // result will have index ['a', 'b']
  /// ```
  Series reindexLike(
    Series other, {
    String? method,
    dynamic fillValue,
    int? limit,
  }) {
    return reindex(
      other.index,
      method: method,
      fillValue: fillValue,
      limit: limit,
    );
  }
}

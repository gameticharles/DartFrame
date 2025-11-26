part of 'data_frame.dart';

/// Extension for enhanced DataFrame sorting operations
extension DataFrameSortingEnhanced on DataFrame {
  /// Sort by the values along either axis with enhanced options.
  ///
  /// Parameters:
  ///   - `by`: Name or list of names to sort by
  ///   - `axis`: Axis to sort along (0 for rows, 1 for columns)
  ///   - `ascending`: Sort ascending vs descending
  ///   - `inplace`: Whether to modify DataFrame in place
  ///   - `kind`: Sorting algorithm ('quicksort', 'mergesort', 'heapsort', 'stable')
  ///   - `naPosition`: Where to put NaNs ('first' or 'last')
  ///   - `ignoreIndex`: If true, reset index to 0, 1, ..., n-1
  ///   - `key`: Function to apply to values before sorting
  ///
  /// Returns:
  ///   Sorted DataFrame (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [3, 1, 2],
  ///   'B': ['z', 'x', 'y'],
  /// });
  ///
  /// // Sort with key function
  /// var sorted = df.sortValuesEnhanced(
  ///   by: 'B',
  ///   key: (value) => value.toString().toLowerCase(),
  /// );
  ///
  /// // Sort and reset index
  /// var sorted2 = df.sortValuesEnhanced(by: 'A', ignoreIndex: true);
  /// ```
  DataFrame? sortValuesEnhanced({
    required dynamic by,
    int axis = 0,
    bool ascending = true,
    bool inplace = false,
    String kind = 'quicksort',
    String naPosition = 'last',
    bool ignoreIndex = false,
    Function(dynamic)? key,
  }) {
    if (axis != 0) {
      throw UnimplementedError(
          'Sorting by columns (axis=1) not yet implemented');
    }

    final columns = by is List ? by : [by];

    // Create list of (index, row) pairs
    final indexedRows = <MapEntry<int, List<dynamic>>>[];
    for (int i = 0; i < rowCount; i++) {
      indexedRows.add(MapEntry(i, List.from(_data[i])));
    }

    // Sort using the specified algorithm
    if (kind == 'stable' || kind == 'mergesort') {
      _mergeSort(indexedRows, columns, ascending, naPosition, key);
    } else {
      // Default to quicksort
      indexedRows.sort((a, b) => _compareRows(
            a.value,
            b.value,
            columns,
            ascending,
            naPosition,
            key,
          ));
    }

    // Extract sorted data and indices
    final sortedData = indexedRows.map((e) => e.value).toList();
    final sortedIndices = indexedRows.map((e) => index[e.key]).toList();

    // Create result index
    final resultIndex =
        ignoreIndex ? List.generate(rowCount, (i) => i) : sortedIndices;

    if (inplace) {
      _data.clear();
      _data.addAll(sortedData);
      index.clear();
      index.addAll(resultIndex);
      return null;
    } else {
      return DataFrame(
        sortedData,
        columns: _columns,
        index: resultIndex,
        allowFlexibleColumns: allowFlexibleColumns,
      );
    }
  }

  /// Sort object by labels (along an axis) with enhanced options.
  ///
  /// Parameters:
  ///   - `axis`: Axis to sort along (0 for index, 1 for columns)
  ///   - `level`: Level(s) to sort by if MultiIndex
  ///   - `ascending`: Sort ascending vs descending
  ///   - `inplace`: Whether to modify DataFrame in place
  ///   - `kind`: Sorting algorithm
  ///   - `naPosition`: Where to put NaNs
  ///   - `sortRemaining`: If true, sort by remaining levels after level
  ///   - `ignoreIndex`: If true, reset index
  ///   - `key`: Function to apply to index values before sorting
  ///
  /// Returns:
  ///   Sorted DataFrame (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// }, index: ['c', 'a', 'b']);
  ///
  /// // Sort by index with key function
  /// var sorted = df.sortIndexEnhanced(
  ///   key: (idx) => idx.toString().toLowerCase(),
  /// );
  ///
  /// // Sort and reset index
  /// var sorted2 = df.sortIndexEnhanced(ignoreIndex: true);
  /// ```
  DataFrame? sortIndexEnhanced({
    int axis = 0,
    dynamic level,
    bool ascending = true,
    bool inplace = false,
    String kind = 'quicksort',
    String naPosition = 'last',
    bool sortRemaining = true,
    bool ignoreIndex = false,
    Function(dynamic)? key,
  }) {
    if (axis == 0) {
      // Sort by row index
      final indexedRows = <MapEntry<dynamic, List<dynamic>>>[];
      for (int i = 0; i < rowCount; i++) {
        indexedRows.add(MapEntry(index[i], List.from(_data[i])));
      }

      // Apply key function if provided
      indexedRows.sort((a, b) {
        final aKey = key != null ? key(a.key) : a.key;
        final bKey = key != null ? key(b.key) : b.key;

        if (_isNA(aKey) && _isNA(bKey)) return 0;
        if (_isNA(aKey)) return naPosition == 'first' ? -1 : 1;
        if (_isNA(bKey)) return naPosition == 'first' ? 1 : -1;

        if (aKey is Comparable && bKey is Comparable) {
          try {
            final cmp = aKey.compareTo(bKey);
            return ascending ? cmp : -cmp;
          } catch (e) {
            return 0;
          }
        }
        return 0;
      });

      final sortedData = indexedRows.map((e) => e.value).toList();
      final sortedIndex = ignoreIndex
          ? List.generate(rowCount, (i) => i)
          : indexedRows.map((e) => e.key).toList();

      if (inplace) {
        _data.clear();
        _data.addAll(sortedData);
        index.clear();
        index.addAll(sortedIndex);
        return null;
      } else {
        return DataFrame(
          sortedData,
          columns: _columns,
          index: sortedIndex,
          allowFlexibleColumns: allowFlexibleColumns,
        );
      }
    } else {
      // Sort by column names
      final columnPairs = <MapEntry<dynamic, int>>[];
      for (int i = 0; i < _columns.length; i++) {
        columnPairs.add(MapEntry(_columns[i], i));
      }

      columnPairs.sort((a, b) {
        final aKey = key != null ? key(a.key) : a.key;
        final bKey = key != null ? key(b.key) : b.key;

        if (aKey is Comparable && bKey is Comparable) {
          try {
            final cmp = aKey.compareTo(bKey);
            return ascending ? cmp : -cmp;
          } catch (e) {
            return 0;
          }
        }
        return 0;
      });

      final newData = <String, List<dynamic>>{};

      for (final pair in columnPairs) {
        newData[pair.key.toString()] = column(pair.key).data;
      }

      if (inplace) {
        final temp = DataFrame.fromMap(newData, index: index);
        _columns.clear();
        _columns.addAll(temp._columns);
        _data.clear();
        _data.addAll(temp._data);
        return null;
      } else {
        return DataFrame.fromMap(newData, index: index);
      }
    }
  }

  /// Compare two rows for sorting
  int _compareRows(
    List<dynamic> rowA,
    List<dynamic> rowB,
    List<dynamic> columns,
    bool ascending,
    String naPosition,
    Function(dynamic)? key,
  ) {
    for (final col in columns) {
      final colIndex = _columns.indexOf(col);
      if (colIndex == -1) continue;

      var valA = rowA[colIndex];
      var valB = rowB[colIndex];

      // Apply key function if provided
      if (key != null) {
        valA = key(valA);
        valB = key(valB);
      }

      // Handle NA values
      if (_isNA(valA) && _isNA(valB)) continue;
      if (_isNA(valA)) return naPosition == 'first' ? -1 : 1;
      if (_isNA(valB)) return naPosition == 'first' ? 1 : -1;

      // Compare values
      if (valA is Comparable && valB is Comparable) {
        try {
          final cmp = valA.compareTo(valB);
          if (cmp != 0) return ascending ? cmp : -cmp;
        } catch (e) {
          // Continue to next column if comparison fails
        }
      }
    }
    return 0;
  }

  /// Merge sort implementation for stable sorting
  void _mergeSort(
    List<MapEntry<int, List<dynamic>>> list,
    List<dynamic> columns,
    bool ascending,
    String naPosition,
    Function(dynamic)? key,
  ) {
    if (list.length <= 1) return;

    final mid = list.length ~/ 2;
    final left = list.sublist(0, mid);
    final right = list.sublist(mid);

    _mergeSort(left, columns, ascending, naPosition, key);
    _mergeSort(right, columns, ascending, naPosition, key);

    int i = 0, j = 0, k = 0;

    while (i < left.length && j < right.length) {
      final cmp = _compareRows(
        left[i].value,
        right[j].value,
        columns,
        ascending,
        naPosition,
        key,
      );

      if (cmp <= 0) {
        list[k++] = left[i++];
      } else {
        list[k++] = right[j++];
      }
    }

    while (i < left.length) {
      list[k++] = left[i++];
    }

    while (j < right.length) {
      list[k++] = right[j++];
    }
  }

  /// Check if value is NA
  bool _isNA(dynamic value) {
    if (value == null) return true;
    if (replaceMissingValueWith != null && value == replaceMissingValueWith) {
      return true;
    }
    return false;
  }
}

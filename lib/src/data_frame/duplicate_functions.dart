part of 'data_frame.dart';

extension DataFrameDuplicateFunctions on DataFrame {
  /// Returns a boolean Series/DataFrame indicating duplicate rows.
  ///
  /// Parameters:
  /// - `subset`: Column names to consider for identifying duplicates.
  ///   If null, uses all columns.
  /// - `keep`: Determines which duplicates to mark:
  ///   - 'first' (default): Mark duplicates as True except for the first occurrence.
  ///   - 'last': Mark duplicates as True except for the last occurrence.
  ///   - false: Mark all duplicates as True.
  ///
  /// Returns:
  /// A Series of boolean values where True indicates a duplicate row.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 'x'},
  ///   {'A': 2, 'B': 'y'},
  ///   {'A': 1, 'B': 'x'},  // duplicate
  ///   {'A': 3, 'B': 'z'},
  ///   {'A': 1, 'B': 'x'},  // duplicate
  /// ]);
  ///
  /// var dups = df.duplicated();
  /// // Returns: [false, false, true, false, true]
  ///
  /// var dups_last = df.duplicated(keep: 'last');
  /// // Returns: [true, false, true, false, false]
  ///
  /// var all_dups = df.duplicated(keep: false);
  /// // Returns: [true, false, true, false, true]
  /// ```
  Series duplicated({List<String>? subset, dynamic keep = 'first'}) {
    if (keep != 'first' && keep != 'last' && keep != false) {
      throw ArgumentError("keep must be 'first', 'last', or false");
    }

    // Determine which columns to check
    final columnsToCheck = subset ?? columns;

    // Validate subset columns exist
    for (var col in columnsToCheck) {
      if (!columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }

    // Get column indices
    final colIndices =
        columnsToCheck.map((col) => columns.indexOf(col)).toList();

    // Track seen rows and their first/last occurrence
    final Map<String, int> seenRows = {};
    final List<bool> isDuplicate = List.filled(rows.length, false);

    // First pass: identify all duplicates
    for (int i = 0; i < rows.length; i++) {
      // Create a key from the subset columns
      final rowKey = colIndices.map((idx) => rows[i][idx].toString()).join('|');

      if (seenRows.containsKey(rowKey)) {
        isDuplicate[i] = true;
        if (keep == 'last') {
          // Mark previous occurrence as duplicate too
          isDuplicate[seenRows[rowKey]!] = true;
        }
      }

      if (keep == 'last') {
        seenRows[rowKey] = i; // Keep updating to track last occurrence
      } else {
        seenRows.putIfAbsent(rowKey, () => i);
      }
    }

    // If keep is 'last', unmark the last occurrence of each duplicate
    if (keep == 'last') {
      final lastOccurrences = seenRows.values.toSet();
      for (var idx in lastOccurrences) {
        isDuplicate[idx] = false;
      }
    }

    // If keep is false, mark all occurrences including first
    if (keep == false) {
      final duplicateKeys = <String>{};
      final rowCounts = <String, int>{};

      for (int i = 0; i < rows.length; i++) {
        final rowKey =
            colIndices.map((idx) => rows[i][idx].toString()).join('|');
        rowCounts[rowKey] = (rowCounts[rowKey] ?? 0) + 1;
        if (rowCounts[rowKey]! > 1) {
          duplicateKeys.add(rowKey);
        }
      }

      for (int i = 0; i < rows.length; i++) {
        final rowKey =
            colIndices.map((idx) => rows[i][idx].toString()).join('|');
        isDuplicate[i] = duplicateKeys.contains(rowKey);
      }
    }

    return Series(isDuplicate, name: 'duplicated', index: index);
  }

  /// Removes duplicate rows from the DataFrame.
  ///
  /// Parameters:
  /// - `subset`: Column names to consider for identifying duplicates.
  ///   If null, uses all columns.
  /// - `keep`: Determines which duplicates to keep:
  ///   - 'first' (default): Keep the first occurrence, drop subsequent duplicates.
  ///   - 'last': Keep the last occurrence, drop previous duplicates.
  ///   - false: Drop all duplicates.
  /// - `inplace`: If true, modifies the DataFrame in place and returns this.
  ///   If false (default), returns a new DataFrame.
  ///
  /// Returns:
  /// A new DataFrame with duplicates removed, or this DataFrame if inplace=true.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 'x'},
  ///   {'A': 2, 'B': 'y'},
  ///   {'A': 1, 'B': 'x'},  // duplicate
  ///   {'A': 3, 'B': 'z'},
  /// ]);
  ///
  /// var unique_df = df.dropDuplicates();
  /// // Returns DataFrame with rows: [{'A': 1, 'B': 'x'}, {'A': 2, 'B': 'y'}, {'A': 3, 'B': 'z'}]
  ///
  /// var df2 = df.dropDuplicates(subset: ['A']);
  /// // Only considers column 'A' for duplicates
  /// ```
  DataFrame dropDuplicates({
    List<String>? subset,
    dynamic keep = 'first',
    bool inplace = false,
  }) {
    final duplicateMask = duplicated(subset: subset, keep: keep);

    // Filter rows where duplicated is false
    final List<List<dynamic>> newData = [];
    final List<dynamic> newIndex = [];

    for (int i = 0; i < rows.length; i++) {
      if (duplicateMask.data[i] == false) {
        newData.add(List<dynamic>.from(rows[i]));
        newIndex.add(index[i]);
      }
    }

    if (inplace) {
      // Modify in place - need to access private fields
      // This is a limitation of extensions, so we'll return a new DataFrame
      throw UnimplementedError(
          'inplace=true is not supported for dropDuplicates. Use: df = df.dropDuplicates()');
    }

    return DataFrame.fromRows(
      List.generate(newData.length, (i) {
        return Map.fromIterables(columns, newData[i]);
      }),
      index: newIndex,
    );
  }

  /// Returns the n largest values ordered by columns.
  ///
  /// Parameters:
  /// - `n`: Number of rows to return.
  /// - `columns`: Column name(s) to order by. Can be a String or List<String>.
  /// - `keep`: When there are duplicate values:
  ///   - 'first' (default): Prioritize the first occurrence.
  ///   - 'last': Prioritize the last occurrence.
  ///   - 'all': Keep all ties (may return more than n rows).
  ///
  /// Returns:
  /// A new DataFrame with the n largest values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Score': 95},
  ///   {'Name': 'Bob', 'Score': 87},
  ///   {'Name': 'Charlie', 'Score': 92},
  ///   {'Name': 'David', 'Score': 88},
  /// ]);
  ///
  /// var top3 = df.nlargest(3, 'Score');
  /// // Returns rows for Alice (95), Charlie (92), David (88)
  /// ```
  DataFrame nlargest(int n, dynamic columns, {String keep = 'first'}) {
    if (n <= 0) {
      return DataFrame.fromRows([], columns: this.columns);
    }

    final List<String> sortColumns =
        columns is String ? [columns] : columns as List<String>;

    // Validate columns exist
    for (var col in sortColumns) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }

    // Create list of (index, row) pairs
    final indexedRows =
        List.generate(rows.length, (i) => {'idx': i, 'row': rows[i]});

    // Sort by specified columns in descending order
    indexedRows.sort((a, b) {
      for (var col in sortColumns) {
        final colIdx = this.columns.indexOf(col);
        final aVal = a['row'][colIdx];
        final bVal = b['row'][colIdx];

        // Handle null/missing values
        if (aVal == null && bVal == null) continue;
        if (aVal == null) return 1;
        if (bVal == null) return -1;

        // Compare values (descending order)
        if (aVal is Comparable && bVal is Comparable) {
          final cmp = (bVal).compareTo(aVal);
          if (cmp != 0) return cmp;
        }
      }

      // If all columns are equal, use original index for stability
      if (keep == 'first') {
        return (a['idx'] as int).compareTo(b['idx'] as int);
      } else if (keep == 'last') {
        return (b['idx'] as int).compareTo(a['idx'] as int);
      }
      return 0;
    });

    // Take top n rows
    final resultCount =
        keep == 'all' ? indexedRows.length : min(n, indexedRows.length);
    final resultData = <List<dynamic>>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < resultCount; i++) {
      if (keep != 'all' && i >= n) break;
      final idx = indexedRows[i]['idx'] as int;
      resultData.add(List<dynamic>.from(rows[idx]));
      resultIndex.add(index[idx]);
    }

    return DataFrame.fromRows(
      List.generate(resultData.length, (i) {
        return Map.fromIterables(this.columns, resultData[i]);
      }),
      index: resultIndex,
    );
  }

  /// Returns the n smallest values ordered by columns.
  ///
  /// Parameters:
  /// - `n`: Number of rows to return.
  /// - `columns`: Column name(s) to order by. Can be a String or List<String>.
  /// - `keep`: When there are duplicate values:
  ///   - 'first' (default): Prioritize the first occurrence.
  ///   - 'last': Prioritize the last occurrence.
  ///   - 'all': Keep all ties (may return more than n rows).
  ///
  /// Returns:
  /// A new DataFrame with the n smallest values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Score': 95},
  ///   {'Name': 'Bob', 'Score': 87},
  ///   {'Name': 'Charlie', 'Score': 92},
  ///   {'Name': 'David', 'Score': 88},
  /// ]);
  ///
  /// var bottom2 = df.nsmallest(2, 'Score');
  /// // Returns rows for Bob (87), David (88)
  /// ```
  DataFrame nsmallest(int n, dynamic columns, {String keep = 'first'}) {
    if (n <= 0) {
      return DataFrame.fromRows([], columns: this.columns);
    }

    final List<String> sortColumns =
        columns is String ? [columns] : columns as List<String>;

    // Validate columns exist
    for (var col in sortColumns) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }

    // Create list of (index, row) pairs
    final indexedRows =
        List.generate(rows.length, (i) => {'idx': i, 'row': rows[i]});

    // Sort by specified columns in ascending order
    indexedRows.sort((a, b) {
      for (var col in sortColumns) {
        final colIdx = this.columns.indexOf(col);
        final aVal = a['row'][colIdx];
        final bVal = b['row'][colIdx];

        // Handle null/missing values
        if (aVal == null && bVal == null) continue;
        if (aVal == null) return 1;
        if (bVal == null) return -1;

        // Compare values (ascending order)
        if (aVal is Comparable && bVal is Comparable) {
          final cmp = (aVal).compareTo(bVal);
          if (cmp != 0) return cmp;
        }
      }

      // If all columns are equal, use original index for stability
      if (keep == 'first') {
        return (a['idx'] as int).compareTo(b['idx'] as int);
      } else if (keep == 'last') {
        return (b['idx'] as int).compareTo(a['idx'] as int);
      }
      return 0;
    });

    // Take top n rows
    final resultCount =
        keep == 'all' ? indexedRows.length : min(n, indexedRows.length);
    final resultData = <List<dynamic>>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < resultCount; i++) {
      if (keep != 'all' && i >= n) break;
      final idx = indexedRows[i]['idx'] as int;
      resultData.add(List<dynamic>.from(rows[idx]));
      resultIndex.add(index[idx]);
    }

    return DataFrame.fromRows(
      List.generate(resultData.length, (i) {
        return Map.fromIterables(this.columns, resultData[i]);
      }),
      index: resultIndex,
    );
  }
}

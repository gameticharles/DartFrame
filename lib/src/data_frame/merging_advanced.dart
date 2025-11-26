part of 'data_frame.dart';

/// Extension for advanced DataFrame merging and joining operations
extension DataFrameMergingAdvanced on DataFrame {
  /// Merge with optional filling/interpolation for ordered data.
  ///
  /// This is useful for ordered data like time series.
  ///
  /// Parameters:
  ///   - `right`: DataFrame to merge with
  ///   - `on`: Column name to join on
  ///   - `leftOn`: Column name to join on in left DataFrame
  ///   - `rightOn`: Column name to join on in right DataFrame
  ///   - `leftBy`: Column name to group by in left DataFrame before merging
  ///   - `rightBy`: Column name to group by in right DataFrame before merging
  ///   - `fillMethod`: Method to fill missing values ('ffill' or 'bfill')
  ///   - `suffixes`: Suffixes for overlapping columns
  ///
  /// Returns:
  ///   Merged DataFrame
  ///
  /// Example:
  /// ```dart
  /// var left = DataFrame.fromMap({
  ///   'time': [1, 3, 5],
  ///   'value': [10, 30, 50],
  /// });
  ///
  /// var right = DataFrame.fromMap({
  ///   'time': [2, 4, 6],
  ///   'price': [20, 40, 60],
  /// });
  ///
  /// var merged = left.mergeOrdered(right, on: 'time', fillMethod: 'ffill');
  /// ```
  DataFrame mergeOrdered(
    DataFrame right, {
    String? on,
    String? leftOn,
    String? rightOn,
    String? leftBy,
    String? rightBy,
    String? fillMethod,
    List<String> suffixes = const ['_x', '_y'],
  }) {
    // Determine join keys
    final leftKey = leftOn ?? on;
    final rightKey = rightOn ?? on;

    if (leftKey == null || rightKey == null) {
      throw ArgumentError('Must specify on or both leftOn and rightOn');
    }

    // Perform outer merge
    var result = merge(
      right,
      how: 'outer',
      leftOn: leftKey,
      rightOn: rightKey,
      suffixes: suffixes,
    );

    // Sort by the join key
    var sorted = result.sortValuesEnhanced(by: leftKey);
    if (sorted != null) {
      result = sorted;
    }

    // Apply fill method if specified
    if (fillMethod != null) {
      if (fillMethod == 'ffill') {
        result = result.ffillDataFrame();
      } else if (fillMethod == 'bfill') {
        result = result.bfillDataFrame();
      }
    }

    return result;
  }

  /// Merge multiple DataFrames at once.
  ///
  /// Parameters:
  ///   - `others`: List of DataFrames to join
  ///   - `on`: Column name(s) to join on
  ///   - `how`: Type of join ('inner', 'outer', 'left', 'right')
  ///   - `suffixes`: List of suffixes for each DataFrame
  ///
  /// Returns:
  ///   Joined DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({'key': [1, 2], 'A': [10, 20]});
  /// var df2 = DataFrame.fromMap({'key': [1, 2], 'B': [30, 40]});
  /// var df3 = DataFrame.fromMap({'key': [1, 2], 'C': [50, 60]});
  ///
  /// var joined = df1.joinMultiple([df2, df3], on: 'key');
  /// ```
  DataFrame joinMultiple(
    List<DataFrame> others, {
    required dynamic on,
    String how = 'inner',
    List<String>? suffixes,
  }) {
    if (others.isEmpty) {
      return copy();
    }

    var result = this;

    for (int i = 0; i < others.length; i++) {
      final suffix = suffixes != null && i < suffixes.length
          ? ['', suffixes[i]]
          : ['_${i}', '_${i + 1}'];

      result = result.merge(
        others[i],
        how: how,
        on: on,
        suffixes: suffix,
      );
    }

    return result;
  }

  /// Enhanced join with lsuffix and rsuffix parameters.
  ///
  /// Parameters:
  ///   - `other`: DataFrame to join with
  ///   - `on`: Column name(s) to join on
  ///   - `how`: Type of join
  ///   - `lsuffix`: Suffix for left DataFrame's overlapping columns
  ///   - `rsuffix`: Suffix for right DataFrame's overlapping columns
  ///
  /// Returns:
  ///   Joined DataFrame
  ///
  /// Example:
  /// ```dart
  /// var left = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// var right = DataFrame.fromMap({'A': [1, 2], 'B': [5, 6]});
  ///
  /// var joined = left.joinWithSuffix(
  ///   right,
  ///   on: 'A',
  ///   lsuffix: '_left',
  ///   rsuffix: '_right',
  /// );
  /// ```
  DataFrame joinWithSuffix(
    DataFrame other, {
    dynamic on,
    String how = 'inner',
    String lsuffix = '_left',
    String rsuffix = '_right',
  }) {
    return merge(
      other,
      how: how,
      on: on,
      suffixes: [lsuffix, rsuffix],
    );
  }
}

/// Axis index for N-dimensional arrays
///
/// Provides labeled access to array dimensions, similar to pandas Index.
/// Used by NDArray and DataCube to label axes.
///
/// Example:
/// ```dart
/// var index = AxisIndex(['2024-01-01', '2024-01-02', '2024-01-03']);
/// print(index.getPosition('2024-01-02'));  // 1
/// print(index.getLabel(1));  // '2024-01-02'
/// ```
class AxisIndex {
  /// The labels for this axis
  final List<dynamic> labels;

  /// Map from label to position for fast lookup
  final Map<dynamic, int> _labelToPosition = {};

  /// Name of this axis (optional)
  final String? name;

  /// Create an axis index from labels
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c'], name: 'columns');
  /// ```
  AxisIndex(this.labels, {this.name}) {
    // Build lookup map
    for (int i = 0; i < labels.length; i++) {
      if (_labelToPosition.containsKey(labels[i])) {
        throw ArgumentError('Duplicate label "${labels[i]}" at positions '
            '${_labelToPosition[labels[i]]} and $i');
      }
      _labelToPosition[labels[i]] = i;
    }
  }

  /// Create an integer range index
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex.range(10);  // [0, 1, 2, ..., 9]
  /// ```
  factory AxisIndex.range(int length, {int start = 0, String? name}) {
    return AxisIndex(
      List.generate(length, (i) => start + i),
      name: name,
    );
  }

  /// Create an index from a DateTime range
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex.dateRange(
  ///   start: DateTime(2024, 1, 1),
  ///   end: DateTime(2024, 1, 10),
  ///   name: 'dates',
  /// );
  /// ```
  factory AxisIndex.dateRange({
    required DateTime start,
    required DateTime end,
    Duration step = const Duration(days: 1),
    String? name,
  }) {
    List<DateTime> dates = [];
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(step);
    }
    return AxisIndex(dates, name: name);
  }

  /// Get position (integer index) for a label
  ///
  /// Returns null if label not found.
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c']);
  /// print(index.getPosition('b'));  // 1
  /// print(index.getPosition('d'));  // null
  /// ```
  int? getPosition(dynamic label) => _labelToPosition[label];

  /// Get label at a position
  ///
  /// Throws RangeError if position is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c']);
  /// print(index.getLabel(1));  // 'b'
  /// ```
  dynamic getLabel(int position) {
    if (position < 0 || position >= labels.length) {
      throw RangeError(
          'Position $position out of bounds [0, ${labels.length})');
    }
    return labels[position];
  }

  /// Check if a label exists in this index
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c']);
  /// print(index.contains('b'));  // true
  /// print(index.contains('d'));  // false
  /// ```
  bool contains(dynamic label) => _labelToPosition.containsKey(label);

  /// Get positions for multiple labels
  ///
  /// Returns null for labels not found.
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c']);
  /// var positions = index.getPositions(['b', 'c', 'd']);
  /// // [1, 2, null]
  /// ```
  List<int?> getPositions(List<dynamic> labelList) {
    return labelList.map((label) => getPosition(label)).toList();
  }

  /// Get labels at multiple positions
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c']);
  /// var labels = index.getLabels([1, 2]);
  /// // ['b', 'c']
  /// ```
  List<dynamic> getLabels(List<int> positions) {
    return positions.map((pos) => getLabel(pos)).toList();
  }

  /// Create a new index with a subset of labels
  ///
  /// Example:
  /// ```dart
  /// var index = AxisIndex(['a', 'b', 'c', 'd']);
  /// var subset = index.slice([1, 2]);
  /// // AxisIndex(['b', 'c'])
  /// ```
  AxisIndex slice(List<int> positions) {
    return AxisIndex(
      positions.map((pos) => getLabel(pos)).toList(),
      name: name,
    );
  }

  /// Length of this index
  int get length => labels.length;

  /// Check if index is empty
  bool get isEmpty => labels.isEmpty;

  /// Check if index is not empty
  bool get isNotEmpty => labels.isNotEmpty;

  /// Check if all labels are unique (always true for AxisIndex)
  bool get isUnique => true;

  /// Check if labels are monotonic increasing
  bool get isMonotonicIncreasing {
    if (labels.length <= 1) return true;
    for (int i = 1; i < labels.length; i++) {
      if (labels[i] is! Comparable) return false;
      if ((labels[i] as Comparable).compareTo(labels[i - 1]) <= 0) {
        return false;
      }
    }
    return true;
  }

  /// Check if labels are monotonic decreasing
  bool get isMonotonicDecreasing {
    if (labels.length <= 1) return true;
    for (int i = 1; i < labels.length; i++) {
      if (labels[i] is! Comparable) return false;
      if ((labels[i] as Comparable).compareTo(labels[i - 1]) >= 0) {
        return false;
      }
    }
    return true;
  }

  /// Check if labels are numeric
  bool get isNumeric => labels.every((label) => label is num);

  /// Check if labels are DateTime
  bool get isDateTime => labels.every((label) => label is DateTime);

  /// Get the data type of labels
  Type get dtype {
    if (labels.isEmpty) return dynamic;
    return labels.first.runtimeType;
  }

  /// Convert to list
  List<dynamic> toList() => List.from(labels);

  @override
  String toString() {
    if (name != null) {
      return 'AxisIndex($name: ${labels.take(5).join(', ')}'
          '${labels.length > 5 ? '...' : ''})';
    }
    return 'AxisIndex(${labels.take(5).join(', ')}'
        '${labels.length > 5 ? '...' : ''})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisIndex &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(labels, other.labels);

  @override
  int get hashCode {
    int hash = name.hashCode;
    for (var label in labels) {
      hash ^= label.hashCode;
    }
    return hash;
  }

  bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

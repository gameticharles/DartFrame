part of '../series/series.dart';

/// Extension providing interpolation methods for Series.
///
/// This extension adds various interpolation methods to fill missing values
/// in a Series using different mathematical approaches.
extension SeriesInterpolation on Series {
  /// Interpolates missing values in the Series using the specified method.
  ///
  /// This method fills missing values (null or DataFrame's replaceMissingValueWith)
  /// using various interpolation techniques.
  ///
  /// Parameters:
  ///   - `method`: The interpolation method to use. Options:
  ///     - 'linear': Linear interpolation between adjacent non-missing values
  ///     - 'polynomial': Polynomial interpolation (requires `order` parameter)
  ///     - 'spline': Cubic spline interpolation
  ///   - `limit`: Maximum number of consecutive missing values to interpolate.
  ///     If null, interpolates all missing values.
  ///   - `limitDirection`: Direction to apply the limit:
  ///     - 'forward': Apply limit in forward direction
  ///     - 'backward': Apply limit in backward direction
  ///     - 'both': Apply limit in both directions
  ///   - `order`: Polynomial order for polynomial interpolation (default: 2)
  ///
  /// Returns:
  ///   A new Series with interpolated values. The original Series is unchanged.
  ///
  /// Throws:
  ///   - `ArgumentError` if method is not supported
  ///   - `StateError` if there are insufficient non-missing values for interpolation
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1.0, null, null, 4.0, 5.0, null, 7.0], name: 'data');
  ///
  /// // Linear interpolation
  /// var linear = s.interpolate(method: 'linear');
  /// // Result: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
  ///
  /// // With limit
  /// var limited = s.interpolate(method: 'linear', limit: 1);
  /// // Result: [1.0, 2.0, null, 4.0, 5.0, 6.0, 7.0]
  /// ```
  Series interpolate({
    String method = 'linear',
    int? limit,
    String limitDirection = 'forward',
    int order = 2,
  }) {
    if (!['linear', 'polynomial', 'spline'].contains(method)) {
      throw ArgumentError(
          "method must be one of 'linear', 'polynomial', 'spline'");
    }

    if (!['forward', 'backward', 'both'].contains(limitDirection)) {
      throw ArgumentError(
          "limitDirection must be one of 'forward', 'backward', 'both'");
    }

    if (method == 'polynomial' && order < 1) {
      throw ArgumentError(
          "order must be at least 1 for polynomial interpolation");
    }

    // Check if we have enough non-missing values
    final nonMissingCount = data.where((value) => !_isMissing(value)).length;
    if (nonMissingCount < 2) {
      throw StateError(
          "Need at least 2 non-missing values for interpolation, got $nonMissingCount");
    }

    switch (method) {
      case 'linear':
        return _linearInterpolate(limit: limit, limitDirection: limitDirection);
      case 'polynomial':
        return _polynomialInterpolate(order,
            limit: limit, limitDirection: limitDirection);
      case 'spline':
        return _splineInterpolate(limit: limit, limitDirection: limitDirection);
      default:
        throw ArgumentError("Unsupported interpolation method: $method");
    }
  }

  /// Performs linear interpolation between adjacent non-missing values.
  Series _linearInterpolate({int? limit, String limitDirection = 'forward'}) {
    List<dynamic> newData = List.from(data);

    // Find all missing value positions
    List<int> missingIndices = [];
    for (int i = 0; i < newData.length; i++) {
      if (_isMissing(newData[i])) {
        missingIndices.add(i);
      }
    }

    if (missingIndices.isEmpty) {
      return Series(newData, name: name, index: List.from(index));
    }

    // Apply limit if specified
    List<int> indicesToInterpolate =
        _applyLimit(missingIndices, limit, limitDirection);

    for (int i in indicesToInterpolate) {
      // Find the nearest non-missing values before and after
      int? leftIndex;
      int? rightIndex;

      // Find left boundary
      for (int j = i - 1; j >= 0; j--) {
        if (!_isMissing(newData[j])) {
          leftIndex = j;
          break;
        }
      }

      // Find right boundary
      for (int j = i + 1; j < newData.length; j++) {
        if (!_isMissing(newData[j])) {
          rightIndex = j;
          break;
        }
      }

      // Perform linear interpolation if we have both boundaries
      if (leftIndex != null && rightIndex != null) {
        final leftValue = newData[leftIndex];
        final rightValue = newData[rightIndex];

        // Only interpolate if both values are numeric
        if (leftValue is num && rightValue is num) {
          final distance = rightIndex - leftIndex;
          final position = i - leftIndex;
          final interpolatedValue =
              leftValue + (rightValue - leftValue) * (position / distance);
          newData[i] = interpolatedValue;
        }
      }
    }

    return Series(newData, name: name, index: List.from(index));
  }

  /// Performs polynomial interpolation using Lagrange interpolation.
  Series _polynomialInterpolate(int order,
      {int? limit, String limitDirection = 'forward'}) {
    List<dynamic> newData = List.from(data);

    // Find all missing value positions
    List<int> missingIndices = [];
    for (int i = 0; i < newData.length; i++) {
      if (_isMissing(newData[i])) {
        missingIndices.add(i);
      }
    }

    if (missingIndices.isEmpty) {
      return Series(newData, name: name, index: List.from(index));
    }

    // Get all non-missing numeric points
    List<MapEntry<int, num>> knownPoints = [];
    for (int i = 0; i < newData.length; i++) {
      if (!_isMissing(newData[i]) && newData[i] is num) {
        knownPoints.add(MapEntry(i, newData[i] as num));
      }
    }

    if (knownPoints.length < order + 1) {
      throw StateError(
          "Need at least ${order + 1} non-missing numeric values for polynomial interpolation of order $order");
    }

    // Apply limit if specified
    List<int> indicesToInterpolate =
        _applyLimit(missingIndices, limit, limitDirection);

    for (int i in indicesToInterpolate) {
      // Use the closest `order + 1` points for interpolation
      List<MapEntry<int, num>> nearestPoints =
          _findNearestPoints(knownPoints, i, order + 1);

      if (nearestPoints.length >= order + 1) {
        double interpolatedValue = _lagrangeInterpolation(nearestPoints, i);
        newData[i] = interpolatedValue;
      }
    }

    return Series(newData, name: name, index: List.from(index));
  }

  /// Performs cubic spline interpolation.
  Series _splineInterpolate({int? limit, String limitDirection = 'forward'}) {
    List<dynamic> newData = List.from(data);

    // Find all missing value positions
    List<int> missingIndices = [];
    for (int i = 0; i < newData.length; i++) {
      if (_isMissing(newData[i])) {
        missingIndices.add(i);
      }
    }

    if (missingIndices.isEmpty) {
      return Series(newData, name: name, index: List.from(index));
    }

    // Get all non-missing numeric points
    List<MapEntry<int, num>> knownPoints = [];
    for (int i = 0; i < newData.length; i++) {
      if (!_isMissing(newData[i]) && newData[i] is num) {
        knownPoints.add(MapEntry(i, newData[i] as num));
      }
    }

    if (knownPoints.length < 4) {
      throw StateError(
          "Need at least 4 non-missing numeric values for spline interpolation");
    }

    // Apply limit if specified
    List<int> indicesToInterpolate =
        _applyLimit(missingIndices, limit, limitDirection);

    // Build cubic spline coefficients
    List<double> x = knownPoints.map((p) => p.key.toDouble()).toList();
    List<double> y = knownPoints.map((p) => p.value.toDouble()).toList();

    List<List<double>> splineCoeffs = _buildCubicSpline(x, y);

    for (int i in indicesToInterpolate) {
      double interpolatedValue = _evaluateSpline(splineCoeffs, x, i.toDouble());
      newData[i] = interpolatedValue;
    }

    return Series(newData, name: name, index: List.from(index));
  }

  /// Applies limit constraints to the list of missing indices.
  List<int> _applyLimit(
      List<int> missingIndices, int? limit, String limitDirection) {
    if (limit == null) {
      return missingIndices;
    }

    List<int> result = [];

    if (limitDirection == 'forward' || limitDirection == 'both') {
      int consecutiveCount = 0;
      for (int i = 0; i < missingIndices.length; i++) {
        if (i == 0 || missingIndices[i] == missingIndices[i - 1] + 1) {
          consecutiveCount++;
        } else {
          consecutiveCount = 1;
        }

        if (consecutiveCount <= limit) {
          result.add(missingIndices[i]);
        }
      }
    }

    if (limitDirection == 'backward' || limitDirection == 'both') {
      List<int> backwardResult = [];
      int consecutiveCount = 0;
      for (int i = missingIndices.length - 1; i >= 0; i--) {
        if (i == missingIndices.length - 1 ||
            missingIndices[i] == missingIndices[i + 1] - 1) {
          consecutiveCount++;
        } else {
          consecutiveCount = 1;
        }

        if (consecutiveCount <= limit) {
          backwardResult.add(missingIndices[i]);
        }
      }

      if (limitDirection == 'backward') {
        result = backwardResult;
      } else {
        // For 'both', take intersection
        result = result.where((idx) => backwardResult.contains(idx)).toList();
      }
    }

    return result;
  }

  /// Finds the nearest points to a given index for polynomial interpolation.
  List<MapEntry<int, num>> _findNearestPoints(
      List<MapEntry<int, num>> points, int targetIndex, int count) {
    List<MapEntry<int, num>> sortedByDistance = List.from(points);
    sortedByDistance.sort((a, b) =>
        (a.key - targetIndex).abs().compareTo((b.key - targetIndex).abs()));

    return sortedByDistance.take(count).toList();
  }

  /// Performs Lagrange interpolation.
  double _lagrangeInterpolation(List<MapEntry<int, num>> points, int x) {
    double result = 0.0;

    for (int i = 0; i < points.length; i++) {
      double term = points[i].value.toDouble();

      for (int j = 0; j < points.length; j++) {
        if (i != j) {
          term *= (x - points[j].key) / (points[i].key - points[j].key);
        }
      }

      result += term;
    }

    return result;
  }

  /// Builds cubic spline coefficients using natural spline conditions.
  List<List<double>> _buildCubicSpline(List<double> x, List<double> y) {
    int n = x.length;
    List<double> h = List.filled(n - 1, 0);
    List<double> alpha = List.filled(n - 1, 0);
    List<double> l = List.filled(n, 0);
    List<double> mu = List.filled(n, 0);
    List<double> z = List.filled(n, 0);
    List<double> c = List.filled(n, 0);
    List<double> b = List.filled(n - 1, 0);
    List<double> d = List.filled(n - 1, 0);

    // Calculate h values
    for (int i = 0; i < n - 1; i++) {
      h[i] = x[i + 1] - x[i];
    }

    // Calculate alpha values
    for (int i = 1; i < n - 1; i++) {
      alpha[i] =
          (3 / h[i]) * (y[i + 1] - y[i]) - (3 / h[i - 1]) * (y[i] - y[i - 1]);
    }

    // Solve tridiagonal system
    l[0] = 1;
    mu[0] = 0;
    z[0] = 0;

    for (int i = 1; i < n - 1; i++) {
      l[i] = 2 * (x[i + 1] - x[i - 1]) - h[i - 1] * mu[i - 1];
      mu[i] = h[i] / l[i];
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }

    l[n - 1] = 1;
    z[n - 1] = 0;
    c[n - 1] = 0;

    // Back substitution
    for (int j = n - 2; j >= 0; j--) {
      c[j] = z[j] - mu[j] * c[j + 1];
      b[j] = (y[j + 1] - y[j]) / h[j] - h[j] * (c[j + 1] + 2 * c[j]) / 3;
      d[j] = (c[j + 1] - c[j]) / (3 * h[j]);
    }

    // Return coefficients as [a, b, c, d] for each segment
    List<List<double>> coefficients = [];
    for (int i = 0; i < n - 1; i++) {
      coefficients.add([y[i], b[i], c[i], d[i]]);
    }

    return coefficients;
  }

  /// Evaluates the cubic spline at a given point.
  double _evaluateSpline(
      List<List<double>> coeffs, List<double> x, double targetX) {
    // Find the appropriate segment
    int segment = 0;
    for (int i = 0; i < x.length - 1; i++) {
      if (targetX >= x[i] && targetX <= x[i + 1]) {
        segment = i;
        break;
      }
    }

    // Evaluate the cubic polynomial for this segment
    double dx = targetX - x[segment];
    List<double> coeff = coeffs[segment];

    return coeff[0] +
        coeff[1] * dx +
        coeff[2] * dx * dx +
        coeff[3] * dx * dx * dx;
  }
}

/// Extension providing missing data analysis tools for Series.
///
/// This extension adds methods for analyzing missing data patterns and
/// providing insights into data completeness in Series objects.
extension SeriesMissingDataAnalysis on Series {
  /// Returns the count of missing values in the Series.
  ///
  /// Returns:
  ///   The number of missing values (null or DataFrame's replaceMissingValueWith).
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, 3, null, 5], name: 'data');
  /// print(s.missingCount()); // Output: 2
  /// ```
  int missingCount() {
    return data.where((value) => _isMissing(value)).length;
  }

  /// Returns the percentage of missing values in the Series.
  ///
  /// Returns:
  ///   The percentage of missing values as a double (0.0 to 100.0).
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, 3, null, 5], name: 'data');
  /// print(s.missingPercentage()); // Output: 40.0
  /// ```
  double missingPercentage() {
    if (data.isEmpty) return 0.0;
    return (missingCount() / data.length) * 100.0;
  }

  /// Returns the completeness ratio of the Series.
  ///
  /// Returns:
  ///   The ratio of non-missing values (0.0 to 1.0).
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, 3, null, 5], name: 'data');
  /// print(s.completeness()); // Output: 0.6
  /// ```
  double completeness() {
    if (data.isEmpty) return 0.0;
    return 1.0 - (missingCount() / data.length);
  }

  /// Identifies consecutive missing value segments in the Series.
  ///
  /// Returns:
  ///   A list of Maps, each containing 'start', 'end', and 'length' of consecutive missing segments.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, null, 4, null, 6], name: 'data');
  /// var segments = s.missingSegments();
  /// // Output: [{'start': 1, 'end': 2, 'length': 2}, {'start': 4, 'end': 4, 'length': 1}]
  /// ```
  List<Map<String, int>> missingSegments() {
    List<Map<String, int>> segments = [];
    int? segmentStart;

    for (int i = 0; i < data.length; i++) {
      if (_isMissing(data[i])) {
        segmentStart ??= i;
      } else {
        if (segmentStart != null) {
          segments.add({
            'start': segmentStart,
            'end': i - 1,
            'length': i - segmentStart,
          });
          segmentStart = null;
        }
      }
    }

    // Handle case where series ends with missing values
    if (segmentStart != null) {
      segments.add({
        'start': segmentStart,
        'end': data.length - 1,
        'length': data.length - segmentStart,
      });
    }

    return segments;
  }

  /// Returns the longest consecutive missing value segment length.
  ///
  /// Returns:
  ///   The length of the longest consecutive missing value segment.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, null, null, 5, null], name: 'data');
  /// print(s.longestMissingSegment()); // Output: 3
  /// ```
  int longestMissingSegment() {
    List<Map<String, int>> segments = missingSegments();
    if (segments.isEmpty) return 0;

    return segments
        .map((segment) => segment['length']!)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Checks if the Series has any missing values.
  ///
  /// Returns:
  ///   True if the Series contains any missing values, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3], name: 'complete');
  /// var s2 = Series([1, null, 3], name: 'incomplete');
  /// print(s1.hasMissingValues()); // Output: false
  /// print(s2.hasMissingValues()); // Output: true
  /// ```
  bool hasMissingValues() {
    return data.any((value) => _isMissing(value));
  }

  /// Returns indices of all missing values in the Series.
  ///
  /// Returns:
  ///   A list of indices where missing values are located.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, 3, null, 5], name: 'data');
  /// print(s.missingValueIndices()); // Output: [1, 3]
  /// ```
  List<int> missingValueIndices() {
    List<int> indices = [];
    for (int i = 0; i < data.length; i++) {
      if (_isMissing(data[i])) {
        indices.add(i);
      }
    }
    return indices;
  }

  /// Returns a comprehensive summary of missing data in the Series.
  ///
  /// Returns:
  ///   A Map containing various missing data statistics and patterns.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, null, 4, null, 6], name: 'data');
  /// var summary = s.missingDataSummary();
  /// // Returns comprehensive missing data analysis
  /// ```
  Map<String, dynamic> missingDataSummary() {
    List<Map<String, int>> segments = missingSegments();

    return {
      'total_count': data.length,
      'missing_count': missingCount(),
      'non_missing_count': data.length - missingCount(),
      'missing_percentage': missingPercentage(),
      'completeness': completeness(),
      'has_missing_values': hasMissingValues(),
      'missing_indices': missingValueIndices(),
      'missing_segments': segments,
      'number_of_segments': segments.length,
      'longest_segment_length': longestMissingSegment(),
      'average_segment_length': segments.isEmpty
          ? 0.0
          : segments.map((s) => s['length']!).reduce((a, b) => a + b) /
              segments.length,
    };
  }
}

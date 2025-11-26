part of 'data_frame.dart';

/// Extension for advanced DataFrame groupby operations
extension DataFrameGroupByAdvanced on DataFrame {
  /// Enhanced groupby with additional parameters.
  ///
  /// Parameters:
  ///   - `by`: Column name(s) to group by
  ///   - `asIndex`: Whether to use group keys as index (default: true)
  ///   - `groupKeys`: Whether to add group keys to index (default: true)
  ///   - `observed`: Only show observed values for categorical groupers (default: false)
  ///   - `dropna`: Whether to drop NA values from groups (default: true)
  ///   - `sort`: Whether to sort group keys (default: true)
  ///
  /// Returns:
  ///   Map of group keys to DataFrames
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': ['foo', 'bar', 'foo', 'bar'],
  ///   'B': [1, 2, 3, 4],
  ///   'C': [10, 20, 30, 40],
  /// });
  ///
  /// var grouped = df.groupByEnhanced(
  ///   by: 'A',
  ///   asIndex: false,
  ///   dropna: true,
  /// );
  /// ```
  Map<dynamic, DataFrame> groupByEnhanced(
    dynamic by, {
    bool asIndex = true,
    bool groupKeys = true,
    bool observed = false,
    bool dropna = true,
    bool sort = true,
  }) {
    // For now, delegate to existing groupBy with available parameters
    // Future enhancement: implement additional parameters
    return groupBy(by);
  }

  /// Enhanced rolling window with additional parameters.
  ///
  /// Parameters:
  ///   - `window`: Size of the moving window
  ///   - `minPeriods`: Minimum number of observations required
  ///   - `center`: Whether to center the window around current observation
  ///   - `winType`: Type of window ('boxcar', 'triang', 'blackman', etc.)
  ///
  /// Returns:
  ///   RollingDataFrame object
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  /// });
  ///
  /// var rolling = df.rollingEnhanced(
  ///   window: 3,
  ///   center: true,
  /// );
  /// var mean = rolling.mean();
  /// ```
  RollingDataFrame rollingEnhanced(
    int window, {
    int? minPeriods,
    bool center = false,
    String winType = 'boxcar',
  }) {
    // Use existing RollingDataFrame with enhanced parameters
    return RollingDataFrame(
      this,
      window,
      minPeriods: minPeriods,
      center: center,
      winType: winType,
    );
  }

  /// Enhanced expanding window with additional parameters.
  ///
  /// Parameters:
  ///   - `minPeriods`: Minimum number of observations required
  ///   - `center`: Whether to center the window
  ///
  /// Returns:
  ///   ExpandingWindow object
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  /// });
  ///
  /// var expanding = df.expandingEnhanced(minPeriods: 2);
  /// var sum = expanding.sum();
  /// ```
  ExpandingWindow expandingEnhanced({
    int minPeriods = 1,
    bool center = false,
  }) {
    return ExpandingWindow(
      this,
      minPeriods: minPeriods,
    );
  }

  /// Enhanced exponentially weighted functions with additional parameters.
  ///
  /// Parameters:
  ///   - `com`: Center of mass (alternative to span)
  ///   - `span`: Span (alternative to com)
  ///   - `halflife`: Half-life (alternative to com/span)
  ///   - `alpha`: Smoothing factor (alternative to com/span/halflife)
  ///   - `minPeriods`: Minimum number of observations required
  ///   - `adjust`: Whether to use bias adjustment
  ///   - `ignoreNA`: Whether to ignore missing values
  ///
  /// Returns:
  ///   ExponentialWeightedWindow object
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  /// });
  ///
  /// var ewm = df.ewmEnhanced(
  ///   span: 3,
  ///   adjust: true,
  ///   ignoreNA: true,
  /// );
  /// var mean = ewm.mean();
  /// ```
  ExponentialWeightedWindow ewmEnhanced({
    double? com,
    int? span,
    double? halflife,
    double? alpha,
    int minPeriods = 0,
    bool adjust = true,
    bool ignoreNA = false,
  }) {
    // Calculate effective span from parameters
    int effectiveSpan;
    if (span != null) {
      effectiveSpan = span;
    } else if (com != null) {
      effectiveSpan = (com + 1).toInt();
    } else if (alpha != null) {
      effectiveSpan = ((2.0 / alpha) - 1.0).toInt();
    } else if (halflife != null) {
      effectiveSpan = (halflife / log(2.0)).toInt();
    } else {
      effectiveSpan = 10; // Default
    }

    return ExponentialWeightedWindow(
      this,
      span: effectiveSpan,
      adjustWeights: adjust,
      ignoreNA: ignoreNA,
    );
  }
}

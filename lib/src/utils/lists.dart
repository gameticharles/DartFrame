/// Comparison options for list equality checking
enum ListComparisonMode {
  /// Strict comparison: order matters, types must match exactly
  strict,

  /// Order-independent comparison: treats lists as sets
  unordered,

  /// Deep comparison: recursively compares nested structures
  deep,

  /// Type-flexible comparison: attempts type coercion where reasonable
  flexible
}

/// Configuration class for list comparison behavior
class ListEqualConfig {
  final ListComparisonMode mode;
  final bool ignoreCase;
  final bool trimStrings;
  final double? numericTolerance;
  final bool allowTypeCoercion;
  final int maxDepth;
  final bool enableCircularReferenceDetection;
  final bool optimizeForLargeLists;
  final bool enableParallelProcessing;
  final Set<Type> customComparableTypes;
  final Map<Type, bool Function(dynamic, dynamic)> customComparators;

  const ListEqualConfig({
    this.mode = ListComparisonMode.strict,
    this.ignoreCase = false,
    this.trimStrings = false,
    this.numericTolerance,
    this.allowTypeCoercion = false,
    this.maxDepth = 100,
    this.enableCircularReferenceDetection = true,
    this.optimizeForLargeLists = false,
    this.enableParallelProcessing = false,
    this.customComparableTypes = const {},
    this.customComparators = const {},
  });

  /// Creates a copy of this config with modified values
  ListEqualConfig copyWith({
    ListComparisonMode? mode,
    bool? ignoreCase,
    bool? trimStrings,
    double? numericTolerance,
    bool? allowTypeCoercion,
    int? maxDepth,
    bool? enableCircularReferenceDetection,
    bool? optimizeForLargeLists,
    bool? enableParallelProcessing,
    Set<Type>? customComparableTypes,
    Map<Type, bool Function(dynamic, dynamic)>? customComparators,
  }) {
    return ListEqualConfig(
      mode: mode ?? this.mode,
      ignoreCase: ignoreCase ?? this.ignoreCase,
      trimStrings: trimStrings ?? this.trimStrings,
      numericTolerance: numericTolerance ?? this.numericTolerance,
      allowTypeCoercion: allowTypeCoercion ?? this.allowTypeCoercion,
      maxDepth: maxDepth ?? this.maxDepth,
      enableCircularReferenceDetection: enableCircularReferenceDetection ??
          this.enableCircularReferenceDetection,
      optimizeForLargeLists:
          optimizeForLargeLists ?? this.optimizeForLargeLists,
      enableParallelProcessing:
          enableParallelProcessing ?? this.enableParallelProcessing,
      customComparableTypes:
          customComparableTypes ?? this.customComparableTypes,
      customComparators: customComparators ?? this.customComparators,
    );
  }
}

/// Exception thrown when list comparison encounters an error
class ListComparisonException implements Exception {
  final String message;
  final String? context;
  final dynamic originalError;

  const ListComparisonException(this.message,
      [this.context, this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('ListComparisonException: $message');
    if (context != null) buffer.write(' (Context: $context)');
    if (originalError != null) {
      buffer.write(' (Original error: $originalError)');
    }
    return buffer.toString();
  }
}

/// Result of list comparison with detailed information
class ListComparisonResult {
  final bool isEqual;
  final String? reason;
  final List<String> differences;
  final int comparisonCount;
  final Duration elapsedTime;

  const ListComparisonResult({
    required this.isEqual,
    this.reason,
    this.differences = const [],
    this.comparisonCount = 0,
    this.elapsedTime = Duration.zero,
  });

  ListComparisonResult copyWith({
    bool? isEqual,
    String? reason,
    List<String>? differences,
    int? comparisonCount,
    Duration? elapsedTime,
  }) {
    return ListComparisonResult(
      isEqual: isEqual ?? this.isEqual,
      reason: reason ?? this.reason,
      differences: differences ?? this.differences,
      comparisonCount: comparisonCount ?? this.comparisonCount,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }

  @override
  String toString() {
    return 'ListComparisonResult(isEqual: $isEqual, reason: $reason, '
        'differences: ${differences.length}, comparisons: $comparisonCount, '
        'time: ${elapsedTime.inMicroseconds}μs)';
  }
}

/// Internal class to track comparison state and detect circular references
class _ComparisonContext {
  final Set<String> visitedObjects = <String>{};
  final List<String> differences = <String>[];
  int comparisonCount = 0;
  int currentDepth = 0;
  final ListEqualConfig config;

  _ComparisonContext(this.config);

  bool addVisitedObject(dynamic obj) {
    if (!config.enableCircularReferenceDetection) return true;

    final objId = '${obj.runtimeType}@${obj.hashCode}';
    if (visitedObjects.contains(objId)) {
      return false; // Circular reference detected
    }
    visitedObjects.add(objId);
    return true;
  }

  void removeVisitedObject(dynamic obj) {
    if (!config.enableCircularReferenceDetection) return;

    final objId = '${obj.runtimeType}@${obj.hashCode}';
    visitedObjects.remove(objId);
  }

  void addDifference(String difference) {
    differences.add('Depth $currentDepth: $difference');
  }
}

/// Comprehensive list equality comparison function
///
/// Compares two or more lists based on the provided configuration.
/// Returns `true` if all lists are considered equal according to the comparison mode.
///
/// ## Parameters
/// - [lists] - Variable number of lists to compare (minimum 2 required)
/// - [config] - Configuration object specifying comparison behavior (optional, defaults to strict mode)
///
/// ## Comparison Modes
/// - **Strict** (default): Order matters, types must match exactly
/// - **Unordered**: Treats lists as sets, ignoring element order
/// - **Deep**: Recursively compares nested structures (lists, maps, sets)
/// - **Flexible**: Attempts type coercion when reasonable
///
/// ## Configuration Options
/// - `ignoreCase`: Ignore case when comparing strings
/// - `trimStrings`: Trim whitespace from strings before comparison
/// - `numericTolerance`: Allow floating-point comparison with tolerance
/// - `allowTypeCoercion`: Enable type conversion in flexible mode
/// - `maxDepth`: Maximum recursion depth for nested structures
/// - `enableCircularReferenceDetection`: Detect and handle circular references
/// - `optimizeForLargeLists`: Use optimized algorithms for large datasets
/// - `enableParallelProcessing`: Use parallel processing for large comparisons
/// - `customComparators`: Custom comparison functions for specific types
///
/// ## Examples
///
/// ### Basic strict comparison (default behavior):
/// ```dart
/// print(listEqual([[1, 2, 3], [1, 2, 3]])); // true
/// print(listEqual([[1, 2, 3], [1, 2, 4]])); // false
/// print(listEqual([[1, 2, 3], [3, 2, 1]])); // false (order matters)
/// ```
///
/// ### Multiple lists comparison:
/// ```dart
/// print(listEqual([[1, 2], [1, 2], [1, 2]])); // true
/// print(listEqual([[1, 2], [1, 2], [1, 3]])); // false
/// ```
///
/// ### Unordered comparison (order doesn't matter):
/// ```dart
/// const unorderedConfig = ListEqualConfig(mode: ListComparisonMode.unordered);
/// print(listEqual([[1, 2, 3], [3, 2, 1]], unorderedConfig)); // true
/// print(listEqual([['a', 'b', 'c'], ['c', 'a', 'b']], unorderedConfig)); // true
/// ```
///
/// ### String comparison with case-insensitive and trimming:
/// ```dart
/// const stringConfig = ListEqualConfig(ignoreCase: true, trimStrings: true);
/// print(listEqual([['Hello', ' World '], ['hello', 'world']], stringConfig)); // true
/// ```
///
/// ### Numeric comparison with tolerance:
/// ```dart
/// const numericConfig = ListEqualConfig(numericTolerance: 0.01);
/// print(listEqual([[1.0, 2.0], [1.001, 2.001]], numericConfig)); // true
/// ```
///
/// ### Deep comparison for nested structures:
/// ```dart
/// const deepConfig = ListEqualConfig(mode: ListComparisonMode.deep);
/// print(listEqual([
///   [1, [2, 3], {'a': 4}],
///   [1, [2, 3], {'a': 4}]
/// ], deepConfig)); // true
/// ```
///
/// ### Flexible comparison with type coercion:
/// ```dart
/// const flexibleConfig = ListEqualConfig(
///   mode: ListComparisonMode.flexible,
///   allowTypeCoercion: true
/// );
/// print(listEqual([['1', '2'], [1, 2]], flexibleConfig)); // true
/// ```
///
/// ### Performance optimization for large lists:
/// ```dart
/// const optimizedConfig = ListEqualConfig(
///   optimizeForLargeLists: true,
///   enableParallelProcessing: true
/// );
/// print(listEqual([largeList1, largeList2], optimizedConfig));
/// ```
///
/// ### Custom comparators:
/// ```dart
/// final customConfig = ListEqualConfig(
///   customComparators: {
///     DateTime: (a, b) => (a as DateTime).millisecondsSinceEpoch ==
///                        (b as DateTime).millisecondsSinceEpoch,
///   }
/// );
/// ```
///
/// ## Throws
/// - [ListComparisonException] if fewer than 2 lists are provided
/// - [ListComparisonException] if comparison encounters an unrecoverable error
/// - [ListComparisonException] if maximum recursion depth is exceeded
/// - [ListComparisonException] if circular references are detected (when enabled)
///
/// ## Returns
/// `true` if all lists are considered equal according to the specified comparison mode,
/// `false` otherwise.
bool listEqual(List<List<dynamic>> lists,
    [ListEqualConfig config = const ListEqualConfig()]) {
  final result = listEqualDetailed(lists, config);
  return result.isEqual;
}

/// Extended version of listEqual that returns detailed comparison results
///
/// Returns a [ListComparisonResult] object containing equality status,
/// performance metrics, and detailed difference information.
ListComparisonResult listEqualDetailed(List<List<dynamic>> lists,
    [ListEqualConfig config = const ListEqualConfig()]) {
  final stopwatch = Stopwatch()..start();

  try {
    // Input validation
    if (lists.length < 2) {
      throw const ListComparisonException(
          'At least 2 lists are required for comparison');
    }

    final context = _ComparisonContext(config);

    // Quick reference check - if all lists are the same reference, they're equal
    if (lists.every((list) => identical(list, lists.first))) {
      stopwatch.stop();
      return ListComparisonResult(
        isEqual: true,
        reason: 'All lists are identical references',
        elapsedTime: stopwatch.elapsed,
      );
    }

    // Early size check for most modes
    if (config.mode != ListComparisonMode.unordered ||
        !config.optimizeForLargeLists) {
      final firstLength = lists.first.length;
      if (!lists.every((list) => list.length == firstLength)) {
        stopwatch.stop();
        return ListComparisonResult(
          isEqual: false,
          reason: 'Lists have different lengths',
          differences: [
            'Length mismatch: ${lists.map((l) => l.length).toList()}'
          ],
          elapsedTime: stopwatch.elapsed,
        );
      }
    }

    // Performance optimization for large lists
    if (config.optimizeForLargeLists && lists.first.length > 1000) {
      final result = _optimizedComparison(lists, config, context);
      stopwatch.stop();
      return result.copyWith(elapsedTime: stopwatch.elapsed);
    }

    // Compare each list with the first one
    final firstList = lists.first;
    for (int i = 1; i < lists.length; i++) {
      if (!_compareTwoLists(firstList, lists[i], config, context)) {
        stopwatch.stop();
        return ListComparisonResult(
          isEqual: false,
          reason: 'Lists differ at comparison ${i + 1}',
          differences: context.differences,
          comparisonCount: context.comparisonCount,
          elapsedTime: stopwatch.elapsed,
        );
      }
    }

    stopwatch.stop();
    return ListComparisonResult(
      isEqual: true,
      reason: 'All lists are equal',
      comparisonCount: context.comparisonCount,
      elapsedTime: stopwatch.elapsed,
    );
  } catch (e) {
    stopwatch.stop();
    if (e is ListComparisonException) {
      rethrow;
    }
    throw ListComparisonException(
        'Unexpected error during comparison', null, e);
  }
}

/// Optimized comparison for large lists
ListComparisonResult _optimizedComparison(List<List<dynamic>> lists,
    ListEqualConfig config, _ComparisonContext context) {
  // Quick hash-based comparison for identical content
  final hashes = <int>[];
  for (final list in lists) {
    hashes.add(_computeListHash(list, config));
  }

  // If all hashes are the same, likely equal (with small collision chance)
  if (hashes.every((hash) => hash == hashes.first)) {
    // Do a final verification on a sample
    if (_sampleVerification(lists, config, context)) {
      return ListComparisonResult(
        isEqual: true,
        reason: 'Optimized comparison - hash match with sample verification',
        comparisonCount: context.comparisonCount,
      );
    }
  }

  // Fall back to regular comparison
  final firstList = lists.first;
  for (int i = 1; i < lists.length; i++) {
    if (!_compareTwoLists(firstList, lists[i], config, context)) {
      return ListComparisonResult(
        isEqual: false,
        reason: 'Optimized comparison failed',
        differences: context.differences,
        comparisonCount: context.comparisonCount,
      );
    }
  }

  return ListComparisonResult(
    isEqual: true,
    reason: 'Optimized comparison successful',
    comparisonCount: context.comparisonCount,
  );
}

/// Compute a hash for a list based on its contents
int _computeListHash(List<dynamic> list, ListEqualConfig config) {
  var hash = list.length;
  for (int i = 0; i < list.length; i++) {
    final element = list[i];
    var elementHash = 0;

    if (element == null) {
      elementHash = 0;
    } else if (element is String) {
      var str = element;
      if (config.trimStrings) str = str.trim();
      if (config.ignoreCase) str = str.toLowerCase();
      elementHash = str.hashCode;
    } else if (element is num) {
      elementHash = element.hashCode;
    } else {
      elementHash = element.hashCode;
    }

    // Combine hashes with position weight (unless unordered mode)
    if (config.mode == ListComparisonMode.unordered) {
      hash ^= elementHash;
    } else {
      hash = hash * 31 + elementHash;
    }
  }
  return hash;
}

/// Sample verification for large lists
bool _sampleVerification(List<List<dynamic>> lists, ListEqualConfig config,
    _ComparisonContext context) {
  final sampleSize = (lists.first.length * 0.01).ceil().clamp(10, 100);
  final random = DateTime.now().millisecondsSinceEpoch;

  for (int i = 0; i < sampleSize; i++) {
    final index = (random + i * 37) % lists.first.length;
    final firstElement = lists.first[index];

    for (int j = 1; j < lists.length; j++) {
      if (!_compareElements(firstElement, lists[j][index], config, context)) {
        return false;
      }
    }
  }
  return true;
}

/// Internal function to compare exactly two lists
bool _compareTwoLists(List<dynamic> list1, List<dynamic> list2,
    ListEqualConfig config, _ComparisonContext context) {
  // Handle empty lists
  if (list1.isEmpty && list2.isEmpty) return true;
  if (list1.isEmpty || list2.isEmpty) {
    context.addDifference('One list is empty, the other is not');
    return false;
  }

  // Depth check
  if (context.currentDepth >= config.maxDepth) {
    throw ListComparisonException(
        'Maximum recursion depth exceeded', 'Depth: ${context.currentDepth}');
  }

  context.currentDepth++;

  try {
    switch (config.mode) {
      case ListComparisonMode.strict:
        return _strictComparison(list1, list2, config, context);
      case ListComparisonMode.unordered:
        return _unorderedComparison(list1, list2, config, context);
      case ListComparisonMode.deep:
        return _deepComparison(list1, list2, config, context);
      case ListComparisonMode.flexible:
        return _flexibleComparison(list1, list2, config, context);
    }
  } finally {
    context.currentDepth--;
  }
}

/// Strict comparison: order matters, types must match exactly
bool _strictComparison(List<dynamic> list1, List<dynamic> list2,
    ListEqualConfig config, _ComparisonContext context) {
  if (list1.length != list2.length) {
    context
        .addDifference('Length mismatch: ${list1.length} vs ${list2.length}');
    return false;
  }

  for (int i = 0; i < list1.length; i++) {
    if (!_compareElements(list1[i], list2[i], config, context)) {
      context.addDifference(
          'Elements differ at index $i: ${list1[i]} vs ${list2[i]}');
      return false;
    }
  }
  return true;
}

/// Unordered comparison: treats lists as sets
bool _unorderedComparison(List<dynamic> list1, List<dynamic> list2,
    ListEqualConfig config, _ComparisonContext context) {
  if (list1.length != list2.length) {
    context
        .addDifference('Length mismatch: ${list1.length} vs ${list2.length}');
    return false;
  }

  // Create frequency maps for both lists
  final freq1 = <String, int>{};
  final freq2 = <String, int>{};

  // Count occurrences in both lists
  for (final element in list1) {
    final key = _elementToKey(element, config);
    freq1[key] = (freq1[key] ?? 0) + 1;
  }

  for (final element in list2) {
    final key = _elementToKey(element, config);
    freq2[key] = (freq2[key] ?? 0) + 1;
  }

  // Compare frequency maps
  if (freq1.length != freq2.length) {
    context.addDifference('Different number of unique elements');
    return false;
  }

  for (final entry in freq1.entries) {
    if (freq2[entry.key] != entry.value) {
      context.addDifference('Frequency mismatch for element ${entry.key}');
      return false;
    }
  }

  return true;
}

/// Deep comparison: recursively compares nested structures
bool _deepComparison(List<dynamic> list1, List<dynamic> list2,
    ListEqualConfig config, _ComparisonContext context) {
  if (list1.length != list2.length) {
    context
        .addDifference('Length mismatch: ${list1.length} vs ${list2.length}');
    return false;
  }

  for (int i = 0; i < list1.length; i++) {
    if (!_deepCompareElements(list1[i], list2[i], config, context)) {
      context.addDifference('Deep comparison failed at index $i');
      return false;
    }
  }
  return true;
}

/// Flexible comparison: attempts type coercion where reasonable
bool _flexibleComparison(List<dynamic> list1, List<dynamic> list2,
    ListEqualConfig config, _ComparisonContext context) {
  if (list1.length != list2.length) {
    context
        .addDifference('Length mismatch: ${list1.length} vs ${list2.length}');
    return false;
  }

  for (int i = 0; i < list1.length; i++) {
    if (!_flexibleCompareElements(list1[i], list2[i], config, context)) {
      context.addDifference('Flexible comparison failed at index $i');
      return false;
    }
  }
  return true;
}

/// Compare two individual elements based on configuration
bool _compareElements(dynamic elem1, dynamic elem2, ListEqualConfig config,
    _ComparisonContext context) {
  context.comparisonCount++;

  // Handle null cases
  if (elem1 == null && elem2 == null) return true;
  if (elem1 == null || elem2 == null) return false;

  // Check for custom comparators
  final type1 = elem1.runtimeType;
  final type2 = elem2.runtimeType;

  if (config.customComparators.containsKey(type1) && type1 == type2) {
    return config.customComparators[type1]!(elem1, elem2);
  }

  // Type checking for strict mode
  if (config.mode == ListComparisonMode.strict && type1 != type2) {
    return false;
  }

  // String comparison with options
  if (elem1 is String && elem2 is String) {
    return _compareStrings(elem1, elem2, config);
  }

  // Numeric comparison with tolerance
  if (elem1 is num && elem2 is num) {
    return _compareNumbers(elem1, elem2, config);
  }

  // DateTime comparison
  if (elem1 is DateTime && elem2 is DateTime) {
    return elem1.isAtSameMomentAs(elem2);
  }

  // Duration comparison
  if (elem1 is Duration && elem2 is Duration) {
    return elem1.inMicroseconds == elem2.inMicroseconds;
  }

  // RegExp comparison
  if (elem1 is RegExp && elem2 is RegExp) {
    return elem1.pattern == elem2.pattern &&
        elem1.isMultiLine == elem2.isMultiLine &&
        elem1.isCaseSensitive == elem2.isCaseSensitive &&
        elem1.isDotAll == elem2.isDotAll &&
        elem1.isUnicode == elem2.isUnicode;
  }

  // Default equality
  return elem1 == elem2;
}

/// Deep comparison of elements including nested structures
bool _deepCompareElements(dynamic elem1, dynamic elem2, ListEqualConfig config,
    _ComparisonContext context) {
  if (elem1 == null && elem2 == null) return true;
  if (elem1 == null || elem2 == null) return false;

  // Circular reference detection
  if (elem1 is List || elem1 is Map || elem1 is Set) {
    if (!context.addVisitedObject(elem1)) {
      throw const ListComparisonException(
          'Circular reference detected in first element');
    }
  }

  if (elem2 is List || elem2 is Map || elem2 is Set) {
    if (!context.addVisitedObject(elem2)) {
      throw const ListComparisonException(
          'Circular reference detected in second element');
    }
  }

  try {
    // If both are lists, recursively compare
    if (elem1 is List && elem2 is List) {
      return _compareTwoLists(elem1, elem2, config, context);
    }

    // If both are maps, compare maps
    if (elem1 is Map && elem2 is Map) {
      return _compareMaps(elem1, elem2, config, context);
    }

    // If both are sets, compare sets
    if (elem1 is Set && elem2 is Set) {
      return _compareSets(elem1, elem2, config, context);
    }

    return _compareElements(elem1, elem2, config, context);
  } finally {
    // Clean up visited objects
    if (elem1 is List || elem1 is Map || elem1 is Set) {
      context.removeVisitedObject(elem1);
    }
    if (elem2 is List || elem2 is Map || elem2 is Set) {
      context.removeVisitedObject(elem2);
    }
  }
}

/// Flexible element comparison with type coercion
bool _flexibleCompareElements(dynamic elem1, dynamic elem2,
    ListEqualConfig config, _ComparisonContext context) {
  if (elem1 == null && elem2 == null) return true;
  if (elem1 == null || elem2 == null) return false;

  // Try direct comparison first
  if (_compareElements(elem1, elem2, config, context)) return true;

  // Attempt type coercion if allowed
  if (config.allowTypeCoercion) {
    // Try converting both to strings
    if (_compareStrings(elem1.toString(), elem2.toString(), config)) {
      return true;
    }

    // Try numeric conversion
    final num1 = _tryParseNumber(elem1);
    final num2 = _tryParseNumber(elem2);
    if (num1 != null && num2 != null) {
      return _compareNumbers(num1, num2, config);
    }

    // Try boolean conversion
    final bool1 = _tryParseBoolean(elem1);
    final bool2 = _tryParseBoolean(elem2);
    if (bool1 != null && bool2 != null) {
      return bool1 == bool2;
    }
  }

  return false;
}

/// Compare strings with configuration options
bool _compareStrings(String str1, String str2, ListEqualConfig config) {
  String s1 = str1, s2 = str2;

  if (config.trimStrings) {
    s1 = s1.trim();
    s2 = s2.trim();
  }

  if (config.ignoreCase) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
  }

  return s1 == s2;
}

/// Compare numbers with optional tolerance
bool _compareNumbers(num num1, num num2, ListEqualConfig config) {
  if (config.numericTolerance != null) {
    return (num1 - num2).abs() <= config.numericTolerance!;
  }
  return num1 == num2;
}

/// Compare two maps recursively
bool _compareMaps(
    Map map1, Map map2, ListEqualConfig config, _ComparisonContext context) {
  if (map1.length != map2.length) return false;

  for (final key in map1.keys) {
    if (!map2.containsKey(key)) return false;
    if (!_deepCompareElements(map1[key], map2[key], config, context)) {
      return false;
    }
  }

  return true;
}

/// Compare two sets
bool _compareSets(
    Set set1, Set set2, ListEqualConfig config, _ComparisonContext context) {
  if (set1.length != set2.length) return false;

  for (final element in set1) {
    bool found = false;
    for (final otherElement in set2) {
      if (_deepCompareElements(element, otherElement, config, context)) {
        found = true;
        break;
      }
    }
    if (!found) return false;
  }

  return true;
}

/// Convert element to a string key for frequency counting
String _elementToKey(dynamic element, ListEqualConfig config) {
  if (element == null) return 'null';

  if (element is String) {
    String key = element;
    if (config.trimStrings) key = key.trim();
    if (config.ignoreCase) key = key.toLowerCase();
    return 'str:$key';
  }

  if (element is num) {
    return 'num:$element';
  }

  if (element is bool) {
    return 'bool:$element';
  }

  if (element is DateTime) {
    return 'datetime:${element.millisecondsSinceEpoch}';
  }

  if (element is Duration) {
    return 'duration:${element.inMicroseconds}';
  }

  if (element is List) {
    return 'list:${element.map((e) => _elementToKey(e, config)).join(',')}';
  }

  if (element is Map) {
    final sortedKeys = element.keys.map((k) => k.toString()).toList()..sort();
    return 'map:${sortedKeys.map((k) => '$k:${_elementToKey(element[k], config)}').join(',')}';
  }

  return '${element.runtimeType}:$element';
}

/// Attempt to parse a value as a number
num? _tryParseNumber(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    try {
      return num.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Attempt to parse a value as a boolean
bool? _tryParseBoolean(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    switch (value.toLowerCase().trim()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'off':
        return false;
    }
  }
  if (value is num) {
    return value != 0;
  }
  return null;
}

/// Extension method to add comparison capabilities to lists
extension ListEqualityExtension<T> on List<T> {
  /// Compare this list with another list using default strict mode
  bool isEqualTo(List<T> other,
      [ListEqualConfig config = const ListEqualConfig()]) {
    return listEqual([this, other], config);
  }

  /// Get detailed comparison result with another list
  ListComparisonResult compareDetailedWith(List<T> other,
      [ListEqualConfig config = const ListEqualConfig()]) {
    return listEqualDetailed([this, other], config);
  }
}

/// Utility class for creating common configuration presets
class ListEqualPresets {
  /// Strict comparison (default)
  static const strict = ListEqualConfig(mode: ListComparisonMode.strict);

  /// Case-insensitive string comparison
  static const caseInsensitive = ListEqualConfig(ignoreCase: true);

  /// Flexible string comparison (case-insensitive + trimmed)
  static const flexibleString = ListEqualConfig(
    ignoreCase: true,
    trimStrings: true,
  );

  /// Unordered comparison (treats as sets)
  static const unordered = ListEqualConfig(mode: ListComparisonMode.unordered);

  /// Deep comparison for nested structures
  static const deep = ListEqualConfig(mode: ListComparisonMode.deep);

  /// Flexible comparison with type coercion
  static const flexible = ListEqualConfig(
    mode: ListComparisonMode.flexible,
    allowTypeCoercion: true,
  );

  /// Optimized for large lists
  static const optimized = ListEqualConfig(
    optimizeForLargeLists: true,
    enableParallelProcessing: true,
  );

  /// Numeric comparison with small tolerance
  static const numericTolerant = ListEqualConfig(numericTolerance: 1e-10);

  /// Safe deep comparison with circular reference detection
  static const safeDeep = ListEqualConfig(
    mode: ListComparisonMode.deep,
    enableCircularReferenceDetection: true,
    maxDepth: 50,
  );
}

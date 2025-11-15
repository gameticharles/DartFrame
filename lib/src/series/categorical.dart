part of 'series.dart';

// dart:math is already imported in series.dart

/// A Categorical data type for efficient storage and manipulation of categorical data.
///
/// This is an internal class used by Series to handle categorical data efficiently.
/// It stores data as integer codes that map to category labels, providing memory
/// efficiency and supporting both ordered and unordered categories.
class _Categorical {
  /// The integer codes representing the categorical values
  final List<int> _codes;

  /// The category labels
  final List<dynamic> _categories;

  /// Whether the categories have a meaningful order
  bool _ordered;

  /// Creates a Categorical from a list of values.
  _Categorical(List<dynamic> values,
      {List<dynamic>? categories, bool ordered = false})
      : _ordered = ordered,
        _categories = categories ?? _inferCategories(values),
        _codes =
            _encodeCategorical(values, categories ?? _inferCategories(values));

  /// Creates a Categorical from codes and categories.
  _Categorical.fromCodes(List<int> codes, List<dynamic> categories,
      {bool ordered = false})
      : _codes = List.from(codes),
        _categories = List.from(categories),
        _ordered = ordered {
    // Validate codes
    for (int i = 0; i < codes.length; i++) {
      if (codes[i] < -1 || codes[i] >= categories.length) {
        throw ArgumentError(
            'Code ${codes[i]} at index $i is out of bounds for categories');
      }
    }
  }

  /// Infers categories from a list of values.
  static List<dynamic> _inferCategories(List<dynamic> values) {
    final uniqueValues = <dynamic>{};
    final orderedUnique = <dynamic>[];

    // Preserve order of first appearance while ensuring uniqueness
    for (var value in values) {
      if (value != null && !uniqueValues.contains(value)) {
        uniqueValues.add(value);
        orderedUnique.add(value);
      }
    }

    // Try to sort if all values are comparable
    try {
      if (orderedUnique.isNotEmpty &&
          orderedUnique.every((v) => v is Comparable)) {
        orderedUnique.sort();
      }
    } catch (e) {
      // If sorting fails, keep original order
    }

    return orderedUnique;
  }

  /// Encodes values as integer codes based on categories.
  static List<int> _encodeCategorical(
      List<dynamic> values, List<dynamic> categories) {
    return values.map((value) {
      if (value == null) {
        return -1; // Use -1 to represent null/missing values
      }
      final index = categories.indexOf(value);
      if (index == -1) {
        throw ArgumentError(
            'Value "$value" not found in categories: $categories');
      }
      return index;
    }).toList();
  }

  /// The category labels
  List<dynamic> get categories => List.unmodifiable(_categories);

  /// The integer codes
  List<int> get codes => List.unmodifiable(_codes);

  /// Whether the categories are ordered
  bool get ordered => _ordered;

  /// The number of categories
  int get nCategories => _categories.length;

  /// The length of the categorical data
  int get length => _codes.length;

  /// The original values
  List<dynamic> get values =>
      _codes.map((code) => code == -1 ? null : _categories[code]).toList();

  /// Returns the value at the specified index
  dynamic operator [](int index) {
    if (index < 0 || index >= _codes.length) {
      throw RangeError.index(index, _codes, 'index');
    }
    final code = _codes[index];
    return code == -1 ? null : _categories[code];
  }

  /// Sets the value at the specified index
  void operator []=(int index, dynamic value) {
    if (index < 0 || index >= _codes.length) {
      throw RangeError.index(index, _codes, 'index');
    }

    if (value == null) {
      _codes[index] = -1;
      return;
    }

    final categoryIndex = _categories.indexOf(value);
    if (categoryIndex == -1) {
      throw ArgumentError(
          'Value "$value" not found in categories: $_categories');
    }

    _codes[index] = categoryIndex;
  }

  /// Returns unique categories that appear in the data.
  List<dynamic> unique({bool sort = false}) {
    final uniqueCodes = Set<int>.from(_codes.where((code) => code != -1));
    final uniqueCategories =
        uniqueCodes.map((code) => _categories[code]).toList();

    if (sort && uniqueCategories.isNotEmpty) {
      try {
        if (uniqueCategories.every((cat) => cat is Comparable)) {
          uniqueCategories.sort();
        }
      } catch (e) {
        // If sorting fails, keep original order
      }
    }

    return uniqueCategories;
  }

  /// Checks if the categorical contains the specified value.
  bool contains(dynamic value) {
    if (value == null) {
      return _codes.contains(-1);
    }
    return _categories.contains(value);
  }
}

/// Categorical accessor for Series, similar to pandas .cat accessor.
///
/// This provides access to categorical-specific operations when a Series
/// has been converted to categorical dtype.
///
/// Example:
/// ```dart
/// var series = Series(['A', 'B', 'A', 'C'], name: 'categories');
/// series.astype('category');
/// print(series.cat.categories); // [A, B, C]
/// print(series.cat.codes); // [0, 1, 0, 2]
/// ```
class CategoricalAccessor {
  final Series _series;

  CategoricalAccessor(this._series) {
    if (!_series.isCategorical) {
      throw StateError(
          'Series is not categorical. Use astype("category") first.');
    }
  }

  /// The category labels
  List<dynamic> get categories => _series._categorical!.categories;

  /// The integer codes
  List<int> get codes => _series._categorical!.codes;

  /// Whether the categories are ordered
  bool get ordered => _series._categorical!.ordered;

  /// The number of categories
  int get nCategories => _series._categorical!.nCategories;

  /// Adds new categories to the categorical series.
  ///
  /// Parameters:
  ///   - `newCategories`: The new categories to add
  ///   - `inplace`: Whether to modify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  Series addCategories(List<dynamic> newCategories, {bool inplace = true}) {
    final updatedCategories =
        List<dynamic>.from(_series._categorical!._categories);

    for (var newCategory in newCategories) {
      if (!updatedCategories.contains(newCategory)) {
        updatedCategories.add(newCategory);
      }
    }

    if (inplace) {
      _series._categorical!._categories.clear();
      _series._categorical!._categories.addAll(updatedCategories);
      return _series;
    } else {
      final newSeries = Series(List.from(_series.data),
          name: _series.name, index: List.from(_series.index));
      newSeries._categorical = _Categorical.fromCodes(
          _series._categorical!._codes, updatedCategories,
          ordered: _series._categorical!._ordered);
      newSeries._syncDataFromCategorical();
      return newSeries;
    }
  }

  /// Removes categories from the categorical series.
  ///
  /// Parameters:
  ///   - `removals`: The categories to remove
  ///   - `inplace`: Whether to modify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  ///
  /// Throws:
  ///   - `ArgumentError` if trying to remove a category that is currently in use
  Series removeCategories(List<dynamic> removals, {bool inplace = true}) {
    final updatedCategories =
        List<dynamic>.from(_series._categorical!._categories);
    final updatedCodes = List<int>.from(_series._categorical!._codes);

    for (var removal in removals) {
      final removalIndex = updatedCategories.indexOf(removal);
      if (removalIndex == -1) continue;

      // Check if this category is in use
      if (_series._categorical!._codes.contains(removalIndex)) {
        throw ArgumentError(
            'Cannot remove category "$removal" as it is currently in use');
      }

      // Remove the category and adjust codes
      updatedCategories.removeAt(removalIndex);

      // Adjust codes that reference categories after the removed one
      for (int i = 0; i < updatedCodes.length; i++) {
        if (updatedCodes[i] > removalIndex) {
          updatedCodes[i]--;
        }
      }
    }

    if (inplace) {
      _series._categorical!._categories.clear();
      _series._categorical!._categories.addAll(updatedCategories);
      _series._categorical!._codes.clear();
      _series._categorical!._codes.addAll(updatedCodes);
      _series._syncDataFromCategorical();
      return _series;
    } else {
      final newSeries = Series(List.from(_series.data),
          name: _series.name, index: List.from(_series.index));
      newSeries._categorical = _Categorical.fromCodes(
          updatedCodes, updatedCategories,
          ordered: _series._categorical!._ordered);
      newSeries._syncDataFromCategorical();
      return newSeries;
    }
  }

  /// Renames categories in the categorical series.
  ///
  /// Parameters:
  ///   - `renameMap`: Map from old category names to new category names
  ///   - `inplace`: Whether to modify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  Series renameCategories(Map<dynamic, dynamic> renameMap,
      {bool inplace = true}) {
    final updatedCategories = _series._categorical!._categories
        .map((cat) => renameMap.containsKey(cat) ? renameMap[cat] : cat)
        .toList();

    if (inplace) {
      for (int i = 0; i < _series._categorical!._categories.length; i++) {
        if (renameMap.containsKey(_series._categorical!._categories[i])) {
          _series._categorical!._categories[i] =
              renameMap[_series._categorical!._categories[i]];
        }
      }
      _series._syncDataFromCategorical();
      return _series;
    } else {
      final newSeries = Series(List.from(_series.data),
          name: _series.name, index: List.from(_series.index));
      newSeries._categorical = _Categorical.fromCodes(
          _series._categorical!._codes, updatedCategories,
          ordered: _series._categorical!._ordered);
      newSeries._syncDataFromCategorical();
      return newSeries;
    }
  }

  /// Reorders the categories.
  ///
  /// Parameters:
  ///   - `newCategories`: The new category order
  ///   - `ordered`: Whether the reordered categorical should be ordered (default: current ordered state)
  ///   - `inplace`: Whether to modify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  ///
  /// Throws:
  ///   - `ArgumentError` if newCategories doesn't contain all existing categories
  Series reorderCategories(List<dynamic> newCategories,
      {bool? ordered, bool inplace = true}) {
    // Validate that all existing categories are present
    final existingSet = Set.from(_series._categorical!._categories);
    final newSet = Set.from(newCategories);

    if (existingSet.difference(newSet).isNotEmpty) {
      throw ArgumentError(
          'New categories must contain all existing categories');
    }

    // Create mapping from old indices to new indices
    final indexMapping = <int, int>{};
    for (int oldIndex = 0;
        oldIndex < _series._categorical!._categories.length;
        oldIndex++) {
      final category = _series._categorical!._categories[oldIndex];
      final newIndex = newCategories.indexOf(category);
      indexMapping[oldIndex] = newIndex;
    }

    // Remap codes
    final newCodes = _series._categorical!._codes
        .map((code) => code == -1 ? -1 : indexMapping[code]!)
        .toList();

    if (inplace) {
      _series._categorical!._categories.clear();
      _series._categorical!._categories.addAll(newCategories);
      _series._categorical!._codes.clear();
      _series._categorical!._codes.addAll(newCodes);
      _series._categorical!._ordered =
          ordered ?? _series._categorical!._ordered;
      _series._syncDataFromCategorical();
      return _series;
    } else {
      final newSeries = Series(List.from(_series.data),
          name: _series.name, index: List.from(_series.index));
      newSeries._categorical = _Categorical.fromCodes(newCodes, newCategories,
          ordered: ordered ?? _series._categorical!._ordered);
      newSeries._syncDataFromCategorical();
      return newSeries;
    }
  }

  /// Returns unique categories that appear in the data.
  List<dynamic> unique({bool sort = false}) {
    return _series._categorical!.unique(sort: sort);
  }

  /// Checks if the categorical series contains the specified value.
  bool contains(dynamic value) {
    return _series._categorical!.contains(value);
  }

  /// Sets the categories to the specified list.
  ///
  /// This replaces all categories with the new list. Values not in the new
  /// categories will become null/missing.
  ///
  /// Parameters:
  ///   - `newCategories`: The new categories to set
  ///   - `ordered`: Whether the categories should be ordered (default: current state)
  ///   - `rename`: If true, renames categories; if false, recodes data (default: false)
  ///   - `inplace`: Whether to modify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'b', 'c'], name: 'data');
  /// s.astype('category');
  /// s.cat.setCategories(['a', 'b', 'd']); // 'c' becomes null
  /// ```
  Series setCategories(List<dynamic> newCategories,
      {bool? ordered, bool rename = false, bool inplace = true}) {
    if (rename) {
      // Rename mode: just replace category labels
      if (newCategories.length != _series._categorical!._categories.length) {
        throw ArgumentError(
            'When rename=true, new categories must have same length as existing categories');
      }

      if (inplace) {
        _series._categorical!._categories.clear();
        _series._categorical!._categories.addAll(newCategories);
        if (ordered != null) {
          _series._categorical!._ordered = ordered;
        }
        _series._syncDataFromCategorical();
        return _series;
      } else {
        final newSeries = Series(List.from(_series.data),
            name: _series.name, index: List.from(_series.index));
        newSeries._categorical = _Categorical.fromCodes(
            _series._categorical!._codes, newCategories,
            ordered: ordered ?? _series._categorical!._ordered);
        newSeries._syncDataFromCategorical();
        return newSeries;
      }
    } else {
      // Recode mode: remap values to new categories
      final newCodes = <int>[];

      for (int i = 0; i < _series._categorical!._codes.length; i++) {
        final code = _series._categorical!._codes[i];
        if (code == -1) {
          newCodes.add(-1);
          continue;
        }

        final currentValue = _series._categorical!._categories[code];
        final newIndex = newCategories.indexOf(currentValue);

        if (newIndex == -1) {
          // Value not in new categories, set to null
          newCodes.add(-1);
        } else {
          newCodes.add(newIndex);
        }
      }

      if (inplace) {
        _series._categorical!._categories.clear();
        _series._categorical!._categories.addAll(newCategories);
        _series._categorical!._codes.clear();
        _series._categorical!._codes.addAll(newCodes);
        if (ordered != null) {
          _series._categorical!._ordered = ordered;
        }
        _series._syncDataFromCategorical();
        return _series;
      } else {
        final newSeries = Series(List.from(_series.data),
            name: _series.name, index: List.from(_series.index));
        newSeries._categorical = _Categorical.fromCodes(newCodes, newCategories,
            ordered: ordered ?? _series._categorical!._ordered);
        newSeries._syncDataFromCategorical();
        return newSeries;
      }
    }
  }

  /// Converts the categorical to ordered.
  ///
  /// Parameters:
  ///   - `inplace`: Whether todify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['low', 'high', 'medium'], name: 'priority');
  /// s.astype('category');
  /// s.cat.asOrdered();
  /// print(s.cat.ordered); // true
  /// ```
  Series asOrdered({bool inplace = true}) {
    if (inplace) {
      _series._categorical!._ordered = true;
      return _series;
    } else {
      final newSeries = Series(List.from(_series.data),
          name: _series.name, index: List.from(_series.index));
      newSeries._categorical = _Categorical.fromCodes(
          _series._categorical!._codes, _series._categorical!._categories,
          ordered: true);
      newSeries._syncDataFromCategorical();
      return newSeries;
    }
  }

  /// Converts the categorical to unordered.
  ///
  /// Parameters:
  ///   - `inplace`: Whether to modify this series in place (default: true)
  ///
  /// Returns:
  ///   The Series (for method chaining)
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['low', 'high', 'medium'], name: 'priority');
  /// s.astype('category');
  /// s.cat.asOrdered();
  /// s.cat.asUnordered();
  /// print(s.cat.ordered); // false
  /// ```
  Series asUnordered({bool inplace = true}) {
    if (inplace) {
      _series._categorical!._ordered = false;
      return _series;
    } else {
      final newSeries = Series(List.from(_series.data),
          name: _series.name, index: List.from(_series.index));
      newSeries._categorical = _Categorical.fromCodes(
          _series._categorical!._codes, _series._categorical!._categories,
          ordered: false);
      newSeries._syncDataFromCategorical();
      return newSeries;
    }
  }

  /// Returns the minimum category value.
  ///
  /// Only works for ordered categoricals.
  ///
  /// Returns:
  ///   The minimum category value
  ///
  /// Throws:
  ///   - `StateError` if the categorical is not ordered
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['low', 'high', 'medium'], name: 'priority');
  /// s.astype('category', categories: ['low', 'medium', 'high'], ordered: true);
  /// print(s.cat.min()); // 'low'
  /// ```
  dynamic min() {
    if (!_series._categorical!._ordered) {
      throw StateError('Cannot get min of unordered categorical');
    }

    // Find the minimum code that's actually present in the data
    int? minCode;
    for (var code in _series._categorical!._codes) {
      if (code != -1) {
        if (minCode == null || code < minCode) {
          minCode = code;
        }
      }
    }

    if (minCode == null) {
      return null; // All values are null
    }

    return _series._categorical!._categories[minCode];
  }

  /// Returns the maximum category value.
  ///
  /// Only works for ordered categoricals.
  ///
  /// Returns:
  ///   The maximum category value
  ///
  /// Throws:
  ///   - `StateError` if the categorical is not ordered
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['low', 'high', 'medium'], name: 'priority');
  /// s.astype('category', categories: ['low', 'medium', 'high'], ordered: true);
  /// print(s.cat.max()); // 'high'
  /// ```
  dynamic max() {
    if (!_series._categorical!._ordered) {
      throw StateError('Cannot get max of unordered categorical');
    }

    // Find the maximum code that's actually present in the data
    int? maxCode;
    for (var code in _series._categorical!._codes) {
      if (code != -1) {
        if (maxCode == null || code > maxCode) {
          maxCode = code;
        }
      }
    }

    if (maxCode == null) {
      return null; // All values are null
    }

    return _series._categorical!._categories[maxCode];
  }

  /// Returns memory usage information for the categorical series.
  ///
  /// Returns a map with:
  ///   - 'codes': Memory used by integer codes (bytes)
  ///   - 'categories': Memory used by category labels (estimated bytes)
  ///   - 'total': Total memory usage (bytes)
  ///   - 'object_equivalent': Estimated memory if stored as object dtype (bytes)
  ///   - 'savings': Memory saved by using categorical (bytes)
  ///   - 'savings_percent': Percentage of memory saved
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['A', 'B', 'A', 'C'] * 1000, name: 'data');
  /// s.astype('category');
  /// var usage = s.cat.memoryUsage();
  /// print('Savings: ${usage['savings_percent']}%');
  /// ```
  Map<String, dynamic> memoryUsage() {
    // Calculate memory for codes (int = 8 bytes on 64-bit systems)
    final codesMemory = _series._categorical!._codes.length * 8;

    // Estimate memory for categories
    // This is approximate - actual memory usage depends on string length and type
    int categoriesMemory = 0;
    for (var category in _series._categorical!._categories) {
      if (category is String) {
        // Approximate: 2 bytes per character + overhead
        categoriesMemory += (category.length * 2) + 40;
      } else if (category is int || category is double) {
        categoriesMemory += 8;
      } else {
        categoriesMemory += 40; // Generic object overhead
      }
    }

    final totalMemory = codesMemory + categoriesMemory;

    // Estimate memory if stored as object dtype
    int objectMemory = 0;
    for (var value in _series.data) {
      if (value is String) {
        objectMemory += (value.toString().length * 2) + 40;
      } else if (value is int || value is double) {
        objectMemory += 8;
      } else if (value == null) {
        objectMemory += 8; // Null pointer
      } else {
        objectMemory += 40;
      }
    }

    final savings = objectMemory - totalMemory;
    final savingsPercent = objectMemory > 0
        ? (savings / objectMemory * 100).toStringAsFixed(2)
        : '0.00';

    return {
      'codes': codesMemory,
      'categories': categoriesMemory,
      'total': totalMemory,
      'object_equivalent': objectMemory,
      'savings': savings,
      'savings_percent': savingsPercent,
    };
  }
}

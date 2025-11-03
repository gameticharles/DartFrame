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
}

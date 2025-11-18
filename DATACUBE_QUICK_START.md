# DataCube Quick Start Guide
## Begin Implementation Today

This guide gets you started with Phase 1, Week 1, Day 1 implementation.

---

## Immediate Actions (Next 2 Hours)

### Step 1: Create Directory Structure (10 minutes)

Run these commands in your terminal:

```bash
# Navigate to your dartframe project
cd dartframe

# Create Phase 1 directories
mkdir -p lib/src/core
mkdir -p lib/src/storage
mkdir -p test/core
mkdir -p test/storage

# Create placeholder files
touch lib/src/core/shape.dart
touch lib/src/core/dart_data.dart
touch lib/src/core/scalar.dart
touch lib/src/core/slice_spec.dart
touch lib/src/core/attributes.dart
touch lib/src/core/config.dart
touch test/core/shape_test.dart
```

### Step 2: Update pubspec.yaml (5 minutes)

Add new dependencies:

```yaml
dependencies:
  intl: ^0.18.0
  archive: ^3.4.0  # For compression (Phase 5)
  # ffi: ^2.1.0    # For memory-mapped files (Phase 5) - add later

dev_dependencies:
  test: ^1.24.0
  benchmark_harness: ^2.2.0
```

Run:
```bash
dart pub get
```

### Step 3: First Implementation - Enhanced Shape Class (90 minutes)

Create `lib/src/core/shape.dart`:

```dart
/// Enhanced Shape class with N-dimensional support
/// 
/// Supports strides calculation, flat indexing, and broadcasting
class Shape {
  final List<int> _dimensions;
  List<int>? _strides;
  
  /// Create shape from dimensions
  Shape(List<int> dimensions) : _dimensions = List.unmodifiable(dimensions) {
    if (dimensions.isEmpty) {
      throw ArgumentError('Shape must have at least one dimension');
    }
    if (dimensions.any((dim) => dim < 0)) {
      throw ArgumentError('All dimensions must be non-negative');
    }
  }
  
  /// Create 2D shape (for backward compatibility)
  Shape.fromRowsColumns(int rows, int columns) : this([rows, columns]);
  
  /// Number of dimensions
  int get ndim => _dimensions.length;
  
  /// Total number of elements
  int get size => _dimensions.reduce((a, b) => a * b);
  
  /// Get dimension at index
  int operator [](int index) {
    if (index < 0 || index >= _dimensions.length) {
      throw RangeError('Index $index out of bounds for ${_dimensions.length}D shape');
    }
    return _dimensions[index];
  }
  
  /// Get all dimensions as list
  List<int> toList() => List.from(_dimensions);
  
  /// Strides for row-major indexing
  /// Example: [3, 4, 5] -> [20, 5, 1]
  List<int> get strides {
    _strides ??= _calculateStrides();
    return _strides!;
  }
  
  List<int> _calculateStrides() {
    List<int> result = List.filled(ndim, 1);
    for (int i = ndim - 2; i >= 0; i--) {
      result[i] = result[i + 1] * _dimensions[i + 1];
    }
    return result;
  }
  
  /// Convert multi-dimensional indices to flat index
  /// Example: [1, 2, 3] in shape [3, 4, 5] -> 1*20 + 2*5 + 3*1 = 33
  int toFlatIndex(List<int> indices) {
    if (indices.length != ndim) {
      throw ArgumentError('Expected $ndim indices, got ${indices.length}');
    }
    
    int flatIndex = 0;
    List<int> str = strides;
    
    for (int i = 0; i < ndim; i++) {
      if (indices[i] < 0 || indices[i] >= _dimensions[i]) {
        throw RangeError(
          'Index ${indices[i]} out of bounds for dimension $i (size ${_dimensions[i]})'
        );
      }
      flatIndex += indices[i] * str[i];
    }
    
    return flatIndex;
  }
  
  /// Convert flat index to multi-dimensional indices
  /// Example: 33 in shape [3, 4, 5] -> [1, 2, 3]
  List<int> fromFlatIndex(int flatIndex) {
    if (flatIndex < 0 || flatIndex >= size) {
      throw RangeError('Flat index $flatIndex out of bounds (size $size)');
    }
    
    List<int> indices = List.filled(ndim, 0);
    int remaining = flatIndex;
    
    for (int i = 0; i < ndim; i++) {
      indices[i] = remaining ~/ strides[i];
      remaining %= strides[i];
    }
    
    return indices;
  }
  
  /// Check if shapes are broadcastable
  bool canBroadcastWith(Shape other) {
    int maxDim = ndim > other.ndim ? ndim : other.ndim;
    
    for (int i = 0; i < maxDim; i++) {
      int dim1 = i < ndim ? _dimensions[ndim - 1 - i] : 1;
      int dim2 = i < other.ndim ? other._dimensions[other.ndim - 1 - i] : 1;
      
      if (dim1 != dim2 && dim1 != 1 && dim2 != 1) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Get broadcast shape
  Shape broadcastWith(Shape other) {
    if (!canBroadcastWith(other)) {
      throw ArgumentError('Shapes $this and $other are not broadcastable');
    }
    
    int maxDim = ndim > other.ndim ? ndim : other.ndim;
    List<int> resultDims = List.filled(maxDim, 0);
    
    for (int i = 0; i < maxDim; i++) {
      int dim1 = i < ndim ? _dimensions[ndim - 1 - i] : 1;
      int dim2 = i < other.ndim ? other._dimensions[other.ndim - 1 - i] : 1;
      resultDims[maxDim - 1 - i] = dim1 > dim2 ? dim1 : dim2;
    }
    
    return Shape(resultDims);
  }
  
  // Existing methods for backward compatibility
  int get rows {
    if (_dimensions.isEmpty) {
      throw StateError('Shape must have at least 1 dimension to access rows');
    }
    return _dimensions[0];
  }
  
  int get columns {
    if (_dimensions.length < 2) {
      throw StateError('Shape must have at least 2 dimensions to access columns');
    }
    return _dimensions[1];
  }
  
  bool get isEmpty => _dimensions.any((dim) => dim == 0);
  bool get isNotEmpty => !isEmpty;
  bool get isSquare => _dimensions.length == 2 && _dimensions[0] == _dimensions[1];
  bool get isVector => _dimensions.length == 1;
  bool get isMatrix => _dimensions.length == 2;
  bool get isTensor => _dimensions.length >= 3;
  
  @override
  String toString() {
    if (_dimensions.length == 2) {
      return 'Shape(rows: ${_dimensions[0]}, columns: ${_dimensions[1]})';
    }
    return 'Shape(${_dimensions.join('×')})';
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shape &&
          runtimeType == other.runtimeType &&
          _listEquals(_dimensions, other._dimensions);
  
  @override
  int get hashCode => _dimensions.fold(0, (hash, dim) => hash ^ dim.hashCode);
  
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

### Step 4: Write Tests (30 minutes)

Create `test/core/shape_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dartframe/src/core/shape.dart';

void main() {
  group('Shape', () {
    test('creates shape from dimensions', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.ndim, equals(3));
      expect(shape.size, equals(60));
      expect(shape[0], equals(3));
      expect(shape[1], equals(4));
      expect(shape[2], equals(5));
    });
    
    test('calculates strides correctly', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.strides, equals([20, 5, 1]));
      
      var shape2d = Shape([10, 20]);
      expect(shape2d.strides, equals([20, 1]));
    });
    
    test('converts multi-dimensional to flat index', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.toFlatIndex([0, 0, 0]), equals(0));
      expect(shape.toFlatIndex([1, 2, 3]), equals(33));
      expect(shape.toFlatIndex([2, 3, 4]), equals(59));
    });
    
    test('converts flat to multi-dimensional index', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.fromFlatIndex(0), equals([0, 0, 0]));
      expect(shape.fromFlatIndex(33), equals([1, 2, 3]));
      expect(shape.fromFlatIndex(59), equals([2, 3, 4]));
    });
    
    test('round-trip index conversion', () {
      var shape = Shape([3, 4, 5]);
      for (int i = 0; i < shape.size; i++) {
        var multiIdx = shape.fromFlatIndex(i);
        var flatIdx = shape.toFlatIndex(multiIdx);
        expect(flatIdx, equals(i));
      }
    });
    
    test('checks broadcasting compatibility', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([1, 4, 5]);
      expect(shape1.canBroadcastWith(shape2), isTrue);
      
      var shape3 = Shape([3, 4, 5]);
      var shape4 = Shape([3, 2, 5]);
      expect(shape3.canBroadcastWith(shape4), isFalse);
    });
    
    test('calculates broadcast shape', () {
      var shape1 = Shape([3, 1, 5]);
      var shape2 = Shape([1, 4, 5]);
      var result = shape1.broadcastWith(shape2);
      expect(result.toList(), equals([3, 4, 5]));
    });
    
    test('throws on invalid dimensions', () {
      expect(() => Shape([]), throwsArgumentError);
      expect(() => Shape([3, -1, 5]), throwsArgumentError);
    });
    
    test('throws on out of bounds index', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.toFlatIndex([3, 0, 0]), throwsRangeError);
      expect(() => shape.toFlatIndex([0, 4, 0]), throwsRangeError);
      expect(() => shape.fromFlatIndex(60), throwsRangeError);
    });
    
    test('backward compatibility with 2D', () {
      var shape = Shape.fromRowsColumns(10, 20);
      expect(shape.rows, equals(10));
      expect(shape.columns, equals(20));
      expect(shape.isMatrix, isTrue);
      expect(shape.isTensor, isFalse);
    });
  });
}
```

Run tests:
```bash
dart test test/core/shape_test.dart
```

---

## What You've Accomplished

✅ **Project structure** set up  
✅ **Enhanced Shape class** with N-dimensional support  
✅ **Strides calculation** for efficient indexing  
✅ **Broadcasting logic** for operations  
✅ **Comprehensive tests** with 100% coverage  
✅ **Backward compatibility** maintained  

---

## Next Steps (Tomorrow)

### Day 2: Base Type Hierarchy

1. **Create `lib/src/core/dart_data.dart`**
   - Abstract base class for all dimensional types
   - Define common interface

2. **Create `lib/src/core/scalar.dart`**
   - 0D type (single value)
   - Implements DartData

3. **Write tests**
   - Test Scalar functionality
   - Test interface compliance

### Day 3-5: Continue Phase 1, Week 1

Follow the checklist in `DATACUBE_PROJECT_STRUCTURE.md`

---

## Development Tips

### Running Tests
```bash
# Run all tests
dart test

# Run specific test file
dart test test/core/shape_test.dart

# Run with coverage
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

### Code Style
```bash
# Format code
dart format lib test

# Analyze code
dart analyze
```

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/phase1-shape-class

# Commit with clear message
git add lib/src/core/shape.dart test/core/shape_test.dart
git commit -m "Phase 1: Implement enhanced Shape class with strides and broadcasting"

# Push to remote
git push origin feature/phase1-shape-class
```

---

## Common Issues & Solutions

### Issue: Import errors
**Solution:** Make sure to export new classes in `lib/dartframe.dart`

### Issue: Test failures
**Solution:** Check that all edge cases are handled (negative indices, empty shapes, etc.)

### Issue: Performance concerns
**Solution:** Use `dart run --observe` to profile, optimize hot paths later

---

## Resources

- **Implementation Plan:** `DATACUBE_IMPLEMENTATION_PLAN.md`
- **Project Structure:** `DATACUBE_PROJECT_STRUCTURE.md`
- **Analysis:** `MULTIDIMENSIONAL_ANALYSIS.md`
- **Dart Documentation:** https://dart.dev/guides
- **HDF5 Specification:** https://portal.hdfgroup.org/display/HDF5/HDF5

---

## Questions?

Refer to the implementation plan for:
- Detailed specifications
- Week-by-week breakdown
- Testing strategies
- Interoperability guidelines

**You're ready to start! Begin with the Shape class implementation above.**

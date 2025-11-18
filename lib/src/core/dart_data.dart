import 'shape.dart';
import 'attributes.dart';

/// Abstract base interface for all dimensional data structures in DartFrame
///
/// This interface provides a common API for:
/// - Scalar (0D)
/// - Series (1D)
/// - DataFrame (2D)
/// - DataCube (3D)
/// - NDArray (N-D)
///
/// All dimensional types implement this interface to enable:
/// - Consistent shape access
/// - Unified slicing operations
/// - Common metadata handling
/// - Type-safe conversions
abstract class DartData {
  /// Shape of the data structure
  ///
  /// Example:
  /// ```dart
  /// var scalar = Scalar(42);
  /// print(scalar.shape);  // Shape([])
  ///
  /// var series = Series([1, 2, 3]);
  /// print(series.shape);  // Shape([3])
  ///
  /// var df = DataFrame([[1, 2], [3, 4]]);
  /// print(df.shape);  // Shape([2, 2])
  ///
  /// var cube = DataCube.fromDataFrames([df1, df2, df3]);
  /// print(cube.shape);  // Shape([3, rows, cols])
  /// ```
  Shape get shape;

  /// Number of dimensions
  ///
  /// - Scalar: 0
  /// - Series: 1
  /// - DataFrame: 2
  /// - DataCube: 3
  /// - NDArray: N
  int get ndim;

  /// Total number of elements
  ///
  /// Equal to the product of all dimensions.
  ///
  /// Example:
  /// ```dart
  /// var array = NDArray([...], [3, 4, 5]);
  /// print(array.size);  // 60
  /// ```
  int get size;

  /// Data type of elements
  ///
  /// Returns the Dart runtime type of the data.
  Type get dtype => dynamic;

  /// Metadata attributes (HDF5-style)
  ///
  /// Allows attaching arbitrary metadata to data structures.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.fromDataFrames([...]);
  /// cube.attrs['units'] = 'celsius';
  /// cube.attrs['description'] = 'Temperature measurements';
  /// cube.attrs['created'] = DateTime.now();
  /// ```
  Attributes get attrs;

  /// Get value at multi-dimensional indices
  ///
  /// Example:
  /// ```dart
  /// var array = NDArray([...], [3, 4, 5]);
  /// var value = array.getValue([1, 2, 3]);
  /// ```
  dynamic getValue(List<int> indices);

  /// Set value at multi-dimensional indices
  ///
  /// Example:
  /// ```dart
  /// var array = NDArray([...], [3, 4, 5]);
  /// array.setValue([1, 2, 3], 42);
  /// ```
  void setValue(List<int> indices, dynamic value);

  /// Slice the data structure
  ///
  /// Returns the appropriate type based on the result dimensions:
  /// - 0D result → Scalar
  /// - 1D result → Series
  /// - 2D result → DataFrame
  /// - 3D result → DataCube
  /// - N-D result → NDArray
  ///
  /// Example:
  /// ```dart
  /// var array = NDArray([...], [10, 20, 30]);
  /// var slice2d = array.slice([5, Slice.all(), Slice.all()]);  // Returns DataFrame
  /// var slice1d = array.slice([5, 10, Slice.all()]);           // Returns Series
  /// var scalar = array.slice([5, 10, 15]);                     // Returns Scalar
  /// ```
  DartData slice(List<dynamic> sliceSpec);

  /// Check if this data structure is empty
  bool get isEmpty => size == 0;

  /// Check if this data structure is not empty
  bool get isNotEmpty => size > 0;

  /// Convert to string representation
  @override
  String toString();

  /// Check equality
  @override
  bool operator ==(Object other);

  /// Hash code
  @override
  int get hashCode;
}

/// Mixin for common DartData functionality
///
/// Provides default implementations for common operations.
mixin DartDataMixin implements DartData {
  @override
  int get ndim => shape.ndim;

  @override
  int get size => shape.size;

  @override
  bool get isEmpty => size == 0;

  @override
  bool get isNotEmpty => size > 0;
}

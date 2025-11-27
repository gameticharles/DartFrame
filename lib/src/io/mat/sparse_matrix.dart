import '../../ndarray/ndarray.dart';
import 'matlab_types.dart';

/// Represents a MATLAB sparse matrix
///
/// MATLAB v7.3 stores sparse matrices in Compressed Sparse Column (CSC) format:
/// - `data`: Non-zero values
/// - `ir` (rowIndices): Row indices for each non-zero value
/// - `jc` (colPointers): Column pointer array (length = ncols + 1)
///
/// This format is efficient for column-oriented operations and is the standard
/// format used by MATLAB, SciPy, and many other scientific libraries.
class SparseMatrix {
  /// Non-zero values
  final List<dynamic> data;

  /// Row indices for each non-zero value (ir in MATLAB)
  final List<int> rowIndices;

  /// Column pointers (jc in MATLAB)
  /// Length is ncols + 1, where jc[i]:jc[i+1] gives indices for column i
  final List<int> colPointers;

  /// Matrix shape [rows, cols]
  final List<int> shape;

  /// MATLAB class of the data elements
  final MatlabClass dataClass;

  SparseMatrix({
    required this.data,
    required this.rowIndices,
    required this.colPointers,
    required this.shape,
    this.dataClass = MatlabClass.double,
  }) {
    _validate();
  }

  /// Validate sparse matrix structure
  void _validate() {
    if (shape.length != 2) {
      throw ArgumentError('Sparse matrix must be 2D, got shape: $shape');
    }

    final nnz = data.length;
    if (rowIndices.length != nnz) {
      throw ArgumentError(
          'rowIndices length (${rowIndices.length}) must match data length ($nnz)');
    }

    if (colPointers.length != shape[1] + 1) {
      throw ArgumentError(
          'colPointers length (${colPointers.length}) must be ncols + 1 (${shape[1] + 1})');
    }

    if (colPointers.last != nnz) {
      throw ArgumentError('Last colPointer must equal nnz ($nnz)');
    }
  }

  /// Number of rows
  int get rows => shape[0];

  /// Number of columns
  int get cols => shape[1];

  /// Number of non-zero elements
  int get nnz => data.length;

  /// Sparsity ratio (percentage of zeros)
  double get sparsity => 1.0 - (nnz / (rows * cols));

  /// Get element at (row, col)
  ///
  /// Returns 0 (or 0.0 for double) for sparse zero elements.
  dynamic operator [](List<int> index) {
    if (index.length != 2) {
      throw ArgumentError('Index must be [row, col], got: $index');
    }

    final row = index[0];
    final col = index[1];

    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      throw RangeError('Index out of bounds: [$row, $col] for shape $shape');
    }

    // Binary search in column col for row
    final start = colPointers[col];
    final end = colPointers[col + 1];

    for (int idx = start; idx < end; idx++) {
      if (rowIndices[idx] == row) {
        return data[idx];
      } else if (rowIndices[idx] > row) {
        break; // Row indices are sorted
      }
    }

    // Element is sparse zero
    return _getZeroValue();
  }

  /// Get appropriate zero value based on data type
  dynamic _getZeroValue() {
    switch (dataClass) {
      case MatlabClass.double:
      case MatlabClass.single:
        return 0.0;
      case MatlabClass.int8:
      case MatlabClass.int16:
      case MatlabClass.int32:
      case MatlabClass.int64:
      case MatlabClass.uint8:
      case MatlabClass.uint16:
      case MatlabClass.uint32:
      case MatlabClass.uint64:
        return 0;
      case MatlabClass.logical:
        return false;
      default:
        return 0;
    }
  }

  /// Convert to dense NDArray
  ///
  /// **Warning**: This can consume a lot of memory for large sparse matrices.
  /// Check `estimateDenseMemory()` before calling.
  NDArray toDense() {
    final totalElements = rows * cols;
    final zeroValue = _getZeroValue();
    final dense = List.filled(totalElements, zeroValue);

    // Fill non-zero values (column-major order)
    for (int col = 0; col < cols; col++) {
      final start = colPointers[col];
      final end = colPointers[col + 1];

      for (int idx = start; idx < end; idx++) {
        final row = rowIndices[idx];
        final value = data[idx];
        // Column-major: index = row + col * rows
        dense[row + col * rows] = value;
      }
    }

    return NDArray.fromFlat(dense, shape);
  }

  /// Estimate memory usage of dense representation in bytes
  int estimateDenseMemory() {
    final totalElements = rows * cols;
    int bytesPerElement;

    switch (dataClass) {
      case MatlabClass.double:
        bytesPerElement = 8;
        break;
      case MatlabClass.single:
        bytesPerElement = 4;
        break;
      case MatlabClass.int8:
      case MatlabClass.uint8:
      case MatlabClass.logical:
        bytesPerElement = 1;
        break;
      case MatlabClass.int16:
      case MatlabClass.uint16:
        bytesPerElement = 2;
        break;
      case MatlabClass.int32:
      case MatlabClass.uint32:
        bytesPerElement = 4;
        break;
      case MatlabClass.int64:
      case MatlabClass.uint64:
        bytesPerElement = 8;
        break;
      default:
        bytesPerElement = 8;
    }

    return totalElements * bytesPerElement;
  }

  /// Get a specific row as a sparse vector
  List<dynamic> getRow(int row) {
    if (row < 0 || row >= rows) {
      throw RangeError('Row index out of bounds: $row');
    }

    final result = List.filled(cols, _getZeroValue());

    for (int col = 0; col < cols; col++) {
      final start = colPointers[col];
      final end = colPointers[col + 1];

      for (int idx = start; idx < end; idx++) {
        if (rowIndices[idx] == row) {
          result[col] = data[idx];
          break;
        }
      }
    }

    return result;
  }

  /// Get a specific column as a list
  List<dynamic> getColumn(int col) {
    if (col < 0 || col >= cols) {
      throw RangeError('Column index out of bounds: $col');
    }

    final result = List.filled(rows, _getZeroValue());
    final start = colPointers[col];
    final end = colPointers[col + 1];

    for (int idx = start; idx < end; idx++) {
      final row = rowIndices[idx];
      result[row] = data[idx];
    }

    return result;
  }

  /// Get non-zero elements as triplets (row, col, value)
  List<SparseTriplet> getNonZeros() {
    final triplets = <SparseTriplet>[];

    for (int col = 0; col < cols; col++) {
      final start = colPointers[col];
      final end = colPointers[col + 1];

      for (int idx = start; idx < end; idx++) {
        triplets.add(SparseTriplet(
          row: rowIndices[idx],
          col: col,
          value: data[idx],
        ));
      }
    }

    return triplets;
  }

  @override
  String toString() {
    final mb = (estimateDenseMemory() / (1024 * 1024)).toStringAsFixed(2);
    return 'SparseMatrix(${rows}x$cols, nnz=$nnz, '
        'sparsity=${(sparsity * 100).toStringAsFixed(1)}%, '
        'dense_size=${mb}MB)';
  }

  /// Create a string representation showing non-zero structure
  String toStructureString({int maxRows = 10, int maxCols = 10}) {
    final buffer = StringBuffer();
    buffer.writeln(toString());
    buffer.writeln('Non-zero pattern:');

    final displayRows = rows > maxRows ? maxRows : rows;
    final displayCols = cols > maxCols ? maxCols : cols;

    for (int r = 0; r < displayRows; r++) {
      for (int c = 0; c < displayCols; c++) {
        final val = this[[r, c]];
        if (val != _getZeroValue()) {
          buffer.write('█ ');
        } else {
          buffer.write('· ');
        }
      }
      if (cols > maxCols) buffer.write('...');
      buffer.writeln();
    }

    if (rows > maxRows) buffer.writeln('...');

    return buffer.toString();
  }
}

/// Represents a single non-zero element in a sparse matrix
class SparseTriplet {
  final int row;
  final int col;
  final dynamic value;

  SparseTriplet({
    required this.row,
    required this.col,
    required this.value,
  });

  @override
  String toString() => '($row, $col) = $value';
}

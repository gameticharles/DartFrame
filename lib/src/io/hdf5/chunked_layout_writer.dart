import 'storage_layout_writer.dart';
import 'byte_writer.dart';
import 'btree_v1_writer.dart';
import 'chunk_calculator.dart';
import 'filter.dart';
import '../../ndarray/ndarray.dart';

/// Information about a written chunk
class WrittenChunkInfo {
  final List<int> chunkIndices;
  final int address;
  final int size;
  final int uncompressedSize;
  final int filterMask;

  WrittenChunkInfo({
    required this.chunkIndices,
    required this.address,
    required this.size,
    required this.uncompressedSize,
    this.filterMask = 0,
  });
}

/// Writer for chunked storage layout
///
/// Chunked storage divides datasets into fixed-size chunks for efficient
/// partial I/O and compression. This writer:
/// - Validates and auto-calculates chunk dimensions
/// - Divides NDArray data into chunks
/// - Writes chunks sequentially with memory-efficient processing
/// - Creates B-tree index for chunk lookup
///
/// Example usage:
/// ```dart
/// final writer = ChunkedLayoutWriter(
///   chunkDimensions: [100, 100],
///   datasetDimensions: [1000, 1000],
/// );
/// final btreeAddress = await writer.writeData(byteWriter, array);
/// final layoutMsg = writer.writeLayoutMessage();
/// ```
class ChunkedLayoutWriter extends StorageLayoutWriter {
  final List<int> chunkDimensions;
  final List<int> datasetDimensions;
  final int dimensionality;
  final ChunkCalculator _calculator;
  final FilterPipeline? filterPipeline;

  int? _btreeAddress;
  final List<WrittenChunkInfo> _writtenChunks = [];

  /// Create a chunked layout writer
  ///
  /// Parameters:
  /// - [chunkDimensions]: Size of each chunk in each dimension
  /// - [datasetDimensions]: Total size of the dataset in each dimension
  /// - [filterPipeline]: Optional filter pipeline for compression/transformation
  ///
  /// Throws:
  /// - [ArgumentError] if chunk dimensions exceed dataset dimensions
  /// - [ArgumentError] if dimensions don't match
  ChunkedLayoutWriter({
    required this.chunkDimensions,
    required this.datasetDimensions,
    this.filterPipeline,
  })  : dimensionality = datasetDimensions.length,
        _calculator = ChunkCalculator(
          datasetDimensions: datasetDimensions,
          chunkDimensions: chunkDimensions,
        ) {
    _validateChunkDimensions();
  }

  /// Create a chunked layout writer with auto-calculated chunk dimensions
  ///
  /// Automatically calculates optimal chunk dimensions based on dataset shape
  /// and element size. The algorithm aims for chunks around 1MB in size.
  ///
  /// Parameters:
  /// - [datasetDimensions]: Total size of the dataset in each dimension
  /// - [elementSize]: Size of each element in bytes
  /// - [filterPipeline]: Optional filter pipeline for compression/transformation
  factory ChunkedLayoutWriter.auto({
    required List<int> datasetDimensions,
    required int elementSize,
    FilterPipeline? filterPipeline,
  }) {
    final chunkDims = _calculateOptimalChunkDimensions(
      datasetDimensions,
      elementSize,
    );
    return ChunkedLayoutWriter(
      chunkDimensions: chunkDims,
      datasetDimensions: datasetDimensions,
      filterPipeline: filterPipeline,
    );
  }

  @override
  int get layoutClass => 2; // Chunked layout

  @override
  List<int> writeLayoutMessage() {
    if (_btreeAddress == null) {
      throw StateError(
        'Must call writeData() before writeLayoutMessage()',
      );
    }

    final writer = ByteWriter();

    // Version 3 (HDF5 1.8+)
    writer.writeUint8(3);

    // Layout class: 2 = chunked
    writer.writeUint8(2);

    // Data address (B-tree address for chunk index)
    writer.writeUint64(_btreeAddress!);

    // Dimensionality
    writer.writeUint8(dimensionality);

    // Chunk dimensions (each dimension size)
    for (final dim in chunkDimensions) {
      writer.writeUint32(dim);
    }

    // Dataset element size (we'll calculate from first chunk)
    // For now, use a placeholder - this should be set by the caller
    final elementSize = _calculateElementSize();
    writer.writeUint32(elementSize);

    return writer.bytes;
  }

  @override
  Future<int> writeData(ByteWriter writer, NDArray array) async {
    // Validate array dimensions match dataset dimensions
    if (array.shape.toList().length != datasetDimensions.length) {
      throw ArgumentError(
        'Array dimensionality ${array.shape.toList().length} does not match '
        'dataset dimensionality $dimensionality',
      );
    }

    for (int i = 0; i < dimensionality; i++) {
      if (array.shape[i] != datasetDimensions[i]) {
        throw ArgumentError(
          'Array shape ${array.shape} does not match dataset dimensions $datasetDimensions',
        );
      }
    }

    // Clear any previous chunks
    _writtenChunks.clear();

    // Get total number of chunks
    final totalChunks = _calculator.getTotalChunks();

    // Write each chunk sequentially
    for (int linearIndex = 0; linearIndex < totalChunks; linearIndex++) {
      final chunkIndices = _calculator.linearToChunkIndices(linearIndex);
      await _writeChunk(writer, array, chunkIndices);
    }

    // Write B-tree index for chunk lookup
    _btreeAddress = await _writeBTreeIndex(writer);

    return _btreeAddress!;
  }

  /// Write a single chunk to the file
  Future<void> _writeChunk(
    ByteWriter writer,
    NDArray array,
    List<int> chunkIndices,
  ) async {
    // Get chunk offset in dataset
    final chunkOffset = _calculator.getChunkOffset(chunkIndices);
    final actualChunkSize = _calculator.getActualChunkSize(chunkIndices);

    // Extract chunk data from array
    final chunkData = _extractChunkData(array, chunkOffset, actualChunkSize);

    // Convert chunk data to bytes
    final chunkBytes = _chunkDataToBytes(chunkData, array);
    final uncompressedSize = chunkBytes.length;

    // Apply filter pipeline if present
    List<int> finalBytes = chunkBytes;
    int filterMask = 0; // 0 = all filters applied

    if (filterPipeline != null && filterPipeline!.isNotEmpty) {
      finalBytes = filterPipeline!.apply(chunkBytes);

      // Skip compression if compressed size >= 90% of original size
      // This is a common optimization in HDF5 implementations
      if (finalBytes.length >= (uncompressedSize * 0.9).round()) {
        finalBytes = chunkBytes; // Use uncompressed data

        // Set filter mask to indicate filters were skipped
        // Each bit corresponds to a filter (bit 0 = first filter, etc.)
        // Bit value 1 = filter skipped, 0 = filter applied
        for (int i = 0; i < filterPipeline!.length; i++) {
          filterMask |= (1 << i);
        }
      }
    }

    // Write chunk data
    final chunkAddress = writer.position;
    writer.writeBytes(finalBytes);

    // Record chunk information
    _writtenChunks.add(WrittenChunkInfo(
      chunkIndices: chunkIndices,
      address: chunkAddress,
      size: finalBytes.length,
      uncompressedSize: uncompressedSize,
      filterMask: filterMask,
    ));
  }

  /// Extract data for a specific chunk from the array
  List<dynamic> _extractChunkData(
    NDArray array,
    List<int> chunkOffset,
    List<int> chunkSize,
  ) {
    final chunkData = <dynamic>[];

    // Extract data using multi-dimensional iteration
    _extractChunkRecursive(
      array,
      chunkOffset,
      chunkSize,
      [],
      0,
      chunkData,
    );

    return chunkData;
  }

  /// Recursively extract chunk data
  void _extractChunkRecursive(
    NDArray array,
    List<int> chunkOffset,
    List<int> chunkSize,
    List<int> currentIndices,
    int dimension,
    List<dynamic> output,
  ) {
    if (dimension == dimensionality) {
      // Base case: we have a complete set of indices
      final datasetIndices = <int>[];
      for (int i = 0; i < dimensionality; i++) {
        datasetIndices.add(chunkOffset[i] + currentIndices[i]);
      }
      output.add(array.getValue(datasetIndices));
      return;
    }

    // Recursive case: iterate through this dimension
    for (int i = 0; i < chunkSize[dimension]; i++) {
      _extractChunkRecursive(
        array,
        chunkOffset,
        chunkSize,
        [...currentIndices, i],
        dimension + 1,
        output,
      );
    }
  }

  /// Convert chunk data to bytes
  List<int> _chunkDataToBytes(
    List<dynamic> chunkData,
    NDArray array,
  ) {
    final writer = ByteWriter();

    // Infer datatype from first element
    final firstValue = chunkData.isNotEmpty
        ? chunkData[0]
        : array.getValue(List.filled(dimensionality, 0));

    if (firstValue is double) {
      for (final value in chunkData) {
        writer.writeFloat64(value.toDouble());
      }
    } else if (firstValue is int) {
      for (final value in chunkData) {
        writer.writeInt64(value.toInt());
      }
    } else {
      throw UnsupportedError(
        'Unsupported data type: ${firstValue.runtimeType}. '
        'Currently supported: double (float64), int (int64)',
      );
    }

    return writer.bytes;
  }

  /// Write B-tree index for chunk lookup
  Future<int> _writeBTreeIndex(ByteWriter writer) async {
    // Create B-tree v1 writer for chunk indexing
    final btreeWriter = BTreeV1Writer(
      dimensionality: dimensionality + 1, // +1 for element size dimension
      offsetSize: 8, // Use 8-byte offsets
    );

    // Convert written chunks to B-tree entries
    final entries = <BTreeV1ChunkEntry>[];
    for (final chunk in _writtenChunks) {
      // Calculate scaled coordinates (chunk_index * chunk_size)
      final scaledCoords = <int>[];
      for (int i = 0; i < dimensionality; i++) {
        scaledCoords.add(chunk.chunkIndices[i] * chunkDimensions[i]);
      }
      // Add element size dimension (always 0)
      scaledCoords.add(0);

      entries.add(BTreeV1ChunkEntry(
        chunkSize: chunk.size,
        filterMask: chunk.filterMask,
        chunkCoordinates: scaledCoords,
        chunkAddress: chunk.address,
      ));
    }

    // Write B-tree
    return btreeWriter.writeChunkIndex(writer, entries);
  }

  /// Validate chunk dimensions
  void _validateChunkDimensions() {
    if (chunkDimensions.length != datasetDimensions.length) {
      throw ArgumentError(
        'Chunk dimensions length ${chunkDimensions.length} does not match '
        'dataset dimensions length ${datasetDimensions.length}',
      );
    }

    for (int i = 0; i < dimensionality; i++) {
      if (chunkDimensions[i] <= 0) {
        throw ArgumentError(
          'Chunk dimension at index $i must be positive, got ${chunkDimensions[i]}',
        );
      }

      if (chunkDimensions[i] > datasetDimensions[i]) {
        throw ArgumentError(
          'Chunk dimension at index $i (${chunkDimensions[i]}) exceeds '
          'dataset dimension (${datasetDimensions[i]})',
        );
      }
    }
  }

  /// Calculate element size from written chunks
  int _calculateElementSize() {
    if (_writtenChunks.isEmpty) {
      return 8; // Default to 8 bytes (float64/int64)
    }

    // Calculate from first chunk
    final firstChunk = _writtenChunks.first;
    final chunkElementCount =
        _calculator.getChunkElementCount(firstChunk.chunkIndices);

    if (chunkElementCount == 0) {
      return 8;
    }

    return firstChunk.size ~/ chunkElementCount;
  }

  /// Calculate optimal chunk dimensions for a dataset
  ///
  /// Algorithm aims for chunks around 1MB in size while maintaining
  /// reasonable proportions relative to the dataset shape.
  static List<int> _calculateOptimalChunkDimensions(
    List<int> datasetDimensions,
    int elementSize,
  ) {
    const targetChunkBytes = 1024 * 1024; // 1MB target
    final targetElements = targetChunkBytes ~/ elementSize;

    // Start with dataset dimensions
    final chunkDims = List<int>.from(datasetDimensions);
    final ndim = datasetDimensions.length;

    // Calculate current chunk size
    int currentElements = chunkDims.reduce((a, b) => a * b);

    // If already smaller than target, use dataset dimensions
    if (currentElements <= targetElements) {
      return chunkDims;
    }

    // Scale down proportionally
    final scaleFactor = (targetElements / currentElements).clamp(0.0, 1.0);
    final dimScaleFactor = pow_(scaleFactor, 1.0 / ndim).toDouble();

    for (int i = 0; i < ndim; i++) {
      chunkDims[i] = (datasetDimensions[i] * dimScaleFactor)
          .ceil()
          .clamp(1, datasetDimensions[i]);
    }

    // Ensure at least 1 in each dimension
    for (int i = 0; i < ndim; i++) {
      if (chunkDims[i] < 1) {
        chunkDims[i] = 1;
      }
    }

    return chunkDims;
  }
}

/// Helper function for power calculation
double pow_(double base, double exponent) {
  if (exponent == 0) return 1.0;
  if (exponent == 1) return base;

  // Simple implementation for positive exponents
  if (exponent > 0) {
    double result = 1.0;
    for (int i = 0; i < exponent.floor(); i++) {
      result *= base;
    }
    // Handle fractional part with approximation
    final fractional = exponent - exponent.floor();
    if (fractional > 0) {
      // Simple approximation: x^0.5 ≈ sqrt(x)
      // For general case, use exp(fractional * ln(base))
      // Here we'll use a simple linear approximation
      result *= (1.0 + fractional * (base - 1.0));
    }
    return result;
  }

  return 1.0 / pow_(base, -exponent);
}

import 'hdf5_error.dart';

/// Configuration options for HDF5 write operations
///
/// This class encapsulates all configuration parameters for writing HDF5 files,
/// including storage layout, compression, format version, and DataFrame-specific
/// options.
///
/// Example usage:
/// ```dart
/// final options = WriteOptions(
///   layout: StorageLayout.chunked,
///   chunkDimensions: [100, 100],
///   compression: CompressionType.gzip,
///   compressionLevel: 6,
/// );
/// ```
class WriteOptions {
  /// Storage layout for the dataset
  final StorageLayout layout;

  /// Chunk dimensions for chunked storage (null for auto-calculate)
  final List<int>? chunkDimensions;

  /// Compression algorithm to use
  final CompressionType compression;

  /// Compression level (1-9 for gzip, ignored for other types)
  final int compressionLevel;

  /// HDF5 format version (0, 1, or 2)
  final int formatVersion;

  /// Automatically create intermediate groups in dataset paths
  final bool createIntermediateGroups;

  /// Storage strategy for DataFrame objects
  final DataFrameStorageStrategy dfStrategy;

  /// Attributes to attach to the dataset or group
  final Map<String, dynamic>? attributes;

  /// Whether to validate the file after writing
  ///
  /// When enabled, performs comprehensive validation checks including:
  /// - Superblock signature verification
  /// - Address reference validation
  /// - B-tree structure validation
  ///
  /// Validation adds minimal overhead but provides confidence that the
  /// written file is valid and can be read by standard HDF5 tools.
  final bool validateOnWrite;

  const WriteOptions({
    this.layout = StorageLayout.contiguous,
    this.chunkDimensions,
    this.compression = CompressionType.none,
    this.compressionLevel = 6,
    this.formatVersion = 0,
    this.createIntermediateGroups = true,
    this.dfStrategy = DataFrameStorageStrategy.compound,
    this.attributes,
    this.validateOnWrite = false,
  });

  /// Validate the options for consistency
  ///
  /// Throws [DataValidationError] or [InvalidChunkDimensionsError] if options are invalid
  void validate({List<int>? datasetDimensions}) {
    // Compression requires chunked storage
    if (compression != CompressionType.none &&
        layout != StorageLayout.chunked) {
      // Automatically enable chunked storage when compression is requested
      // This is handled by the caller, but we document it here
      throw DataValidationError(
        reason: 'Compression requires chunked storage layout',
        details:
            'When compression is enabled, the storage layout must be set to StorageLayout.chunked. '
            'Current layout: $layout, Compression: $compression',
      );
    }

    // Validate compression level
    if (compression == CompressionType.gzip) {
      if (compressionLevel < 1 || compressionLevel > 9) {
        throw DataValidationError(
          reason: 'Invalid compression level for gzip',
          details:
              'Compression level must be between 1 and 9 for gzip. Got: $compressionLevel. '
              'Use 1 for fastest compression, 9 for best compression, or 6 for balanced performance.',
        );
      }
    }

    // Validate chunk dimensions if provided
    if (chunkDimensions != null) {
      if (chunkDimensions!.isEmpty) {
        throw InvalidChunkDimensionsError(
          chunkDimensions: chunkDimensions!,
          datasetDimensions: datasetDimensions ?? [],
          additionalDetails: 'Chunk dimensions cannot be empty',
        );
      }

      if (chunkDimensions!.any((dim) => dim <= 0)) {
        throw InvalidChunkDimensionsError(
          chunkDimensions: chunkDimensions!,
          datasetDimensions: datasetDimensions ?? [],
          additionalDetails:
              'All chunk dimensions must be positive integers. Got: $chunkDimensions',
        );
      }

      // Validate chunk dimensions against dataset dimensions if provided
      if (datasetDimensions != null) {
        if (chunkDimensions!.length != datasetDimensions.length) {
          throw InvalidChunkDimensionsError(
            chunkDimensions: chunkDimensions!,
            datasetDimensions: datasetDimensions,
            additionalDetails:
                'Chunk dimensions rank (${chunkDimensions!.length}) must match '
                'dataset dimensions rank (${datasetDimensions.length})',
          );
        }

        for (int i = 0; i < chunkDimensions!.length; i++) {
          if (chunkDimensions![i] > datasetDimensions[i]) {
            throw InvalidChunkDimensionsError(
              chunkDimensions: chunkDimensions!,
              datasetDimensions: datasetDimensions,
              additionalDetails:
                  'Chunk dimension at index $i (${chunkDimensions![i]}) exceeds '
                  'dataset dimension (${datasetDimensions[i]})',
            );
          }
        }
      }
    }

    // Validate format version
    if (formatVersion < 0 || formatVersion > 2) {
      throw DataValidationError(
        reason: 'Invalid HDF5 format version',
        details: 'Format version must be 0, 1, or 2. Got: $formatVersion. '
            'Version 0 is the most compatible, version 2 offers better performance for large files.',
      );
    }
  }

  /// Create a copy with modified options
  WriteOptions copyWith({
    StorageLayout? layout,
    List<int>? chunkDimensions,
    CompressionType? compression,
    int? compressionLevel,
    int? formatVersion,
    bool? createIntermediateGroups,
    DataFrameStorageStrategy? dfStrategy,
    Map<String, dynamic>? attributes,
    bool? validateOnWrite,
  }) {
    return WriteOptions(
      layout: layout ?? this.layout,
      chunkDimensions: chunkDimensions ?? this.chunkDimensions,
      compression: compression ?? this.compression,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      formatVersion: formatVersion ?? this.formatVersion,
      createIntermediateGroups:
          createIntermediateGroups ?? this.createIntermediateGroups,
      dfStrategy: dfStrategy ?? this.dfStrategy,
      attributes: attributes ?? this.attributes,
      validateOnWrite: validateOnWrite ?? this.validateOnWrite,
    );
  }

  @override
  String toString() {
    return 'WriteOptions('
        'layout: $layout, '
        'compression: $compression, '
        'formatVersion: $formatVersion'
        ')';
  }
}

/// Storage layout for datasets
enum StorageLayout {
  /// Contiguous storage - data stored in a single continuous block
  contiguous,

  /// Chunked storage - data divided into fixed-size chunks
  chunked,
}

/// Compression algorithm types
enum CompressionType {
  /// No compression
  none,

  /// GZIP/DEFLATE compression (filter ID 1)
  gzip,

  /// LZF compression (filter ID 32000)
  lzf,
}

/// Storage strategy for DataFrame objects
enum DataFrameStorageStrategy {
  /// Store as compound datatype (struct-like, one record per row)
  compound,

  /// Store each column as a separate dataset in a group
  columnwise,
}

/// Compression codec interface for DartFrame
library;

/// Abstract compression codec interface
abstract class Codec {
  /// Codec name (e.g., 'gzip', 'zlib', 'none')
  String get name;

  /// Compress data with optional compression level
  List<int> compress(List<int> data, {int level = 6});

  /// Decompress compressed data
  List<int> decompress(List<int> compressed);

  /// Estimate compression ratio from a sample
  /// Returns ratio (0.0 to 1.0, lower is better compression)
  double estimateRatio(List<int> sample);

  /// Default compression level
  int get defaultLevel => 6;

  /// Minimum compression level (fastest)
  int get minLevel => 1;

  /// Maximum compression level (best compression)
  int get maxLevel => 9;

  /// Whether this codec is available
  bool get isAvailable => true;

  @override
  String toString() => name;
}

/// Compression strategy for adaptive selection
enum CompressionStrategy {
  /// Prioritize speed over compression ratio
  fastest,

  /// Balance speed and compression ratio
  balanced,

  /// Prioritize compression ratio over speed
  smallest,

  /// No compression
  none,
}

/// Result of compression test
class CompressionResult {
  final Codec codec;
  final int originalSize;
  final int compressedSize;
  final Duration compressionTime;
  final Duration decompressionTime;

  CompressionResult({
    required this.codec,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionTime,
    required this.decompressionTime,
  });

  /// Compression ratio (0.0 to 1.0, lower is better)
  double get ratio => compressedSize / originalSize;

  /// Space saved in bytes
  int get spaceSaved => originalSize - compressedSize;

  /// Space saved as percentage
  double get percentSaved => (1.0 - ratio) * 100;

  /// Compression speed in MB/s
  double get compressionSpeed =>
      (originalSize / 1024 / 1024) / compressionTime.inMicroseconds * 1000000;

  /// Decompression speed in MB/s
  double get decompressionSpeed =>
      (originalSize / 1024 / 1024) / decompressionTime.inMicroseconds * 1000000;

  /// Score for adaptive selection (lower is better)
  /// Balances ratio and speed
  double score(CompressionStrategy strategy) {
    switch (strategy) {
      case CompressionStrategy.fastest:
        return compressionTime.inMicroseconds.toDouble();
      case CompressionStrategy.balanced:
        return ratio * compressionTime.inMicroseconds;
      case CompressionStrategy.smallest:
        return ratio;
      case CompressionStrategy.none:
        return 0.0;
    }
  }

  @override
  String toString() {
    return '${codec.name}: ${percentSaved.toStringAsFixed(1)}% saved, '
        '${compressionSpeed.toStringAsFixed(1)} MB/s compress, '
        '${decompressionSpeed.toStringAsFixed(1)} MB/s decompress';
  }
}

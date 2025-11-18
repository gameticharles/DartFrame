/// Adaptive compression selection
library;

import 'dart:math' as math;
import 'codec.dart';
import 'registry.dart';

/// Adaptive compression system
/// Automatically selects the best codec based on data characteristics
class AdaptiveCompression {
  /// Select best codec for data based on strategy
  static Codec selectCodec(
    List<int> sample, {
    CompressionStrategy strategy = CompressionStrategy.balanced,
    List<Codec>? candidates,
  }) {
    if (strategy == CompressionStrategy.none) {
      return CompressionRegistry.getOrThrow('none');
    }

    // Use provided candidates or all available codecs
    final codecs = candidates ?? CompressionRegistry.getAvailable();

    if (codecs.isEmpty) {
      return CompressionRegistry.getOrThrow('none');
    }

    // For small samples, use default
    if (sample.length < 1024) {
      return CompressionRegistry.getDefault();
    }

    // Take a sample if data is large
    final testSample = sample.length > 100000
        ? sample.sublist(0, math.min(100000, sample.length))
        : sample;

    // Test all codecs
    final results = testCodecs(testSample, codecs);

    if (results.isEmpty) {
      return CompressionRegistry.getDefault();
    }

    // Select best based on strategy
    results.sort((a, b) => a.score(strategy).compareTo(b.score(strategy)));

    return results.first.codec;
  }

  /// Test multiple codecs on sample data
  static List<CompressionResult> testCodecs(
    List<int> sample,
    List<Codec> codecs,
  ) {
    final results = <CompressionResult>[];

    for (final codec in codecs) {
      try {
        final result = testCodec(sample, codec);
        results.add(result);
      } catch (e) {
        // Skip codecs that fail
        continue;
      }
    }

    return results;
  }

  /// Test a single codec on sample data
  static CompressionResult testCodec(
    List<int> sample,
    Codec codec, {
    int level = 6,
  }) {
    // Measure compression
    final compressStart = DateTime.now();
    final compressed = codec.compress(sample, level: level);
    final compressEnd = DateTime.now();

    // Measure decompression
    final decompressStart = DateTime.now();
    codec.decompress(compressed);
    final decompressEnd = DateTime.now();

    return CompressionResult(
      codec: codec,
      originalSize: sample.length,
      compressedSize: compressed.length,
      compressionTime: compressEnd.difference(compressStart),
      decompressionTime: decompressEnd.difference(decompressStart),
    );
  }

  /// Analyze data characteristics
  static DataCharacteristics analyzeData(List<int> sample) {
    if (sample.isEmpty) {
      return DataCharacteristics(
        entropy: 0.0,
        uniqueValues: 0,
        isRandom: false,
        isSparse: false,
      );
    }

    // Calculate entropy
    final freq = <int, int>{};
    for (final byte in sample) {
      freq[byte] = (freq[byte] ?? 0) + 1;
    }

    var entropy = 0.0;
    for (final count in freq.values) {
      final p = count / sample.length;
      entropy -= p * (math.log(p) / math.ln2);
    }

    // Check if data is sparse (many zeros)
    final zeroCount = freq[0] ?? 0;
    final isSparse = zeroCount > sample.length * 0.5;

    // Check if data is random (high entropy)
    final isRandom = entropy > 7.0; // Close to 8 bits

    return DataCharacteristics(
      entropy: entropy,
      uniqueValues: freq.length,
      isRandom: isRandom,
      isSparse: isSparse,
    );
  }

  /// Recommend codec based on data characteristics
  static Codec recommendCodec(DataCharacteristics chars) {
    CompressionRegistry.initialize();

    // Random data doesn't compress well
    if (chars.isRandom) {
      return CompressionRegistry.getOrThrow('none');
    }

    // Sparse data compresses very well
    if (chars.isSparse) {
      return CompressionRegistry.getOrThrow('gzip');
    }

    // Low entropy data compresses well
    if (chars.entropy < 4.0) {
      return CompressionRegistry.getOrThrow('gzip');
    }

    // Default to balanced codec
    return CompressionRegistry.getDefault();
  }
}

/// Data characteristics for compression analysis
class DataCharacteristics {
  /// Shannon entropy (0-8 bits)
  final double entropy;

  /// Number of unique byte values
  final int uniqueValues;

  /// Whether data appears random
  final bool isRandom;

  /// Whether data is sparse (many zeros)
  final bool isSparse;

  const DataCharacteristics({
    required this.entropy,
    required this.uniqueValues,
    required this.isRandom,
    required this.isSparse,
  });

  @override
  String toString() {
    return 'DataCharacteristics('
        'entropy: ${entropy.toStringAsFixed(2)}, '
        'unique: $uniqueValues, '
        'random: $isRandom, '
        'sparse: $isSparse)';
  }
}

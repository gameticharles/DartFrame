/// Gzip compression codec
library;

import 'dart:io';
import 'codec.dart';

/// Gzip compression codec
/// Uses Dart's built-in gzip implementation
class GzipCodec implements Codec {
  const GzipCodec();

  @override
  String get name => 'gzip';

  @override
  List<int> compress(List<int> data, {int level = 6}) {
    final codec = gzip.encoder;
    return codec.convert(data);
  }

  @override
  List<int> decompress(List<int> compressed) {
    final codec = gzip.decoder;
    return codec.convert(compressed);
  }

  @override
  double estimateRatio(List<int> sample) {
    if (sample.isEmpty) return 1.0;

    try {
      final compressed = compress(sample, level: defaultLevel);
      return compressed.length / sample.length;
    } catch (e) {
      return 1.0; // Assume no compression on error
    }
  }

  @override
  int get defaultLevel => 6;

  @override
  int get minLevel => 1;

  @override
  int get maxLevel => 9;

  @override
  bool get isAvailable => true;
}

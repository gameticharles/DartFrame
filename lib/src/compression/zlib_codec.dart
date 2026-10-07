/// Zlib compression codec
library;

import 'package:archive/archive.dart';
import 'codec.dart';

/// Zlib compression codec
/// Uses archive package's zlib implementation
/// Similar to Gzip but with different header
class ZlibCodec implements Codec {
  const ZlibCodec();

  @override
  String get name => 'zlib';

  @override
  List<int> compress(List<int> data, {int level = 6}) {
    return ZLibEncoder().encode(data, level: level);
  }

  @override
  List<int> decompress(List<int> compressed) {
    return ZLibDecoder().decodeBytes(compressed);
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

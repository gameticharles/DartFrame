/// No compression codec (passthrough)
library;

import 'codec.dart';

/// No compression - data passes through unchanged
class NoneCodec implements Codec {
  const NoneCodec();

  @override
  String get name => 'none';

  @override
  List<int> compress(List<int> data, {int level = 0}) {
    // Return copy to maintain immutability
    return List<int>.from(data);
  }

  @override
  List<int> decompress(List<int> compressed) {
    // Return copy to maintain immutability
    return List<int>.from(compressed);
  }

  @override
  double estimateRatio(List<int> sample) {
    return 1.0; // No compression
  }

  @override
  int get defaultLevel => 0;

  @override
  int get minLevel => 0;

  @override
  int get maxLevel => 0;

  @override
  bool get isAvailable => true;
}

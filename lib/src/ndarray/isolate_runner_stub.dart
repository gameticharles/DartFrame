import 'dart:async';
import 'ndarray.dart';

/// Runs a chunk processing task synchronously on platforms without isolates (such as Web).
Future<dynamic> runChunkInIsolate(
  NDArray chunk,
  dynamic Function(NDArray) processor,
) async {
  return processor(chunk);
}

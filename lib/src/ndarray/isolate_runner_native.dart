import 'dart:async';
import 'dart:isolate';
import 'ndarray.dart';

/// Runs a chunk processing task in an isolate on native platforms.
Future<dynamic> runChunkInIsolate(
  NDArray chunk,
  dynamic Function(NDArray) processor,
) async {
  final receivePort = ReceivePort();

  try {
    await Isolate.spawn(
      _isolateWorker,
      _IsolateMessage(
        sendPort: receivePort.sendPort,
        data: chunk.toFlatList(),
        shape: chunk.shape.toList(),
        processor: processor,
      ),
    );

    final result = await receivePort.first;
    return result;
  } catch (e) {
    // If isolate fails, fall back to synchronous processing
    return processor(chunk);
  }
}

void _isolateWorker(_IsolateMessage message) {
  try {
    final chunk = NDArray.fromFlat(message.data, message.shape);
    final result = message.processor(chunk);
    message.sendPort.send(result);
  } catch (e) {
    message.sendPort.send(null);
  }
}

class _IsolateMessage {
  final SendPort sendPort;
  final List<dynamic> data;
  final List<int> shape;
  final dynamic Function(NDArray) processor;

  _IsolateMessage({
    required this.sendPort,
    required this.data,
    required this.shape,
    required this.processor,
  });
}

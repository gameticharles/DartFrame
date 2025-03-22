import 'dart:async';
// import 'dart:html';
import 'dart:js_interop';
import 'package:web/web.dart';

import 'file_io.dart';

class FileIO implements FileIOBase {
  
  void _saveToFileWeb(String path, String data) {
    // Create a JSArray for Blob constructor
    final jsArray = <JSAny>[data.toJS].toJS;
    var blob = Blob(jsArray);
    var url = URL.createObjectURL(blob);
    var anchor = document.createElement('a') as HTMLAnchorElement;
    anchor.href = url;
    anchor.style.display = 'none';
    anchor.download = path;
    
    document.body!.appendChild(anchor);

    // download the file
    anchor.click();

    // cleanup the DOM
    document.body!.removeChild(anchor);
    URL.revokeObjectURL(url);
  }

  Future<String> _readFromFileWeb(HTMLInputElement uploadInput) async {
    var file = uploadInput.files!.item(0);
    if (file == null) {
      throw Exception("No file selected.");
    }
    var reader = FileReader();

    var completer = Completer<String>();
    // reader.onLoadEnd.listen((e) {
    //   completer.complete(reader.result.toString());
    // });
    // Convert Dart functions to JS-compatible event listeners using toJS
    void onLoadEnd(Event event) {
      completer.complete(reader.result.toString());
    }
    void onError(Event event) {
      completer.completeError(reader.error ?? Exception('Unknown error'));
    }
    // Use the JS interop conversion
    reader.addEventListener('loadend', onLoadEnd.toJS);
    reader.addEventListener('error', onError.toJS);
    reader.readAsArrayBuffer(file as Blob);

    return completer.future;
  }

  @override
  void saveToFile(String path, String data) {
    _saveToFileWeb(data, path);
  }

  @override
  Future<String> readFromFile(dynamic uploadInput) async {
    return await _readFromFileWeb(uploadInput);
  }

  @override
  Stream<String> readFileAsStream(String path) {
    // Stream-based reading is not directly supported in web environments.
    // You may need to implement custom logic depending on the use case.
    // Typically, file reading in web is event-driven, as shown in _readFromFileWeb.
    throw UnimplementedError(
        'Stream reading is not supported in web environments.');
  }

  @override
  StreamSink<String> writeFileAsStream(dynamic path) {
    // Stream-based writing is not directly supported in web environments.
    // Implementing this would require a custom approach, maybe accumulating data in memory
    // and then triggering a download when the stream is closed.
    throw UnimplementedError(
        'Stream writing is not supported in web environments.');
  }
}

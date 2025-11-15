import 'dart:async';

export 'file_io_stub.dart'
    if (dart.library.js_interop) 'file_io_web.dart'
    if (dart.library.io) 'file_io_other.dart';

/// Abstract interface for random access file operations
///
/// Provides platform-independent random access to file data.
/// On desktop platforms, this wraps dart:io's RandomAccessFile.
/// On web platforms, this operates on in-memory Uint8List data.
abstract class RandomAccessFileBase {
  /// Gets the current position in the file
  int get position;

  /// Sets the byte position in the file
  Future<void> setPosition(int position);

  /// Reads up to [bytes] bytes from the current position
  /// Returns the actual bytes read (may be less than requested at EOF)
  Future<List<int>> read(int bytes);

  /// Gets the length of the file in bytes
  Future<int> length();

  /// Closes the file and releases resources
  Future<void> close();
}

/// A class to provide file input/output operations.
///
/// Implementations of this class should provide means
/// to save data to a file and read data from a file, including
/// streaming support for large files.
abstract class FileIOBase {
  /// Saves the given data to a file.
  ///
  /// The parameters passed can be different based on the platform:
  ///   * For desktop, pass the file path as [pathOrData] and the content as [dataOrFileName].
  ///   * For web, pass the content as [pathOrData] and the filename as [dataOrFileName].
  ///
  /// Example usage (desktop):
  /// ```
  /// var fileIO = FileIO();
  /// await fileIO.saveToFile("/path/to/file.txt", "This is some content.");
  /// ```
  /// Example usage (web):
  /// ```
  /// var fileIO = FileIO();
  /// await fileIO.saveToFile("This is some content.", "file.txt");
  /// ```
  Future<void> saveToFile(String pathOrData, String dataOrFileName);

  /// Reads the content from a file.
  ///
  /// The parameter can be different based on the platform:
  ///   * For desktop, pass the file path.
  ///   * For web, pass the InputElement used for file upload.
  ///
  /// This method returns a `Future<String>` which completes with the content of the file.
  ///
  /// Example usage (desktop):
  /// ```
  /// var fileIO = FileIO();
  /// var content = await fileIO.readFromFile("/path/to/file.txt");
  /// print(content);
  /// ```
  /// Example usage (web):
  /// ```
  /// var fileIO = FileIO();
  /// InputElement uploadInput = querySelector('#upload');
  /// var content = await fileIO.readFromFile(uploadInput);
  /// print(content);
  /// ```
  Future<String> readFromFile(dynamic pathOrUploadInput);

  /// Reads from a file as a stream of strings, with each string representing a line in the file.
  ///
  /// This method returns a `Stream<String>` where each item represents a line in the file.
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// fileIO.readFileAsStream("/path/to/file.txt").listen((line) {
  ///   print(line);
  /// });
  /// ```
  Stream<String> readFileAsStream(String pathOrUploadInput);

  /// Writes to a file using a stream.
  ///
  /// This method returns a `StreamSink<String>` that can be used to write data to the file.
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// StreamSink<String> sink = fileIO.writeFileAsStream("/path/to/file.txt");
  /// sink.add("Line 1");
  /// sink.add("Line 2");
  /// sink.close();
  /// ```
  dynamic writeFileAsStream(dynamic pathOrData);

  /// Reads bytes from a file.
  ///
  /// This method returns a `Future<List<int>>` which completes with the bytes of the file.
  /// Useful for reading binary files like Excel, images, etc.
  ///
  /// Example usage (desktop):
  /// ```
  /// var fileIO = FileIO();
  /// var bytes = await fileIO.readBytesFromFile("/path/to/file.xlsx");
  /// ```
  Future<List<int>> readBytesFromFile(dynamic pathOrUploadInput);

  /// Writes bytes to a file.
  ///
  /// This method writes binary data to a file.
  /// Useful for writing binary files like Excel, images, etc.
  ///
  /// Example usage (desktop):
  /// ```
  /// var fileIO = FileIO();
  /// await fileIO.writeBytesToFile("/path/to/file.xlsx", bytes);
  /// ```
  Future<void> writeBytesToFile(String path, List<int> bytes);

  /// Checks if a file exists.
  ///
  /// Returns true if the file exists, false otherwise.
  /// On web, this always returns false as file system access is not available.
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// if (await fileIO.fileExists("/path/to/file.txt")) {
  ///   print("File exists");
  /// }
  /// ```
  Future<bool> fileExists(String path);

  /// Checks if a file exists synchronously.
  ///
  /// Returns true if the file exists, false otherwise.
  /// On web, this always returns false as file system access is not available.
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// if (fileIO.fileExistsSync("/path/to/file.txt")) {
  ///   print("File exists");
  /// }
  /// ```
  bool fileExistsSync(String path);

  /// Deletes a file at the specified path.
  ///
  /// Returns true if the file was successfully deleted, false otherwise.
  /// On web, this is a no-op and always returns false.
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// if (await fileIO.deleteFile("/path/to/file.txt")) {
  ///   print("File deleted");
  /// }
  /// ```
  Future<bool> deleteFile(String path);

  /// Opens a file for random access reading.
  ///
  /// On desktop, this opens the file using dart:io's RandomAccessFile.
  /// On web, this loads the entire file into memory and provides random access to it.
  ///
  /// Parameters:
  /// - [pathOrUploadInput]: On desktop, pass the file path as a String.
  ///                        On web, pass the HTMLInputElement or Uint8List data.
  ///
  /// Returns a RandomAccessFileBase implementation for the platform.
  ///
  /// Example usage (desktop):
  /// ```
  /// var fileIO = FileIO();
  /// var raf = await fileIO.openRandomAccess("/path/to/file.dat");
  /// await raf.setPosition(100);
  /// var bytes = await raf.read(50);
  /// await raf.close();
  /// ```
  Future<RandomAccessFileBase> openRandomAccess(dynamic pathOrUploadInput);

  /// Gets the parent directory path of a file.
  ///
  /// On desktop, returns the actual parent directory path.
  /// On web, returns an empty string (no file system concept).
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// var parentPath = fileIO.getParentPath("/path/to/file.txt");
  /// // Returns: "/path/to"
  /// ```
  String getParentPath(String path);

  /// Resolves a relative path against a base path.
  ///
  /// On desktop, properly resolves relative paths using file system semantics.
  /// On web, performs simple string-based path resolution.
  ///
  /// Example usage:
  /// ```
  /// var fileIO = FileIO();
  /// var resolved = fileIO.resolvePath("/base/path", "../other/file.txt");
  /// // Returns: "/base/other/file.txt"
  /// ```
  String resolvePath(String basePath, String relativePath);
}

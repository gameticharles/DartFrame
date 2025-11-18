/// Stub for dart:io on web platform.
library;

class Directory {
  Directory(String path);
  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) async {}
}

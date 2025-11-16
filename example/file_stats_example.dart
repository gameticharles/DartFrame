import 'package:dartframe/dartframe.dart';

/// Example demonstrating file statistics functionality
void main() async {
  final fileIO = FileIO();

  // Example file path (adjust to your system)
  const filePath = 'example/basic_usage.dart';

  print('=== File Statistics Example ===\n');

  // Check if file exists first
  if (await fileIO.fileExists(filePath)) {
    // Get file stats asynchronously
    print('--- Async Stats ---');
    final stats = await fileIO.getFileStats(filePath);
    if (stats != null) {
      print('File: $filePath');
      print(
          'Size: ${stats.size} bytes (${(stats.size / 1024).toStringAsFixed(2)} KB)');
      print('Type: ${stats.type}');
      print('Modified: ${stats.modified}');
      if (stats.accessed != null) {
        print('Accessed: ${stats.accessed}');
      }
      if (stats.changed != null) {
        print('Changed: ${stats.changed}');
      }
      if (stats.mode != null) {
        print('Mode: ${stats.mode!.toRadixString(8)}'); // Octal format
      }
    } else {
      print('Could not retrieve stats for: $filePath');
    }

    print('\n--- Sync Stats ---');
    // Get file stats synchronously
    final statsSync = fileIO.getFileStatsSync(filePath);
    if (statsSync != null) {
      print('File: $filePath');
      print('Size: ${statsSync.size} bytes');
      print('Modified: ${statsSync.modified}');
    }
  } else {
    print('File does not exist: $filePath');
  }

  print('\n--- Non-existent File ---');
  // Try to get stats for non-existent file
  final nonExistentStats = await fileIO.getFileStats('non_existent_file.txt');
  if (nonExistentStats == null) {
    print('Stats returned null for non-existent file (expected behavior)');
  }

  print('\n=== Example Complete ===');
}

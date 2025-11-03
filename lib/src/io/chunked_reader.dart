import 'dart:async';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';

/// A class for reading large files in chunks to manage memory efficiently
class ChunkedReader {
  final String filePath;
  final int chunkSize;
  final String? separator;
  final bool hasHeader;
  final Map<String, dynamic>? options;

  List<String>? _headers;
  bool _isInitialized = false;

  ChunkedReader(
    this.filePath, {
    this.chunkSize = 10000,
    this.separator,
    this.hasHeader = true,
    this.options,
  });

  /// Initializes the chunked reader by reading headers if present
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final fileIO = FileIO();
      final stream = fileIO.readFileAsStream(filePath);

      if (hasHeader) {
        await for (final line in stream) {
          if (line.trim().isNotEmpty) {
            _headers = _parseRow(line);
            break;
          }
        }
      }

      _isInitialized = true;
    } catch (e) {
      throw ChunkedReadError('Failed to initialize chunked reader: $e');
    }
  }

  /// Reads the file in chunks and returns a stream of DataFrames
  Stream<DataFrame> readChunks() async* {
    await _initialize();

    try {
      final fileIO = FileIO();
      final stream = fileIO.readFileAsStream(filePath);

      List<String> currentChunk = [];
      int lineCount = 0;
      int skippedLines = 0;

      await for (final line in stream) {
        // Skip header if present
        if (hasHeader && skippedLines == 0) {
          skippedLines++;
          continue;
        }

        if (line.trim().isNotEmpty) {
          currentChunk.add(line);
          lineCount++;

          if (lineCount >= chunkSize) {
            yield _createDataFrameFromChunk(currentChunk);
            currentChunk.clear();
            lineCount = 0;
          }
        }
      }

      // Process remaining lines
      if (currentChunk.isNotEmpty) {
        yield _createDataFrameFromChunk(currentChunk);
      }
    } catch (e) {
      throw ChunkedReadError('Failed to read chunks: $e');
    }
  }

  /// Reads a specific chunk by index
  Future<DataFrame> readChunk(int chunkIndex) async {
    await _initialize();

    try {
      final fileIO = FileIO();
      final stream = fileIO.readFileAsStream(filePath);

      List<String> targetChunk = [];
      int lineCount = 0;
      int currentChunkIndex = 0;
      int skippedLines = 0;

      await for (final line in stream) {
        // Skip header if present
        if (hasHeader && skippedLines == 0) {
          skippedLines++;
          continue;
        }

        if (line.trim().isNotEmpty) {
          if (currentChunkIndex == chunkIndex) {
            targetChunk.add(line);
            lineCount++;

            if (lineCount >= chunkSize) {
              break;
            }
          } else {
            lineCount++;
            if (lineCount >= chunkSize) {
              currentChunkIndex++;
              lineCount = 0;
            }
          }
        }
      }

      if (targetChunk.isEmpty) {
        throw ChunkedReadError('Chunk index $chunkIndex not found');
      }

      return _createDataFrameFromChunk(targetChunk);
    } catch (e) {
      throw ChunkedReadError('Failed to read chunk $chunkIndex: $e');
    }
  }

  /// Gets the total number of chunks in the file
  Future<int> getChunkCount() async {
    await _initialize();

    try {
      final fileIO = FileIO();
      final stream = fileIO.readFileAsStream(filePath);

      int totalLines = 0;
      int skippedLines = 0;

      await for (final line in stream) {
        // Skip header if present
        if (hasHeader && skippedLines == 0) {
          skippedLines++;
          continue;
        }

        if (line.trim().isNotEmpty) {
          totalLines++;
        }
      }

      return (totalLines / chunkSize).ceil();
    } catch (e) {
      throw ChunkedReadError('Failed to get chunk count: $e');
    }
  }

  /// Gets the headers of the file
  List<String>? get headers => _headers;

  DataFrame _createDataFrameFromChunk(List<String> lines) {
    if (lines.isEmpty) {
      return DataFrame.empty();
    }

    final data = <String, List<dynamic>>{};
    List<String> columnNames;

    if (_headers != null) {
      columnNames = _headers!;
    } else {
      // Use first line as headers if no headers were set
      columnNames = _parseRow(lines[0]);
      lines = lines.skip(1).toList();
    }

    // Initialize columns
    for (final header in columnNames) {
      data[header] = <dynamic>[];
    }

    // Parse data rows
    for (final line in lines) {
      final values = _parseRow(line);
      for (int i = 0; i < columnNames.length; i++) {
        final value = i < values.length ? values[i] : null;
        data[columnNames[i]]!.add(_parseValue(value));
      }
    }

    return DataFrame.fromMap(data);
  }

  List<String> _parseRow(String row) {
    final sep = separator ?? _detectSeparator(row);

    if (sep == ',') {
      return _parseCsvRow(row);
    } else {
      return row.split(sep).map((s) => s.trim()).toList();
    }
  }

  List<String> _parseCsvRow(String row) {
    final values = <String>[];
    final chars = row.split('');
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    values.add(current.trim());
    return values;
  }

  String _detectSeparator(String line) {
    final separators = [',', '\t', ';', '|'];
    int maxCount = 0;
    String bestSeparator = ',';

    for (final sep in separators) {
      final count = sep.allMatches(line).length;
      if (count > maxCount) {
        maxCount = count;
        bestSeparator = sep;
      }
    }

    return bestSeparator;
  }

  dynamic _parseValue(String? value) {
    if (value == null || value.isEmpty || value.toLowerCase() == 'null')
      return null;

    // Remove quotes if present
    String cleanValue = value;
    if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    }

    // Try to parse as number
    final numValue = num.tryParse(cleanValue);
    if (numValue != null) return numValue;

    // Try to parse as boolean
    if (cleanValue.toLowerCase() == 'true') return true;
    if (cleanValue.toLowerCase() == 'false') return false;

    // Try to parse as DateTime
    final dateValue = DateTime.tryParse(cleanValue);
    if (dateValue != null) return dateValue;

    // Return as string
    return cleanValue;
  }
}

/// Streaming data processor for continuous data processing
class StreamingDataProcessor {
  final Stream<String> dataStream;
  final int bufferSize;
  final bool hasHeader;

  List<String>? _headers;
  final StreamController<DataFrame> _controller = StreamController<DataFrame>();

  StreamingDataProcessor(
    this.dataStream, {
    this.bufferSize = 1000,
    this.hasHeader = true,
  });

  /// Processes the data stream and returns a stream of DataFrames
  Stream<DataFrame> process() {
    _processStream();
    return _controller.stream;
  }

  void _processStream() async {
    try {
      List<String> buffer = [];
      bool headerProcessed = false;

      await for (final line in dataStream) {
        if (line.trim().isEmpty) continue;

        // Process header
        if (hasHeader && !headerProcessed) {
          _headers = _parseRow(line);
          headerProcessed = true;
          continue;
        }

        buffer.add(line);

        if (buffer.length >= bufferSize) {
          final df = _createDataFrameFromBuffer(buffer);
          _controller.add(df);
          buffer.clear();
        }
      }

      // Process remaining buffer
      if (buffer.isNotEmpty) {
        final df = _createDataFrameFromBuffer(buffer);
        _controller.add(df);
      }

      await _controller.close();
    } catch (e) {
      _controller
          .addError(StreamingProcessError('Streaming processing failed: $e'));
    }
  }

  DataFrame _createDataFrameFromBuffer(List<String> lines) {
    final data = <String, List<dynamic>>{};
    List<String> columnNames;

    if (_headers != null) {
      columnNames = _headers!;
    } else {
      // Use first line as headers if no headers were set
      columnNames = _parseRow(lines[0]);
      lines = lines.skip(1).toList();
    }

    // Initialize columns
    for (final header in columnNames) {
      data[header] = <dynamic>[];
    }

    // Parse data rows
    for (final line in lines) {
      final values = _parseRow(line);
      for (int i = 0; i < columnNames.length; i++) {
        final value = i < values.length ? values[i] : null;
        data[columnNames[i]]!.add(_parseValue(value));
      }
    }

    return DataFrame.fromMap(data);
  }

  List<String> _parseRow(String row) {
    // Simple CSV parsing - could be enhanced for more complex formats
    return row.split(',').map((s) => s.trim()).toList();
  }

  dynamic _parseValue(String? value) {
    if (value == null || value.isEmpty || value.toLowerCase() == 'null')
      return null;

    // Remove quotes if present
    String cleanValue = value;
    if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    }

    // Try to parse as number
    final numValue = num.tryParse(cleanValue);
    if (numValue != null) return numValue;

    // Try to parse as boolean
    if (cleanValue.toLowerCase() == 'true') return true;
    if (cleanValue.toLowerCase() == 'false') return false;

    // Return as string
    return cleanValue;
  }
}

/// Memory-efficient data loader for large datasets
class MemoryEfficientLoader {
  /// Loads data with automatic memory management
  static Stream<DataFrame> loadLarge(
    String filePath, {
    int chunkSize = 10000,
    bool hasHeader = true,
    String? separator,
  }) {
    final reader = ChunkedReader(
      filePath,
      chunkSize: chunkSize,
      hasHeader: hasHeader,
      separator: separator,
    );

    return reader.readChunks();
  }

  /// Processes data with a custom function while managing memory
  static Stream<DataFrame> processLarge<T>(
    String filePath,
    DataFrame Function(DataFrame) processor, {
    int chunkSize = 10000,
    bool hasHeader = true,
  }) async* {
    final reader = ChunkedReader(
      filePath,
      chunkSize: chunkSize,
      hasHeader: hasHeader,
    );

    await for (final chunk in reader.readChunks()) {
      yield processor(chunk);
    }
  }
}

/// Exception thrown when chunked reading fails
class ChunkedReadError extends Error {
  final String message;
  ChunkedReadError(this.message);

  @override
  String toString() => 'ChunkedReadError: $message';
}

/// Exception thrown when streaming processing fails
class StreamingProcessError extends Error {
  final String message;
  StreamingProcessError(this.message);

  @override
  String toString() => 'StreamingProcessError: $message';
}

import 'byte_writer.dart';
import 'datatype.dart';
import '../../ndarray/ndarray.dart';

/// Writer for HDF5 dataset raw data with memory management
///
/// This class handles writing raw array data to HDF5 files with efficient
/// memory management for large datasets. It supports chunked writing to
/// avoid memory spikes and handles float64 and int64 data types.
///
/// Features:
/// - Chunked writing for large datasets (1MB chunks by default)
/// - Memory-efficient processing
/// - Support for float64 and int64 data types
/// - Contiguous layout writing
///
/// Example usage:
/// ```dart
/// final writer = DataWriter();
/// final dataAddress = await writer.writeData(byteWriter, array);
/// ```
class DataWriter {
  /// Default chunk size for writing data (1MB)
  static const int defaultChunkSize = 1024 * 1024;

  /// Chunk size in number of elements (not bytes)
  final int chunkSize;

  /// Create a DataWriter with optional custom chunk size
  ///
  /// The [chunkSize] parameter specifies how many elements to write at once
  /// before allowing garbage collection. Default is 1MB worth of elements.
  DataWriter({this.chunkSize = defaultChunkSize});

  /// Write raw array data to the byte writer
  ///
  /// This method writes the NDArray data in contiguous layout format,
  /// processing the data in chunks to manage memory efficiently for large
  /// datasets.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write data to
  /// - [array]: The NDArray containing the data to write
  ///
  /// Returns the address where the data was written
  Future<int> writeData(ByteWriter writer, NDArray array) async {
    final dataAddress = writer.position;
    final datatype = _inferDatatype(array);

    // Get flat data from array
    final flatData = array.toFlatList(copy: false);

    // Write data in chunks to manage memory
    await _writeChunked(writer, flatData, datatype);

    return dataAddress;
  }

  /// Write data in chunks to manage memory for large datasets
  ///
  /// This method processes the data in chunks, allowing garbage collection
  /// between chunks to prevent memory spikes with large datasets.
  Future<void> _writeChunked(
    ByteWriter writer,
    List<dynamic> flatData,
    Hdf5Datatype datatype,
  ) async {
    final totalElements = flatData.length;

    // Calculate chunk size in elements based on data type
    final elementSize = datatype.size;
    final elementsPerChunk = chunkSize ~/ elementSize;

    // Write data in chunks
    for (int i = 0; i < totalElements; i += elementsPerChunk) {
      final end = (i + elementsPerChunk < totalElements)
          ? i + elementsPerChunk
          : totalElements;

      // Write chunk
      _writeChunk(writer, flatData, i, end, datatype);

      // Allow garbage collection between chunks for large datasets
      if (i + elementsPerChunk < totalElements) {
        await Future.delayed(Duration.zero);
      }
    }
  }

  /// Write a chunk of data elements
  void _writeChunk(
    ByteWriter writer,
    List<dynamic> flatData,
    int start,
    int end,
    Hdf5Datatype datatype,
  ) {
    if (datatype.dataclass == Hdf5DatatypeClass.float) {
      for (int j = start; j < end; j++) {
        writer.writeFloat64(flatData[j].toDouble());
      }
    } else if (datatype.dataclass == Hdf5DatatypeClass.integer) {
      for (int j = start; j < end; j++) {
        writer.writeInt64(flatData[j].toInt());
      }
    } else {
      throw UnsupportedError(
        'Unsupported data type: ${datatype.dataclass}. '
        'Currently supported: float (float64), integer (int64)',
      );
    }
  }

  /// Infer HDF5 datatype from NDArray
  ///
  /// Examines the first element of the array to determine the data type.
  /// Throws UnsupportedError if the data type is not supported.
  Hdf5Datatype _inferDatatype(NDArray array) {
    // Check the type of the first element to infer the datatype
    final firstValue = array.getValue(List.filled(array.ndim, 0));

    if (firstValue is double) {
      return Hdf5Datatype.float64;
    } else if (firstValue is int) {
      return Hdf5Datatype.int64;
    } else {
      throw UnsupportedError(
        'Unsupported data type: ${firstValue.runtimeType}. '
        'Currently supported: double (float64), int (int64)',
      );
    }
  }

  /// Calculate the total size of the data in bytes
  ///
  /// This is useful for pre-allocating space or validating disk space
  /// before writing.
  int calculateDataSize(NDArray array) {
    final datatype = _inferDatatype(array);
    final elementCount = array.size;
    return elementCount * datatype.size;
  }
}

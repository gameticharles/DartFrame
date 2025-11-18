import 'byte_writer.dart';
import '../../ndarray/ndarray.dart';

/// Base class for storage layout writers
///
/// Storage layout writers handle how dataset data is organized in the HDF5 file.
/// HDF5 supports multiple storage layouts:
/// - Contiguous: Data stored in a single continuous block
/// - Chunked: Data divided into fixed-size chunks for efficient partial I/O
/// - Compact: Small data stored directly in the object header
abstract class StorageLayoutWriter {
  /// Write the layout message for the object header
  ///
  /// Returns the bytes for the data layout message (type 0x0008)
  List<int> writeLayoutMessage();

  /// Write the dataset data to the file
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write data to
  /// - [array]: The NDArray containing the data to write
  ///
  /// Returns the address where the primary data structure was written
  /// (for contiguous: data address, for chunked: B-tree address)
  Future<int> writeData(ByteWriter writer, NDArray array);

  /// Get the layout class identifier
  ///
  /// Layout classes:
  /// - 0: Compact
  /// - 1: Contiguous
  /// - 2: Chunked
  int get layoutClass;
}

/// Calculates chunk coordinates and offsets for chunked datasets
class ChunkCalculator {
  final List<int> datasetDimensions;
  final List<int> chunkDimensions;
  final int dimensionality;

  ChunkCalculator({
    required this.datasetDimensions,
    required this.chunkDimensions,
  }) : dimensionality = datasetDimensions.length {
    if (datasetDimensions.length != chunkDimensions.length) {
      throw ArgumentError(
        'Dataset and chunk dimensions must have the same length: '
        'dataset=${datasetDimensions.length}, chunk=${chunkDimensions.length}',
      );
    }
  }

  /// Calculates the number of chunks in each dimension
  List<int> getNumChunks() {
    final numChunks = <int>[];
    for (int i = 0; i < dimensionality; i++) {
      numChunks.add((datasetDimensions[i] + chunkDimensions[i] - 1) ~/
          chunkDimensions[i]);
    }
    return numChunks;
  }

  /// Calculates the total number of chunks in the dataset
  int getTotalChunks() {
    final numChunks = getNumChunks();
    return numChunks.reduce((a, b) => a * b);
  }

  /// Converts chunk indices to a linear chunk index
  /// For example, in a 2D dataset with chunks [3, 4], chunk [1, 2] -> 1*4 + 2 = 6
  int chunkIndicesToLinear(List<int> chunkIndices) {
    if (chunkIndices.length != dimensionality) {
      throw ArgumentError(
        'Chunk indices must match dimensionality: '
        'expected=$dimensionality, got=${chunkIndices.length}',
      );
    }

    final numChunks = getNumChunks();
    int linearIndex = 0;
    int multiplier = 1;

    // Calculate linear index in row-major order (C-style)
    for (int i = dimensionality - 1; i >= 0; i--) {
      if (chunkIndices[i] >= numChunks[i]) {
        throw ArgumentError(
          'Chunk index out of bounds: dimension=$i, index=${chunkIndices[i]}, max=${numChunks[i] - 1}',
        );
      }
      linearIndex += chunkIndices[i] * multiplier;
      multiplier *= numChunks[i];
    }

    return linearIndex;
  }

  /// Converts a linear chunk index to chunk indices
  List<int> linearToChunkIndices(int linearIndex) {
    final numChunks = getNumChunks();
    final chunkIndices = List<int>.filled(dimensionality, 0);

    int remaining = linearIndex;
    for (int i = dimensionality - 1; i >= 0; i--) {
      chunkIndices[i] = remaining % numChunks[i];
      remaining ~/= numChunks[i];
    }

    return chunkIndices;
  }

  /// Calculates the dataset offset for a given chunk
  /// Returns the starting position [dim0, dim1, ...] in the dataset
  List<int> getChunkOffset(List<int> chunkIndices) {
    if (chunkIndices.length != dimensionality) {
      throw ArgumentError(
        'Chunk indices must match dimensionality: '
        'expected=$dimensionality, got=${chunkIndices.length}',
      );
    }

    final offset = <int>[];
    for (int i = 0; i < dimensionality; i++) {
      offset.add(chunkIndices[i] * chunkDimensions[i]);
    }
    return offset;
  }

  /// Calculates the actual size of a chunk (may be smaller at boundaries)
  List<int> getActualChunkSize(List<int> chunkIndices) {
    if (chunkIndices.length != dimensionality) {
      throw ArgumentError(
        'Chunk indices must match dimensionality: '
        'expected=$dimensionality, got=${chunkIndices.length}',
      );
    }

    final actualSize = <int>[];
    for (int i = 0; i < dimensionality; i++) {
      final offset = chunkIndices[i] * chunkDimensions[i];
      final remaining = datasetDimensions[i] - offset;
      actualSize
          .add(remaining < chunkDimensions[i] ? remaining : chunkDimensions[i]);
    }
    return actualSize;
  }

  /// Calculates the number of elements in a chunk
  int getChunkElementCount(List<int> chunkIndices) {
    final actualSize = getActualChunkSize(chunkIndices);
    return actualSize.reduce((a, b) => a * b);
  }

  /// Converts dataset coordinates to chunk indices
  List<int> datasetCoordsToChunkIndices(List<int> datasetCoords) {
    if (datasetCoords.length != dimensionality) {
      throw ArgumentError(
        'Dataset coordinates must match dimensionality: '
        'expected=$dimensionality, got=${datasetCoords.length}',
      );
    }

    final chunkIndices = <int>[];
    for (int i = 0; i < dimensionality; i++) {
      chunkIndices.add(datasetCoords[i] ~/ chunkDimensions[i]);
    }
    return chunkIndices;
  }

  /// Converts dataset coordinates to coordinates within a chunk
  List<int> datasetCoordsToChunkCoords(List<int> datasetCoords) {
    if (datasetCoords.length != dimensionality) {
      throw ArgumentError(
        'Dataset coordinates must match dimensionality: '
        'expected=$dimensionality, got=${datasetCoords.length}',
      );
    }

    final chunkCoords = <int>[];
    for (int i = 0; i < dimensionality; i++) {
      chunkCoords.add(datasetCoords[i] % chunkDimensions[i]);
    }
    return chunkCoords;
  }
}

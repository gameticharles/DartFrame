import 'package:dartframe/dartframe.dart';

/// Example: Writing multiple datasets with groups
///
/// This example demonstrates how to write multiple datasets to a single HDF5 file
/// with a hierarchical group structure. This is useful for organizing related data
/// together in a single file.
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     Writing Multiple Datasets with Groups Example         ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Example 1: Weather station data with group hierarchy
  print('Example 1: Weather Station Data\n');
  print('Creating multiple measurement datasets...');

  // Create measurement data
  final temperature = NDArray.generate(
    [100, 100],
    (i) => 20.0 + (i[0] * 0.1) + (i[1] * 0.05),
  );

  final pressure = NDArray.generate(
    [100, 100],
    (i) => 1013.0 + (i[0] * 0.5) - (i[1] * 0.2),
  );

  final humidity = NDArray.generate(
    [100, 100],
    (i) => 50.0 + (i[0] * 0.2) + (i[1] * 0.1),
  );

  final windSpeed = NDArray.generate(
    [100, 100],
    (i) => 5.0 + (i[0] * 0.05) + (i[1] * 0.03),
  );

  // Create calibration data
  final calibrationOffsets = NDArray([0.1, 0.2, -0.15, 0.05]);
  final calibrationFactors = NDArray([1.0, 1.05, 0.98, 1.02]);

  // Write all datasets to one file with group structure
  print('Writing to weather_station.h5...');
  await HDF5WriterUtils.writeMultiple('weather_station.h5', {
    '/measurements/temperature': temperature,
    '/measurements/pressure': pressure,
    '/measurements/humidity': humidity,
    '/measurements/wind_speed': windSpeed,
    '/calibration/offsets': calibrationOffsets,
    '/calibration/factors': calibrationFactors,
  });

  print('✓ Weather station data written successfully!\n');
  print('File structure:');
  print('  /measurements/');
  print('    ├── temperature (100x100)');
  print('    ├── pressure (100x100)');
  print('    ├── humidity (100x100)');
  print('    └── wind_speed (100x100)');
  print('  /calibration/');
  print('    ├── offsets (4,)');
  print('    └── factors (4,)');
  print('');

  // Example 2: Scientific experiment with metadata
  print('Example 2: Scientific Experiment Data\n');
  print('Creating experiment datasets with metadata...');

  // Create experimental data
  final rawData = NDArray.generate([500, 300], (i) => i[0] + i[1] * 0.5);
  final processedData =
      NDArray.generate([500, 300], (i) => (i[0] + i[1] * 0.5) * 1.05);
  final backgroundNoise = NDArray.generate([500, 300], (i) => i[0] * 0.01);

  // Create analysis results
  final peaks = NDArray([125.5, 250.3, 375.8, 450.2]);
  final intensities = NDArray([1000.0, 850.0, 920.0, 780.0]);

  // Write with default options (compression enabled)
  print('Writing to experiment.h5 with compression...');
  await HDF5WriterUtils.writeMultiple(
    'experiment.h5',
    {
      '/raw/data': rawData,
      '/raw/background': backgroundNoise,
      '/processed/data': processedData,
      '/analysis/peaks': peaks,
      '/analysis/intensities': intensities,
    },
    defaultOptions: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'experiment_id': 'EXP-2024-001',
        'date': '2024-01-15',
        'researcher': 'Dr. Smith',
      },
    ),
  );

  print('✓ Experiment data written successfully!\n');
  print('File structure:');
  print('  /raw/');
  print('    ├── data (500x300, compressed)');
  print('    └── background (500x300, compressed)');
  print('  /processed/');
  print('    └── data (500x300, compressed)');
  print('  /analysis/');
  print('    ├── peaks (4,)');
  print('    └── intensities (4,)');
  print('');

  // Example 3: Mixed data types with per-dataset options
  print('Example 3: Mixed Data with Per-Dataset Options\n');
  print('Creating datasets with different compression settings...');

  // Large dataset - use maximum compression
  final largeData = NDArray.generate([1000, 1000], (i) => i[0] * 1000 + i[1]);

  // Small dataset - no compression needed
  final smallData = NDArray([1.0, 2.0, 3.0, 4.0, 5.0]);

  // Medium dataset - use fast compression
  final mediumData = NDArray.generate([200, 200], (i) => i[0] + i[1]);

  print('Writing to mixed_data.h5 with per-dataset options...');
  await HDF5WriterUtils.writeMultiple(
    'mixed_data.h5',
    {
      '/large/data': largeData,
      '/small/data': smallData,
      '/medium/data': mediumData,
    },
    defaultOptions: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 6,
    ),
    perDatasetOptions: {
      '/large/data': WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [100, 100],
        compression: CompressionType.gzip,
        compressionLevel: 9, // Maximum compression for large data
        attributes: {'description': 'Large dataset with max compression'},
      ),
      '/small/data': WriteOptions(
        layout: StorageLayout.contiguous, // No chunking for small data
        compression: CompressionType.none,
        attributes: {'description': 'Small dataset, no compression'},
      ),
      '/medium/data': WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.lzf, // Fast compression
        attributes: {'description': 'Medium dataset with fast compression'},
      ),
    },
  );

  print('✓ Mixed data written successfully!\n');
  print('File structure:');
  print('  /large/');
  print('    └── data (1000x1000, gzip level 9)');
  print('  /small/');
  print('    └── data (5,, no compression)');
  print('  /medium/');
  print('    └── data (200x200, lzf compression)');
  print('');

  // Python usage example
  print('═' * 60);
  print('Python Usage Examples:\n');
  print('# Read weather station data');
  print("import h5py");
  print("with h5py.File('weather_station.h5', 'r') as f:");
  print("    temp = f['/measurements/temperature'][:]");
  print("    pressure = f['/measurements/pressure'][:]");
  print("    print(f'Temperature shape: {temp.shape}')");
  print('');
  print('# Read experiment data');
  print("with h5py.File('experiment.h5', 'r') as f:");
  print("    raw = f['/raw/data'][:]");
  print("    processed = f['/processed/data'][:]");
  print("    attrs = dict(f['/raw/data'].attrs)");
  print("    print(f'Experiment ID: {attrs[\"experiment_id\"]}')");
  print('');
  print('# List all datasets');
  print("with h5py.File('weather_station.h5', 'r') as f:");
  print("    def print_structure(name, obj):");
  print("        print(name)");
  print("    f.visititems(print_structure)");
  print('');

  print('═' * 60);
  print('✓ All examples completed successfully!');
}

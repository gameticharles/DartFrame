import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Example demonstrating multi-dataset HDF5 file creation
void main() async {
  print('Creating HDF5 file with multiple datasets...\n');

  // Create a file builder
  final builder = HDF5FileBuilder();

  // Add multiple datasets to the root group
  print('Adding datasets to root group...');
  final temperatures = NDArray.fromFlat([20.5, 21.0, 22.3, 23.1], [4]);
  await builder.addDataset('/temperature', temperatures,
      options: WriteOptions(attributes: {'units': 'celsius'}));

  final pressures = NDArray.fromFlat([1013.25, 1012.5, 1014.0], [3]);
  await builder.addDataset('/pressure', pressures,
      options: WriteOptions(attributes: {'units': 'hPa'}));

  // Create groups and add datasets
  print('Creating groups with datasets...');
  final windSpeed = NDArray.fromFlat([5.2, 6.1, 4.8, 5.5], [4]);
  await builder.addDataset('/weather/wind_speed', windSpeed,
      options: WriteOptions(
          attributes: {'units': 'm/s'}, createIntermediateGroups: true));

  final humidity = NDArray.fromFlat([65.0, 68.0, 70.0, 72.0], [4]);
  await builder.addDataset('/weather/humidity', humidity,
      options: WriteOptions(attributes: {'units': '%'}));

  // Finalize and write to file
  print('Finalizing HDF5 file...');
  final bytes = await builder.finalize();

  final file = File('multi_dataset_example.h5');
  await file.writeAsBytes(bytes);

  print('\nFile created: ${file.path}');
  print('File size: ${bytes.length} bytes');
  print('\nDatasets:');
  print('  /temperature (4 values)');
  print('  /pressure (3 values)');
  print('  /weather/wind_speed (4 values)');
  print('  /weather/humidity (4 values)');
}

import 'package:dartframe/dartframe.dart';

/// Example demonstrating how to read MATLAB v7.3 .mat files
///
/// This example shows various ways to read and inspect MATLAB files.
void main() async {
  // Note: This example requires a MATLAB v7.3 .mat file to run
  // Create one in MATLAB with: save('test_data.mat', 'A', 'B', '-v7.3')

  final matFile = 'example/data/test_data.mat';

  print('=== MATLAB v7.3 File Reader Example ===\n');

  // Example 1: List all variables in the file
  print('Example 1: Listing variables');
  print('-' * 40);
  try {
    final variables = await FileReader.listMATVariables(matFile);
    print('Found ${variables.length} variables:');
    for (final varName in variables) {
      print('  - $varName');
    }
  } catch (e) {
    print('Error: $e');
    print('(Create a test .mat file first)\n');
  }
  print('');

  // Example 2: Inspect file structure
  print('Example 2: Inspecting file structure');
  print('-' * 40);
  try {
    final info = await FileReader.inspectMAT(matFile);
    print('Variable count: ${info['variableCount']}');
    print('Variables: ${info['variables']}');

    final varInfo = info['variableInfo'] as Map;
    for (final entry in varInfo.entries) {
      final v = entry.value as MatlabVariableInfo;
      print('\n${entry.key}:');
      print('  Type: ${v.matlabClass.toMatlabString()}');
      print('  Shape: ${v.shape}');
      print('  Size: ${v.size} elements');
    }
  } catch (e) {
    print('Error: $e\n');
  }
  print('');

  // Example 3: Read a specific variable
  print('Example 3: Reading a specific variable');
  print('-' * 40);
  try {
    // Read a numeric array
    final data = await MATReader.readVariable(matFile, 'A');
    print('Variable A: $data');

    if (data is NDArray) {
      print('  Shape: ${data.shape}');
      print('  Mean: ${data.mean()}');
    }
  } catch (e) {
    print('Error: $e\n');
  }
  print('');

  // Example 4: Read as DataFrame
  print('Example 4: Reading as DataFrame');
  print('-' * 40);
  try {
    final df = await FileReader.readMAT(matFile, variable: 'A');
    print('DataFrame shape: ${df.shape}');
    print(df.head());
  } catch (e) {
    print('Error: $e\n');
  }
  print('');

  // Example 5: Read all variables
  print('Example 5: Reading all variables at once');
  print('-' * 40);
  try {
    final allData = await MATReader.readAll(matFile);
    print('Loaded ${allData.length} variables:');
    for (final entry in allData.entries) {
      print('  ${entry.key}: ${entry.value.runtimeType}');
    }
  } catch (e) {
    print('Error: $e\n');
  }

  print('\n=== Example Complete ===');
}

/// Helper function to create a test MATLAB file
///
/// Run this in MATLAB to create a test file:
/// ```matlab
/// % Create test data
/// A = magic(5);              % 5x5 matrix
/// B = randn(10, 20);         % 10x20 random data
/// names = {'Alice', 'Bob', 'Charlie'};  % Cell array
/// data = struct('x', 1:10, 'y', 'test'); % Structure
///
/// % Save as v7.3
/// save('test_data.mat', 'A', 'B', 'names', 'data', '-v7.3');
/// ```
void createTestFileInstructions() {
  print('''
To create a test MATLAB file, run this in MATLAB:

% Create test data
A = magic(5);              % 5x5 matrix
B = randn(10, 20);         % 10x20 random data
names = {'Alice', 'Bob', 'Charlie'};  % Cell array
data = struct('x', 1:10, 'y', 'test'); % Structure

% Save as v7.3
save('test_data.mat', 'A', 'B', 'names', 'data', '-v7.3');
  ''');
}

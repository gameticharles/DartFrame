% MATLAB Script to Generate Test Files for DartFrame MAT Reader
% This script creates various .mat v7.3 files to test different data types
% 
% Usage: Run this script in MATLAB to generate test files
%        Files will be saved in the current directory

fprintf('Generating MATLAB v7.3 test files for DartFrame...\n\n');

%% Test 1: Basic Numeric Arrays
fprintf('1. Creating test_numeric.mat (numeric arrays)...\n');

% Scalar
scalar_double = 42.5;
scalar_int = int32(100);

% Vectors
vec_row = [1, 2, 3, 4, 5];
vec_col = [10; 20; 30; 40; 50];

% 2D Matrices
matrix_small = magic(5);
matrix_large = randn(100, 50);

% Different numeric types
double_array = [1.1, 2.2, 3.3; 4.4, 5.5, 6.6];
single_array = single([1.1, 2.2; 3.3, 4.4]);
int8_array = int8([1, 2, 3; 4, 5, 6]);
uint8_array = uint8([10, 20, 30; 40, 50, 60]);
int16_array = int16([100, 200; 300, 400]);
uint16_array = uint16([1000, 2000; 3000, 4000]);
int32_array = int32([10000, 20000; 30000, 40000]);
uint32_array = uint32([100000, 200000; 300000, 400000]);
int64_array = int64([1e10, 2e10; 3e10, 4e10]);
uint64_array = uint64([1e12, 2e12; 3e12, 4e12]);

save('test_numeric.mat', 'scalar_double', 'scalar_int', 'vec_row', 'vec_col', ...
     'matrix_small', 'matrix_large', 'double_array', 'single_array', ...
     'int8_array', 'uint8_array', 'int16_array', 'uint16_array', ...
     'int32_array', 'uint32_array', 'int64_array', 'uint64_array', '-v7.3');

fprintf('   ✓ test_numeric.mat created\n\n');

%% Test 2: Strings and Characters
fprintf('2. Creating test_strings.mat (strings and character arrays)...\n');

% Character arrays
char_scalar = 'Hello';
char_array = ['Hello'; 'World'; 'Test!'];
char_2d = char('MATLAB', 'Dart', 'Python');

% String arrays (MATLAB R2016b+)
if exist('string', 'builtin')
    str_scalar = "Hello World";
    str_array = ["Alice", "Bob", "Charlie"];
    str_2d = ["A", "B"; "C", "D"];
    
    save('test_strings.mat', 'char_scalar', 'char_array', 'char_2d', ...
         'str_scalar', 'str_array', 'str_2d', '-v7.3');
else
    save('test_strings.mat', 'char_scalar', 'char_array', 'char_2d', '-v7.3');
end

fprintf('   ✓ test_strings.mat created\n\n');

%% Test 3: Logical Arrays
fprintf('3. Creating test_logical.mat (logical/boolean arrays)...\n');

logical_scalar = true;
logical_vector = [true, false, true, false, true];
logical_matrix = [true, false, true; false, true, false; true, true, false];
logical_from_comparison = magic(5) > 15;

save('test_logical.mat', 'logical_scalar', 'logical_vector', ...
     'logical_matrix', 'logical_from_comparison', '-v7.3');

fprintf('   ✓ test_logical.mat created\n\n');

%% Test 4: Cell Arrays
fprintf('4. Creating test_cells.mat (cell arrays)...\n');

% Simple cell array
cell_simple = {1, 'hello', true};

% Mixed type cell array
cell_mixed = {42, 'test', [1,2,3], magic(3), true};

% 2D cell array
cell_2d = {1, 2, 3; 'a', 'b', 'c'; true, false, true};

% Nested cell array
cell_nested = {{1, 2}, {'a', 'b'}, {true, false}};

% Cell array with matrices
cell_matrices = {magic(3), randn(2,2), eye(4)};

save('test_cells.mat', 'cell_simple', 'cell_mixed', 'cell_2d', ...
     'cell_nested', 'cell_matrices', '-v7.3');

fprintf('   ✓ test_cells.mat created\n\n');

%% Test 5: Structures
fprintf('5. Creating test_structures.mat (structure arrays)...\n');

% Simple structure
struct_simple.name = 'Alice';
struct_simple.age = 30;
struct_simple.scores = [85, 90, 95];

% Nested structure
struct_nested.person.name = 'Bob';
struct_nested.person.age = 25;
struct_nested.location.city = 'NYC';
struct_nested.location.country = 'USA';

% Structure array
people(1).name = 'Alice';
people(1).age = 30;
people(1).scores = [85, 90, 95];

people(2).name = 'Bob';
people(2).age = 25;
people(2).scores = [78, 88, 92];

people(3).name = 'Charlie';
people(3).age = 35;
people(3).scores = [90, 95, 88];

% Structure with various field types
struct_mixed.id = 101;
struct_mixed.name = 'Test';
struct_mixed.values = [1, 2, 3, 4, 5];
struct_mixed.matrix = magic(4);
struct_mixed.flag = true;
struct_mixed.metadata = struct('version', 1.0, 'date', '2024-01-01');

save('test_structures.mat', 'struct_simple', 'struct_nested', ...
     'people', 'struct_mixed', '-v7.3');

fprintf('   ✓ test_structures.mat created\n\n');

%% Test 6: Complex Scenarios
fprintf('6. Creating test_complex.mat (complex mixed data)...\n');

% Mix of everything
experiment_data.id = 12345;
experiment_data.name = 'Experiment A';
experiment_data.samples = randn(1000, 10);
experiment_data.labels = {'Sample1', 'Sample2', 'Sample3', 'Sample4', 'Sample5', ...
                          'Sample6', 'Sample7', 'Sample8', 'Sample9', 'Sample10'};
experiment_data.metadata.date = '2024-01-15';
experiment_data.metadata.researcher = 'Dr. Smith';
experiment_data.metadata.lab = 'Lab 42';
experiment_data.results.mean = mean(randn(1000, 10));
experiment_data.results.std = std(randn(1000, 10));
experiment_data.results.significant = [true, false, true, false, true, false, true, false, true, false];

% Large dataset
large_matrix = randn(500, 200);
large_cell = cell(10, 10);
for i = 1:10
    for j = 1:10
        large_cell{i,j} = randn(5, 5);
    end
end

save('test_complex.mat', 'experiment_data', 'large_matrix', 'large_cell', '-v7.3');

fprintf('   ✓ test_complex.mat created\n\n');

%% Test 7: Edge Cases
fprintf('7. Creating test_edge_cases.mat (edge cases and special values)...\n');

% Empty arrays
empty_double = [];
empty_char = '';
empty_cell = {};
empty_struct = struct();

% Special values
inf_value = inf;
neg_inf = -inf;
nan_value = nan;
special_array = [1, inf, -inf, nan, 2];

% Very small and large values
tiny_value = eps;
huge_value = realmax;

% Single element arrays
single_element = 42;
single_cell = {42};

save('test_edge_cases.mat', 'empty_double', 'empty_char', 'empty_cell', ...
     'empty_struct', 'inf_value', 'neg_inf', 'nan_value', 'special_array', ...
     'tiny_value', 'huge_value', 'single_element', 'single_cell', '-v7.3');

fprintf('   ✓ test_edge_cases.mat created\n\n');

%% Test 8: Multidimensional Arrays
fprintf('8. Creating test_multidim.mat (3D and higher dimensional arrays)...\n');

% 3D array
array_3d = randn(5, 4, 3);

% 4D array
array_4d = randn(3, 3, 3, 3);

% Higher dimensional
array_5d = randn(2, 2, 2, 2, 2);

save('test_multidim.mat', 'array_3d', 'array_4d', 'array_5d', '-v7.3');

fprintf('   ✓ test_multidim.mat created\n\n');

%% Summary
fprintf('========================================\n');
fprintf('Test file generation complete!\n');
fprintf('========================================\n\n');

fprintf('Generated files:\n');
fprintf('  1. test_numeric.mat      - Various numeric types\n');
fprintf('  2. test_strings.mat      - Character and string arrays\n');
fprintf('  3. test_logical.mat      - Boolean/logical arrays\n');
fprintf('  4. test_cells.mat        - Cell arrays (simple and nested)\n');
fprintf('  5. test_structures.mat   - Structure arrays\n');
fprintf('  6. test_complex.mat      - Complex mixed data\n');
fprintf('  7. test_edge_cases.mat   - Edge cases and special values\n');
fprintf('  8. test_multidim.mat     - Multidimensional arrays\n\n');

fprintf('Copy these files to your test/data/ directory in DartFrame\n');
fprintf('Then run: dart test test/mat_reader_test.dart\n');

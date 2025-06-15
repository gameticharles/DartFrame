import 'package:dartframe/dartframe.dart';

void main() async {
  final df = DataFrame([
    [1, 2, 3.0],
    [4, 5, 6],
    [7, 'hi', 9]
  ], index: [
    'Dog',
    'Dog',
    'Catty'
  ], columns: [
    'a',
    'b',
    'c'
  ]);

  print(df);

  // Create or update a column via name
  df['a'] = [1, 2, 3];
  print(df);

  // Access and modify column data by index
  df[2] = [30.0, 'newDate', 5.0];
  print(df);

  // Modify a specific element in the 'a' column
  df['a'][2] = 30;
  print(df);

  print(df['a'][2] * 2);

  // listEqualTest();
  dataframe1();
  // dataframe2();
}

void listEqualTest() {
  print('=== Enhanced List Equality Function Tests ===\n');

  // Basic usage examples
  print('=== Basic Usage Examples ===');
  print(listEqual([
    [1, 2, 3],
    [1, 2, 3]
  ])); // true
  print(listEqual([
    [1, 2, 3],
    [1, 2, 4]
  ])); // false
  print(listEqual([
    [1, 2, 3],
    [3, 2, 1]
  ])); // false (order matters)

  // Multiple lists
  print('\n=== Multiple Lists Comparison ===');
  print(listEqual([
    [1, 2],
    [1, 2],
    [1, 2]
  ])); // true
  print(listEqual([
    [1, 2],
    [1, 2],
    [1, 3]
  ])); // false

  // Unordered comparison
  print('\n=== Unordered Comparison ===');
  print(listEqual([
    [1, 2, 3],
    [3, 2, 1]
  ], ListEqualPresets.unordered)); // true
  print(listEqual([
    ['a', 'b', 'c'],
    ['c', 'a', 'b']
  ], ListEqualPresets.unordered)); // true

  // String options
  print('\n=== String Comparison Options ===');
  print(listEqual([
    ['Hello', ' World '],
    ['hello', 'world']
  ], ListEqualPresets.flexibleString)); // true

  // Numeric tolerance
  print('\n=== Numeric Tolerance ===');
  const numericConfig = ListEqualConfig(numericTolerance: 0.01);
  print(listEqual([
    [1.0, 2.0],
    [1.001, 2.001]
  ], numericConfig)); // true

  // Deep comparison
  print('\n=== Deep Comparison ===');
  print(listEqual([
    [
      1,
      [2, 3],
      {'a': 4}
    ],
    [
      1,
      [2, 3],
      {'a': 4}
    ]
  ], ListEqualPresets.deep)); // true

  // Flexible comparison
  print('\n=== Flexible Comparison ===');
  print(listEqual([
    ['1', '2'],
    [1, 2]
  ], ListEqualPresets.flexible)); // true

  // Custom comparators
  print('\n=== Custom Comparators ===');
  final customConfig = ListEqualConfig(customComparators: {
    DateTime: (a, b) =>
        (a as DateTime).millisecondsSinceEpoch ==
        (b as DateTime).millisecondsSinceEpoch,
  });
  final date1 = DateTime(2023, 1, 1);
  final date2 = DateTime(2023, 1, 1);
  print(listEqual([
    [date1],
    [date2]
  ], customConfig)); // true

  // Detailed comparison results
  print('\n=== Detailed Comparison Results ===');
  final result = listEqualDetailed([
    [1, 2, 3],
    [1, 2, 4]
  ]);
  print('Result: $result');

  // Extension method usage
  print('\n=== Extension Method Usage ===');
  final list1 = [1, 2, 3];
  final list2 = [1, 2, 3];
  print('Extension method result: ${list1.isEqualTo(list2)}'); // true

  // Performance test simulation
  print('\n=== Performance Test (Simulated) ===');
  final largeList1 = List.generate(1000, (i) => i);
  final largeList2 = List.generate(1000, (i) => i);
  final perfResult =
      listEqualDetailed([largeList1, largeList2], ListEqualPresets.optimized);
  print(
      'Large list comparison: ${perfResult.isEqual} (${perfResult.elapsedTime.inMicroseconds}μs)');

  // Type-specific comparisons
  print('\n=== Type-specific Comparisons ===');

  // DateTime comparison
  final now1 = DateTime.now();
  final now2 = DateTime.fromMillisecondsSinceEpoch(now1.millisecondsSinceEpoch);
  print('DateTime comparison: ${listEqual([
        [now1],
        [now2]
      ])}'); // true

  // Duration comparison
  final duration1 = const Duration(hours: 1, minutes: 30);
  final duration2 = const Duration(minutes: 90);
  print('Duration comparison: ${listEqual([
        [duration1],
        [duration2]
      ])}'); // true

  // RegExp comparison
  final regex1 = RegExp(r'\d+', caseSensitive: false);
  final regex2 = RegExp(r'\d+', caseSensitive: false);
  print('RegExp comparison: ${listEqual([
        [regex1],
        [regex2]
      ])}'); // true

  // Boolean coercion in flexible mode
  print('\n=== Boolean Coercion (Flexible Mode) ===');
  print(listEqual([
    ['true', 1, 'yes'],
    [true, true, true]
  ], ListEqualPresets.flexible)); // true

  // Error handling
  print('\n=== Error Handling ===');
  try {
    listEqual([]);
  } catch (e) {
    print('Caught expected error: $e');
  }

  // Circular reference detection
  print('\n=== Circular Reference Detection ===');
  try {
    final circularList = <dynamic>[1, 2];
    circularList.add(circularList); // Create circular reference

    final result = listEqualDetailed([
      circularList,
      [1, 2, 'something']
    ], ListEqualPresets.safeDeep);
    print('Circular reference handled: ${result.isEqual}');
  } catch (e) {
    print('Circular reference detected: $e');
  }

  // Nested structure comparison
  print('\n=== Complex Nested Structures ===');
  final complex1 = [
    1,
    [
      2,
      3,
      [4, 5]
    ],
    {
      'a': 6,
      'b': [7, 8]
    },
    {9, 10, 11}
  ];
  final complex2 = [
    1,
    [
      2,
      3,
      [4, 5]
    ],
    {
      'a': 6,
      'b': [7, 8]
    },
    {9, 10, 11}
  ];
  print('Complex nested: ${listEqual([
        complex1,
        complex2
      ], ListEqualPresets.deep)}'); // true

  // Mixed type flexible comparison
  print('\n=== Mixed Type Flexible Comparison ===');
  final mixed1 = ['1', 2.0, true, '4.5'];
  final mixed2 = [1, 2, 1, 4.5];
  print('Mixed types flexible: ${listEqual([
        mixed1,
        mixed2
      ], ListEqualPresets.flexible)}'); // true

  print('\n=== All Tests Completed ===');
}

void dataframe1() async {
  // Load the CSV data into a DataFrame and tries to convert string to the right type
  var df = await DataFrame.fromCSV(
    // Added await
    csv: csvData,
    formatData: true,
    missingDataIndicator: ['<NA>', 'NA'],
    replaceMissingValueWith: null, //'NaN'
  );

  // Data Exploration
  print('Shape: ${df.shape}');
  print('Dimension: ${df.dimension}\n');
  print('List Columns:\n${df.columns}');
  print(df.tail(5)); // View the last 5 rows
  print(df.head(5)); // View the first 5 rows
  print(df.limit(10,
      startIndex: 5)); // View some number of rows starting at an index
  print('Describe Data:\n${df.describe()}\n'); // Summary statistics
  print(
      'Structure:\n${df.structure()}\n'); // Get the structure of the dataframe

  // Data Cleaning
  df.replaceInPlace('<NA>', null); // Replace the missing values with null
  df = df.replace('<NA>', null);
  df = df.fillna('Unknown'); // Fill missing values with 'Unknown'

  // Data Analysis
  var dfGrouped = df.groupBy('area');
  print(dfGrouped);
  print(df.valueCounts('area')); //Count the freq. of each value in a column
  print(dfGrouped['Brent']); // Get Brent data

  // Average price per area
  dfGrouped.forEach((key, value) {
    Series priceColumn = value['price'];
    print('$key Mean: ${priceColumn.mean()}');
  });

  // Add a new column using calculations
  Series deliveryMinSeries = df['delivery_min'];
  df['delivery_time_over_30'] = deliveryMinSeries > 30;
  print('\nDelivery Mins > 30:\n${df['delivery_time_over_30']}\n');

  // Get only data with match the criteria
  print(df[df['delivery_time_over_30']]);

  // Get specific column
  print(df['date']);
  print(df[1]);
  print(df.column('date'));
  print(df.column(1));

  df.toJSON();
  //String jsonString = jsonEncode(df.toJSON());
  //print(jsonString);

  // Table manipulation
  print(df.head(5));
  df.rename({"date": "Date"});
  print(df.columns);
  df.drop('index');
  print(df.head(5));
  df.fillna('Charles');
  print(df.head(5));
}

void dataframe2() {
  Series numbers = Series([1, 2, 3, 4], name: "Numbers");

  // Update a single element
  numbers[1] = 10;

  // Update multiple elements
  numbers[[0, 2]] = [5, 6];

  // Update based on a condition
  numbers[numbers > 7] = 99;

  print(numbers);
  print(numbers.mean());

  // Series concatenation
  Series s1 = Series([1, 2, 3], name: 'A');
  Series s2 = Series([4, 5, 6], name: 'B');

// Vertical concatenation
  Series sVertical = s1.concatenate(s2);
  print(sVertical);

// Horizontal concatenation
  Series sHorizontal = s1.concatenate(s2, axis: 1);
  print(sHorizontal);

// DataFrame concatenation
  var df1 = DataFrame(columns: [
    'A',
    'B'
  ], [
    [1, 2],
    [3, 4]
  ]);
  var df2 = DataFrame(columns: [
    'A',
    'B'
  ], [
    [5, 6],
    [7, 8]
  ]);
  var df3 = DataFrame([
    [10, 11],
    [12, 13]
  ], columns: [
    'C',
    'D'
  ]);

// Vertical concatenation
  var dfVertical = df1.concatenate([df2]);

// Horizontal concatenation
  var dfHorizontal = df1.concatenate([df3], axis: 1);
  print(dfHorizontal);
  print(dfVertical);

  // print(s_horizontal);

  var df = DataFrame(
    columns: ['A', 'B', 'C', 'D'],
    [
      [1, 2.5, 3, 4],
      [2, 3.5, 4, 5],
      [3, 4.5, 5, 6],
      [4, 5.5, 6, 7],
    ],
  );

  // Describe the DataFrame
  print(df.describe());

  df = DataFrame(
    allowFlexibleColumns: true,
    [
      [1, 'A'],
      [2, 'B'],
      [3, 'C'],
      [4, 'D'],
    ],
  );

  print('Before shuffle:');
  print(df);

// new columns
  df.columns = ['ID', 'Letter', 'Free'];

  // Shuffle without a seed
  var newDf = df.shuffle();
  print('After random shuffle:');
  print(newDf);

  df.columns = ['id', 'alpha'];

  // Shuffle with a seed for reproducibility
  newDf = df.shuffle(seed: 123);
  print('After shuffle with seed:');
  print(newDf);
}

var csvData = """
index,date,week,weekday,area,count,rabate,price,operator,driver,delivery_min,temperature,wine_ordered,wine_delivered,wrongpizza,quality
1,01/03/2014,9,6,Camden,5,TRUE,65.655,Rhonda,Taylor,20,53,0,0,FALSE,medium
2,01/03/2014,9,6,Westminster,2,FALSE,26.98,Rhonda,Butcher,19.6,56.4,0,0,FALSE,high
3,01/03/2014,9,6,Westminster,3,FALSE,40.97,Allanah,Butcher,17.8,36.5,0,0,FALSE,NA
4,01/03/2014,9,6,Brent,2,FALSE,25.98,Allanah,Taylor,37.3,NA,0,0,FALSE,NA
5,01/03/2014,9,6,Brent,5,TRUE,57.555,Rhonda,Carter,21.8,50,0,0,FALSE,medium
6,01/03/2014,9,6,Camden,1,FALSE,13.99,Allanah,Taylor,48.7,27,0,0,FALSE,low
7,01/03/2014,9,6,Camden,4,TRUE,89.442,Rhonda,Taylor,49.3,33.9,1,1,FALSE,low
8,01/03/2014,9,6,Brent,NA,NA,NA,Allanah,Taylor,25.6,54.8,NA,NA,FALSE,high
9,01/03/2014,9,6,Westminster,3,FALSE,40.97,Allanah,Taylor,26.4,48,0,0,FALSE,high
10,01/03/2014,9,6,Brent,6,TRUE,84.735,Rhonda,Carter,24.3,54.4,1,1,FALSE,medium
11,01/03/2014,9,6,Westminster,3,FALSE,66.41,Allanah,Miller,11.7,28.8,1,1,FALSE,low
12,01/03/2014,9,6,Brent,5,TRUE,62.955,Rhonda,Carter,19.5,51.3,0,0,FALSE,medium
13,01/03/2014,9,6,Camden,4,TRUE,46.764,Allanah,Taylor,32.7,24.05,0,0,FALSE,low
14,01/03/2014,9,6,Camden,1,FALSE,49.95,Rhonda,Carter,38.8,35.7,1,1,FALSE,low
15,01/03/2014,9,6,Brent,6,TRUE,73.746,Rhonda,Carter,23,53.6,0,0,FALSE,medium
16,01/03/2014,9,6,Westminster,5,TRUE,57.555,Rhonda,Miller,30.8,51.3,0,0,FALSE,<NA>
17,<NA>,NA,NA,Brent,2,FALSE,26.98,Allanah,Carter,27.7,51,0,0,FALSE,high
18,01/03/2014,9,6,Brent,2,FALSE,27.98,Rhonda,Butcher,29.7,47.7,0,0,FALSE,medium
19,01/03/2014,9,6,Brent,3,FALSE,41.97,Rhonda,Carter,9.1,52.8,0,0,FALSE,medium
20,01/03/2014,9,6,Westminster,1,FALSE,11.99,Rhonda,Miller,37.3,20,0,0,FALSE,low
21,01/03/2014,9,6,Brent,4,TRUE,46.764,Allanah,Butcher,21.2,52.4,0,0,FALSE,<NA>
22,01/03/2014,9,6,Brent,4,TRUE,52.164,Rhonda,Butcher,10.6,55.1,0,0,FALSE,medium
23,01/03/2014,9,6,Westminster,3,FALSE,44.97,Rhonda,Butcher,19.5,26.7,0,0,FALSE,low
24,01/03/2014,9,6,Camden,4,TRUE,51.264,Rhonda,Taylor,31,49.8,0,0,FALSE,medium
25,01/03/2014,9,6,Westminster,3,FALSE,38.97,Allanah,Miller,20.8,32.5,0,0,FALSE,low
26,01/03/2014,9,6,Brent,5,TRUE,58.455,Allanah,Taylor,18,36.8,0,0,FALSE,medium
27,01/03/2014,9,6,Brent,5,TRUE,97.065,Rhonda,Butcher,25.6,51,1,1,FALSE,medium
28,01/03/2014,9,6,Westminster,6,TRUE,75.546,Allanah,Miller,11.8,54.4,0,0,FALSE,high
29,01/03/2014,9,6,Camden,5,TRUE,65.655,Rhonda,Taylor,36.5,46.2,0,0,FALSE,medium
30,01/03/2014,9,6,Westminster,2,FALSE,30.98,Rhonda,Butcher,17.4,56.4,0,0,FALSE,<NA>
31,01/03/2014,9,6,Camden,2,FALSE,26.98,Allanah,Carter,23.5,35.7,0,0,FALSE,medium
32,01/03/2014,9,6,Westminster,4,TRUE,51.264,Rhonda,Butcher,24.2,49.1,0,0,FALSE,medium
33,01/03/2014,9,6,Brent,5,TRUE,61.155,Allanah,Carter,15,53.3,0,0,FALSE,<NA>
34,01/03/2014,9,6,Camden,3,FALSE,42.97,Allanah,Carter,36.2,41.7,0,0,FALSE,<NA>
35,01/03/2014,9,6,Westminster,2,FALSE,25.98,Rhonda,Taylor,25.9,47.6,0,0,FALSE,<NA>
36,01/03/2014,9,6,Westminster,5,TRUE,57.555,Allanah,Butcher,32.4,30.3,0,0,FALSE,low
37,01/03/2014,9,6,Brent,3,FALSE,44.97,Allanah,Butcher,15.4,37.8,0,0,FALSE,medium
38,01/03/2014,9,6,Brent,4,TRUE,48.564,Rhonda,Taylor,30.6,23.55,0,0,FALSE,low
39,01/03/2014,9,6,Brent,3,FALSE,40.97,Allanah,Taylor,27.9,49.9,0,0,FALSE,high
40,01/03/2014,9,6,Camden,4,TRUE,49.464,Allanah,Taylor,23,50.7,0,0,FALSE,high
41,01/03/2014,9,6,Brent,2,FALSE,24.98,Rhonda,Taylor,39.7,20.45,0,0,FALSE,low
42,01/03/2014,9,6,Westminster,6,TRUE,74.646,Allanah,Miller,29.1,25.85,0,0,FALSE,low
43,01/03/2014,9,6,Camden,3,FALSE,38.97,Rhonda,Taylor,34.4,43.8,0,0,FALSE,medium
44,02/03/2014,9,7,Camden,4,TRUE,92.466,Rhonda,Farmer,9.5,54.2,1,0,FALSE,medium
45,02/03/2014,9,7,Camden,1,FALSE,56.43,Allanah,Farmer,11.2,55.2,1,1,FALSE,high
46,02/03/2014,9,7,Westminster,4,TRUE,44.964,Rhonda,Farmer,14.4,55.9,0,0,FALSE,high
47,02/03/2014,9,7,Brent,4,TRUE,78.957,Allanah,Hunter,9.2,22.2,1,1,FALSE,low
48,02/03/2014,9,7,Brent,1,FALSE,13.99,Allanah,Hunter,11.9,52.8,0,0,FALSE,high
49,02/03/2014,9,7,Brent,4,TRUE,89.154,Allanah,Butcher,9.4,41,1,1,FALSE,medium
50,02/03/2014,9,7,Brent,3,FALSE,37.97,Allanah,Taylor,21.4,33.2,0,0,FALSE,low
51,02/03/2014,9,7,Brent,2,FALSE,29.98,Rhonda,Hunter,11.5,54.5,0,0,FALSE,medium
52,02/03/2014,9,7,Brent,3,FALSE,47.97,Allanah,Hunter,15.7,54.4,0,0,FALSE,<NA>
53,02/03/2014,9,7,Camden,1,FALSE,13.99,Allanah,Taylor,27.2,46,0,0,FALSE,<NA>
54,02/03/2014,9,7,Camden,3,FALSE,75.47,Rhonda,Taylor,27.7,26.3,1,1,FALSE,low
55,02/03/2014,9,7,Camden,6,TRUE,74.646,Rhonda,Farmer,23.7,51.1,0,0,FALSE,medium
56,02/03/2014,9,7,Camden,3,FALSE,36.97,Rhonda,Farmer,18.2,26.35,0,0,FALSE,low
57,02/03/2014,9,7,Westminster,4,TRUE,49.464,Allanah,Hunter,17.1,37.8,0,0,FALSE,medium
58,02/03/2014,9,7,Camden,1,FALSE,13.99,Rhonda,Farmer,19.9,51.5,0,0,FALSE,<NA>
59,02/03/2014,9,7,Camden,3,FALSE,79.67,Rhonda,Farmer,21.9,53.1,1,1,FALSE,<NA>
60,02/03/2014,9,7,Westminster,2,FALSE,63.78,Rhonda,Farmer,15.5,54.5,1,1,FALSE,medium
61,02/03/2014,9,7,Camden,4,TRUE,54.864,Allanah,Taylor,25.4,48.8,0,0,FALSE,high
62,02/03/2014,9,7,Camden,2,FALSE,25.98,Rhonda,Taylor,25.6,50.3,0,0,FALSE,medium
12,01/03/2014,9,6,Brent,5,TRUE,62.955,Rhonda,Carter,19.5,51.3,0,0,FALSE,medium
13,01/03/2014,9,6,Camden,4,TRUE,46.764,Allanah,Taylor,32.7,24.05,0,0,FALSE,low
14,01/03/2014,9,6,Camden,1,FALSE,49.95,Rhonda,Carter,38.8,35.7,1,1,FALSE,low
15,01/03/2014,9,6,Brent,6,TRUE,73.746,Rhonda,Carter,23,53.6,0,0,FALSE,medium
16,01/03/2014,9,6,Westminster,5,TRUE,57.555,Rhonda,Miller,30.8,51.3,0,0,FALSE,<NA>
17,<NA>,NA,NA,Brent,2,FALSE,26.98,Allanah,Carter,27.7,51,0,0,FALSE,high
18,01/03/2014,9,6,Brent,2,FALSE,27.98,Rhonda,Butcher,29.7,47.7,0,0,FALSE,medium
19,01/03/2014,9,6,Brent,3,FALSE,41.97,Rhonda,Carter,9.1,52.8,0,0,FALSE,medium
20,01/03/2014,9,6,Westminster,1,FALSE,11.99,Rhonda,Miller,37.3,20,0,0,FALSE,low
21,01/03/2014,9,6,Brent,4,TRUE,46.764,Allanah,Butcher,21.2,52.4,0,0,FALSE,<NA>
22,01/03/2014,9,6,Brent,4,TRUE,52.164,Rhonda,Butcher,10.6,55.1,0,0,FALSE,medium
23,01/03/2014,9,6,Westminster,3,FALSE,44.97,Rhonda,Butcher,19.5,26.7,0,0,FALSE,low
24,01/03/2014,9,6,Camden,4,TRUE,51.264,Rhonda,Taylor,31,49.8,0,0,FALSE,medium
25,01/03/2014,9,6,Westminster,3,FALSE,38.97,Allanah,Miller,20.8,32.5,0,0,FALSE,low
26,01/03/2014,9,6,Brent,5,TRUE,58.455,Allanah,Taylor,18,36.8,0,0,FALSE,medium
27,01/03/2014,9,6,Brent,5,TRUE,97.065,Rhonda,Butcher,25.6,51,1,1,FALSE,medium
28,01/03/2014,9,6,Westminster,6,TRUE,75.546,Allanah,Miller,11.8,54.4,0,0,FALSE,high
29,01/03/2014,9,6,Camden,5,TRUE,65.655,Rhonda,Taylor,36.5,46.2,0,0,FALSE,medium
30,01/03/2014,9,6,Westminster,2,FALSE,30.98,Rhonda,Butcher,17.4,56.4,0,0,FALSE,<NA>
31,01/03/2014,9,6,Camden,2,FALSE,26.98,Allanah,Carter,23.5,35.7,0,0,FALSE,medium
32,01/03/2014,9,6,Westminster,4,TRUE,51.264,Rhonda,Butcher,24.2,49.1,0,0,FALSE,medium
33,01/03/2014,9,6,Brent,5,TRUE,61.155,Allanah,Carter,15,53.3,0,0,FALSE,<NA>
34,01/03/2014,9,6,Camden,3,FALSE,42.97,Allanah,Carter,36.2,41.7,0,0,FALSE,<NA>
35,01/03/2014,9,6,Westminster,2,FALSE,25.98,Rhonda,Taylor,25.9,47.6,0,0,FALSE,<NA>
36,01/03/2014,9,6,Westminster,5,TRUE,57.555,Allanah,Butcher,32.4,30.3,0,0,FALSE,low
37,01/03/2014,9,6,Brent,3,FALSE,44.97,Allanah,Butcher,15.4,37.8,0,0,FALSE,medium
38,01/03/2014,9,6,Brent,4,TRUE,48.564,Rhonda,Taylor,30.6,23.55,0,0,FALSE,low
39,01/03/2014,9,6,Brent,3,FALSE,40.97,Allanah,Taylor,27.9,49.9,0,0,FALSE,high
40,01/03/2014,9,6,Camden,4,TRUE,49.464,Allanah,Taylor,23,50.7,0,0,FALSE,high
41,01/03/2014,9,6,Brent,2,FALSE,24.98,Rhonda,Taylor,39.7,20.45,0,0,FALSE,low
42,01/03/2014,9,6,Westminster,6,TRUE,74.646,Allanah,Miller,29.1,25.85,0,0,FALSE,low
43,01/03/2014,9,6,Camden,3,FALSE,38.97,Rhonda,Taylor,34.4,43.8,0,0,FALSE,medium
44,02/03/2014,9,7,Camden,4,TRUE,92.466,Rhonda,Farmer,9.5,54.2,1,0,FALSE,medium
45,02/03/2014,9,7,Camden,1,FALSE,56.43,Allanah,Farmer,11.2,55.2,1,1,FALSE,high
46,02/03/2014,9,7,Westminster,4,TRUE,44.964,Rhonda,Farmer,14.4,55.9,0,0,FALSE,high
47,02/03/2014,9,7,Brent,4,TRUE,78.957,Allanah,Hunter,9.2,22.2,1,1,FALSE,low
48,02/03/2014,9,7,Brent,1,FALSE,13.99,Allanah,Hunter,11.9,52.8,0,0,FALSE,high
49,02/03/2014,9,7,Brent,4,TRUE,89.154,Allanah,Butcher,9.4,41,1,1,FALSE,medium
50,02/03/2014,9,7,Brent,3,FALSE,37.97,Allanah,Taylor,21.4,33.2,0,0,FALSE,low
51,02/03/2014,9,7,Brent,2,FALSE,29.98,Rhonda,Hunter,11.5,54.5,0,0,FALSE,medium
52,02/03/2014,9,7,Brent,3,FALSE,47.97,Allanah,Hunter,15.7,54.4,0,0,FALSE,<NA>
53,02/03/2014,9,7,Camden,1,FALSE,13.99,Allanah,Taylor,27.2,46,0,0,FALSE,<NA>
54,02/03/2014,9,7,Camden,3,FALSE,75.47,Rhonda,Taylor,27.7,26.3,1,1,FALSE,low
55,02/03/2014,9,7,Camden,6,TRUE,74.646,Rhonda,Farmer,23.7,51.1,0,0,FALSE,medium
56,02/03/2014,9,7,Camden,3,FALSE,36.97,Rhonda,Farmer,18.2,26.35,0,0,FALSE,low
57,02/03/2014,9,7,Westminster,4,TRUE,49.464,Allanah,Hunter,17.1,37.8,0,0,FALSE,medium
58,02/03/2014,9,7,Camden,1,FALSE,13.99,Rhonda,Farmer,19.9,51.5,0,0,FALSE,<NA>
59,02/03/2014,9,7,Camden,3,FALSE,79.67,Rhonda,Farmer,21.9,53.1,1,1,FALSE,<NA>
60,02/03/2014,9,7,Westminster,2,FALSE,63.78,Rhonda,Farmer,15.5,54.5,1,1,FALSE,medium
61,02/03/2014,9,7,Camden,4,TRUE,54.864,Allanah,Taylor,25.4,48.8,0,0,FALSE,high
62,02/03/2014,9,7,Camden,2,FALSE,25.98,Rhonda,Taylor,25.6,50.3,0,0,FALSE,medium
""";

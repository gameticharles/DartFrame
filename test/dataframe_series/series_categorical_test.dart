import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series Categorical Operations', () {
    late Series<String> stringSeries;
    late Series<int> numericSeries;
    late Series<String> mixedSeries;

    setUp(() {
      stringSeries = Series(['A', 'B', 'A', 'C', 'B', 'A'], name: 'categories');
      numericSeries = Series([1, 2, 1, 3, 2, 1], name: 'numeric_categories');
      mixedSeries =
          Series(['A', 'B', 'A', null, 'B', 'A'], name: 'mixed_categories');
    });

    group('Categorical Creation and Conversion', () {
      test('Convert Series to categorical', () {
        stringSeries.astype('category');

        expect(stringSeries.isCategorical, isTrue);
        expect(stringSeries.seriesDtype, equals('category'));
        expect(stringSeries.cat, isNotNull);
      });

      test('Convert Series to categorical with custom categories', () {
        final customCategories = ['A', 'B', 'C', 'D'];
        stringSeries.astype('category', categories: customCategories);

        expect(stringSeries.cat!.categories, equals(customCategories));
        expect(stringSeries.cat!.nCategories, equals(4));
      });

      test('Convert Series to ordered categorical', () {
        stringSeries.astype('category', ordered: true);

        expect(stringSeries.cat!.ordered, isTrue);
      });

      test('Convert numeric Series to categorical', () {
        numericSeries.astype('category');

        expect(numericSeries.isCategorical, isTrue);
        expect(numericSeries.cat!.categories, equals([1, 2, 3]));
      });

      test('Convert Series with null values to categorical', () {
        mixedSeries.astype('category');

        expect(mixedSeries.isCategorical, isTrue);
        expect(mixedSeries.cat!.categories, equals(['A', 'B']));
        expect(mixedSeries.data, equals(['A', 'B', 'A', null, 'B', 'A']));
      });

      test('Return null when accessing cat on non-categorical Series', () {
        expect(stringSeries.cat, isNull);
      });
    });

    group('Categorical Properties and Access', () {
      setUp(() {
        stringSeries.astype('category');
        numericSeries.astype('category', ordered: true);
      });

      test('Access categorical properties', () {
        expect(stringSeries.cat!.categories, equals(['A', 'B', 'C']));
        expect(stringSeries.cat!.codes, equals([0, 1, 0, 2, 1, 0]));
        expect(stringSeries.cat!.nCategories, equals(3));
        expect(stringSeries.cat!.ordered, isFalse);
      });

      test('Access ordered categorical properties', () {
        expect(numericSeries.cat!.ordered, isTrue);
        expect(numericSeries.cat!.categories, equals([1, 2, 3]));
      });

      test('Get unique categories', () {
        final unique = stringSeries.cat!.unique();
        expect(unique, containsAll(['A', 'B', 'C']));
        expect(unique.length, equals(3));
      });

      test('Check if categorical contains value', () {
        expect(stringSeries.cat!.contains('A'), isTrue);
        expect(stringSeries.cat!.contains('D'), isFalse);
      });
    });

    group('Category Manipulation', () {
      setUp(() {
        stringSeries.astype('category');
      });

      test('Add new categories', () {
        stringSeries.cat!.addCategories(['D', 'E']);

        expect(stringSeries.cat!.categories, equals(['A', 'B', 'C', 'D', 'E']));
        expect(stringSeries.cat!.nCategories, equals(5));
      });

      test('Add categories without modifying in place', () {
        final newSeries =
            stringSeries.cat!.addCategories(['D'], inplace: false);

        expect(stringSeries.cat!.categories, equals(['A', 'B', 'C']));
        expect(newSeries.cat!.categories, equals(['A', 'B', 'C', 'D']));
      });

      test('Remove unused categories', () {
        stringSeries.cat!.addCategories(['D', 'E']);
        stringSeries.cat!.removeCategories(['D', 'E']);

        expect(stringSeries.cat!.categories, equals(['A', 'B', 'C']));
      });

      test('Throw error when removing used categories', () {
        expect(() => stringSeries.cat!.removeCategories(['A']),
            throwsA(isA<ArgumentError>()));
      });

      test('Rename categories', () {
        final renameMap = {'A': 'Alpha', 'B': 'Beta'};
        stringSeries.cat!.renameCategories(renameMap);

        expect(stringSeries.cat!.categories, equals(['Alpha', 'Beta', 'C']));
        expect(stringSeries.data,
            equals(['Alpha', 'Beta', 'Alpha', 'C', 'Beta', 'Alpha']));
      });

      test('Reorder categories', () {
        final newOrder = ['C', 'A', 'B'];
        stringSeries.cat!.reorderCategories(newOrder);

        expect(stringSeries.cat!.categories, equals(['C', 'A', 'B']));
        expect(stringSeries.cat!.codes, equals([1, 2, 1, 0, 2, 1]));
      });

      test('Throw error when reordering with missing categories', () {
        expect(() => stringSeries.cat!.reorderCategories(['A', 'B']),
            throwsA(isA<ArgumentError>()));
      });
    });

    group('Ordered vs Unordered Categories', () {
      late Series<String> orderedSeries;
      late Series<String> unorderedSeries;

      setUp(() {
        orderedSeries =
            Series(['small', 'large', 'medium', 'small'], name: 'sizes');
        unorderedSeries =
            Series(['red', 'blue', 'green', 'red'], name: 'colors');

        orderedSeries.astype('category',
            categories: ['small', 'medium', 'large'], ordered: true);
        unorderedSeries.astype('category');
      });

      test('Ordered categorical properties', () {
        expect(orderedSeries.cat!.ordered, isTrue);
        expect(orderedSeries.cat!.categories,
            equals(['small', 'medium', 'large']));
      });

      test('Unordered categorical properties', () {
        expect(unorderedSeries.cat!.ordered, isFalse);
        expect(unorderedSeries.cat!.categories,
            containsAll(['red', 'blue', 'green']));
      });

      test('Reorder categories and change ordered status', () {
        unorderedSeries.cat!
            .reorderCategories(['blue', 'green', 'red'], ordered: true);

        expect(unorderedSeries.cat!.ordered, isTrue);
        expect(
            unorderedSeries.cat!.categories, equals(['blue', 'green', 'red']));
      });
    });

    group('Categorical Data Integrity', () {
      setUp(() {
        stringSeries.astype('category');
      });

      test('Data consistency after category operations', () {
        final originalData = List.from(stringSeries.data);

        // Add and remove categories
        stringSeries.cat!.addCategories(['D']);
        stringSeries.cat!.removeCategories(['D']);

        expect(stringSeries.data, equals(originalData));
      });

      test('Codes consistency after reordering', () {
        final originalData = List.from(stringSeries.data);

        stringSeries.cat!.reorderCategories(['B', 'C', 'A']);

        expect(stringSeries.data, equals(originalData));
      });

      test('Handle null values correctly', () {
        mixedSeries.astype('category');

        expect(mixedSeries.cat!.codes, equals([0, 1, 0, -1, 1, 0]));
        expect(mixedSeries.data[3], isNull);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Empty Series categorical conversion', () {
        final emptySeries = Series<String>([], name: 'empty');
        emptySeries.astype('category');

        expect(emptySeries.isCategorical, isTrue);
        expect(emptySeries.cat!.categories, isEmpty);
        expect(emptySeries.cat!.codes, isEmpty);
      });

      test('Single value Series', () {
        final singleSeries = Series(['A'], name: 'single');
        singleSeries.astype('category');

        expect(singleSeries.cat!.categories, equals(['A']));
        expect(singleSeries.cat!.codes, equals([0]));
      });

      test('All null values Series', () {
        final nullSeries = Series<String?>([null, null, null], name: 'nulls');
        nullSeries.astype('category');

        expect(nullSeries.cat!.categories, isEmpty);
        expect(nullSeries.cat!.codes, equals([-1, -1, -1]));
      });

      test('Invalid category value in initial data', () {
        expect(() {
          final invalidSeries = Series(['A', 'B', 'C'], name: 'invalid');
          invalidSeries.astype('category',
              categories: ['A', 'B']); // C is not in categories
        }, throwsA(isA<ArgumentError>()));
      });
    });
  });

  group('Performance Tests', () {
    test('Large categorical dataset creation', () {
      // Create a large dataset with repeated categorical values
      final largeData = List.generate(100000, (i) => 'Category${i % 100}');
      final largeSeries = Series(largeData, name: 'large_categorical');

      final stopwatch = Stopwatch()..start();
      largeSeries.astype('category');
      stopwatch.stop();

      expect(largeSeries.isCategorical, isTrue);
      expect(largeSeries.cat!.nCategories, equals(100));
      expect(stopwatch.elapsedMilliseconds,
          lessThan(5000)); // Should complete within 5 seconds
    });

    test('Large categorical operations performance', () {
      final largeData = List.generate(50000, (i) => 'Cat${i % 50}');
      final largeSeries = Series(largeData, name: 'large_ops');
      largeSeries.astype('category');

      final stopwatch = Stopwatch()..start();

      // Perform various operations
      largeSeries.cat!.addCategories(['NewCat1', 'NewCat2']);
      largeSeries.cat!.unique();
      largeSeries.cat!.contains('Cat25');
      largeSeries.cat!.removeCategories(['NewCat1', 'NewCat2']);

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds,
          lessThan(2000)); // Should complete within 2 seconds
    });

    test('Memory efficiency of categorical vs object dtype', () {
      // This is a conceptual test - in a real scenario you'd measure actual memory usage
      final repeatedData = List.generate(10000, (i) => 'Category${i % 10}');

      final objectSeries =
          Series(List.from(repeatedData), name: 'object_series');
      final categoricalSeries =
          Series(List.from(repeatedData), name: 'categorical_series');

      categoricalSeries.astype('category');

      // Categorical should have fewer unique categories stored
      expect(categoricalSeries.cat!.nCategories, equals(10));
      expect(categoricalSeries.cat!.codes.length, equals(10000));

      // Verify data integrity
      expect(categoricalSeries.data, equals(objectSeries.data));
    });
  });

  group('Categorical Utility Methods', () {
    test('isCategoricalLike detection', () {
      final highlyRepeated =
          Series(['A', 'B', 'A', 'B', 'A', 'B'], name: 'repeated');
      final mostlyUnique =
          Series(['A', 'B', 'C', 'D', 'E', 'F'], name: 'unique');

      expect(highlyRepeated.isCategoricalLike(), isTrue);
      expect(mostlyUnique.isCategoricalLike(), isFalse);
    });

    test('isCategoricalLike with custom threshold', () {
      final series = Series(['A', 'B', 'C', 'A'],
          name: 'test'); // 3 unique out of 4 = 0.75 ratio

      expect(series.isCategoricalLike(threshold: 0.8), isTrue);
      expect(series.isCategoricalLike(threshold: 0.7), isFalse);
    });

    test('Convert back from categorical to object', () {
      final testSeries =
          Series(['A', 'B', 'A', 'C', 'B', 'A'], name: 'categories');
      testSeries.astype('category');
      expect(testSeries.isCategorical, isTrue);

      testSeries.astype('object');
      expect(testSeries.isCategorical, isFalse);
      expect(testSeries.seriesDtype, equals('object'));
    });
  });

  group('Categorical Arithmetic Operations', () {
    late Series<String> stringCategorical;
    late Series<int> numericCategorical;

    setUp(() {
      stringCategorical = Series(['A', 'B', 'A', 'C'], name: 'string_cat');
      numericCategorical = Series([1, 2, 1, 3], name: 'numeric_cat');

      stringCategorical.astype('category');
      numericCategorical.astype('category');
    });

    test('Addition operation converts to object dtype', () {
      final result = numericCategorical + 10;

      expect(result.data, equals([11, 12, 11, 13]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('String concatenation with addition', () {
      final result = stringCategorical + stringCategorical;

      expect(result.data, equals(['AA', 'BB', 'AA', 'CC']));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Subtraction operation converts to object dtype', () {
      final result = numericCategorical - 1;

      expect(result.data, equals([0, 1, 0, 2]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Multiplication operation converts to object dtype', () {
      final result = numericCategorical * 2;

      expect(result.data, equals([2, 4, 2, 6]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Division operation converts to object dtype', () {
      final result = numericCategorical / 2;

      expect(result.data, equals([0.5, 1.0, 0.5, 1.5]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Division by zero handling', () {
      final result = numericCategorical / 0;

      // Should return missing values for division by zero
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Series-to-Series arithmetic operations', () {
      final other = Series([1, 1, 1, 1], name: 'other');
      final result = numericCategorical + other;

      expect(result.data, equals([2, 3, 2, 4]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Floor division operation', () {
      final result = numericCategorical ~/ 2;

      expect(result.data, equals([0, 1, 0, 1]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Modulo operation', () {
      final result = numericCategorical % 2;

      expect(result.data, equals([1, 0, 1, 1]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });
  });

  group('Categorical Comparison Operations', () {
    late Series<String> stringCategorical1;
    late Series<String> stringCategorical2;
    late Series<int> numericCategorical;

    setUp(() {
      stringCategorical1 = Series(['A', 'B', 'A', 'C'], name: 'cat1');
      stringCategorical2 = Series(['A', 'B', 'B', 'C'], name: 'cat2');
      numericCategorical = Series([1, 2, 1, 3], name: 'numeric_cat');

      stringCategorical1.astype('category');
      stringCategorical2.astype('category');
      numericCategorical.astype('category');
    });

    test('Equality comparison between categorical Series', () {
      final result = stringCategorical1.isEqual(stringCategorical2);

      expect(result.data, equals([true, true, false, true]));
      expect(result.name, equals('cat1 == cat2'));
    });

    test('Optimized equality comparison with identical categories', () {
      // Create Series with same category order for optimization
      final cat1 = Series(['A', 'B', 'A', 'C'], name: 'opt_cat1');
      final cat2 = Series(['A', 'B', 'B', 'C'], name: 'opt_cat2');

      cat1.astype('category', categories: ['A', 'B', 'C']);
      cat2.astype('category', categories: ['A', 'B', 'C']);

      final result = cat1.isEqual(cat2);

      expect(result.data, equals([true, true, false, true]));
      expect(cat1.cat!.categories, equals(cat2.cat!.categories));
    });

    test('Scalar equality comparison', () {
      final result = stringCategorical1.isEqual('A');

      expect(result.data, equals([true, false, true, false]));
      expect(result.name, equals('cat1 == A'));
    });

    test('Numeric comparison operations', () {
      final greaterThan = numericCategorical > 1;
      final lessThan = numericCategorical < 3;
      final greaterEqual = numericCategorical >= 2;
      final lessEqual = numericCategorical <= 2;

      expect(greaterThan.data, equals([false, true, false, true]));
      expect(lessThan.data, equals([true, true, true, false]));
      expect(greaterEqual.data, equals([false, true, false, true]));
      expect(lessEqual.data, equals([true, true, true, false]));
    });

    test('Comparison with scalar values', () {
      final equalToTwo = numericCategorical.isEqual(2);
      final greaterThanOne = numericCategorical > 1;

      expect(equalToTwo.data, equals([false, true, false, false]));
      expect(greaterThanOne.data, equals([false, true, false, true]));
    });

    test('Not equal comparison', () {
      final result = stringCategorical1.notEqual(stringCategorical2);

      expect(result.data, equals([false, false, true, false]));
      expect(result.name, equals('cat1 != cat2'));
    });
  });

  group('Categorical Bitwise Operations', () {
    late Series<int> numericCategorical;

    setUp(() {
      numericCategorical = Series([1, 2, 4, 8], name: 'bitwise_cat');
      numericCategorical.astype('category');
    });

    test('Bitwise AND operation', () {
      final result = numericCategorical & 3;

      expect(result.data, equals([1, 2, 0, 0]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Bitwise OR operation', () {
      final result = numericCategorical | 1;

      expect(result.data, equals([1, 3, 5, 9]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Bitwise XOR operation', () {
      final result = numericCategorical ^ 1;

      expect(result.data, equals([0, 3, 5, 9]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });

    test('Series-to-Series bitwise operations', () {
      final other = Series([1, 1, 1, 1], name: 'other');
      final result = numericCategorical & other;

      expect(result.data, equals([1, 0, 0, 0]));
      expect(result.seriesDtype, equals('object'));
      expect(result.isCategorical, isFalse);
    });
  });

  group('Categorical Operations Error Handling', () {
    late Series<String> stringCategorical;
    late Series<int> numericCategorical;

    setUp(() {
      stringCategorical = Series(['A', 'B', 'A', 'C'], name: 'string_cat');
      numericCategorical = Series([1, 2, 1, 3], name: 'numeric_cat');

      stringCategorical.astype('category');
      numericCategorical.astype('category');
    });

    test('Arithmetic operations on string categories behavior', () {
      // String concatenation works with addition
      final addResult = stringCategorical + stringCategorical;
      expect(addResult.data, equals(['AA', 'BB', 'AA', 'CC']));
      expect(addResult.isCategorical, isFalse);

      // Other operations return missing values for incompatible operations
      final subResult = stringCategorical - stringCategorical;
      expect(subResult.isCategorical, isFalse);
      expect(subResult.seriesDtype, equals('object'));

      // Multiplication with number attempts string repetition or returns missing values
      final multResult = stringCategorical * 2;
      expect(multResult.isCategorical, isFalse);
      expect(multResult.seriesDtype, equals('object'));
    });

    test('Comparison operations with different length Series', () {
      final shortSeries = Series(['A', 'B'], name: 'short');
      shortSeries.astype('category');

      expect(() => stringCategorical.isEqual(shortSeries), throwsException);
      expect(() => stringCategorical > shortSeries, throwsException);
    });

    test('Operations with incompatible types', () {
      // Operations with incompatible types should throw exceptions
      expect(() => stringCategorical + DateTime.now(), throwsException);
      expect(() => numericCategorical & 'invalid', throwsException);
      expect(() => stringCategorical + [], throwsException);
    });
  });

  group('Categorical Operations Performance', () {
    test('Large categorical Series operations performance', () {
      final largeData = List.generate(50000, (i) => i % 100);
      final largeSeries = Series(largeData, name: 'large_numeric_cat');
      largeSeries.astype('category');

      final stopwatch = Stopwatch()..start();

      // Perform various operations
      final addResult = largeSeries + 1;
      final multResult = largeSeries * 2;
      final compResult = largeSeries > 50;
      final eqResult = largeSeries.isEqual(25);

      stopwatch.stop();

      expect(addResult.length, equals(50000));
      expect(multResult.length, equals(50000));
      expect(compResult.length, equals(50000));
      expect(eqResult.length, equals(50000));
      expect(stopwatch.elapsedMilliseconds,
          lessThan(3000)); // Should complete within 3 seconds
    });

    test('Optimized categorical comparison performance', () {
      final data1 = List.generate(10000, (i) => 'Cat${i % 10}');
      final data2 = List.generate(10000, (i) => 'Cat${(i + 1) % 10}');

      final series1 = Series(data1, name: 'perf_cat1');
      final series2 = Series(data2, name: 'perf_cat2');

      // Use same categories for optimization
      final categories = List.generate(10, (i) => 'Cat$i');
      series1.astype('category', categories: categories);
      series2.astype('category', categories: categories);

      final stopwatch = Stopwatch()..start();
      final result = series1.isEqual(series2);
      stopwatch.stop();

      expect(result.length, equals(10000));
      expect(stopwatch.elapsedMilliseconds,
          lessThan(1000)); // Should be fast due to optimization
    });
  });
}

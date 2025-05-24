import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dartframe/dartframe.dart'; // Assuming this is the correct import path

// Helper for generating random data
final Random _random = Random(42); // Seed for reproducibility

// --- Creation Benchmarks ---
class SeriesCreationIntBenchmark extends BenchmarkBase {
  final int size;
  late List<int> data;

  SeriesCreationIntBenchmark(this.size) : super('Series.creation.int(size:$size)');

  @override
  void setup() {
    data = List.generate(size, (i) => _random.nextInt(size));
  }

  @override
  void run() {
    Series(data, name: 'test_int_series');
  }
}

class SeriesCreationDoubleBenchmark extends BenchmarkBase {
  final int size;
  late List<double> data;

  SeriesCreationDoubleBenchmark(this.size) : super('Series.creation.double(size:$size)');

  @override
  void setup() {
    data = List.generate(size, (i) => _random.nextDouble() * size);
  }

  @override
  void run() {
    Series(data, name: 'test_double_series');
  }
}

class SeriesCreationStringBenchmark extends BenchmarkBase {
  final int size;
  late List<String> data;

  SeriesCreationStringBenchmark(this.size) : super('Series.creation.string(size:$size)');

  @override
  void setup() {
    data = List.generate(size, (i) => 'item_${_random.nextInt(size)}');
  }

  @override
  void run() {
    Series(data, name: 'test_string_series');
  }
}

class SeriesCreationDateTimeBenchmark extends BenchmarkBase {
  final int size;
  late List<DateTime> data;
  final DateTime start = DateTime(2020, 1, 1);

  SeriesCreationDateTimeBenchmark(this.size) : super('Series.creation.dateTime(size:$size)');

  @override
  void setup() {
    data = List.generate(size, (i) => start.add(Duration(days: _random.nextInt(365 * 5))));
  }

  @override
  void run() {
    Series(data, name: 'test_datetime_series');
  }
}

class SeriesCreationWithIndexBenchmark extends BenchmarkBase {
  final int size;
  late List<int> data;
  late List<String> index;

  SeriesCreationWithIndexBenchmark(this.size) : super('Series.creation.withIndex(size:$size)');

  @override
  void setup() {
    data = List.generate(size, (i) => i);
    index = List.generate(size, (i) => 'idx_$i');
  }

  @override
  void run() {
    Series(data, name: 'test_indexed_series', index: index);
  }
}

// --- sort_values() Benchmarks ---
class SeriesSortValuesIntBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesSortValuesIntBenchmark(this.size) : super('Series.sort_values.int(size:$size)');

  @override
  void setup() {
    final data = List.generate(size, (i) => _random.nextInt(size * 10));
    s = Series(data, name: 'sort_int');
  }

  @override
  void run() {
    s.sort_values();
  }
}

class SeriesSortValuesStringBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesSortValuesStringBenchmark(this.size) : super('Series.sort_values.string(size:$size)');

  @override
  void setup() {
    final data = List.generate(size, (i) => 'val_${_random.nextInt(size * 100)}');
    s = Series(data, name: 'sort_string');
  }

  @override
  void run() {
    s.sort_values();
  }
}

class SeriesSortValuesWithMissingBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesSortValuesWithMissingBenchmark(this.size) : super('Series.sort_values.withMissing(size:$size)');

  @override
  void setup() {
    final data = List<int?>.generate(size, (i) {
      return _random.nextDouble() < 0.2 ? null : _random.nextInt(size * 10); // 20% missing
    });
    s = Series(data, name: 'sort_missing_int');
  }

  @override
  void run() {
    s.sort_values();
  }
}

// --- sort_index() Benchmark ---
class SeriesSortIndexBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesSortIndexBenchmark(this.size) : super('Series.sort_index(size:$size)');

  @override
  void setup() {
    final data = List.generate(size, (i) => i);
    var stringIndex = List.generate(size, (i) => 'idx_${_random.nextInt(size * 10)}');
    // No need to shuffle stringIndex explicitly for benchmark, as sort_index sorts it.
    s = Series(data, name: 'sort_by_index', index: stringIndex);
  }

  @override
  void run() {
    s.sort_index();
  }
}

// --- apply() Benchmarks ---
class SeriesApplySimpleMathBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesApplySimpleMathBenchmark(this.size) : super('Series.apply.simpleMath(size:$size)');

  @override
  void setup() {
    s = Series(List.generate(size, (i) => i), name: 'apply_math');
  }

  @override
  void run() {
    s.apply((x) => x * 2);
  }
}

class SeriesApplyToStringBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesApplyToStringBenchmark(this.size) : super('Series.apply.toString(size:$size)');

  @override
  void setup() {
    s = Series(List.generate(size, (i) => i), name: 'apply_string');
  }

  @override
  void run() {
    s.apply((x) => x.toString());
  }
}

// --- isin() Benchmark ---
class SeriesIsInBenchmark extends BenchmarkBase {
  final int size;
  final int lookupSize;
  late Series s;
  late List<int> lookupValues;

  SeriesIsInBenchmark(this.size, this.lookupSize) : super('Series.isin(size:$size,lookups:$lookupSize)');

  @override
  void setup() {
    s = Series(List.generate(size, (i) => _random.nextInt(size * 2)), name: 'isin_series');
    lookupValues = List.generate(lookupSize, (i) => _random.nextInt(size * 2));
  }

  @override
  void run() {
    s.isin(lookupValues);
  }
}

// --- fillna() Benchmarks ---
class SeriesFillNaFfillBenchmark extends BenchmarkBase {
  final int size;
  final double missingPercentage;
  late Series s;

  SeriesFillNaFfillBenchmark(this.size, this.missingPercentage)
      : super('Series.fillna.ffill(size:$size,missing:${(missingPercentage*100).toInt()}%)');

  @override
  void setup() {
    final data = List<double?>.generate(size, (i) {
      return _random.nextDouble() < missingPercentage ? null : _random.nextDouble() * 100;
    });
    s = Series(data, name: 'fillna_ffill');
  }

  @override
  void run() {
    s.fillna(method: 'ffill');
  }
}

class SeriesFillNaBfillBenchmark extends BenchmarkBase {
  final int size;
  final double missingPercentage;
  late Series s;

  SeriesFillNaBfillBenchmark(this.size, this.missingPercentage)
      : super('Series.fillna.bfill(size:$size,missing:${(missingPercentage*100).toInt()}%)');

  @override
  void setup() {
    final data = List<double?>.generate(size, (i) {
      return _random.nextDouble() < missingPercentage ? null : _random.nextDouble() * 100;
    });
    s = Series(data, name: 'fillna_bfill');
  }

  @override
  void run() {
    s.fillna(method: 'bfill');
  }
}

// --- .dt Accessor Benchmarks ---
class SeriesDtYearBenchmark extends BenchmarkBase {
  final int size;
  late Series s;
  final DateTime baseDate = DateTime(2000, 1, 1);

  SeriesDtYearBenchmark(this.size) : super('Series.dt.year(size:$size)');

  @override
  void setup() {
    final data = List.generate(size, (i) => baseDate.add(Duration(days: _random.nextInt(10000))));
    s = Series(data, name: 'dt_series');
  }

  @override
  void run() {
    s.dt.year;
  }
}

class SeriesDtDayOfWeekBenchmark extends BenchmarkBase {
  final int size;
  late Series s;
  final DateTime baseDate = DateTime(2000, 1, 1);

  SeriesDtDayOfWeekBenchmark(this.size) : super('Series.dt.weekday(size:$size)');

  @override
  void setup() {
    final data = List.generate(size, (i) => baseDate.add(Duration(days: _random.nextInt(10000))));
    s = Series(data, name: 'dt_series');
  }

  @override
  void run() {
    s.dt.weekday;
  }
}

class SeriesDtDateBenchmark extends BenchmarkBase {
  final int size;
  late Series s;
  final DateTime baseDate = DateTime(2000, 1, 1);

  SeriesDtDateBenchmark(this.size) : super('Series.dt.date(size:$size)');

  @override
  void setup() {
    final data = List.generate(size, (i) => baseDate.add(Duration(days: _random.nextInt(10000), hours: _random.nextInt(24))));
    s = Series(data, name: 'dt_series');
  }

  @override
  void run() {
    s.dt.date;
  }
}

// --- Arithmetic Operations Benchmarks ---
class SeriesAddScalarBenchmark extends BenchmarkBase {
  final int size;
  late Series s;

  SeriesAddScalarBenchmark(this.size) : super('Series.add.scalar(size:$size)');

  @override
  void setup() {
    s = Series(List.generate(size, (i) => i), name: 'arith_series');
  }

  @override
  void run() {
    s + 5; // Assumes Series + scalar is implemented
  }
}

class SeriesAddSeriesBenchmark extends BenchmarkBase {
  final int size;
  late Series s1;
  late Series s2;

  SeriesAddSeriesBenchmark(this.size) : super('Series.add.series(size:$size)');

  @override
  void setup() {
    s1 = Series(List.generate(size, (i) => i), name: 's1');
    s2 = Series(List.generate(size, (i) => i * 2), name: 's2');
  }

  @override
  void run() {
    s1 + s2; // Assumes Series + Series is implemented with aligned indexes
  }
}


void main() {
  final sizes = [100, 1000, 10000, 100000, 1000000]; // Updated sizes
  final missingPercentages = [0.1, 0.5]; // 10%, 50%
  final lookupSizes = [10, 100];

  for (var size in sizes) {
    SeriesCreationIntBenchmark(size).report();
    SeriesCreationDoubleBenchmark(size).report();
    SeriesCreationStringBenchmark(size).report();
    SeriesCreationDateTimeBenchmark(size).report();
    SeriesCreationWithIndexBenchmark(size).report();

    SeriesSortValuesIntBenchmark(size).report();
    SeriesSortValuesStringBenchmark(size).report();
    SeriesSortValuesWithMissingBenchmark(size).report();
    
    SeriesSortIndexBenchmark(size).report();

    SeriesApplySimpleMathBenchmark(size).report();
    SeriesApplyToStringBenchmark(size).report();

    for (var lookupSize in lookupSizes) {
      if (lookupSize <= size) { // Meaningful to have lookup size smaller or equal
        SeriesIsInBenchmark(size, lookupSize).report();
      }
    }
    
    for (var perc in missingPercentages) {
      SeriesFillNaFfillBenchmark(size, perc).report();
      SeriesFillNaBfillBenchmark(size, perc).report();
    }

    SeriesDtYearBenchmark(size).report();
    SeriesDtDayOfWeekBenchmark(size).report();
    SeriesDtDateBenchmark(size).report();
    
    SeriesAddScalarBenchmark(size).report();
    SeriesAddSeriesBenchmark(size).report();
  }
}

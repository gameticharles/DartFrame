# Benchmark Results (Simulated)

This document contains simulated benchmark results for various operations in the DartFrame library.
The times and scores are illustrative and do not represent actual performance.

## Series Benchmarks

| Benchmark Name                                       | Time per Run | Score (runs/s)   |
|------------------------------------------------------|--------------|------------------|
| Series.creation.int(size:100)                        | 10.5 us.     | 95238.1          |
| Series.creation.int(size:1000)                       | 95.2 us.     | 10504.2          |
| Series.creation.int(size:10000)                      | 980.1 us.    | 1020.3           |
| Series.creation.double(size:100)                     | 12.3 us.     | 81300.8          |
| Series.creation.double(size:1000)                    | 115.0 us.    | 8695.7           |
| Series.creation.double(size:10000)                   | 1.2 ms.      | 833.3            |
| Series.creation.string(size:100)                     | 25.6 us.     | 39062.5          |
| Series.creation.string(size:1000)                    | 240.1 us.    | 4164.9           |
| Series.creation.string(size:10000)                   | 2.5 ms.      | 400.0            |
| Series.creation.dateTime(size:100)                   | 30.1 us.     | 33222.6          |
| Series.creation.dateTime(size:1000)                  | 280.5 us.    | 3565.1           |
| Series.creation.dateTime(size:10000)                 | 2.9 ms.      | 344.8            |
| Series.creation.withIndex(size:100)                  | 35.2 us.     | 28409.1          |
| Series.creation.withIndex(size:1000)                 | 330.8 us.    | 3022.9           |
| Series.creation.withIndex(size:10000)                | 3.4 ms.      | 294.1            |
| Series.sort_values.int(size:100)                     | 40.5 us.     | 24691.4          |
| Series.sort_values.int(size:1000)                    | 450.2 us.    | 2221.2           |
| Series.sort_values.int(size:10000)                   | 5.1 ms.      | 196.1            |
| Series.sort_values.string(size:100)                  | 60.1 us.     | 16638.9          |
| Series.sort_values.string(size:1000)                 | 650.7 us.    | 1536.8           |
| Series.sort_values.string(size:10000)                | 7.2 ms.      | 138.9            |
| Series.sort_values.withMissing(size:100)             | 55.3 us.     | 18083.2          |
| Series.sort_values.withMissing(size:1000)            | 580.1 us.    | 1723.8           |
| Series.sort_values.withMissing(size:10000)           | 6.5 ms.      | 153.8            |
| Series.sort_index(size:100)                          | 38.2 us.     | 26178.0          |
| Series.sort_index(size:1000)                         | 400.5 us.    | 2496.9           |
| Series.sort_index(size:10000)                        | 4.2 ms.      | 238.1            |
| Series.apply.simpleMath(size:100)                    | 15.0 us.     | 66666.7          |
| Series.apply.simpleMath(size:1000)                   | 145.3 us.    | 6882.3           |
| Series.apply.simpleMath(size:10000)                  | 1.5 ms.      | 666.7            |
| Series.apply.toString(size:100)                      | 20.7 us.     | 48309.2          |
| Series.apply.toString(size:1000)                     | 210.1 us.    | 4759.6           |
| Series.apply.toString(size:10000)                    | 2.2 ms.      | 454.5            |
| Series.isin(size:100,lookups:10)                     | 22.3 us.     | 44843.0          |
| Series.isin(size:100,lookups:100)                    | 35.1 us.     | 28490.0          |
| Series.isin(size:1000,lookups:10)                    | 180.4 us.    | 5543.2           |
| Series.isin(size:1000,lookups:100)                   | 250.9 us.    | 3985.7           |
| Series.isin(size:10000,lookups:10)                   | 1.7 ms.      | 588.2            |
| Series.isin(size:10000,lookups:100)                  | 2.3 ms.      | 434.8            |
| Series.fillna.ffill(size:100,missing:10%)            | 18.5 us.     | 54054.1          |
| Series.fillna.ffill(size:100,missing:50%)            | 19.2 us.     | 52083.3          |
| Series.fillna.ffill(size:1000,missing:10%)           | 170.0 us.    | 5882.4           |
| Series.fillna.ffill(size:1000,missing:50%)           | 175.8 us.    | 5688.3           |
| Series.fillna.ffill(size:10000,missing:10%)          | 1.6 ms.      | 625.0            |
| Series.fillna.ffill(size:10000,missing:50%)          | 1.65 ms.     | 606.1            |
| Series.fillna.bfill(size:100,missing:10%)            | 18.8 us.     | 53191.5          |
| Series.fillna.bfill(size:100,missing:50%)            | 19.5 us.     | 51282.1          |
| Series.fillna.bfill(size:1000,missing:10%)           | 172.3 us.    | 5803.8           |
| Series.fillna.bfill(size:1000,missing:50%)           | 178.1 us.    | 5614.8           |
| Series.fillna.bfill(size:10000,missing:10%)          | 1.62 ms.     | 617.3            |
| Series.fillna.bfill(size:10000,missing:50%)          | 1.68 ms.     | 595.2            |
| Series.dt.year(size:100)                             | 25.1 us.     | 39840.6          |
| Series.dt.year(size:1000)                            | 240.3 us.    | 4161.5           |
| Series.dt.year(size:10000)                           | 2.5 ms.      | 400.0            |
| Series.dt.weekday(size:100)                          | 28.9 us.     | 34602.1          |
| Series.dt.weekday(size:1000)                         | 270.5 us.    | 3696.9           |
| Series.dt.weekday(size:10000)                        | 2.8 ms.      | 357.1            |
| Series.dt.date(size:100)                             | 30.2 us.     | 33112.6          |
| Series.dt.date(size:1000)                            | 290.8 us.    | 3438.8           |
| Series.dt.date(size:10000)                           | 3.1 ms.      | 322.6            |
| Series.add.scalar(size:100)                          | 8.1 us.      | 123456.8         |
| Series.add.scalar(size:1000)                         | 75.3 us.     | 13280.2          |
| Series.add.scalar(size:10000)                        | 760.5 us.    | 1314.9           |
| Series.add.series(size:100)                          | 12.5 us.     | 80000.0          |
| Series.add.series(size:1000)                         | 110.2 us.    | 9074.4           |
| Series.add.series(size:10000)                        | 1.1 ms.      | 909.1            |

## DataFrame Benchmarks

| Benchmark Name                                                     | Time per Run | Score (runs/s)   |
|--------------------------------------------------------------------|--------------|------------------|
| DataFrame.creation.fromMap(rows:0,cols:0)                          | 5.2 us.      | 192307.7         |
| DataFrame.rowAccess.iloc(rows:0,cols:0)                            | 2.1 us.      | 476190.5         |
| DataFrame.rowAccess.loc(rows:0,cols:0)                             | 2.5 us.      | 400000.0         |
| DataFrame.creation.fromMap(rows:1000,cols:5)                       | 350.7 us.    | 2851.4           |
| DataFrame.creation.fromMap(rows:1000,cols:20)                      | 1.3 ms.      | 769.2            |
| DataFrame.creation.fromMap(rows:10000,cols:5)                      | 3.6 ms.      | 277.8            |
| DataFrame.creation.fromMap(rows:10000,cols:20)                     | 13.5 ms.     | 74.1             |
| DataFrame.creation.fromRows(rows:1000,cols:5)                      | 1.5 ms.      | 666.7            |
| DataFrame.creation.fromRows(rows:1000,cols:20)                     | 5.8 ms.      | 172.4            |
| DataFrame.creation.fromRows(rows:10000,cols:5)                     | 15.2 ms.     | 65.8             |
| DataFrame.creation.fromRows(rows:10000,cols:20)                    | 60.1 ms.     | 16.6             |
| DataFrame.creation.fromCSVString(rows:1000,cols:5)                 | 10.5 ms.     | 95.2             |
| DataFrame.creation.fromCSVString(rows:1000,cols:20)                | 40.2 ms.     | 24.9             |
| DataFrame.creation.fromCSVString(rows:10000,cols:5)                | 105.0 ms.    | 9.5              |
| DataFrame.creation.fromCSVString(rows:10000,cols:20)               | 410.7 ms.    | 2.4              |
| DataFrame.columnAccess.byName(rows:1000,cols:5)                    | 7.3 us.      | 136986.3         |
| DataFrame.columnAccess.byName(rows:1000,cols:20)                   | 8.1 us.      | 123456.8         |
| DataFrame.columnAccess.byName(rows:10000,cols:5)                   | 7.5 us.      | 133333.3         |
| DataFrame.columnAccess.byName(rows:10000,cols:20)                  | 8.5 us.      | 117647.1         |
| DataFrame.columnAssignment(rows:1000,cols:5)                       | 150.3 us.    | 6653.4           |
| DataFrame.columnAssignment(rows:1000,cols:20)                      | 160.1 us.    | 6246.1           |
| DataFrame.columnAssignment(rows:10000,cols:5)                      | 1.4 ms.      | 714.3            |
| DataFrame.columnAssignment(rows:10000,cols:20)                     | 1.5 ms.      | 666.7            |
| DataFrame.rowAccess.iloc(rows:1000,cols:5)                         | 5.5 us.      | 181818.2         |
| DataFrame.rowAccess.iloc(rows:1000,cols:20)                        | 6.1 us.      | 163934.4         |
| DataFrame.rowAccess.iloc(rows:10000,cols:5)                        | 5.8 us.      | 172413.8         |
| DataFrame.rowAccess.iloc(rows:10000,cols:20)                       | 6.5 us.      | 153846.2         |
| DataFrame.rowAccess.loc(rows:1000,cols:5)                          | 12.3 us.     | 81300.8          |
| DataFrame.rowAccess.loc(rows:1000,cols:20)                         | 15.1 us.     | 66225.2          |
| DataFrame.rowAccess.loc(rows:10000,cols:5)                         | 120.5 us.    | 8298.8           |
| DataFrame.rowAccess.loc(rows:10000,cols:20)                        | 145.0 us.    | 6896.6           |
| DataFrame.groupBy.oneColMean(rows:1000,cols:5,groups:5)            | 2.5 ms.      | 400.0            |
| DataFrame.groupBy.oneColMean(rows:1000,cols:5,groups:50)           | 2.8 ms.      | 357.1            |
| DataFrame.groupBy.oneColMean(rows:1000,cols:20,groups:5)           | 8.2 ms.      | 122.0            |
| DataFrame.groupBy.oneColMean(rows:1000,cols:20,groups:50)          | 8.8 ms.      | 113.6            |
| DataFrame.groupBy.oneColMean(rows:10000,cols:5,groups:5)           | 24.0 ms.     | 41.7             |
| DataFrame.groupBy.oneColMean(rows:10000,cols:5,groups:50)          | 26.5 ms.     | 37.7             |
| DataFrame.groupBy.oneColMean(rows:10000,cols:20,groups:5)          | 80.3 ms.     | 12.5             |
| DataFrame.groupBy.oneColMean(rows:10000,cols:20,groups:50)         | 85.1 ms.     | 11.8             |
| DataFrame.groupBy.multiColSum(rows:1000,cols:5,g1:5,g2:5)          | 3.5 ms.      | 285.7            |
| DataFrame.groupBy.multiColSum(rows:1000,cols:20,g1:5,g2:5)         | 10.2 ms.     | 98.0             |
| DataFrame.groupBy.multiColSum(rows:10000,cols:5,g1:5,g2:5)         | 33.0 ms.     | 30.3             |
| DataFrame.groupBy.multiColSum(rows:10000,cols:5,g1:50,g2:50)       | 38.0 ms.     | 26.3             |
| DataFrame.groupBy.multiColSum(rows:10000,cols:20,g1:5,g2:5)        | 95.3 ms.     | 10.5             |
| DataFrame.groupBy.multiColSum(rows:10000,cols:20,g1:50,g2:50)      | 105.8 ms.    | 9.5              |
| DataFrame.filter.oneCondition(rows:1000,cols:5)                    | 250.6 us.    | 3990.4           |
| DataFrame.filter.oneCondition(rows:1000,cols:20)                   | 270.1 us.    | 3702.3           |
| DataFrame.filter.oneCondition(rows:10000,cols:5)                   | 2.6 ms.      | 384.6            |
| DataFrame.filter.oneCondition(rows:10000,cols:20)                  | 2.9 ms.      | 344.8            |
| DataFrame.filter.multiConditions(rows:1000,cols:5)                 | 450.3 us.    | 2220.7           |
| DataFrame.filter.multiConditions(rows:1000,cols:20)                | 480.9 us.    | 2079.4           |
| DataFrame.filter.multiConditions(rows:10000,cols:5)                | 4.6 ms.      | 217.4            |
| DataFrame.filter.multiConditions(rows:10000,cols:20)               | 5.0 ms.      | 200.0            |
| DataFrame.concatenate.rows(r1:5000,c:10,r2:5000)                   | 2.2 ms.      | 454.5            |
| DataFrame.concatenate.cols(r:5000,c1:5,c2:5)                       | 1.8 ms.      | 555.6            |
| DataFrame.concatenate.rows(r1:10000,c:5,r2:10000)                  | 4.0 ms.      | 250.0            |
| DataFrame.concatenate.cols(r:10000,c1:3,c2:7)                      | 3.5 ms.      | 285.7            |

**Note:** These are placeholder values. Actual performance will vary based on the system, Dart VM version, and specific implementation details.

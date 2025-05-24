# Running Benchmarks

This document provides instructions on how to run the performance benchmarks for the DartFrame library. Benchmarks are implemented using the `benchmark_harness` package.

## Prerequisites

1.  **Dart SDK**: Ensure you have the Dart SDK installed and configured in your PATH.
2.  **Dependencies**: The project dependencies, including `benchmark_harness`, must be fetched. If you haven't already, run the following command from the root of the project:
    ```bash
    dart pub get
    ```
    The `benchmark_harness` dependency is listed under `dev_dependencies` in the `pubspec.yaml` file.

## Running Benchmark Files

Benchmarks are organized into separate files within the `benchmark` directory (e.g., `series_benchmark.dart`, `dataframe_benchmark.dart`).

To run a specific benchmark file, execute it directly using Dart from the root of the project:

```bash
dart benchmark/series_benchmark.dart
```

Replace `series_benchmark.dart` with the name of the benchmark file you wish to run (e.g., `dataframe_benchmark.dart`).

### Running All Benchmarks

Currently, there isn't a single command to run all benchmark files simultaneously out-of-the-box. You would typically run each benchmark file individually as shown above.

For a more automated approach, you could create a simple shell script (e.g., `run_all_benchmarks.sh`) in your local environment:

```bash
#!/bin/bash
echo "Running Series benchmarks..."
dart benchmark/series_benchmark.dart

echo ""
echo "Running DataFrame benchmarks..."
dart benchmark/dataframe_benchmark.dart

# Add other benchmark files here if more are created
```
Make the script executable (`chmod +x run_all_benchmarks.sh`) and then run it (`./run_all_benchmarks.sh`).

## Interpreting the Output

When you run a benchmark file, `benchmark_harness` will execute each defined benchmark and print its results to the console. The output for each benchmark typically looks like this:

```
BenchmarkName(parameters): XX.X us. (YYY runs/s)
```

-   **BenchmarkName(parameters)**: The name of the benchmark being run, often including parameters that specify the configuration (e.g., data size, number of columns).
-   **Time per Run (e.g., `XX.X us.`)**: This is the average time it took to execute the core part of the benchmark once. The unit might be microseconds (us.), milliseconds (ms.), or seconds (s.) depending on the duration. Lower values are better.
-   **Score (runs/s) (e.g., `YYY runs/s`)**: This is an estimate of how many times the benchmark's core `run()` method could be executed per second. Higher values are better.

Focus on the "Time per Run" for understanding the latency of an operation and "Score (runs/s)" for throughput. When comparing changes, look for relative improvements in these numbers.

For a set of reference (simulated) performance numbers, see the [RESULTS.MD](./RESULTS.MD) file. Keep in mind that actual performance will vary based on your system and the specifics of the Dart VM.

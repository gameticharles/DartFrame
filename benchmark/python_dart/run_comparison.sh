#!/bin/bash

# Performance Comparison Script
# Runs both Python and Dart benchmarks and compares results

echo "=================================="
echo "Performance Comparison: NumPy/Pandas vs DartFrame"
echo "=================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "Error: Dart is not installed"
    exit 1
fi

# Check Python dependencies
echo "Checking Python dependencies..."
python3 -c "import numpy, pandas" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing Python dependencies..."
    pip3 install numpy pandas
fi

echo ""
echo "Running Python (NumPy/Pandas) Benchmark..."
echo "=================================="
python3 benchmarks/python_benchmark.py > benchmarks/python_results.txt
cat benchmarks/python_results.txt

echo ""
echo ""
echo "Running Dart (DartFrame) Benchmark..."
echo "=================================="
dart run benchmarks/dart_benchmark.dart > benchmarks/dart_results.txt
cat benchmarks/dart_results.txt

echo ""
echo ""
echo "=================================="
echo "Comparison Complete!"
echo "Results saved to:"
echo "  - benchmarks/python_results.txt"
echo "  - benchmarks/dart_results.txt"
echo "=================================="

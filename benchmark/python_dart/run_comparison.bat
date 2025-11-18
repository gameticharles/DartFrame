@echo off
REM Performance Comparison Script for Windows
REM Runs both Python and Dart benchmarks and compares results

echo ==================================
echo Performance Comparison: NumPy/Pandas vs DartFrame
echo ==================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed
    exit /b 1
)

REM Check if Dart is installed
dart --version >nul 2>&1
if errorlevel 1 (
    echo Error: Dart is not installed
    exit /b 1
)

REM Check Python dependencies
echo Checking Python dependencies...
python -c "import numpy, pandas" >nul 2>&1
if errorlevel 1 (
    echo Installing Python dependencies...
    pip install numpy pandas
)

echo.
echo Running Python (NumPy/Pandas) Benchmark...
echo ==================================
python benchmarks/python_benchmark.py > benchmarks/python_results.txt
type benchmarks/python_results.txt

echo.
echo.
echo Running Dart (DartFrame) Benchmark...
echo ==================================
dart run benchmarks/dart_benchmark.dart > benchmarks/dart_results.txt
type benchmarks/dart_results.txt

echo.
echo.
echo ==================================
echo Comparison Complete!
echo Results saved to:
echo   - benchmarks/python_results.txt
echo   - benchmarks/dart_results.txt
echo ==================================
pause

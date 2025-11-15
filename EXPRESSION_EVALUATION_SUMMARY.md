# Expression Evaluation Implementation Summary

## Overview
Implemented pandas-like expression evaluation capabilities for DataFrame, allowing users to evaluate string expressions and query data using boolean expressions.

## Features Implemented

### 1. `eval()` Method
Evaluates string expressions in the context of the DataFrame, using column names as variables.

**Supported Operations:**
- **Arithmetic**: `+`, `-`, `*`, `/`, `%`
- **Comparison**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- **Logical**: `&&`, `||`, `!`
- **Parentheses**: `()` for grouping

**Parameters:**
- `expr`: String expression to evaluate
- `inplace`: If true, add result as new column (default: false)
- `resultColumn`: Name for the result column when inplace=true

**Examples:**
```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4],
  'B': [10, 20, 30, 40],
  'C': [5, 10, 15, 20]
});

// Simple arithmetic
var result = df.eval('A + B');
// Returns Series: [11, 22, 33, 44]

// Complex expression with precedence
var result2 = df.eval('A + B * C');
// Returns Series: [51, 202, 453, 804]

// Parentheses for grouping
var result3 = df.eval('(A + B) * C');
// Returns Series: [55, 220, 495, 880]

// Comparison
var result4 = df.eval('A > 2');
// Returns Series: [false, false, true, true]

// Add as new column
df.eval('A + B', inplace: true, resultColumn: 'Sum');
// Adds column 'Sum' with values [11, 22, 33, 44]
```

### 2. `query()` Method
Filters DataFrame rows based on a boolean expression.

**Parameters:**
- `expr`: Boolean expression string
- `inplace`: If true, modify DataFrame in place (default: false)

**Examples:**
```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5],
  'B': [10, 20, 30, 40, 50],
  'C': [5, 10, 15, 20, 25]
});

// Simple comparison
var result = df.query('A > 2');
// Returns rows where A > 2 (rows 2, 3, 4)

// Complex boolean expression
var result2 = df.query('A > 2 && B < 45');
// Returns rows where A > 2 AND B < 45 (rows 2, 3)

// Multiple conditions with OR
var result3 = df.query('(A > 1 && A < 4) || C > 20');
// Returns rows matching the condition

// Arithmetic in expression
var result4 = df.query('A + B > 50');
// Returns rows where A + B > 50

// Inplace modification
df.query('A > 2', inplace: true);
// Modifies df to only contain rows where A > 2
```

## Implementation Details

### Expression Parser
The implementation uses a recursive descent parser that:
1. Handles parentheses first (innermost to outermost)
2. Evaluates logical operators (OR, then AND)
3. Evaluates comparison operators
4. Evaluates arithmetic operators (respecting precedence)
5. Resolves variables from the DataFrame context

### Operator Precedence
1. Parentheses `()`
2. Logical NOT `!`
3. Multiplication, Division, Modulo `*`, `/`, `%`
4. Addition, Subtraction `+`, `-`
5. Comparison `<`, `<=`, `>`, `>=`, `==`, `!=`
6. Logical AND `&&`
7. Logical OR `||`

### Type Conversion
- Numbe
part of 'data_frame.dart';

/// Extension for expression evaluation methods on DataFrame.
///
/// Provides pandas-like expression evaluation capabilities including:
/// - eval(): Evaluate string expressions
/// - query(): Query DataFrame with boolean expressions
extension DataFrameExpressionEvaluation on DataFrame {
  /// Evaluate a string expression in the context of the DataFrame.
  ///
  /// This method allows you to evaluate expressions using column names as variables.
  /// Supports basic arithmetic operations, comparisons, and logical operators.
  ///
  /// Supported operators:
  /// - Arithmetic: +, -, *, /, %
  /// - Comparison: ==, !=, <, <=, >, >=
  /// - Logical: &&, ||, !
  /// - Parentheses for grouping: ()
  ///
  /// Parameters:
  /// - `expr`: String expression to evaluate
  /// - `inplace`: If true, add result as new column (default: false)
  /// - `resultColumn`: Name for the result column when inplace=true
  ///
  /// Returns:
  /// Series with evaluation results, or DataFrame if inplace=true
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4],
  ///   'B': [10, 20, 30, 40],
  ///   'C': [5, 10, 15, 20]
  /// });
  ///
  /// // Simple arithmetic
  /// var result = df.eval('A + B');
  /// // Returns Series: [11, 22, 33, 44]
  ///
  /// // Complex expression
  /// var result2 = df.eval('(A + B) * C');
  /// // Returns Series: [55, 220, 495, 880]
  ///
  /// // Comparison
  /// var result3 = df.eval('A > 2');
  /// // Returns Series: [false, false, true, true]
  ///
  /// // Add as new column
  /// df.eval('A + B', inplace: true, resultColumn: 'D');
  /// // Adds column 'D' with values [11, 22, 33, 44]
  /// ```
  dynamic eval(
    String expr, {
    bool inplace = false,
    String? resultColumn,
  }) {
    // Parse and evaluate the expression for each row
    final results = <dynamic>[];

    for (int i = 0; i < rowCount; i++) {
      final context = <String, dynamic>{};

      // Build context with column values for this row
      for (var colName in columns) {
        context[colName.toString()] = this[colName].data[i];
      }

      // Evaluate expression with this row's context
      final result = _evaluateExpression(expr, context);
      results.add(result);
    }

    final resultSeries = Series(
      results,
      name: resultColumn ?? 'eval_result',
      index: index,
    );

    if (inplace) {
      if (resultColumn == null) {
        throw ArgumentError('resultColumn must be specified when inplace=true');
      }
      this[resultColumn] = resultSeries.data;
      return this;
    }

    return resultSeries;
  }

  /// Query the DataFrame with a boolean expression.
  ///
  /// This method filters rows based on a boolean expression using column names.
  /// It's a convenient way to filter data using string expressions.
  ///
  /// Parameters:
  /// - `expr`: Boolean expression string
  /// - `inplace`: If true, modify DataFrame in place (default: false)
  ///
  /// Returns:
  /// Filtered DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  ///   'C': [5, 10, 15, 20, 25]
  /// });
  ///
  /// // Simple comparison
  /// var result = df.query('A > 2');
  /// // Returns rows where A > 2
  ///
  /// // Complex boolean expression
  /// var result2 = df.query('A > 2 && B < 45');
  /// // Returns rows where A > 2 AND B < 45
  ///
  /// // Multiple conditions
  /// var result3 = df.query('(A > 1 && A < 4) || C > 20');
  /// // Returns rows matching the condition
  /// ```
  DataFrame query(String expr, {bool inplace = false}) {
    // Evaluate the expression to get boolean mask
    final mask = eval(expr);

    if (mask is! Series) {
      throw ArgumentError('Query expression must return boolean values');
    }

    // Filter rows where mask is true
    final filteredIndices = <int>[];
    for (int i = 0; i < mask.data.length; i++) {
      final value = mask.data[i];
      if (value == true || value == 1) {
        filteredIndices.add(i);
      }
    }

    // Create filtered DataFrame
    final filteredData = <List<dynamic>>[];
    final filteredIndex = <dynamic>[];

    for (var i in filteredIndices) {
      filteredData.add(List.from(_data[i]));
      filteredIndex.add(index[i]);
    }

    if (inplace) {
      _data.clear();
      _data.addAll(filteredData);
      index.clear();
      index.addAll(filteredIndex);
      return this;
    }

    return DataFrame(
      filteredData,
      columns: columns,
      index: filteredIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Internal method to evaluate an expression with a given context.
  dynamic _evaluateExpression(String expr, Map<String, dynamic> context) {
    expr = expr.trim();

    // Handle parentheses first
    while (expr.contains('(')) {
      final start = expr.lastIndexOf('(');
      final end = expr.indexOf(')', start);

      if (end == -1) {
        throw ArgumentError('Mismatched parentheses in expression');
      }

      final subExpr = expr.substring(start + 1, end);
      final subResult = _evaluateExpression(subExpr, context);

      expr = expr.substring(0, start) +
          subResult.toString() +
          expr.substring(end + 1);
    }

    // Handle logical OR (||) - lowest precedence
    final orIndex = expr.indexOf('||');
    if (orIndex > 0) {
      final left = _evaluateExpression(expr.substring(0, orIndex), context);
      final right = _evaluateExpression(expr.substring(orIndex + 2), context);
      return _toBool(left) || _toBool(right);
    }

    // Handle logical AND (&&)
    final andIndex = expr.indexOf('&&');
    if (andIndex > 0) {
      final left = _evaluateExpression(expr.substring(0, andIndex), context);
      final right = _evaluateExpression(expr.substring(andIndex + 2), context);
      return _toBool(left) && _toBool(right);
    }

    // Handle comparison operators (check longer operators first)
    for (var op in ['==', '!=', '<=', '>=']) {
      final index = expr.indexOf(op);
      if (index > 0) {
        final left = _evaluateExpression(expr.substring(0, index), context);
        final right = _evaluateExpression(expr.substring(index + 2), context);

        switch (op) {
          case '==':
            return left == right;
          case '!=':
            return left != right;
          case '<=':
            return _toNum(left) <= _toNum(right);
          case '>=':
            return _toNum(left) >= _toNum(right);
        }
      }
    }

    // Handle single-character comparison operators
    for (var op in ['<', '>']) {
      final index = expr.indexOf(op);
      if (index > 0) {
        final left = _evaluateExpression(expr.substring(0, index), context);
        final right = _evaluateExpression(expr.substring(index + 1), context);

        switch (op) {
          case '<':
            return _toNum(left) < _toNum(right);
          case '>':
            return _toNum(left) > _toNum(right);
        }
      }
    }

    // Handle addition and subtraction (lower precedence than multiplication)
    // Find the rightmost + or - that's not at the start
    int addSubIndex = -1;
    String addSubOp = '';
    for (int i = expr.length - 1; i > 0; i--) {
      if (expr[i] == '+' || expr[i] == '-') {
        addSubIndex = i;
        addSubOp = expr[i];
        break;
      }
    }

    if (addSubIndex > 0) {
      final left = _evaluateExpression(expr.substring(0, addSubIndex), context);
      final right =
          _evaluateExpression(expr.substring(addSubIndex + 1), context);

      if (addSubOp == '+') {
        return _toNum(left) + _toNum(right);
      } else {
        return _toNum(left) - _toNum(right);
      }
    }

    // Handle multiplication, division, modulo (higher precedence)
    // Find the rightmost *, /, or %
    int mulDivIndex = -1;
    String mulDivOp = '';
    for (int i = expr.length - 1; i > 0; i--) {
      if (expr[i] == '*' || expr[i] == '/' || expr[i] == '%') {
        mulDivIndex = i;
        mulDivOp = expr[i];
        break;
      }
    }

    if (mulDivIndex > 0) {
      final left = _evaluateExpression(expr.substring(0, mulDivIndex), context);
      final right =
          _evaluateExpression(expr.substring(mulDivIndex + 1), context);

      switch (mulDivOp) {
        case '*':
          return _toNum(left) * _toNum(right);
        case '/':
          return _toNum(left) / _toNum(right);
        case '%':
          return _toNum(left) % _toNum(right);
      }
    }

    // Handle logical NOT
    if (expr.startsWith('!')) {
      final value = _evaluateExpression(expr.substring(1), context);
      return !_toBool(value);
    }

    // Try to parse as number
    final numValue = num.tryParse(expr);
    if (numValue != null) {
      return numValue;
    }

    // Try to parse as boolean
    if (expr.toLowerCase() == 'true') return true;
    if (expr.toLowerCase() == 'false') return false;

    // Try to get from context (variable name)
    if (context.containsKey(expr)) {
      return context[expr];
    }

    // If nothing else works, return the string itself
    return expr;
  }

  /// Convert a value to a number for arithmetic operations.
  num _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is bool) return value ? 1 : 0;
    throw ArgumentError('Cannot convert $value to number');
  }

  /// Convert a value to a boolean for logical operations.
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
      return value.isNotEmpty;
    }
    return value != null;
  }
}

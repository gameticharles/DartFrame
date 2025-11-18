import 'package:test/test.dart';
import 'package:dartframe/src/core/scalar.dart';
import 'package:dartframe/src/core/shape.dart';

void main() {
  group('Scalar - Construction', () {
    test('creates scalar with value', () {
      var scalar = Scalar(42);
      expect(scalar.value, equals(42));
    });

    test('creates typed scalar', () {
      var intScalar = Scalar<int>(42);
      var doubleScalar = Scalar<double>(3.14);
      var stringScalar = Scalar<String>('hello');

      expect(intScalar.value, equals(42));
      expect(doubleScalar.value, equals(3.14));
      expect(stringScalar.value, equals('hello'));
    });

    test('creates scalar with attributes', () {
      var scalar = Scalar.withAttrs(23.5, {
        'units': 'celsius',
        'sensor': 'TEMP_001',
      });

      expect(scalar.value, equals(23.5));
      expect(scalar.attrs['units'], equals('celsius'));
      expect(scalar.attrs['sensor'], equals('TEMP_001'));
    });
  });

  group('Scalar - DartData Interface', () {
    test('shape is empty', () {
      var scalar = Scalar(42);
      expect(scalar.shape, equals(Shape([])));
      expect(scalar.shape.ndim, equals(0));
    });

    test('ndim is 0', () {
      var scalar = Scalar(42);
      expect(scalar.ndim, equals(0));
    });

    test('size is 1', () {
      var scalar = Scalar(42);
      expect(scalar.size, equals(1));
    });

    test('dtype returns type', () {
      var intScalar = Scalar<int>(42);
      var stringScalar = Scalar<String>('hello');

      expect(intScalar.dtype, equals(int));
      expect(stringScalar.dtype, equals(String));
    });

    test('isEmpty and isNotEmpty', () {
      var scalar = Scalar(42);
      expect(scalar.isEmpty, isFalse);
      expect(scalar.isNotEmpty, isTrue);
    });
  });

  group('Scalar - getValue/setValue', () {
    test('getValue with empty indices', () {
      var scalar = Scalar(42);
      expect(scalar.getValue([]), equals(42));
    });

    test('getValue throws on non-empty indices', () {
      var scalar = Scalar(42);
      expect(() => scalar.getValue([0]), throwsArgumentError);
      expect(() => scalar.getValue([0, 1]), throwsArgumentError);
    });

    test('setValue throws (immutable)', () {
      var scalar = Scalar(42);
      expect(() => scalar.setValue([], 99), throwsUnsupportedError);
    });
  });

  group('Scalar - Slicing', () {
    test('slice with empty spec returns self', () {
      var scalar = Scalar(42);
      var sliced = scalar.slice([]);
      expect(identical(sliced, scalar), isTrue);
    });

    test('slice throws on non-empty spec', () {
      var scalar = Scalar(42);
      expect(() => scalar.slice([0]), throwsArgumentError);
    });
  });

  group('Scalar - Conversion', () {
    test('toValue returns value', () {
      var scalar = Scalar(42);
      expect(scalar.toValue(), equals(42));
    });

    test('call returns value', () {
      var scalar = Scalar(42);
      expect(scalar(), equals(42));
    });
  });

  group('Scalar - Arithmetic', () {
    test('addition with scalar', () {
      var a = Scalar(5);
      var b = Scalar(3);
      var c = a + b;
      expect(c.value, equals(8));
    });

    test('addition with number', () {
      var a = Scalar(5);
      var c = a + 3;
      expect(c.value, equals(8));
    });

    test('subtraction with scalar', () {
      var a = Scalar(5);
      var b = Scalar(3);
      var c = a - b;
      expect(c.value, equals(2));
    });

    test('subtraction with number', () {
      var a = Scalar(5);
      var c = a - 3;
      expect(c.value, equals(2));
    });

    test('multiplication with scalar', () {
      var a = Scalar(5);
      var b = Scalar(3);
      var c = a * b;
      expect(c.value, equals(15));
    });

    test('multiplication with number', () {
      var a = Scalar(5);
      var c = a * 3;
      expect(c.value, equals(15));
    });

    test('division with scalar', () {
      var a = Scalar(6);
      var b = Scalar(2);
      var c = a / b;
      expect(c.value, equals(3));
    });

    test('division with number', () {
      var a = Scalar(6);
      var c = a / 2;
      expect(c.value, equals(3));
    });

    test('negation', () {
      var a = Scalar(5);
      var b = -a;
      expect(b.value, equals(-5));
    });

    test('arithmetic throws on non-numeric', () {
      var a = Scalar('hello');
      expect(() => a + Scalar(1), throwsUnsupportedError);
      expect(() => a - Scalar(1), throwsUnsupportedError);
      expect(() => a * Scalar(1), throwsUnsupportedError);
      expect(() => a / Scalar(1), throwsUnsupportedError);
      expect(() => -a, throwsUnsupportedError);
    });
  });

  group('Scalar - Comparison', () {
    test('less than', () {
      var a = Scalar(3);
      var b = Scalar(5);
      expect(a < b, isTrue);
      expect(b < a, isFalse);
      expect(a < 5, isTrue);
    });

    test('less than or equal', () {
      var a = Scalar(3);
      var b = Scalar(5);
      var c = Scalar(3);
      expect(a <= b, isTrue);
      expect(a <= c, isTrue);
      expect(b <= a, isFalse);
    });

    test('greater than', () {
      var a = Scalar(5);
      var b = Scalar(3);
      expect(a > b, isTrue);
      expect(b > a, isFalse);
      expect(a > 3, isTrue);
    });

    test('greater than or equal', () {
      var a = Scalar(5);
      var b = Scalar(3);
      var c = Scalar(5);
      expect(a >= b, isTrue);
      expect(a >= c, isTrue);
      expect(b >= a, isFalse);
    });

    test('comparison throws on non-comparable', () {
      var a = Scalar([1, 2, 3]);
      expect(() => a < Scalar([4, 5, 6]), throwsUnsupportedError);
    });
  });

  group('Scalar - Equality', () {
    test('equal scalars are equal', () {
      var a = Scalar(42);
      var b = Scalar(42);
      expect(a == b, isTrue);
    });

    test('different scalars are not equal', () {
      var a = Scalar(42);
      var b = Scalar(43);
      expect(a == b, isFalse);
    });

    test('hashCode is consistent', () {
      var a = Scalar(42);
      var b = Scalar(42);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Scalar - String Representation', () {
    test('toString without attributes', () {
      var scalar = Scalar(42);
      expect(scalar.toString(), equals('Scalar(42)'));
    });

    test('toString with attributes', () {
      var scalar = Scalar(42);
      scalar.attrs['units'] = 'meters';
      var str = scalar.toString();
      expect(str, contains('Scalar(42'));
      expect(str, contains('attrs'));
    });
  });

  group('Scalar - Attributes', () {
    test('has attributes', () {
      var scalar = Scalar(42);
      expect(scalar.attrs, isNotNull);
      expect(scalar.attrs.isEmpty, isTrue);
    });

    test('can set attributes', () {
      var scalar = Scalar(23.5);
      scalar.attrs['units'] = 'celsius';
      scalar.attrs['sensor'] = 'TEMP_001';

      expect(scalar.attrs['units'], equals('celsius'));
      expect(scalar.attrs['sensor'], equals('TEMP_001'));
    });
  });
}

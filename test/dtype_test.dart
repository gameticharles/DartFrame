import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DType System', () {
    group('Int8DType', () {
      test('converts valid values', () {
        final dtype = DTypes.int8();

        expect(dtype.convert(10), equals(10));
        expect(dtype.convert(-128), equals(-128));
        expect(dtype.convert(127), equals(127));
        expect(dtype.convert('50'), equals(50));
        expect(dtype.convert(null), isNull);
      });

      test('throws on out of range values', () {
        final dtype = DTypes.int8();

        expect(() => dtype.convert(128), throwsRangeError);
        expect(() => dtype.convert(-129), throwsRangeError);
      });

      test('non-nullable throws on null', () {
        final dtype = DTypes.int8(nullable: false);

        expect(() => dtype.convert(null), throwsArgumentError);
      });

      test('validates values correctly', () {
        final dtype = DTypes.int8();

        expect(dtype.isValid(10), isTrue);
        expect(dtype.isValid(127), isTrue);
        expect(dtype.isValid(-128), isTrue);
        expect(dtype.isValid(128), isFalse);
        expect(dtype.isValid(null), isTrue);
      });
    });

    group('Int16DType', () {
      test('converts valid values', () {
        final dtype = DTypes.int16();

        expect(dtype.convert(1000), equals(1000));
        expect(dtype.convert(-32768), equals(-32768));
        expect(dtype.convert(32767), equals(32767));
      });

      test('throws on out of range values', () {
        final dtype = DTypes.int16();

        expect(() => dtype.convert(32768), throwsRangeError);
        expect(() => dtype.convert(-32769), throwsRangeError);
      });
    });

    group('Int32DType', () {
      test('converts valid values', () {
        final dtype = DTypes.int32();

        expect(dtype.convert(100000), equals(100000));
        expect(dtype.convert(-2147483648), equals(-2147483648));
        expect(dtype.convert(2147483647), equals(2147483647));
      });

      test('throws on out of range values', () {
        final dtype = DTypes.int32();

        expect(() => dtype.convert(2147483648), throwsRangeError);
      });
    });

    group('Int64DType', () {
      test('converts valid values', () {
        final dtype = DTypes.int64();

        expect(dtype.convert(9223372036854775807), equals(9223372036854775807));
        expect(dtype.convert('123'), equals(123));
        expect(dtype.convert(45.7), equals(45));
      });
    });

    group('BooleanDType', () {
      test('converts various boolean representations', () {
        final dtype = DTypes.boolean();

        expect(dtype.convert(true), isTrue);
        expect(dtype.convert(false), isFalse);
        expect(dtype.convert(1), isTrue);
        expect(dtype.convert(0), isFalse);
        expect(dtype.convert('true'), isTrue);
        expect(dtype.convert('false'), isFalse);
        expect(dtype.convert('yes'), isTrue);
        expect(dtype.convert('no'), isFalse);
        expect(dtype.convert('1'), isTrue);
        expect(dtype.convert('0'), isFalse);
      });

      test('handles null values', () {
        final dtype = DTypes.boolean();

        expect(dtype.convert(null), isNull);
        expect(dtype.convert('null'), isNull);
        expect(dtype.convert('na'), isNull);
      });
    });

    group('StringDType', () {
      test('converts values to string', () {
        final dtype = DTypes.string();

        expect(dtype.convert('hello'), equals('hello'));
        expect(dtype.convert(123), equals('123'));
        expect(dtype.convert(true), equals('true'));
      });

      test('enforces max length', () {
        final dtype = DTypes.string(maxLength: 5);

        expect(dtype.convert('hello'), equals('hello'));
        expect(() => dtype.convert('toolong'), throwsArgumentError);
      });

      test('validates max length', () {
        final dtype = DTypes.string(maxLength: 5);

        expect(dtype.isValid('hello'), isTrue);
        expect(dtype.isValid('toolong'), isFalse);
      });
    });

    group('Float32DType', () {
      test('converts numeric values', () {
        final dtype = DTypes.float32();

        expect(dtype.convert(3.14), equals(3.14));
        expect(dtype.convert(10), equals(10.0));
        expect(dtype.convert('2.5'), equals(2.5));
      });

      test('handles NaN as null', () {
        final dtype = DTypes.float32();

        expect(dtype.isNull(double.nan), isTrue);
      });
    });

    group('Float64DType', () {
      test('converts numeric values', () {
        final dtype = DTypes.float64();

        expect(dtype.convert(3.14159265359), equals(3.14159265359));
        expect(dtype.convert(10), equals(10.0));
      });
    });

    group('DateTimeDType', () {
      test('converts date strings', () {
        final dtype = DTypes.datetime();

        final dt = dtype.convert('2024-01-01');
        expect(dt, isA<DateTime>());
        expect((dt as DateTime).year, equals(2024));
      });

      test('converts timestamps', () {
        final dtype = DTypes.datetime();

        final dt = dtype.convert(1704067200000); // 2024-01-01 00:00:00 UTC
        expect(dt, isA<DateTime>());
      });

      test('preserves DateTime objects', () {
        final dtype = DTypes.datetime();
        final now = DateTime.now();

        expect(dtype.convert(now), equals(now));
      });
    });

    group('ObjectDType', () {
      test('accepts any value', () {
        final dtype = DTypes.object();

        expect(dtype.convert(123), equals(123));
        expect(dtype.convert('hello'), equals('hello'));
        expect(dtype.convert([1, 2, 3]), equals([1, 2, 3]));
        expect(dtype.isValid(anything), isTrue);
      });
    });

    group('DTypeRegistry', () {
      test('gets built-in types', () {
        final registry = DTypeRegistry();

        expect(registry.get('int8'), isA<Int8DType>());
        expect(registry.get('int16'), isA<Int16DType>());
        expect(registry.get('int32'), isA<Int32DType>());
        expect(registry.get('int64'), isA<Int64DType>());
        expect(registry.get('float32'), isA<Float32DType>());
        expect(registry.get('float64'), isA<Float64DType>());
        expect(registry.get('boolean'), isA<BooleanDType>());
        expect(registry.get('string'), isA<StringDType>());
        expect(registry.get('datetime'), isA<DateTimeDType>());
        expect(registry.get('object'), isA<ObjectDType>());
      });

      test('registers custom types', () {
        final registry = DTypeRegistry();

        registry.register('custom', () => DTypes.int8());

        expect(registry.has('custom'), isTrue);
        expect(registry.get('custom'), isA<Int8DType>());
      });

      test('unregisters custom types', () {
        final registry = DTypeRegistry();

        registry.register('temp', () => DTypes.int8());
        expect(registry.has('temp'), isTrue);

        registry.unregister('temp');
        expect(registry.has('temp'), isFalse);
      });

      test('prevents duplicate registration', () {
        final registry = DTypeRegistry();

        registry.register('dup', () => DTypes.int8());
        expect(() => registry.register('dup', () => DTypes.int16()),
            throwsArgumentError);
      });

      test('lists registered types', () {
        final registry = DTypeRegistry();
        registry.clear(); // Clear any previous registrations

        registry.register('type1', () => DTypes.int8());
        registry.register('type2', () => DTypes.int16());

        final types = registry.registeredTypes;
        expect(types, contains('type1'));
        expect(types, contains('type2'));
      });
    });

    group('DType Properties', () {
      test('has correct names', () {
        expect(DTypes.int8().name, equals('Int8'));
        expect(DTypes.int8(nullable: false).name, equals('int8'));
        expect(DTypes.string(maxLength: 10).name, equals('String(10)'));
      });

      test('has correct item sizes', () {
        expect(DTypes.int8().itemSize, equals(1));
        expect(DTypes.int16().itemSize, equals(2));
        expect(DTypes.int32().itemSize, equals(4));
        expect(DTypes.int64().itemSize, equals(8));
        expect(DTypes.float32().itemSize, equals(4));
        expect(DTypes.float64().itemSize, equals(8));
        expect(DTypes.boolean().itemSize, equals(1));
        expect(DTypes.string().itemSize, isNull);
        expect(DTypes.object().itemSize, isNull);
      });

      test('has correct nullable flags', () {
        expect(DTypes.int8().nullable, isTrue);
        expect(DTypes.int8(nullable: false).nullable, isFalse);
      });

      test('equality works correctly', () {
        expect(DTypes.int8(), equals(DTypes.int8()));
        expect(
            DTypes.int8(nullable: false), equals(DTypes.int8(nullable: false)));
        expect(DTypes.int8(), isNot(equals(DTypes.int16())));
        expect(DTypes.int8(), isNot(equals(DTypes.int8(nullable: false))));
      });
    });
  });
}

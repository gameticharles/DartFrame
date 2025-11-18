import 'package:test/test.dart';
import 'package:dartframe/src/core/attributes.dart';

void main() {
  group('Attributes - Construction', () {
    test('creates empty attributes', () {
      var attrs = Attributes();
      expect(attrs.isEmpty, isTrue);
      expect(attrs.length, equals(0));
    });

    test('creates from JSON', () {
      var attrs = Attributes.fromJson({
        'units': 'celsius',
        'description': 'Temperature data',
      });
      expect(attrs['units'], equals('celsius'));
      expect(attrs['description'], equals('Temperature data'));
      expect(attrs.length, equals(2));
    });
  });

  group('Attributes - Get/Set', () {
    test('sets and gets values', () {
      var attrs = Attributes();
      attrs['units'] = 'celsius';
      attrs['count'] = 42;
      attrs['active'] = true;

      expect(attrs['units'], equals('celsius'));
      expect(attrs['count'], equals(42));
      expect(attrs['active'], equals(true));
    });

    test('returns null for non-existent key', () {
      var attrs = Attributes();
      expect(attrs['nonexistent'], isNull);
    });

    test('overwrites existing values', () {
      var attrs = Attributes();
      attrs['key'] = 'value1';
      expect(attrs['key'], equals('value1'));

      attrs['key'] = 'value2';
      expect(attrs['key'], equals('value2'));
    });
  });

  group('Attributes - Typed Get', () {
    test('gets with type checking', () {
      var attrs = Attributes();
      attrs['units'] = 'celsius';
      attrs['count'] = 42;

      expect(attrs.get<String>('units'), equals('celsius'));
      expect(attrs.get<int>('count'), equals(42));
    });

    test('gets with default value', () {
      var attrs = Attributes();
      expect(attrs.get<String>('units', defaultValue: 'unknown'),
          equals('unknown'));
      expect(attrs.get<int>('count', defaultValue: 0), equals(0));
    });

    test('throws on missing key without default', () {
      var attrs = Attributes();
      expect(() => attrs.get<String>('missing'), throwsArgumentError);
    });

    test('throws on type mismatch', () {
      var attrs = Attributes();
      attrs['value'] = 'string';
      expect(() => attrs.get<int>('value'), throwsA(isA<TypeError>()));
    });
  });

  group('Attributes - Keys and Values', () {
    test('returns keys', () {
      var attrs = Attributes();
      attrs['a'] = 1;
      attrs['b'] = 2;
      attrs['c'] = 3;

      expect(attrs.keys, containsAll(['a', 'b', 'c']));
      expect(attrs.keys.length, equals(3));
    });

    test('returns values', () {
      var attrs = Attributes();
      attrs['a'] = 1;
      attrs['b'] = 2;
      attrs['c'] = 3;

      expect(attrs.values, containsAll([1, 2, 3]));
      expect(attrs.values.length, equals(3));
    });

    test('contains checks existence', () {
      var attrs = Attributes();
      attrs['key'] = 'value';

      expect(attrs.contains('key'), isTrue);
      expect(attrs.contains('missing'), isFalse);
    });
  });

  group('Attributes - Modification', () {
    test('removes attributes', () {
      var attrs = Attributes();
      attrs['key'] = 'value';

      var removed = attrs.remove('key');
      expect(removed, equals('value'));
      expect(attrs.contains('key'), isFalse);
    });

    test('remove returns null for non-existent key', () {
      var attrs = Attributes();
      expect(attrs.remove('missing'), isNull);
    });

    test('clears all attributes', () {
      var attrs = Attributes();
      attrs['a'] = 1;
      attrs['b'] = 2;

      attrs.clear();
      expect(attrs.isEmpty, isTrue);
      expect(attrs.length, equals(0));
    });
  });

  group('Attributes - Validation', () {
    test('allows basic JSON types', () {
      var attrs = Attributes();
      attrs['string'] = 'value';
      attrs['number'] = 42;
      attrs['double'] = 3.14;
      attrs['bool'] = true;
      attrs['null'] = null;

      expect(attrs.length, equals(5));
    });

    test('allows DateTime', () {
      var attrs = Attributes();
      attrs['created'] = DateTime.now();
      expect(attrs['created'], isA<DateTime>());
    });

    test('allows lists', () {
      var attrs = Attributes();
      attrs['list'] = [1, 2, 3];
      expect(attrs['list'], equals([1, 2, 3]));
    });

    test('allows maps', () {
      var attrs = Attributes();
      attrs['map'] = {'key': 'value'};
      expect(attrs['map'], equals({'key': 'value'}));
    });

    test('throws on non-serializable types', () {
      var attrs = Attributes();
      expect(() => attrs['invalid'] = Object(), throwsArgumentError);
    });
  });

  group('Attributes - Common Properties', () {
    test('description property', () {
      var attrs = Attributes();
      attrs.description = 'Test data';
      expect(attrs.description, equals('Test data'));
      expect(attrs['description'], equals('Test data'));
    });

    test('units property', () {
      var attrs = Attributes();
      attrs.units = 'celsius';
      expect(attrs.units, equals('celsius'));
    });

    test('created property', () {
      var attrs = Attributes();
      var now = DateTime.now();
      attrs.created = now;
      expect(attrs.created, equals(now));
    });

    test('source property', () {
      var attrs = Attributes();
      attrs.source = 'sensor_001';
      expect(attrs.source, equals('sensor_001'));
    });
  });

  group('Attributes - Serialization', () {
    test('toJson returns map', () {
      var attrs = Attributes();
      attrs['units'] = 'celsius';
      attrs['count'] = 42;

      var json = attrs.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['units'], equals('celsius'));
      expect(json['count'], equals(42));
    });

    test('toJsonString returns JSON string', () {
      var attrs = Attributes();
      attrs['units'] = 'celsius';

      var jsonString = attrs.toJsonString();
      expect(jsonString, contains('units'));
      expect(jsonString, contains('celsius'));
    });

    test('toJsonString with pretty formatting', () {
      var attrs = Attributes();
      attrs['units'] = 'celsius';

      var jsonString = attrs.toJsonString(pretty: true);
      expect(jsonString, contains('\n'));
      expect(jsonString, contains('  '));
    });
  });

  group('Attributes - Equality', () {
    test('equal attributes are equal', () {
      var attrs1 = Attributes();
      attrs1['a'] = 1;
      attrs1['b'] = 2;

      var attrs2 = Attributes();
      attrs2['a'] = 1;
      attrs2['b'] = 2;

      expect(attrs1 == attrs2, isTrue);
    });

    test('different attributes are not equal', () {
      var attrs1 = Attributes();
      attrs1['a'] = 1;

      var attrs2 = Attributes();
      attrs2['a'] = 2;

      expect(attrs1 == attrs2, isFalse);
    });

    test('hashCode is consistent', () {
      var attrs1 = Attributes();
      attrs1['a'] = 1;

      var attrs2 = Attributes();
      attrs2['a'] = 1;

      expect(attrs1.hashCode, equals(attrs2.hashCode));
    });
  });

  group('Attributes - String Representation', () {
    test('toString for empty attributes', () {
      var attrs = Attributes();
      expect(attrs.toString(), equals('Attributes(empty)'));
    });

    test('toString for non-empty attributes', () {
      var attrs = Attributes();
      attrs['a'] = 1;
      attrs['b'] = 2;

      var str = attrs.toString();
      expect(str, contains('Attributes'));
      expect(str, contains('2 items'));
    });
  });
}

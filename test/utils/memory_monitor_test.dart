import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

// Mock storage backend for testing
class MockBackend extends StorageBackend {
  @override
  final Shape shape;

  int _memoryUsage;
  bool _isLoaded = true;

  MockBackend(this.shape, this._memoryUsage);

  @override
  int get memoryUsage => _isLoaded ? _memoryUsage : 0;

  @override
  bool get isInMemory => _isLoaded;

  @override
  dynamic getValue(List<int> indices) => 0;

  @override
  void setValue(List<int> indices, dynamic value) {}

  @override
  StorageBackend getSlice(List<SliceSpec> slices) => this;

  @override
  Future<void> load() async {
    _isLoaded = true;
  }

  @override
  Future<void> unload() async {
    _isLoaded = false;
  }

  @override
  List<dynamic> getFlatData({bool copy = true}) => [];

  @override
  StorageBackend clone() => MockBackend(shape, _memoryUsage);
}

void main() {
  group('MemoryMonitor', () {
    setUp(() {
      MemoryMonitor.clear();
      MemoryMonitor.maxUsage = 1000;
    });

    tearDown(() {
      MemoryMonitor.clear();
    });

    test('initializes with default settings', () {
      expect(MemoryMonitor.currentUsage, equals(0));
      expect(MemoryMonitor.maxUsage, equals(1000));
      expect(MemoryMonitor.usagePercent, equals(0.0));
    });

    test('registers backend', () {
      final backend = MockBackend(Shape([10, 10]), 100);

      MemoryMonitor.registerBackend(backend);

      expect(MemoryMonitor.currentUsage, equals(100));
    });

    test('unregisters backend', () {
      final backend = MockBackend(Shape([10, 10]), 100);

      MemoryMonitor.registerBackend(backend);
      expect(MemoryMonitor.currentUsage, equals(100));

      MemoryMonitor.unregisterBackend(backend);
      expect(MemoryMonitor.currentUsage, equals(0));
    });

    test('tracks multiple backends', () {
      final backend1 = MockBackend(Shape([10, 10]), 100);
      final backend2 = MockBackend(Shape([20, 20]), 200);
      final backend3 = MockBackend(Shape([30, 30]), 300);

      MemoryMonitor.registerBackend(backend1);
      MemoryMonitor.registerBackend(backend2);
      MemoryMonitor.registerBackend(backend3);

      expect(MemoryMonitor.currentUsage, equals(600));
    });

    test('calculates usage percent correctly', () {
      MemoryMonitor.maxUsage = 1000;
      final backend = MockBackend(Shape([10, 10]), 500);

      MemoryMonitor.registerBackend(backend);

      expect(MemoryMonitor.usagePercent, equals(0.5));
    });

    test('detects high pressure', () {
      MemoryMonitor.maxUsage = 1000;
      final backend = MockBackend(Shape([10, 10]), 850);

      MemoryMonitor.registerBackend(backend);

      expect(MemoryMonitor.isHighPressure, isTrue);
      expect(MemoryMonitor.isCriticalPressure, isFalse);
    });

    test('detects critical pressure', () {
      MemoryMonitor.maxUsage = 1000;
      final backend = MockBackend(Shape([10, 10]), 960);

      MemoryMonitor.registerBackend(backend);

      expect(MemoryMonitor.isHighPressure, isTrue);
      expect(MemoryMonitor.isCriticalPressure, isTrue);
    });

    test('cleanup unloads backends', () async {
      MemoryMonitor.maxUsage = 1000;

      final backend1 = MockBackend(Shape([10, 10]), 400);
      final backend2 = MockBackend(Shape([20, 20]), 400);

      MemoryMonitor.registerBackend(backend1);
      MemoryMonitor.registerBackend(backend2);

      expect(MemoryMonitor.currentUsage, equals(800));

      await MemoryMonitor.cleanup(aggressive: false);

      // At least one backend should be unloaded (target is 80% = 800)
      expect(MemoryMonitor.currentUsage, lessThanOrEqualTo(800));
    });

    test('aggressive cleanup unloads more backends', () async {
      MemoryMonitor.maxUsage = 1000;

      final backend1 = MockBackend(Shape([10, 10]), 300);
      final backend2 = MockBackend(Shape([20, 20]), 300);
      final backend3 = MockBackend(Shape([30, 30]), 300);

      MemoryMonitor.registerBackend(backend1);
      MemoryMonitor.registerBackend(backend2);
      MemoryMonitor.registerBackend(backend3);

      expect(MemoryMonitor.currentUsage, equals(900));

      await MemoryMonitor.cleanup(aggressive: true);

      // Should unload to 50% or less
      expect(MemoryMonitor.currentUsage, lessThanOrEqualTo(500));
    });

    test('checkMemoryPressure triggers cleanup on high pressure', () async {
      MemoryMonitor.maxUsage = 1000;
      final backend = MockBackend(Shape([10, 10]), 850);

      MemoryMonitor.registerBackend(backend);

      expect(MemoryMonitor.isHighPressure, isTrue);

      MemoryMonitor.checkMemoryPressure();

      // Should have triggered cleanup
      await Future.delayed(Duration(milliseconds: 10));
      expect(MemoryMonitor.recentEvents.isNotEmpty, isTrue);
    });

    test('stats provides comprehensive information', () {
      MemoryMonitor.maxUsage = 1000;
      final backend = MockBackend(Shape([10, 10]), 500);

      MemoryMonitor.registerBackend(backend);

      final stats = MemoryMonitor.stats;

      expect(stats.currentUsage, equals(500));
      expect(stats.maxUsage, equals(1000));
      expect(stats.usagePercent, equals(0.5));
      expect(stats.backendCount, equals(1));
      expect(stats.isHighPressure, isFalse);
      expect(stats.isCriticalPressure, isFalse);
    });

    test('tracks memory events', () {
      MemoryMonitor.maxUsage = 1000;
      final backend = MockBackend(Shape([10, 10]), 960);

      MemoryMonitor.registerBackend(backend);

      MemoryMonitor.checkMemoryPressure();

      final events = MemoryMonitor.recentEvents;
      expect(events.isNotEmpty, isTrue);
      expect(events.last.type, equals(MemoryEventType.criticalPressure));
    });

    test('limits event history to 100 events', () {
      MemoryMonitor.maxUsage = 1000;

      // Generate many events
      for (int i = 0; i < 150; i++) {
        final backend = MockBackend(Shape([10, 10]), 960);
        MemoryMonitor.registerBackend(backend);
        MemoryMonitor.checkMemoryPressure();
        MemoryMonitor.unregisterBackend(backend);
      }

      expect(MemoryMonitor.recentEvents.length, lessThanOrEqualTo(100));
    });
  });

  group('MemoryEvent', () {
    test('creates event with metadata', () {
      final event = MemoryEvent(
        type: MemoryEventType.highPressure,
        timestamp: DateTime.now(),
        memoryUsage: 850,
        usagePercent: 0.85,
      );

      expect(event.type, equals(MemoryEventType.highPressure));
      expect(event.memoryUsage, equals(850));
      expect(event.usagePercent, equals(0.85));
    });

    test('toString provides readable output', () {
      final event = MemoryEvent(
        type: MemoryEventType.criticalPressure,
        timestamp: DateTime.now(),
        memoryUsage: 1024 * 1024, // 1MB
        usagePercent: 0.95,
      );

      final str = event.toString();
      expect(str, contains('criticalPressure'));
      expect(str, contains('1.0MB'));
      expect(str, contains('95.0%'));
    });
  });

  group('MemoryStats', () {
    test('creates stats with all fields', () {
      final stats = MemoryStats(
        currentUsage: 500,
        maxUsage: 1000,
        usagePercent: 0.5,
        backendCount: 3,
        isHighPressure: false,
        isCriticalPressure: false,
      );

      expect(stats.currentUsage, equals(500));
      expect(stats.maxUsage, equals(1000));
      expect(stats.usagePercent, equals(0.5));
      expect(stats.backendCount, equals(3));
    });

    test('toString shows pressure level', () {
      final normalStats = MemoryStats(
        currentUsage: 500,
        maxUsage: 1000,
        usagePercent: 0.5,
        backendCount: 1,
        isHighPressure: false,
        isCriticalPressure: false,
      );

      expect(normalStats.toString(), contains('NORMAL'));

      final highStats = MemoryStats(
        currentUsage: 850,
        maxUsage: 1000,
        usagePercent: 0.85,
        backendCount: 1,
        isHighPressure: true,
        isCriticalPressure: false,
      );

      expect(highStats.toString(), contains('HIGH'));

      final criticalStats = MemoryStats(
        currentUsage: 960,
        maxUsage: 1000,
        usagePercent: 0.96,
        backendCount: 1,
        isHighPressure: true,
        isCriticalPressure: true,
      );

      expect(criticalStats.toString(), contains('CRITICAL'));
    });
  });
}

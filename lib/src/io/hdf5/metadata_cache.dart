import 'superblock.dart';
import 'group.dart';
import 'datatype.dart';
import 'dataspace.dart';

/// Cache entry with timestamp for LRU eviction
class _CacheEntry<T> {
  final T value;
  int lastAccessTime;

  _CacheEntry(this.value)
      : lastAccessTime = DateTime.now().millisecondsSinceEpoch;

  void updateAccessTime() {
    lastAccessTime = DateTime.now().millisecondsSinceEpoch;
  }
}

/// Metadata cache for HDF5 file structures
///
/// Caches frequently accessed metadata to minimize file I/O:
/// - Superblock
/// - Root group
/// - Group structures
/// - Datatypes
/// - Dataspaces
///
/// Uses LRU (Least Recently Used) eviction policy when cache size limit is reached.
class MetadataCache {
  // Cache size limits (number of entries)
  final int maxGroupCacheSize;
  final int maxDatatypeCacheSize;
  final int maxDataspaceCacheSize;

  // Cached data
  Superblock? _superblock;
  Group? _rootGroup;
  final Map<int, _CacheEntry<Group>> _groupCache = {};
  final Map<int, _CacheEntry<Hdf5Datatype>> _datatypeCache = {};
  final Map<int, _CacheEntry<Hdf5Dataspace>> _dataspaceCache = {};

  MetadataCache({
    this.maxGroupCacheSize = 100,
    this.maxDatatypeCacheSize = 50,
    this.maxDataspaceCacheSize = 50,
  });

  /// Caches the superblock (only one per file)
  void cacheSuperblock(Superblock superblock) {
    _superblock = superblock;
  }

  /// Gets the cached superblock
  Superblock? get superblock => _superblock;

  /// Caches the root group (only one per file)
  void cacheRootGroup(Group group) {
    _rootGroup = group;
  }

  /// Gets the cached root group
  Group? get rootGroup => _rootGroup;

  /// Caches a group at the given address
  void cacheGroup(int address, Group group) {
    _evictIfNeeded(_groupCache, maxGroupCacheSize);
    _groupCache[address] = _CacheEntry(group);
  }

  /// Gets a cached group by address
  Group? getGroup(int address) {
    final entry = _groupCache[address];
    if (entry != null) {
      entry.updateAccessTime();
      return entry.value;
    }
    return null;
  }

  /// Caches a datatype at the given address
  void cacheDatatype(int address, Hdf5Datatype datatype) {
    _evictIfNeeded(_datatypeCache, maxDatatypeCacheSize);
    _datatypeCache[address] = _CacheEntry(datatype);
  }

  /// Gets a cached datatype by address
  Hdf5Datatype? getDatatype(int address) {
    final entry = _datatypeCache[address];
    if (entry != null) {
      entry.updateAccessTime();
      return entry.value;
    }
    return null;
  }

  /// Caches a dataspace at the given address
  void cacheDataspace(int address, Hdf5Dataspace dataspace) {
    _evictIfNeeded(_dataspaceCache, maxDataspaceCacheSize);
    _dataspaceCache[address] = _CacheEntry(dataspace);
  }

  /// Gets a cached dataspace by address
  Hdf5Dataspace? getDataspace(int address) {
    final entry = _dataspaceCache[address];
    if (entry != null) {
      entry.updateAccessTime();
      return entry.value;
    }
    return null;
  }

  /// Evicts the least recently used entry if cache is full
  void _evictIfNeeded<T>(Map<int, _CacheEntry<T>> cache, int maxSize) {
    if (cache.length >= maxSize) {
      // Find the least recently used entry
      int? oldestKey;
      int oldestTime = DateTime.now().millisecondsSinceEpoch;

      for (final entry in cache.entries) {
        if (entry.value.lastAccessTime < oldestTime) {
          oldestTime = entry.value.lastAccessTime;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        cache.remove(oldestKey);
      }
    }
  }

  /// Clears all caches
  void clear() {
    _superblock = null;
    _rootGroup = null;
    _groupCache.clear();
    _datatypeCache.clear();
    _dataspaceCache.clear();
  }

  /// Gets cache statistics
  Map<String, dynamic> get stats => {
        'superblock': _superblock != null ? 'cached' : 'not cached',
        'rootGroup': _rootGroup != null ? 'cached' : 'not cached',
        'groups': _groupCache.length,
        'datatypes': _datatypeCache.length,
        'dataspaces': _dataspaceCache.length,
        'totalEntries':
            _groupCache.length + _datatypeCache.length + _dataspaceCache.length,
      };
}

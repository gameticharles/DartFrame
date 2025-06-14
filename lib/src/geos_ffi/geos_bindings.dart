// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

// 1. Define Native Type Aliases

// Opaque types for handles and pointers
final class GEOSContextHandle_opaque extends ffi.Opaque {}
final class GEOSGeometry_opaque extends ffi.Opaque {}
final class GEOSPreparedGeometry_opaque extends ffi.Opaque {}
final class GEOSWKTReader_opaque extends ffi.Opaque {}
final class GEOSWKTWriter_opaque extends ffi.Opaque {}
final class GEOSWKBReader_opaque extends ffi.Opaque {}
final class GEOSWKBWriter_opaque extends ffi.Opaque {}
final class GEOSCoordSequence_opaque extends ffi.Opaque {}

// Typedefs for pointers to opaque types
typedef GEOSContextHandle_t = ffi.Pointer<GEOSContextHandle_opaque>;
typedef GEOSGeometry = ffi.Pointer<GEOSGeometry_opaque>;
typedef GEOSPreparedGeometry = ffi.Pointer<GEOSPreparedGeometry_opaque>;
typedef GEOSWKTReader = ffi.Pointer<GEOSWKTReader_opaque>;
typedef GEOSWKTWriter = ffi.Pointer<GEOSWKTWriter_opaque>;
typedef GEOSWKBReader = ffi.Pointer<GEOSWKBReader_opaque>;
typedef GEOSWKBWriter = ffi.Pointer<GEOSWKBWriter_opaque>;
typedef GEOSCoordSequence = ffi.Pointer<GEOSCoordSequence_opaque>;

// Typedef for the message handler callback
// Native signature: void GEOSMessageHandler_r(const char *message, void *userData)
typedef GEOSMessageHandler_r_native = ffi.Void Function(
    ffi.Pointer<Utf8> message, ffi.Pointer<ffi.Void> userData);
// Dart signature for the callback pointer
typedef GEOSMessageHandler_r = ffi.Pointer<ffi.NativeFunction<GEOSMessageHandler_r_native>>;

// 2. Load GEOS Library
// This will be platform-dependent and might need configuration.
// For now, we'll use a placeholder and show how to load it.
// You'll need to replace 'libgeos_c' with the actual library name
// e.g. 'libgeos_c.so.1' on Linux, 'libgeos_c.dylib' on macOS, 'geos_c.dll' on Windows.

ffi.DynamicLibrary _loadGEOSLibrary() {
  if (ffi.Abi.current() == ffi.Abi.linuxX64 || ffi.Abi.current() == ffi.Abi.linuxArm64) {
    return ffi.DynamicLibrary.open('libgeos_c.so.1');
  }
  if (ffi.Abi.current() == ffi.Abi.macosX64 || ffi.Abi.current() == ffi.Abi.macosArm64) {
    return ffi.DynamicLibrary.open('libgeos_c.dylib');
  }
  if (ffi.Abi.current() == ffi.Abi.windowsX64 || ffi.Abi.current() == ffi.Abi.windowsIA32) {
    return ffi.DynamicLibrary.open('geos_c.dll');
  }
  throw UnsupportedError('Unsupported platform for GEOS FFI');
}

final geos = _loadGEOSLibrary();

// 3. Define FFI Function Signatures
class GEOSFFIBindings {
  final ffi.DynamicLibrary _geos;

  GEOSFFIBindings(this._geos) {
    _initialize();
  }

  factory GEOSFFIBindings.load(String path) {
    return GEOSFFIBindings(ffi.DynamicLibrary.open(path));
  }

  factory GEOSFFIBindings.process() {
    return GEOSFFIBindings(ffi.DynamicLibrary.process());
  }
  
  factory GEOSFFIBindings.defaultLibrary() {
    return GEOSFFIBindings(geos);
  }

  // Function pointers
  // Context Management
  late GEOSContextHandle_t Function() GEOS_init_r;
  late void Function(GEOSContextHandle_t handle) GEOS_finish_r;
  late void Function(GEOSContextHandle_t extHandle, GEOSMessageHandler_r ef, ffi.Pointer<ffi.Void> userData) GEOSContext_setErrorMessageHandler_r;

  // WKT Reading/Writing
  late GEOSWKTReader Function(GEOSContextHandle_t handle) GEOSWKTReader_create_r;
  late GEOSGeometry Function(GEOSContextHandle_t handle, GEOSWKTReader reader, ffi.Pointer<Utf8> wkt) GEOSWKTReader_read_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKTReader reader) GEOSWKTReader_destroy_r;
  late GEOSWKTWriter Function(GEOSContextHandle_t handle) GEOSWKTWriter_create_r;
  late ffi.Pointer<Utf8> Function(GEOSContextHandle_t handle, GEOSWKTWriter writer, GEOSGeometry g) GEOSWKTWriter_write_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKTWriter writer) GEOSWKTWriter_destroy_r;
  late void Function(GEOSContextHandle_t handle, ffi.Pointer<ffi.Void> buffer) GEOSFree_r;

  // WKB Reading/Writing
  late GEOSWKBReader Function(GEOSContextHandle_t handle) GEOSWKBReader_create_r;
  late GEOSGeometry Function(GEOSContextHandle_t handle, GEOSWKBReader reader, ffi.Pointer<ffi.Uint8> wkb, int size) GEOSWKBReader_read_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKBReader reader) GEOSWKBReader_destroy_r;
  late GEOSWKBWriter Function(GEOSContextHandle_t handle) GEOSWKBWriter_create_r;
  late ffi.Pointer<ffi.Uint8> Function(GEOSContextHandle_t handle, GEOSWKBWriter writer, GEOSGeometry g, ffi.Pointer<ffi.IntPtr> size) GEOSWKBWriter_write_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKBWriter writer) GEOSWKBWriter_destroy_r;
  
  // Geometry Destruction
  late void Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSGeom_destroy_r;

  // Binary Predicates
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSContains_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSIntersects_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSWithin_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSDisjoint_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSEquals_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSTouches_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSCrosses_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSOverlaps_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSCovers_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSCoveredBy_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, ffi.Pointer<Utf8> imPattern) GEOSRelatePattern_r;
  late ffi.Pointer<Utf8> Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSRelate_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, double dist) GEOSDistanceWithin_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, double tolerance) GEOSEqualsExact_r;

  // Other Utility Functions
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSisEmpty_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSisSimple_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSisValid_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSGeomTypeId_r;
  late GEOSPreparedGeometry Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSPrepare_r;
  late void Function(GEOSContextHandle_t handle, GEOSPreparedGeometry pg) GEOSPreparedGeom_destroy_r;
  late int Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, ffi.Pointer<ffi.Double> dist) GEOSDistance_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKTWriter writer, int trim) GEOSWKTWriter_setTrim_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKTWriter writer, int dim) GEOSWKTWriter_setOutputDimension_r;



  void _initialize() {
    // Context Management
    GEOS_init_r = _geos
        .lookup<ffi.NativeFunction<GEOSContextHandle_t Function()>>('GEOS_init_r')
        .asFunction();
    GEOS_finish_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t)>>('GEOS_finish_r')
        .asFunction();
    GEOSContext_setErrorMessageHandler_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSMessageHandler_r, ffi.Pointer<ffi.Void>)>>('GEOSContext_setErrorMessageHandler_r')
        .asFunction();

    // WKT Reading/Writing
    GEOSWKTReader_create_r = _geos
        .lookup<ffi.NativeFunction<GEOSWKTReader Function(GEOSContextHandle_t)>>('GEOSWKTReader_create_r')
        .asFunction();
    GEOSWKTReader_read_r = _geos
        .lookup<ffi.NativeFunction<GEOSGeometry Function(GEOSContextHandle_t, GEOSWKTReader, ffi.Pointer<Utf8>)>>('GEOSWKTReader_read_r')
        .asFunction();
    GEOSWKTReader_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKTReader)>>('GEOSWKTReader_destroy_r')
        .asFunction();
    GEOSWKTWriter_create_r = _geos
        .lookup<ffi.NativeFunction<GEOSWKTWriter Function(GEOSContextHandle_t)>>('GEOSWKTWriter_create_r')
        .asFunction();
    GEOSWKTWriter_write_r = _geos
        .lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(GEOSContextHandle_t, GEOSWKTWriter, GEOSGeometry)>>('GEOSWKTWriter_write_r')
        .asFunction();
    GEOSWKTWriter_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKTWriter)>>('GEOSWKTWriter_destroy_r')
        .asFunction();
    // Add these missing WKT Writer configuration method lookups
    GEOSWKTWriter_setTrim_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKTWriter, ffi.Int)>>('GEOSWKTWriter_setTrim_r')
        .asFunction();
    GEOSWKTWriter_setOutputDimension_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKTWriter, ffi.Int)>>('GEOSWKTWriter_setOutputDimension_r')
        .asFunction();
        
    GEOSFree_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, ffi.Pointer<ffi.Void>)>>('GEOSFree_r')
        .asFunction();

    // WKB Reading/Writing
    GEOSWKBReader_create_r = _geos
        .lookup<ffi.NativeFunction<GEOSWKBReader Function(GEOSContextHandle_t)>>('GEOSWKBReader_create_r')
        .asFunction();
    GEOSWKBReader_read_r = _geos
        .lookup<ffi.NativeFunction<GEOSGeometry Function(GEOSContextHandle_t, GEOSWKBReader, ffi.Pointer<ffi.Uint8>, ffi.Size)>>('GEOSWKBReader_read_r')
        .asFunction();
    GEOSWKBReader_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKBReader)>>('GEOSWKBReader_destroy_r')
        .asFunction();

    // Geometry Destruction
    GEOSGeom_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSGeom_destroy_r')
        .asFunction();

    // Binary Predicates
    GEOSContains_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSContains_r')
        .asFunction();
    GEOSIntersects_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSIntersects_r')
        .asFunction();
    GEOSWithin_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSWithin_r')
        .asFunction();
    GEOSDisjoint_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSDisjoint_r')
        .asFunction();
    GEOSEquals_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSEquals_r')
        .asFunction();
    GEOSTouches_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSTouches_r')
        .asFunction();
    GEOSCrosses_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSCrosses_r')
        .asFunction();
    GEOSOverlaps_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSOverlaps_r')
        .asFunction();
    GEOSCovers_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSCovers_r')
        .asFunction();
    GEOSCoveredBy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSCoveredBy_r')
        .asFunction();
    GEOSRelatePattern_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Pointer<Utf8>)>>('GEOSRelatePattern_r')
        .asFunction();
    GEOSRelate_r = _geos
        .lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSRelate_r')
        .asFunction();
    GEOSDistanceWithin_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Double)>>('GEOSDistanceWithin_r')
        .asFunction();
    GEOSEqualsExact_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Double)>>('GEOSEqualsExact_r')
        .asFunction();
    
    // Other Utility Functions
    GEOSisEmpty_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSisEmpty_r')
        .asFunction();
    GEOSisSimple_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSisSimple_r')
        .asFunction();
    GEOSisValid_r = _geos
        .lookup<ffi.NativeFunction<ffi.Char Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSisValid_r')
        .asFunction();
    GEOSGeomTypeId_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSGeomTypeId_r')
        .asFunction();
    GEOSPrepare_r = _geos
        .lookup<ffi.NativeFunction<GEOSPreparedGeometry Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSPrepare_r')
        .asFunction();
    GEOSPreparedGeom_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSPreparedGeometry)>>('GEOSPreparedGeom_destroy_r')
        .asFunction();
    GEOSDistance_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Pointer<ffi.Double>)>>('GEOSDistance_r')
        .asFunction();
  }
}
/*
// --- Helper Functions ---

/// Converts a Dart string to a C-style null-terminated UTF-8 string.
/// The caller is responsible for freeing the allocated memory using `pkg_ffi.malloc.free()`.
ffi.Pointer<pkg_ffi.Utf8> stringToCharPointer(String s) {
  return s.toNativeUtf8(allocator: pkg_ffi.malloc);
}

/// Converts a C-style null-terminated char* (assumed UTF-8) to a Dart string.
String charPointerToString(ffi.Pointer<ffi.Char> ptr) {
  return ptr.cast<pkg_ffi.Utf8>().toDartString();
}

/// Creates a GEOSGeometry from a WKT string using the provided context and WKT reader.
/// Returns `ffi.nullptr` if WKT is invalid or reader fails.
/// The caller is responsible for destroying the returned GEOSGeom if not null/nullptr,
/// OR if this function returns ffi.nullptr (as GEOSWKTReader_read_r might return null on parse error).
GEOSGeom createGeosGeomFromWKT(String wkt, GEOSContextHandle_t context, GEOSWKTReader_t reader) {
  final wktPointer = stringToCharPointer(wkt);
  GEOSGeom geom = ffi.nullptr; // Initialize to nullptr
  try {
    geom = GEOSWKTReader_read_r(context, reader, wktPointer);
    // No need to check geom.address == 0 here explicitly, as ffi.nullptr.address is 0.
    // If GEOSWKTReader_read_r returns NULL, geom will remain ffi.nullptr.
  } finally {
    pkg_ffi.malloc.free(wktPointer); // Free the C string memory
  }
  return geom; // Can be ffi.nullptr if read failed
}

/// Converts a GEOSGeometry to a WKT string using the provided context and WKT writer.
/// Returns null if the geometry is invalid, writer fails, or if the input geom is nullptr.
/// The C string returned by GEOS is freed by this function.
String? getWKTFromGeosGeom(GEOSGeom geom, GEOSContextHandle_t context, GEOSWKTWriter_t writer) {
  if (geom.address == 0) return null; // Handle nullptr input
  ffi.Pointer<ffi.Char> wktCStrPtr = GEOSWKTWriter_write_r(context, writer, geom);
  
  if (wktCStrPtr.address == 0) { // Check if GEOS returned a null pointer
    return null;
  }
  try {
    return charPointerToString(wktCStrPtr);
  } finally {
    // The string returned by GEOSWKTWriter_write_r must be freed with GEOSFree_r
     freeGeosMemory(context, wktCStrPtr.cast<ffi.Void>());
  }
}

/// Frees memory allocated by GEOS (e.g., for WKT strings from GEOSWKTWriter_write_r).
void freeGeosMemory(GEOSContextHandle_t context, ffi.Pointer<ffi.Void> buffer) {
   if (buffer.address != 0) { // Do not attempt to free a null pointer
    GEOSFree_r(context, buffer);
   }
}

/// Global GEOS context handle, initialized once.
final GEOSContextHandle_t globalContextHandle = GEOS_init_r();

// TODO: Add a proper mechanism for GEOS_finish_r when the application/isolate exits.
// A notice/error handler could be added to globalContextHandle via GEOSContext_setNoticeHandler_r
// if more detailed error messages from GEOS are desired.

*/
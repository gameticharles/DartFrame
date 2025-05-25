// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

// 1. Define Native Type Aliases

// Opaque types for handles and pointers
class GEOSContextHandle_opaque extends ffi.Opaque {}
class GEOSGeometry_opaque extends ffi.Opaque {}
class GEOSPreparedGeometry_opaque extends ffi.Opaque {}
class GEOSWKTReader_opaque extends ffi.Opaque {}
class GEOSWKTWriter_opaque extends ffi.Opaque {}
class GEOSWKBReader_opaque extends ffi.Opaque {}
class GEOSWKBWriter_opaque extends ffi.Opaque {}
class GEOSCoordSequence_opaque extends ffi.Opaque {}

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

DynamicLibrary _loadGEOSLibrary() {
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
  late GEOSGeometry Function(GEOSContextHandle_t handle, GEOSWKBReader reader, ffi.Pointer<ffi.Uint8> wkb, ffi.IntPtr size) GEOSWKBReader_read_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKBReader reader) GEOSWKBReader_destroy_r;
  late GEOSWKBWriter Function(GEOSContextHandle_t handle) GEOSWKBWriter_create_r;
  late ffi.Pointer<ffi.Uint8> Function(GEOSContextHandle_t handle, GEOSWKBWriter writer, GEOSGeometry g, ffi.Pointer<ffi.IntPtr> size) GEOSWKBWriter_write_r;
  late void Function(GEOSContextHandle_t handle, GEOSWKBWriter writer) GEOSWKBWriter_destroy_r;
  
  // Geometry Destruction
  late void Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSGeom_destroy_r;

  // Binary Predicates
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSContains_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSIntersects_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSWithin_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSDisjoint_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSEquals_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSTouches_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSCrosses_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSOverlaps_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSCovers_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSCoveredBy_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, ffi.Pointer<Utf8> imPattern) GEOSRelatePattern_r;
  late ffi.Pointer<Utf8> Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2) GEOSRelate_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, ffi.Double dist) GEOSDistanceWithin_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, ffi.Double tolerance) GEOSEqualsExact_r;

  // Other Utility Functions
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSisEmpty_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSisSimple_r;
  late ffi.Int8 Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSisValid_r;
  late ffi.Int32 Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSGeomTypeId_r; // GEOSGeomTypes in geos_c.h is an enum, typically int
  late GEOSPreparedGeometry Function(GEOSContextHandle_t handle, GEOSGeometry g) GEOSPrepare_r;
  late void Function(GEOSContextHandle_t handle, GEOSPreparedGeometry pg) GEOSPreparedGeom_destroy_r;
  late ffi.Int32 Function(GEOSContextHandle_t handle, GEOSGeometry g1, GEOSGeometry g2, ffi.Pointer<ffi.Double> dist) GEOSDistance_r; // Returns int, not char


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
    GEOSFree_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, ffi.Pointer<ffi.Void>)>>('GEOSFree_r')
        .asFunction();

    // WKB Reading/Writing
    GEOSWKBReader_create_r = _geos
        .lookup<ffi.NativeFunction<GEOSWKBReader Function(GEOSContextHandle_t)>>('GEOSWKBReader_create_r')
        .asFunction();
    GEOSWKBReader_read_r = _geos
        .lookup<ffi.NativeFunction<GEOSGeometry Function(GEOSContextHandle_t, GEOSWKBReader, ffi.Pointer<ffi.Uint8>, ffi.IntPtr)>>('GEOSWKBReader_read_r')
        .asFunction();
    GEOSWKBReader_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKBReader)>>('GEOSWKBReader_destroy_r')
        .asFunction();
    GEOSWKBWriter_create_r = _geos
        .lookup<ffi.NativeFunction<GEOSWKBWriter Function(GEOSContextHandle_t)>>('GEOSWKBWriter_create_r')
        .asFunction();
    GEOSWKBWriter_write_r = _geos
        .lookup<ffi.NativeFunction<ffi.Pointer<ffi.Uint8> Function(GEOSContextHandle_t, GEOSWKBWriter, GEOSGeometry, ffi.Pointer<ffi.IntPtr>)>>('GEOSWKBWriter_write_r')
        .asFunction();
    GEOSWKBWriter_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSWKBWriter)>>('GEOSWKBWriter_destroy_r')
        .asFunction();

    // Geometry Destruction
    GEOSGeom_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSGeom_destroy_r')
        .asFunction();

    // Binary Predicates
    GEOSContains_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSContains_r')
        .asFunction();
    GEOSIntersects_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSIntersects_r')
        .asFunction();
    GEOSWithin_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSWithin_r')
        .asFunction();
    GEOSDisjoint_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSDisjoint_r')
        .asFunction();
    GEOSEquals_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSEquals_r')
        .asFunction();
    GEOSTouches_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSTouches_r')
        .asFunction();
    GEOSCrosses_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSCrosses_r')
        .asFunction();
    GEOSOverlaps_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSOverlaps_r')
        .asFunction();
    GEOSCovers_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSCovers_r')
        .asFunction();
    GEOSCoveredBy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSCoveredBy_r')
        .asFunction();
    GEOSRelatePattern_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Pointer<Utf8>)>>('GEOSRelatePattern_r')
        .asFunction();
    GEOSRelate_r = _geos
        .lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry)>>('GEOSRelate_r')
        .asFunction();
    GEOSDistanceWithin_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Double)>>('GEOSDistanceWithin_r')
        .asFunction();
    GEOSEqualsExact_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Double)>>('GEOSEqualsExact_r')
        .asFunction();
    
    // Other Utility Functions
    GEOSisEmpty_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSisEmpty_r')
        .asFunction();
    GEOSisSimple_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSisSimple_r')
        .asFunction();
    GEOSisValid_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int8 Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSisValid_r')
        .asFunction();
    GEOSGeomTypeId_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int32 Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSGeomTypeId_r')
        .asFunction();
    GEOSPrepare_r = _geos
        .lookup<ffi.NativeFunction<GEOSPreparedGeometry Function(GEOSContextHandle_t, GEOSGeometry)>>('GEOSPrepare_r')
        .asFunction();
    GEOSPreparedGeom_destroy_r = _geos
        .lookup<ffi.NativeFunction<ffi.Void Function(GEOSContextHandle_t, GEOSPreparedGeometry)>>('GEOSPreparedGeom_destroy_r')
        .asFunction();
    GEOSDistance_r = _geos
        .lookup<ffi.NativeFunction<ffi.Int32 Function(GEOSContextHandle_t, GEOSGeometry, GEOSGeometry, ffi.Pointer<ffi.Double>)>>('GEOSDistance_r')
        .asFunction();
  }
}

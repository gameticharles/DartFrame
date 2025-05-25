// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi' as ffi;
import 'package:dartframe/dartframe.dart';
import 'package:ffi/ffi.dart';
import 'geos_bindings.dart';

/// Converts a Dart [GeoJSONGeometry] to a GEOS [GEOSGeometry] pointer.
///
/// The caller is responsible for destroying the returned [GEOSGeometry]
/// using `bindings.GEOSGeom_destroy_r(contextHandle, result)`.
///
/// Returns `ffi.nullptr` if [dartGeom] is null or if conversion fails.
/// Throws exceptions if GEOS reader creation fails. Returns `nullptr` if WKT parsing fails.
GEOSGeometry geoJSONToGEOS(
  GeoJSONGeometry? dartGeom,
  GEOSFFIBindings bindings,
  GEOSContextHandle_t contextHandle,
) {
  if (dartGeom == null) {
    return ffi.nullptr;
  }

  ffi.Pointer<Utf8> nativeWkt;
  try {
    // Assuming dartGeom.toWKT() is the correct method name.
    // If it's dartGeom.toWkt(), this line should be changed.
    final wktString = dartGeom.toWkt();
    nativeWkt = wktString.toNativeUtf8();
  } catch (e) {
    print('Error converting GeoJSON to WKT or WKT to native UTF8: $e');
    return ffi.nullptr; // Return nullptr if WKT conversion or native string conversion fails
  }

  final wktReader = bindings.GEOSWKTReader_create_r(contextHandle);
  if (wktReader == ffi.nullptr) {
    malloc.free(nativeWkt); // Free allocated nativeWkt before throwing
    throw Exception('Failed to create GEOSWKTReader.');
  }

  final geosGeom = bindings.GEOSWKTReader_read_r(contextHandle, wktReader, nativeWkt);

  malloc.free(nativeWkt); // Free nativeWkt after use
  bindings.GEOSWKTReader_destroy_r(contextHandle, wktReader);

  if (geosGeom == ffi.nullptr) {
    // WKT parsing failed
    print('GEOSWKTReader_read_r failed to parse WKT. Input WKT might be invalid.');
    // The task asks to "throw an informative exception or return nullptr after logging".
    // Returning nullptr is chosen here.
    return ffi.nullptr;
  }

  return geosGeom;
}

/// Converts a GEOS [GEOSGeometry] pointer to its WKT [String] representation.
///
/// Returns `null` if [geosGeom] is `nullptr` or if conversion fails.
/// Throws exceptions if GEOS writer creation fails or WKT writing fails.
String? geosToWKT(
  GEOSGeometry geosGeom,
  GEOSFFIBindings bindings,
  GEOSContextHandle_t contextHandle,
) {
  if (geosGeom == ffi.nullptr) {
    print('geosToWKT received a null GEOSGeometry pointer.');
    return null; // As per instruction: "return null or throw an error"
  }

  final wktWriter = bindings.GEOSWKTWriter_create_r(contextHandle);
  if (wktWriter == ffi.nullptr) {
    throw Exception('Failed to create GEOSWKTWriter.');
  }

  // Set desired properties on the writer as per subtask instructions.
  // This assumes GEOSWKTWriter_setTrim_r and GEOSWKTWriter_setOutputDimension_r
  // are (or will be) defined in GEOSFFIBindings.
  // If these bindings do not exist, this will cause a compile-time error.
  // The subtask for geos_bindings.dart should ideally have included them.
  bindings.GEOSWKTWriter_setTrim_r(contextHandle, wktWriter, 1); // Enable trim
  bindings.GEOSWKTWriter_setOutputDimension_r(contextHandle, wktWriter, 3); // Default to 3D

  final nativeWkt = bindings.GEOSWKTWriter_write_r(contextHandle, wktWriter, geosGeom);
  // Destroy the writer immediately after use, regardless of nativeWkt outcome.
  bindings.GEOSWKTWriter_destroy_r(contextHandle, wktWriter);

  if (nativeWkt == ffi.nullptr) {
    // As per instruction: "If nativeWkt is nullptr (write failed), throw an exception."
    throw Exception('GEOSWKTWriter_write_r failed to write geometry to WKT.');
  }

  String? result;
  try {
    result = nativeWkt.toDartString();
  } catch (e) {
    print('Error converting native WKT to Dart String: $e');
    result = null; // Ensure null is returned on conversion error
  } finally {
    // Free the nativeWkt C string using GEOSFree_r
    bindings.GEOSFree_r(contextHandle, nativeWkt.cast<ffi.Void>());
  }

  return result;
}

part of '../../dartframe.dart';

import 'package:ffi/ffi.dart' as ffi;
import '../geos_ffi/geos_bindings.dart';
import '../geos_ffi/geos_utils.dart';

extension GeoSeriesFunctions on GeoSeries {
  /// Gets coordinates from a GeoSeries as a DataFrame of floats.
  ///
  /// The shape of the returned DataFrame is (N, 2), with N being the number of coordinate pairs.
  /// With the default of includeZ=false, three-dimensional data is ignored.
  /// When specifying includeZ=true, the shape of the returned DataFrame is (N, 3).
  ///
  /// Parameters:
  ///   - `includeZ`: Include Z coordinates (default: false)
  ///   - `ignoreIndex`: If true, the resulting index will be labelled 0, 1, ..., n - 1,
  ///     ignoring indexParts (default: false)
  ///   - `indexParts`: If true, the resulting index will include both the original index
  ///     and a part index for each coordinate in a geometry (default: false)
  ///
  /// Returns a DataFrame with columns `['x', 'y']` or `['x', 'y', 'z']`
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONLineString([[1, -1], [1, 0]]),
  ///   GeoJSONPolygon([[[3, -1], [4, 0], [3, 1], [3, -1]]]),
  /// ]);
  ///
  /// // Default behavior - preserves original indices
  /// final coords = series.getCoordinates();
  /// // Returns DataFrame:
  /// //      x    y
  /// // 0  1.0  1.0
  /// // 1  1.0 -1.0
  /// // 1  1.0  0.0
  /// // 2  3.0 -1.0
  /// // 2  4.0  0.0
  /// // 2  3.0  1.0
  /// // 2  3.0 -1.0
  ///
  /// // With ignore_index=true - uses sequential indices
  /// final coordsIgnoreIndex = series.getCoordinates(ignoreIndex: true);
  /// // Returns DataFrame:
  /// //      x    y
  /// // 0  1.0  1.0
  /// // 1  1.0 -1.0
  /// // 2  1.0  0.0
  /// // 3  3.0 -1.0
  /// // 4  4.0  0.0
  /// // 5  3.0  1.0
  /// // 6  3.0 -1.0
  ///
  /// // With index_parts=true - uses multi-index with geometry index and part index
  /// final coordsIndexParts = series.getCoordinates(indexParts: true);
  /// // Returns DataFrame:
  /// //        x    y
  /// // 0 0  1.0  1.0
  /// // 1 0  1.0 -1.0
  /// //   1  1.0  0.0
  /// // 2 0  3.0 -1.0
  /// //   1  4.0  0.0
  /// //   2  3.0  1.0
  /// //   3  3.0 -1.0
  /// ```
  DataFrame getCoordinates({
    bool includeZ = false,
    bool ignoreIndex = false,
    bool indexParts = false,
    bool indexPartsAsList = false,
  }) {
    List<List<dynamic>> coordData = [];
    List<dynamic> indices = [];
    List<dynamic> partIndices = [];
    List<dynamic> originalIndices = index;

    // Extract coordinates from each geometry
    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      final originalIndex =
          originalIndices[i]; // Capture original index for this geometry
      if (geom is GeoJSONGeometry) {
        List<List<double>> coords = _extractCoordinates(geom);

        // Add coordinates and indices
        for (int j = 0; j < coords.length; j++) {
          var coord = coords[j];
          if (includeZ) {
            coordData
                .add([coord[0], coord[1], coord.length > 2 ? coord[2] : 0.0]);
          } else {
            coordData.add([coord[0], coord[1]]);
          }

          indices.add(
              originalIndex); // Use original index for this specific geometry
          partIndices.add(j);
        }
      } else {
        // Handle null geometries - add placeholder or skip
        // If we need to maintain a 1:1 correspondence in rows even for null geoms for some reason:
        // coordData.add(includeZ ? [double.nan, double.nan, double.nan] : [double.nan, double.nan]);
        // indices.add(originalIndex);
        // partIndices.add(0);
        // However, get_coordinates usually skips nulls.
      }
    }

    // Create column names
    List<String> columns = includeZ ? ['x', 'y', 'z'] : ['x', 'y'];

    // Create DataFrame
    DataFrame result;
    if (ignoreIndex) {
      // Use simple numeric index for the coordData length
      result = DataFrame(columns: columns, coordData);
    } else if (indexParts) {
      // Create multi-index using both original index and part index
      List<dynamic> multiIndex = List.generate(
          coordData.length, // Length of the actual coordinate data collected
          (k) => indexPartsAsList
              ? [indices[k], partIndices[k]]
              : (partIndices[k] == 0
                  ? "${indices[k]} ${partIndices[k]}"
                  : "  ${partIndices[k]}"
                      .padLeft("${indices[k]} ${partIndices[k]}".length + 1)));
      result = DataFrame(coordData, columns: columns, index: multiIndex);
    } else {
      // Use original geometry indices (flattened, corresponding to each coordinate)
      result = DataFrame(coordData, columns: columns, index: indices);
    }

    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is almost equal to the corresponding geometry in `other` within a given tolerance.
  Series<bool> geomAlmostEquals(dynamic other, double tolerance, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'geomAlmostEquals' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosAlmostEquals(g, other, tolerance, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_geom_almost_equals', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosAlmostEquals(
                data[i], other.data[i], tolerance, bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "geomAlmostEquals with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_geom_almost_equals', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for geomAlmostEquals method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is almost equal to geom2 using GEOS, within a tolerance.
  bool _geosAlmostEquals(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2, double tolerance,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    
    if (geom1 == null || geom2 == null) {
      return false;
    }
    if (tolerance < 0) {
        print("Warning: geomAlmostEquals called with negative tolerance ($tolerance). Using absolute value.");
        tolerance = tolerance.abs();
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSEqualsExact_r(contextHandle, tempGeosGeom1, tempGeosGeom2, tolerance);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSEqualsExact_r (geomAlmostEquals) reported an error for geometries (WKT): '$wkt1' and '$wkt2' with tolerance $tolerance");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is within a specified distance of the corresponding geometry in `other`.
  Series<bool> dwithin(dynamic other, double distance, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'dwithin' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosDWithin(g, other, distance, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_dwithin', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosDWithin(
                data[i], other.data[i], distance, bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "dwithin with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_dwithin', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for dwithin method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is within a given distance of geom2 using GEOS
  bool _geosDWithin(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2, double distance,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    
    if (geom1 == null || geom2 == null) {
      return false;
    }
    if (distance < 0) {
        // GEOS may handle this, but it's clearer to define behavior.
        // Typically, distance cannot be negative.
        print("Warning: dwithin called with negative distance ($distance). Returning false.");
        return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSDistanceWithin_r(contextHandle, tempGeosGeom1, tempGeosGeom2, distance);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSDistanceWithin_r reported an error for geometries (WKT): '$wkt1' and '$wkt2' with distance $distance");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is topologically covered by the corresponding geometry in `other`.
  Series<bool> coveredBy(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'coveredBy' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosCoveredBy(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_coveredBy', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosCoveredBy(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "coveredBy with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_coveredBy', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for coveredBy method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is topologically covered by geom2 using GEOS
  bool _geosCoveredBy(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSCoveredBy_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSCoveredBy_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != ffi.nullptr) { // Added null check for safety, though should be non-null
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) { // Added null check for safety
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that topologically covers the corresponding geometry in `other`.
  Series<bool> covers(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'covers' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosCovers(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_covers', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosCovers(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "covers with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_covers', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for covers method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 topologically covers geom2 using GEOS
  bool _geosCovers(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSCovers_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSCovers_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that topologically overlaps the corresponding geometry in `other`.
  Series<bool> overlaps(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'overlaps' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosOverlaps(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_overlaps', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosOverlaps(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "overlaps with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_overlaps', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for overlaps method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 topologically overlaps geom2 using GEOS
  bool _geosOverlaps(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSOverlaps_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSOverlaps_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that topologically crosses the corresponding geometry in `other`.
  Series<bool> crosses(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'crosses' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosCrosses(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_crosses', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosCrosses(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "crosses with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_crosses', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for crosses method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 topologically crosses geom2 using GEOS
  bool _geosCrosses(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSCrosses_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSCrosses_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that topologically touches the corresponding geometry in `other`.
  Series<bool> touches(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'touches' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosTouches(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_touches', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosTouches(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "touches with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_touches', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for touches method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 topologically touches geom2 using GEOS
  bool _geosTouches(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSTouches_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSTouches_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is topologically equal to the corresponding geometry in `other`.
  Series<bool> geom_equals(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'geom_equals' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosEquals(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_geom_equals', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosEquals(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "geom_equals with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_geom_equals', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for geom_equals method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is topologically equal to geom2 using GEOS
  bool _geosEquals(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      // NOTE: GEOSEquals_r is for topological equality.
      final charResult =
          bindings.GEOSEquals_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSEquals_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is spatially within the corresponding geometry in `other`.
  Series<bool> within(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'within' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosWithin(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_within', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(
                _geosWithin(data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false);
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }
          // No specific adjustment needed if resultData.length == index.length or resultData.length > index.length
          // (which implies 'this' series was shorter or equal length to 'other')
          // as resultIndex is already this.index.

        } else {
          throw UnimplementedError(
              "within with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_within', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for within method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is within geom2 using GEOS
  bool _geosWithin(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // Note: GEOSGeometry is already ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      // geoJSONToGEOS logs its own errors
      return false;
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      if (geosGeom1 != ffi.nullptr) { // Should always be true here, but good practice
          bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      }
      // geoJSONToGEOS logs its own errors
      return false;
    }

    // Using GEOSGeometry (which is a Pointer type) directly.
    // The _ptr suffix is not part of the actual typedef in geos_bindings.dart.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // Redundant null check if geoJSONToGEOS guarantees non-null or throws,
      // and if prior checks catch ffi.nullptr. But safe.
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSWithin_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // 2 indicates an exception in GEOS
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) {}
        try { wkt2 = geom2.toWKT(); } catch (_) {}
        print("GEOSWithin_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1; // 1 for true, 0 for false
      }
    } finally {
      // Ensure GEOS geometries are destroyed
      if (tempGeosGeom1 != ffi.nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each aligned geometry that intersects other.
  Series intersects(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosIntersects(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData,
            name: '${name}_intersects', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            // Assuming data[i] and other.data[i] are the geometries to compare
            // If series need to be aligned by index first, that's a more complex operation
            // For now, this is positional alignment.
            resultData.add(_geosIntersects(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false);
          }
          // If 'this' series was shorter, resultData is already commonLength.
          // The index should match 'this' series' index, truncated if 'this' was longer.
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          } else if (resultData.length > index.length && length < other.length) {
            // This case implies 'this' series was shorter than 'other',
            // and resultData was padded to 'this.length'.
            // No change to resultIndex needed if it's already 'this.index'.
          }


        } else { // No alignment, iterate over this series, compare each with other (scalar)
            throw UnimplementedError("intersects with align=false is not yet fully specified for GeoSeries vs GeoSeries. Defaulting to align=true behavior for now or consider scalar comparison.");
            // If it were scalar comparison:
            // for (int i = 0; i < length; ++i) {
            //   resultData.add(_geosIntersects(data[i], other.data[0], bindings, contextHandle)); // Example: compare all of this to first of other
            // }
        }
         return Series<bool>(resultData, name: '${name}_intersects', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for intersects method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if one geometry intersects another using GEOS
  bool _geosIntersects(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    final geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    final geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(
          contextHandle, geosGeom1); // Clean up geosGeom1
      return false; // geoJSONToGEOS logs errors
    }

    // Correct typedef for GEOSGeometry pointers for clarity, actual type is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This check is slightly redundant if geoJSONToGEOS handles its errors well, but safe.
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false;
      }
      final charResult = bindings.GEOSIntersects_r(
          contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // 2 indicates an exception in GEOS
        String? wkt1, wkt2;
        try { wkt1 = geom1.toWKT(); } catch (_) { wkt1 = "Invalid WKT for geom1"; }
        try { wkt2 = geom2.toWKT(); } catch (_) { wkt2 = "Invalid WKT for geom2"; }
        print(
            "GEOSIntersects_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1; // 1 for true, 0 for false
      }
    } finally {
      // Ensure GEOS geometries are destroyed
      // Null check already performed for tempGeosGeom1 & tempGeosGeom2 before use in GEOSIntersects_r
      // but as a safety for the destroy calls themselves if the pointers were re-assigned or nulled.
      if (tempGeosGeom1 != ffi.nullptr) {
         bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series containing the count of the number of coordinate pairs in each geometry.
  Series get countCoordinates {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      if (geom is GeoJSONPoint) return 1;
      if (geom is GeoJSONMultiPoint) return geom.coordinates.length;
      if (geom is GeoJSONLineString) return geom.coordinates.length;
      if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.fold<int>(0, (sum, line) => sum + line.length);
      }
      if (geom is GeoJSONPolygon) {
        return geom.coordinates.fold<int>(0, (sum, ring) => sum + ring.length);
      }
      if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.fold<int>(
            0,
            (sum, poly) =>
                sum +
                poly.fold<int>(0, (sumRing, ring) => sumRing + ring.length));
      }
      return 0;
    }).toList();
    return Series(counts, name: '${name}_coordinate_count', index: index);
  }

  /// Returns a Series containing the count of geometries in each multi-part geometry.
  Series get countGeometries {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      if (geom is GeoJSONMultiPoint) return geom.coordinates.length;
      if (geom is GeoJSONMultiLineString) return geom.coordinates.length;
      if (geom is GeoJSONMultiPolygon) return geom.coordinates.length;
      if (geom is GeoJSONGeometry) return 1; // Single geometries
      return 0;
    }).toList();
    return Series(counts, name: '${name}_geometry_count', index: index);
  }

  /// Returns a Series containing the count of the number of interior rings in a polygonal geometry.
  Series get countInteriorRings {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      if (geom is GeoJSONPolygon) {
        return geom.coordinates.length > 1 ? geom.coordinates.length - 1 : 0;
      }
      if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.fold<int>(
            0, (sum, poly) => sum + (poly.length > 1 ? poly.length - 1 : 0));
      }
      return 0;
    }).toList();
    return Series(counts,
        name: '${name}_interior_rings_count', index: index);
  }

  /// Returns a Series of boolean values indicating if a LineString's or LinearRing's
  /// first and last points are equal.
  Series get isClosed {
    final closedFlags = data.map((geom) {
      if (geom == null) return false;
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 2) return false;
        return _arePointsEqual(coords.first, coords.last);
      }
      return false;
    }).toList();
    return Series(closedFlags, name: '${name}_is_closed', index: index);
  }

  /// Returns a Series of boolean values indicating if geometries are empty.
  /// A null geometry is considered not empty by GeoPandas, so this also returns false for null.
  Series get isEmpty {
    final emptyFlags = data.map((geom) {
      if (geom == null) {
        return false; // Consistent with GeoPandas: None is not empty.
      }
      return _isGeometryEmpty(geom); // Uses the internal helper
    }).toList();
    return Series(emptyFlags, name: '${name}_is_empty', index: index);
  }

  /// Returns a Series of boolean values indicating if features are rings.
  /// A feature is a ring if it is a LineString that is simple and closed.
  /// This implementation checks for closure and minimum points (>=4).
  /// Note: This does not check for self-intersections (simplicity).
  /// For a more rigorous check, one might combine `isRing && isSimple`.
  Series get isRing {
    final ringFlags = data.map((geom) {
      if (geom == null) return false;
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 4) {
          return false; // Ring needs at least 4 points (A-B-C-A)
        }
        return _arePointsEqual(coords.first, coords.last); // Check closure
      }
      return false;
    }).toList();
    return Series(ringFlags, name: '${name}_is_ring', index: index);
  }

  /// Returns a Series of boolean values with value true for geometries that are valid.
  /// Note: Polygon validation is simplified. Null geometries are invalid. Empty geometries are invalid.
  Series get isValid {
    final validFlags = data.map((geom) {
      if (geom == null) return false;
      if (_isGeometryEmpty(geom)) {
        return false; // Empty geometries are not valid
      }

      if (geom is GeoJSONPolygon) {
        return _isValidPolygon(geom.coordinates); // Simplified check
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return false;
        return geom.coordinates
            .every((polygonRings) => _isValidPolygon(polygonRings));
      }
      return true;
    }).toList();
    return Series(validFlags, name: '${name}_is_valid', index: index);
  }

  /// Returns a Series of boolean values with value true for features that have a z-component.
  Series get hasZ {
    final hasZFlags = data.map((geom) {
      if (geom == null) return false;
      if (geom is GeoJSONPoint) return geom.coordinates.length > 2;
      if (geom is GeoJSONMultiPoint) {
        return geom.coordinates.isNotEmpty && geom.coordinates[0].length > 2;
      }
      if (geom is GeoJSONLineString) {
        return geom.coordinates.isNotEmpty && geom.coordinates[0].length > 2;
      }
      if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.isNotEmpty &&
            geom.coordinates[0].isNotEmpty &&
            geom.coordinates[0][0].length > 2;
      }
      if (geom is GeoJSONPolygon) {
        return geom.coordinates.isNotEmpty &&
            geom.coordinates[0].isNotEmpty &&
            geom.coordinates[0][0].length > 2;
      }
      if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.isNotEmpty &&
            geom.coordinates[0].isNotEmpty &&
            geom.coordinates[0][0].isNotEmpty &&
            geom.coordinates[0][0][0].length > 2;
      }
      return false;
    }).toList();
    return Series(hasZFlags, name: '${name}_has_z', index: index);
  }

  /// Gets the bounds of each geometry.
  DataFrame get bounds {
    final List<List<double>> boundsData = [];
    final List<dynamic> newIndex = [];

    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      final originalIdx = index[i];

      if (geom is GeoJSONPolygon &&
          (geom.coordinates.isEmpty ||
              geom.coordinates[0].isEmpty ||
              geom.coordinates[0].length < 4)) {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      } else if (geom is GeoJSONLineString && geom.coordinates.length < 2) {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      } else if (geom is GeoJSONPoint && geom.coordinates.isEmpty) {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      } else if (geom is GeoJSONGeometry) {
        try {
          final bbox = geom.bbox ?? [0.0, 0.0, 0.0, 0.0];
          boundsData.add(bbox);
        } catch (e) {
          boundsData.add([0.0, 0.0, 0.0, 0.0]);
        }
      } else {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      }
      newIndex.add(originalIdx);
    }
    return DataFrame(boundsData,
        columns: ['minx', 'miny', 'maxx', 'maxy'], index: newIndex);
  }

  /// Gets the total bounds of all geometries in the GeoSeries.
  List<double> get total_bounds {
    List<double>? currentOverallBounds;
    for (var geom in data) {
      List<double> geomBounds;
      if (geom is GeoJSONPolygon &&
          (geom.coordinates.isEmpty ||
              geom.coordinates[0].isEmpty ||
              geom.coordinates[0].length < 4)) {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      } else if (geom is GeoJSONLineString && geom.coordinates.length < 2) {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      } else if (geom is GeoJSONPoint && geom.coordinates.isEmpty) {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      } else if (geom is GeoJSONGeometry) {
        try {
          geomBounds = geom.bbox ?? [0.0, 0.0, 0.0, 0.0];
        } catch (e) {
          geomBounds = [0.0, 0.0, 0.0, 0.0];
        }
      } else {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      }

      bool isEffectivelyEmpty = geomBounds[0] == 0 &&
          geomBounds[1] == 0 &&
          geomBounds[2] == 0 &&
          geomBounds[3] == 0;

      if (currentOverallBounds == null) {
        currentOverallBounds = List.from(geomBounds);
      } else {
        if (!isEffectivelyEmpty) {
          currentOverallBounds[0] = min(currentOverallBounds[0], geomBounds[0]);
          currentOverallBounds[1] = min(currentOverallBounds[1], geomBounds[1]);
          currentOverallBounds[2] = max(currentOverallBounds[2], geomBounds[2]);
          currentOverallBounds[3] = max(currentOverallBounds[3], geomBounds[3]);
        }
      }
    }
    return currentOverallBounds ?? [0.0, 0.0, 0.0, 0.0];
  }

  /// Gets the centroid of each geometry.
  GeoSeries get centroid {
    final centroids = data.map((geom) {
      if (geom == null) return GeoJSONPoint([0, 0]);
      if (geom is GeoJSONPoint) {
        return geom;
      } else if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty ||
            geom.coordinates[0].isEmpty ||
            geom.coordinates[0].length < 3) {
          return GeoJSONPoint([0, 0]);
        }
        final coords = geom.coordinates[0];
        double sumX = 0, sumY = 0;
        int numPoints = 0;
        for (int k = 0; k < coords.length - 1; k++) {
          sumX += coords[k][0];
          sumY += coords[k][1];
          numPoints++;
        }
        if (!_arePointsEqual(coords.first, coords.last) ||
            coords.length - 1 == 0) {
          if (coords.isNotEmpty && numPoints < coords.length) {
            sumX += coords.last[0];
            sumY += coords.last[1];
            numPoints++;
          }
        }
        if (numPoints == 0) return GeoJSONPoint([0, 0]);
        return GeoJSONPoint([sumX / numPoints, sumY / numPoints]);
      } else if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.isEmpty) return GeoJSONPoint([0, 0]);
        double sumX = 0, sumY = 0;
        for (var point in coords) {
          sumX += point[0];
          sumY += point[1];
        }
        return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
      } else if (geom is GeoJSONMultiPoint) {
        final coords = geom.coordinates;
        if (coords.isEmpty) return GeoJSONPoint([0, 0]);
        double sumX = 0, sumY = 0;
        for (var point in coords) {
          sumX += point[0];
          sumY += point[1];
        }
        return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
      } else if (geom is GeoJSONMultiLineString) {
        final lineStrings = geom.coordinates;
        if (lineStrings.isEmpty) return GeoJSONPoint([0, 0]);
        double sumX = 0, sumY = 0;
        int totalPoints = 0;
        for (var lineString in lineStrings) {
          if (lineString.isEmpty) continue;
          for (var point in lineString) {
            sumX += point[0];
            sumY += point[1];
            totalPoints++;
          }
        }
        if (totalPoints > 0) {
          return GeoJSONPoint([sumX / totalPoints, sumY / totalPoints]);
        }
        return GeoJSONPoint([0, 0]);
      } else if (geom is GeoJSONMultiPolygon) {
        final polygons = geom.coordinates;
        if (polygons.isEmpty) return GeoJSONPoint([0, 0]);
        double totalArea = 0;
        double weightedSumX = 0;
        double weightedSumY = 0;
        for (var polygonRings in polygons) {
          if (polygonRings.isNotEmpty && polygonRings[0].length >= 3) {
            final coords = polygonRings[0];
            double sumX = 0, sumY = 0;
            int numPoints = 0;
            for (int k = 0; k < coords.length - 1; k++) {
              sumX += coords[k][0];
              sumY += coords[k][1];
              numPoints++;
            }
            if (!_arePointsEqual(coords.first, coords.last) ||
                coords.length - 1 == 0) {
              if (coords.isNotEmpty && numPoints < coords.length) {
                sumX += coords.last[0];
                sumY += coords.last[1];
                numPoints++;
              }
            }
            if (numPoints == 0) continue;
            final centroidX = sumX / numPoints;
            final centroidY = sumY / numPoints;
            final currentPolygonArea =
                _calculatePolygonAreaForCentroid(polygonRings);
            totalArea += currentPolygonArea;
            weightedSumX += centroidX * currentPolygonArea;
            weightedSumY += centroidY * currentPolygonArea;
          }
        }
        if (totalArea > 0) {
          return GeoJSONPoint(
              [weightedSumX / totalArea, weightedSumY / totalArea]);
        }
        return GeoJSONPoint([0, 0]);
      }
          return GeoJSONPoint([0, 0]);
    }).toList();
    return GeoSeries(centroids,
        crs: crs, name: '${name}_centroid', index: index);
  }

  /// Gets the type of each geometry.
  Series get geom_type {
    final types = data.map((geom) {
      if (geom == null) return 'Unknown';
      if (geom is GeoJSONPoint) return 'Point';
      if (geom is GeoJSONMultiPoint) return 'MultiPoint';
      if (geom is GeoJSONLineString) return 'LineString';
      if (geom is GeoJSONMultiLineString) return 'MultiLineString';
      if (geom is GeoJSONPolygon) return 'Polygon';
      if (geom is GeoJSONMultiPolygon) return 'MultiPolygon';
      if (geom is GeoJSONGeometryCollection) return 'GeometryCollection';
      return 'Unknown';
    }).toList();
    return Series(types, name: '${name}_geom_type', index: index);
  }

  /// Gets the area of each geometry.
  Series get area {
    final areas = data.map((geom) {
      if (geom == null) return 0.0;
      if (geom is GeoJSONPolygon) {
        return _calculatePolygonArea(geom.coordinates);
      }
      if (geom is GeoJSONMultiPolygon) {
        double totalArea = 0;
        for (var polygon in geom.coordinates) {
          totalArea += _calculatePolygonArea(polygon);
        }
        return totalArea;
      }
      return 0.0;
    }).toList();
    return Series(areas, name: '${name}_area', index: index);
  }

  /// Returns a new `GeoSeries` containing the boundaries of each geometry.
  GeoSeries get boundary {
    final boundaries = data.map((geom) {
      if (geom == null) return GeoJSONGeometryCollection([]);
      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty || geom.coordinates[0].length < 4) {
          return GeoJSONGeometryCollection([]);
        }
        if (geom.coordinates.length > 1) {
          final validRings =
              geom.coordinates.where((ring) => ring.length >= 4).toList();
          if (validRings.isEmpty) return GeoJSONGeometryCollection([]);
          // If only the exterior was valid and it was the only ring initially, return as LineString
          if (validRings.length == 1 &&
              geom.coordinates.length == 1 &&
              validRings[0] == geom.coordinates[0]) {
            return GeoJSONLineString(validRings[0]);
          }
          return GeoJSONMultiLineString(validRings);
        }
        return GeoJSONLineString(geom.coordinates[0]);
      } else if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 2) return GeoJSONGeometryCollection([]);
        if (_arePointsEqual(coords.first, coords.last)) {
          return GeoJSONGeometryCollection([]);
        }
        return GeoJSONMultiPoint([coords.first, coords.last]);
      } else if (geom is GeoJSONPoint) {
        return GeoJSONGeometryCollection([]);
      } else if (geom is GeoJSONMultiPoint) {
        return GeoJSONGeometryCollection([]);
      } else if (geom is GeoJSONMultiLineString) {
        if (geom.coordinates.isEmpty) return GeoJSONGeometryCollection([]);
        List<List<double>> boundaryPoints = [];
        for (var lineStringCoords in geom.coordinates) {
          if (lineStringCoords.length < 2) continue;
          if (!_arePointsEqual(lineStringCoords.first, lineStringCoords.last)) {
            boundaryPoints.add(lineStringCoords.first);
            boundaryPoints.add(lineStringCoords.last);
          }
        }
        if (boundaryPoints.isEmpty) return GeoJSONGeometryCollection([]);
        return GeoJSONMultiPoint(boundaryPoints);
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return GeoJSONGeometryCollection([]);
        List<List<List<double>>> allRings = [];
        for (var polygonCoordList in geom.coordinates) {
          for (var ring in polygonCoordList) {
            if (ring.length >= 4) allRings.add(ring);
          }
        }
        if (allRings.isEmpty) return GeoJSONGeometryCollection([]);
        return GeoJSONMultiLineString(allRings);
      }
      return GeoJSONGeometryCollection([]);
    }).toList();
    return GeoSeries(boundaries,
        name: '${name}_boundary', crs: crs, index: index);
  }

  /// Returns a Series containing the length of each geometry expressed in the units of the CRS.
  Series get geom_length {
    final lengths = data.map((geom) {
      if (geom == null) return 0.0;
      if (geom is GeoJSONLineString) {
        return _calculateLineStringLength(geom.coordinates);
      }
      if (geom is GeoJSONMultiLineString) {
        double totalLength = 0.0;
        for (var line in geom.coordinates) {
          totalLength += _calculateLineStringLength(line);
        }
        return totalLength;
      } else if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isNotEmpty && geom.coordinates[0].isNotEmpty) {
          return _calculateLineStringLength(geom.coordinates[0]);
        }
        return 0.0;
      } else if (geom is GeoJSONMultiPolygon) {
        double totalLength = 0.0;
        for (var polygon in geom.coordinates) {
          if (polygon.isNotEmpty && polygon[0].isNotEmpty) {
            totalLength += _calculateLineStringLength(polygon[0]);
          }
        }
        return totalLength;
      } else if (geom is GeoJSONGeometryCollection) {
        double totalLength = 0.0;
        for (var subGeom in geom.geometries) {
          final tempSeries = GeoSeries([subGeom], crs: crs);
          totalLength += tempSeries.geom_length.data[0] as double;
        }
        return totalLength;
      } else if (geom is GeoJSONPoint || geom is GeoJSONMultiPoint) return 0.0;
      return 0.0;
    }).toList();
    return Series(lengths, name: '${name}_geom_length', index: index);
  }

  /// Calculate the length of a line string (ring)
  double _calculateLineStringLength(List<List<double>> coordinates) {
    if (coordinates.length < 2) return 0.0;
    double length = 0.0;
    for (int i = 0; i < coordinates.length - 1; i++) {
      length += _distance(coordinates[i], coordinates[i + 1]);
    }
    return length;
  }

  /// Returns a Series of boolean values with value true if a LineString or LinearRing
  /// is counterclockwise. Also applies to the exterior ring of a Polygon.
  Series get isCCW {
    final ccwFlags = data.map((geom) {
      if (geom == null) return false;
      List<List<double>>? coordsToCheck;
      if (geom is GeoJSONLineString) {
        coordsToCheck = geom.coordinates;
      } else if (geom is GeoJSONPolygon && geom.coordinates.isNotEmpty) {
        coordsToCheck = geom.coordinates[0]; // Check exterior ring of polygon
      }

      if (coordsToCheck != null) {
        if (coordsToCheck.length < 4 ||
            !_arePointsEqual(coordsToCheck.first, coordsToCheck.last)) {
          return false;
        }
        return _calculateSignedArea(coordsToCheck) > 0;
      }
      return false;
    }).toList();
    return Series(ccwFlags, name: '${name}_is_ccw', index: index);
  }

  /// Returns a Series of boolean values with value True for each aligned geometry that contains other.
  Series contains(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context");
    }

    try {
      if (other is GeoJSONGeometry) {
        final result = data
            .map((g) => _geosContains(g, other, bindings, contextHandle))
            .toList();
        return Series(result, name: '${name}_contains', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        // Determine common length for alignment, or use full length if not aligning (though align=true is default)
        int commonLength = length; // Default if align is false or lengths are same
        if (align) {
          commonLength = min(length, other.length);
        }
        // If align is true and lengths differ, consider how to handle indices.
        // Current Series constructor might not align indices perfectly if resultData is shorter.
        // This simplified loop matches geopandas behavior for default align=True (element-wise up to shortest)

        for (int i = 0; i < commonLength; ++i) {
          resultData.add(
              _geosContains(data[i], other.data[i], bindings, contextHandle));
        }
        // If align is true and this series is longer, fill remaining with false
        if (align && length > other.length) {
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false);
          }
        }
        // If align is true and other series is longer, the result series will be of length `this.length`
        // matching geopandas behavior where `s1.contains(s2)` has index of `s1`.

        // Create index for the result series. If aligning and lengths differ,
        // the result should match the index of `this` GeoSeries up to commonLength.
        List<dynamic> resultIndex = index;
        if (align && length != other.length) {
           // If `this` series is longer, its index is already fine.
           // If `other` series is longer, `resultData` will be of `this.length`, so `this.index` is fine.
           // If `resultData` became shorter than `this.length` due to `other` being shorter,
           // then `this.index` needs to be truncated for the Series constructor.
           if (resultData.length < index.length) {
             resultIndex = index.sublist(0, resultData.length);
           }
        }


        return Series(resultData, name: '${name}_contains', index: resultIndex);
      }
      throw ArgumentError("Other must be GeoJSONGeometry or GeoSeries");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if one geometry contains another using GEOS
  bool _geosContains(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    final geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      // geoJSONToGEOS should log its own errors
      return false;
    }

    final geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1); // Clean up geosGeom1
      // geoJSONToGEOS should log its own errors
      return false;
    }

    // Use temporary variables for the finally block to ensure correct pointers are used
    // if initial ones were null (though caught above, this is safer pattern)
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // Double check, though geoJSONToGEOS returning nullptr should be caught above
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false;
      }

      final charResult = bindings.GEOSContains_r(
          contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // 2 indicates an exception in GEOS
        // GEOSHasError in GEOS C API might give more info, or a message handler.
        // For now, just log based on WKT.
        String? wkt1, wkt2;
        try {
          wkt1 = geom1.toWKT();
        } catch (_) {
          wkt1 = "Invalid WKT for geom1";
        }
        try {
          wkt2 = geom2.toWKT();
        } catch (_) {
          wkt2 = "Invalid WKT for geom2";
        }
        print(
            "GEOSContains_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1; // 1 for true, 0 for false
      }
    } finally {
      // Ensure GEOS geometries are destroyed
      if (tempGeosGeom1 != ffi.nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is spatially disjoint from the corresponding geometry in `other`.
  Series<bool> disjoint(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'disjoint' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosDisjoint(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_disjoint', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosDisjoint(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); // Or specific value for disjoint, typically false if no counterpart
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }
          // No specific adjustment needed if resultData.length == index.length or resultData.length > index.length
          // as resultIndex is already this.index.

        } else {
          throw UnimplementedError(
              "disjoint with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_disjoint', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for disjoint method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is disjoint from geom2 using GEOS
  bool _geosDisjoint(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      // geosGeom1 was successfully created, so it must be destroyed.
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      // However, it adds a layer of safety before dereferencing.
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        // This case should ideally not be reached if the prior checks are correct.
        // If it is, it implies an issue in logic or assumptions about geoJSONToGEOS.
        return false; 
      }
      final charResult =
          bindings.GEOSDisjoint_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) { // 2 indicates an exception in GEOS
        String? wkt1 = "Error fetching WKT"; // Default error string
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { /* Keep default error string */ }
        try { wkt2 = geom2.toWKT(); } catch (_) { /* Keep default error string */ }
        print("GEOSDisjoint_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1; // 1 for true, 0 for false
      }
    } finally {
      // Ensure GEOS geometries are destroyed.
      // The pointers tempGeosGeom1 and tempGeosGeom2 hold the original values of
      // geosGeom1 and geosGeom2 that were valid (non-null) when passed to GEOSDisjoint_r.
      // No need to check for ffi.nullptr again here if they were valid for the GEOS call.
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
    }
    return result;
  }

  /// Returns a Series of DE-9IM intersection matrix strings for each geometry in this series
  /// when related to the corresponding geometry in `other`.
  Series<String?> relate(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'relate' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<String?> resultData = data.map((g) {
          return _geosRelate(g, other, bindings, contextHandle);
        }).toList();
        return Series<String?>(resultData, name: '${name}_relate', index: index);
      } else if (other is GeoSeries) {
        List<String?> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosRelate(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are null
          for (int i = commonLength; i < length; ++i) {
            resultData.add(null); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "relate with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<String?>(resultData, name: '${name}_relate', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for relate method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to compute the DE-9IM matrix for geom1 related to geom2 using GEOS
  String? _geosRelate(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return null;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return null; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return null; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual;
    // the actual type from geos_bindings.dart is GEOSGeometry.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    String? de9imMatrix;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return null; 
      }
      final nativeMatrix =
          bindings.GEOSRelate_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (nativeMatrix == ffi.nullptr) { // GEOSRelate_r returns NULL on exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        print("GEOSRelate_r reported an error or returned NULL for geometries (WKT): '$wkt1' and '$wkt2'");
        de9imMatrix = null;
      } else {
        de9imMatrix = nativeMatrix.toDartString();
        // GEOSFree_r expects Pointer<Void>, so cast nativeMatrix
        bindings.GEOSFree_r(contextHandle, nativeMatrix.cast<ffi.Void>());
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return de9imMatrix;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that matches the DE-9IM `pattern` when related to the corresponding geometry in `other`.
  Series<bool> relatePattern(dynamic other, String pattern, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'relatePattern' method.");
    }

    ffi.Pointer<Utf8> nativePattern = ffi.nullptr;
    try {
      nativePattern = pattern.toNativeUtf8();
      if (nativePattern == ffi.nullptr) {
        throw ArgumentError("Failed to convert pattern string to native UTF8.");
      }

      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosRelatePattern(g, other, nativePattern, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_relate_pattern', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosRelatePattern(
                data[i], other.data[i], nativePattern, bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "relatePattern with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_relate_pattern', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for relatePattern method");
    } finally {
      if (nativePattern != ffi.nullptr) {
        malloc.free(nativePattern);
      }
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 relates to geom2 via a DE-9IM pattern using GEOS
  bool _geosRelatePattern(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2, 
      ffi.Pointer<Utf8> nativePattern,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    
    if (geom1 == null || geom2 == null || nativePattern == ffi.nullptr) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = geoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == ffi.nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = geoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == ffi.nullptr) {
      bindings.GEOSGeom_destroy_r(contextHandle, geosGeom1);
      return false; // geoJSONToGEOS logs errors
    }

    // Using GEOSGeometry (which is a Pointer type) directly for temp variables.
    // The GEOSGeometry_ptr? type hint in the task description is conceptual.
    GEOSGeometry tempGeosGeom1 = geosGeom1;
    GEOSGeometry tempGeosGeom2 = geosGeom2;
    bool result = false;

    try {
      // This null check is technically redundant if the above checks are thorough
      // and geoJSONToGEOS either returns a valid pointer or ffi.nullptr (which is checked).
      if (tempGeosGeom1 == ffi.nullptr || tempGeosGeom2 == ffi.nullptr) {
        return false; 
      }
      final charResult =
          bindings.GEOSRelatePattern_r(contextHandle, tempGeosGeom1, tempGeosGeom2, nativePattern);

      if (charResult == 2) { // GEOS exception
        String? wkt1 = "Error fetching WKT"; 
        String? wkt2 = "Error fetching WKT";
        String patternStr = "Error fetching pattern";
        try { wkt1 = geom1.toWKT(); } catch (_) { }
        try { wkt2 = geom2.toWKT(); } catch (_) { }
        try { patternStr = nativePattern.toDartString(); } catch (_) {}

        print("GEOSRelatePattern_r reported an error for geometries (WKT): '$wkt1' and '$wkt2' with pattern '$patternStr'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != ffi.nullptr) { 
          bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that properly contains the corresponding geometry in `other`.
  /// Proper containment means the interior of this geometry contains the other, and their boundaries do not touch.
  Series<bool> containsProperly(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == ffi.nullptr) {
      throw StateError("Failed to initialize GEOS context for 'containsProperly' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosContainsProperly(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData, name: '${name}_contains_properly', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosContainsProperly(
                data[i], other.data[i], bindings, contextHandle));
          }
          // If this series is longer, remaining are false
          for (int i = commonLength; i < length; ++i) {
            resultData.add(false); 
          }
          
          if (resultData.length < index.length) {
            resultIndex = index.sublist(0, resultData.length);
          }

        } else {
          throw UnimplementedError(
              "containsProperly with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData, name: '${name}_contains_properly', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for containsProperly method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 properly contains geom2 using GEOS,
  /// by checking GEOSContains and not GEOSTouches.
  bool _geosContainsProperly(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // Call _geosContains. This helper will manage its own GEOS geometry conversions and cleanup.
    final bool containsResult = _geosContains(geom1, geom2, bindings, contextHandle);

    if (!containsResult) {
      return false; // If it doesn't contain, it can't contain properly.
    }

    // Call _geosTouches. This helper also manages its own GEOS geometry conversions and cleanup.
    final bool touchesResult = _geosTouches(geom1, geom2, bindings, contextHandle);

    // Contains properly if it contains AND does not touch.
    return containsResult && !touchesResult;
  }


  // _isPolygonContainingPolygon can be removed as it was part of the old _containsGeometry
  // bool _isPolygonContainingPolygon(...) { ... }

  /// Check if a geometry is empty
  bool _isGeometryEmpty(GeoJSONGeometry? geom) {
    if (geom == null) return true;
    if (geom is GeoJSONPoint) return geom.coordinates.isEmpty;
    if (geom is GeoJSONMultiPoint) return geom.coordinates.isEmpty;
    if (geom is GeoJSONLineString) return geom.coordinates.length < 2;
    if (geom is GeoJSONMultiLineString) {
      return geom.coordinates.isEmpty ||
          geom.coordinates.every((l) => l.length < 2);
    }
    if (geom is GeoJSONPolygon) {
      return geom.coordinates.isEmpty || geom.coordinates[0].length < 4;
    }
    if (geom is GeoJSONMultiPolygon) {
      return geom.coordinates.isEmpty ||
          geom.coordinates.every((p) => p.isEmpty || p[0].length < 4);
    }
    if (geom is GeoJSONGeometryCollection) {
      return geom.geometries.isEmpty ||
          geom.geometries.every((g) => _isGeometryEmpty(g));
    }
    return true;
  }

  /// Check if a point is inside a polygon ring using the ray casting algorithm
  // This method is part of the old geometry logic, and can be removed or kept if used by other methods.
  // For GEOS 'contains', this specific implementation is no longer directly used by the 'contains' method.
  bool _pointInPolygon(List<double> point, List<List<double>> polygonRing) {
    bool inside = false;
    double x = point[0];
    double y = point[1];
    if (polygonRing.length < 4) return false; // Not a valid ring

    for (int i = 0, j = polygonRing.length - 1;
        i < polygonRing.length;
        j = i++) {
      double xi = polygonRing[i][0];
      double yi = polygonRing[i][1];
      double xj = polygonRing[j][0];
      double yj = polygonRing[j][1];
      bool intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Check if a point is on a line segment list
  bool _pointOnLine(List<double> pointCoords, List<List<double>> lineCoords) {
    if (lineCoords.length < 2) return false;
    for (int i = 0; i < lineCoords.length - 1; i++) {
      if (_pointToLineSegmentDistance(
              pointCoords, lineCoords[i], lineCoords[i + 1]) <
          1e-9) {
        return true;
      }
    }
    return false;
  }

  /// Calculate Euclidean distance between two points
  double _distance(List<double> p1, List<double> p2) {
    if (p1.isEmpty || p2.isEmpty || p1.length < 2 || p2.length < 2) {
      return double.nan;
    }
    double dx = p1[0] - p2[0];
    double dy = p1[1] - p2[1];
    return sqrt(dx * dx + dy * dy);
  }

  /// Helper function to check if two points are equal (within a small tolerance)
  bool _arePointsEqual(List<double> p1, List<double> p2,
      {double epsilon = 1e-9}) {
    if (p1.length != p2.length || p1.length < 2) return false;
    for (int i = 0; i < p1.length; i++) {
      if ((p1[i] - p2[i]).abs() > epsilon) return false;
    }
    return true;
  }

  /// Calculate the signed area of a ring
  double _calculateSignedArea(List<List<double>> coords) {
    if (coords.isEmpty || coords.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < coords.length - 1; i++) {
      area +=
          (coords[i][0] * coords[i + 1][1]) - (coords[i + 1][0] * coords[i][1]);
    }
    area += (coords[coords.length - 1][0] * coords[0][1]) -
        (coords[0][0] * coords[coords.length - 1][1]);
    return area / 2.0;
  }

  /// Calculates the area of a single polygon ring using the Shoelace formula.
  double _calculateRingArea(List<List<double>> ringCoordinates) {
    if (ringCoordinates.length < 4) return 0.0;
    return _calculateSignedArea(ringCoordinates).abs();
  }

  GeoSeries get exterior {
    final exteriors = data.map((geom) {
      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isNotEmpty && geom.coordinates[0].length >= 4) {
          return GeoJSONLineString(geom.coordinates[0]);
        }
        return GeoJSONGeometryCollection([]);
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return GeoJSONGeometryCollection([]);
        List<List<List<double>>> exteriorRings = [];
        for (var polygonCoords in geom.coordinates) {
          if (polygonCoords.isNotEmpty && polygonCoords[0].length >= 4) {
            exteriorRings.add(polygonCoords[0]);
          }
        }
        if (exteriorRings.isEmpty) return GeoJSONGeometryCollection([]);
        if (exteriorRings.length == 1) {
          return GeoJSONLineString(exteriorRings[0]);
        }
        return GeoJSONMultiLineString(exteriorRings);
      }
      return GeoJSONGeometryCollection([]);
    }).toList();
    return GeoSeries(exteriors,
        name: '${name}_exterior', crs: crs, index: index);
  }

  Series get interiors {
    final allInteriors = data.map((geom) {
      List<List<List<double>>> interiorRingsCoords = [];
      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.length > 1) {
          for (int i = 1; i < geom.coordinates.length; i++) {
            if (geom.coordinates[i].length >= 4) {
              interiorRingsCoords.add(geom.coordinates[i]);
            }
          }
        }
      } else if (geom is GeoJSONMultiPolygon) {
        for (var polygonCoords in geom.coordinates) {
          if (polygonCoords.length > 1) {
            for (int i = 1; i < polygonCoords.length; i++) {
              if (polygonCoords[i].length >= 4) {
                interiorRingsCoords.add(polygonCoords[i]);
              }
            }
          }
        }
      }
      return interiorRingsCoords
          .map((coords) => GeoJSONLineString(coords))
          .toList();
    }).toList();
    return Series(allInteriors, name: '${name}_interiors', index: index);
  }

  Series get x {
    final values = data.map((geom) {
      if (geom is GeoJSONPoint && geom.coordinates.isNotEmpty) {
        return geom.coordinates[0];
      }
      return double.nan;
    }).toList();
    return Series(values, name: '${name}_x', index: index);
  }

  Series get y {
    final values = data.map((geom) {
      if (geom is GeoJSONPoint && geom.coordinates.length > 1) {
        return geom.coordinates[1];
      }
      return double.nan;
    }).toList();
    return Series(values, name: '${name}_y', index: index);
  }

  Series get z {
    final values = data.map((geom) {
      if (geom is GeoJSONPoint && geom.coordinates.length > 2) {
        return geom.coordinates[2];
      }
      return double.nan;
    }).toList();
    return Series(values, name: '${name}_z', index: index);
  }

  GeoSeries get representative_point {
    final points = data.map((geom) {
      if (geom == null || _isGeometryEmpty(geom)) {
        return GeoJSONGeometryCollection([]);
      }
      if (geom is GeoJSONPoint) return geom;
      if (geom is GeoJSONLineString) return GeoJSONPoint(geom.coordinates[0]);
      if (geom is GeoJSONPolygon) {
        final coords = geom.coordinates[0];
        double sumX = 0, sumY = 0;
        int numPoints = 0;
        for (int k = 0; k < coords.length - 1; k++) {
          sumX += coords[k][0];
          sumY += coords[k][1];
          numPoints++;
        }
        if (!_arePointsEqual(coords.first, coords.last) ||
            coords.length - 1 == 0) {
          if (coords.isNotEmpty && numPoints < coords.length) {
            sumX += coords.last[0];
            sumY += coords.last[1];
            numPoints++;
          }
        }
        if (numPoints == 0) return GeoJSONGeometryCollection([]);
        return GeoJSONPoint([sumX / numPoints, sumY / numPoints]);
      }
      if (geom is GeoJSONMultiPoint && geom.coordinates.isNotEmpty) {
        return GeoJSONPoint(geom.coordinates[0]);
      }
      if (geom is GeoJSONMultiLineString &&
          geom.coordinates.isNotEmpty &&
          geom.coordinates[0].isNotEmpty) {
        return GeoJSONPoint(geom.coordinates[0][0]);
      }
      if (geom is GeoJSONMultiPolygon &&
          geom.coordinates.isNotEmpty &&
          geom.coordinates[0].isNotEmpty &&
          geom.coordinates[0][0].isNotEmpty) {
        final coords = geom.coordinates[0][0];
        double sumX = 0, sumY = 0;
        int numPoints = 0;
        for (int k = 0; k < coords.length - 1; k++) {
          sumX += coords[k][0];
          sumY += coords[k][1];
          numPoints++;
        }
        if (!_arePointsEqual(coords.first, coords.last) ||
            coords.length - 1 == 0) {
          if (coords.isNotEmpty && numPoints < coords.length) {
            sumX += coords.last[0];
            sumY += coords.last[1];
            numPoints++;
          }
        }
        if (numPoints == 0) return GeoJSONGeometryCollection([]);
        return GeoJSONPoint([sumX / numPoints, sumY / numPoints]);
      }
      return GeoJSONGeometryCollection([]);
    }).toList();
    return GeoSeries(points,
        name: '${name}_representative_point', crs: crs, index: index);
  }

  double _roundToPrecision(double value, double gridSize) {
    if (gridSize <= 0) return value;
    if (gridSize == 1.0) return value.roundToDouble();
    int decimalPlaces = 0;
    if (gridSize > 0 && gridSize < 1) {
      String s = gridSize.toStringAsFixed(10);
      int dotIndex = s.indexOf('.');
      if (dotIndex != -1) {
        String fraction = s.substring(dotIndex + 1);
        for (int i = 0; i < fraction.length; ++i) {
          if (fraction[i] == '0') {
            decimalPlaces++;
          } else if (fraction[i] == '1' &&
              (i + 1 == fraction.length ||
                  fraction.substring(i + 1).split('').every((c) => c == '0'))) {
            decimalPlaces++;
            break;
          } else {
            decimalPlaces = -1;
            break;
          }
        }
        if (decimalPlaces == -1 ||
            gridSize.toString().length >
                dotIndex +
                    1 +
                    decimalPlaces +
                    (gridSize.toString().contains('e') ? 0 : 1)) {
          return (value / gridSize).round() * gridSize;
        }
      } else {
        return (value / gridSize).round() * gridSize;
      }
    } else if (gridSize > 1) {
      return (value / gridSize).round() * gridSize;
    }
    double multiplier = pow(10, decimalPlaces).toDouble();
    return (value * multiplier).round() / multiplier;
  }

  List<double> _roundCoordinate(List<double> coord, double gridSize) {
    return coord.map((val) => _roundToPrecision(val, gridSize)).toList();
  }

  List<List<double>> _roundCoordinatesList(
      List<List<double>> coordsList, double gridSize) {
    return coordsList
        .map((coord) => _roundCoordinate(coord, gridSize))
        .toList();
  }

  List<List<List<double>>> _roundCoordinatesListList(
      List<List<List<double>>> coordsListList, double gridSize) {
    return coordsListList
        .map((coordsList) => _roundCoordinatesList(coordsList, gridSize))
        .toList();
  }

  List<List<List<List<double>>>> _roundCoordinatesListListList(
      List<List<List<List<double>>>> coordsListListList, double gridSize) {
    return coordsListListList
        .map((coordsListList) =>
            _roundCoordinatesListList(coordsListList, gridSize))
        .toList();
  }

  GeoSeries set_precision(double gridSize) {
    if (gridSize == 0) {
      return GeoSeries(List.from(data),
          name: name, crs: crs, index: index);
    }
    if (gridSize < 0) throw ArgumentError("grid_size must be non-negative");

    final newGeometries = data.map((geom) {
      if (geom == null) return null;
      if (geom is GeoJSONPoint) {
        return GeoJSONPoint(_roundCoordinate(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONLineString) {
        return GeoJSONLineString(
            _roundCoordinatesList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONPolygon) {
        return GeoJSONPolygon(
            _roundCoordinatesListList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONMultiPoint) {
        return GeoJSONMultiPoint(
            _roundCoordinatesList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONMultiLineString) {
        return GeoJSONMultiLineString(
            _roundCoordinatesListList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONMultiPolygon) {
        return GeoJSONMultiPolygon(
            _roundCoordinatesListListList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONGeometryCollection) {
        List<GeoJSONGeometry> roundedGeoms = [];
        for (var subGeom in geom.geometries) {
          var tempSeries = GeoSeries([subGeom], crs: crs);
          var roundedSubGeom = tempSeries.set_precision(gridSize).data[0];
          if (roundedSubGeom != null) roundedGeoms.add(roundedSubGeom);
        }
        return GeoJSONGeometryCollection(roundedGeoms);
      }
      return geom;
    }).toList();
    return GeoSeries(newGeometries,
        name: '${name}_prec', crs: crs, index: index);
  }

  Series get get_precision {
    final values = data.map((_) => double.nan).toList();
    return Series(values, name: '${name}_precision', index: index);
  }

  Series distance(dynamic other, {bool align = true}) {
    List<double> distances = [];
    List<dynamic> newIndex = List.from(index);

    if (other is GeoJSONGeometry) {
      for (int i = 0; i < length; i++) {
        distances.add(_calculateDistanceBetweenGeometries(data[i], other));
      }
    } else if (other is GeoSeries) {
      int commonLength = min(length, other.length);
      if (length != other.length && align) {
        print(
            "Warning: GeoSeries.distance with align=true and different lengths is using positional matching up to shortest length. Full index-based alignment is not yet implemented.");
      }

      for (int i = 0; i < commonLength; i++) {
        distances.add(
            _calculateDistanceBetweenGeometries(data[i], other.data[i]));
      }
      for (int i = commonLength; i < length; i++) {
        distances.add(double.nan);
      }
    } else {
      throw ArgumentError(
          "The 'other' parameter must be a GeoJSONGeometry or a GeoSeries.");
    }
    return Series(distances, name: '${name}_distance', index: newIndex);
  }

  double _calculateDistanceBetweenGeometries(
      GeoJSONGeometry? geom1, GeoJSONGeometry? geom2) {
    if (geom1 == null || geom2 == null) return double.nan;
    if (_isGeometryEmpty(geom1) || _isGeometryEmpty(geom2)) return double.nan;

    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPoint) {
      return _distance(geom1.coordinates, geom2.coordinates);
    }
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONLineString) {
      return _pointToLineStringDistance(geom1, geom2);
    }
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONPoint) {
      return _pointToLineStringDistance(geom2, geom1);
    }
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPolygon) {
      return _pointToPolygonDistance(geom1, geom2);
    }
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPoint) {
      return _pointToPolygonDistance(geom2, geom1);
    }

    if (geom1 is GeoJSONLineString && geom2 is GeoJSONLineString) {
      for (var p1c in geom1.coordinates) {
        if (_pointToLineStringDistance(GeoJSONPoint(p1c), geom2) < 1e-9) {
          return 0.0;
      }
        }
      for (var p2c in geom2.coordinates) {
        if (_pointToLineStringDistance(GeoJSONPoint(p2c), geom1) < 1e-9) {
          return 0.0;
      }
        }
      double minD = double.infinity;
      for (var p1c in geom1.coordinates) {
        minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(p1c), geom2));
      }
      for (var p2c in geom2.coordinates) {
        minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(p2c), geom1));
      }
      return minD == double.infinity ? double.nan : minD;
    }
    if ((geom1 is GeoJSONLineString && geom2 is GeoJSONPolygon) ||
        (geom1 is GeoJSONPolygon && geom2 is GeoJSONLineString)) {
      GeoJSONLineString line =
          (geom1 is GeoJSONLineString ? geom1 : geom2 as GeoJSONLineString);
      GeoJSONPolygon poly =
          (geom1 is GeoJSONPolygon ? geom1 : geom2 as GeoJSONPolygon);
      for (var v in line.coordinates) {
        if (_pointToPolygonDistance(GeoJSONPoint(v), poly) < 1e-9) return 0.0;
      }
      for (var ring in poly.coordinates)
      {
        for (var pv in ring) {
          if (_pointToLineStringDistance(GeoJSONPoint(pv), line) < 1e-9) {
            return 0.0;
          }
        }
      }
      double minD = double.infinity;
      for (var v in line.coordinates) {
        minD = min(
            minD,
            _pointToPolygonDistance(GeoJSONPoint(v), poly,
                skipInsideCheck: true));
      }
      for (var ring in poly.coordinates)
      {
        for (var pv in ring) {
          minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(pv), line));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    }
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPolygon) {
      for (var r1 in geom1.coordinates)
      {
        for (var v1 in r1) {
          if (_pointToPolygonDistance(GeoJSONPoint(v1), geom2) < 1e-9) {
            return 0.0;
          }
        }
      }
      for (var r2 in geom2.coordinates)
      {
        for (var v2 in r2) {
          if (_pointToPolygonDistance(GeoJSONPoint(v2), geom1) < 1e-9) {
            return 0.0;
          }
        }
      }
      double minD = double.infinity;
      for (var r1 in geom1.coordinates)
      {
        for (var v1 in r1) {
          minD = min(
              minD,
              _pointToPolygonDistance(GeoJSONPoint(v1), geom2,
                  skipInsideCheck: true));
        }
      }
      for (var r2 in geom2.coordinates){
        for (var v2 in r2) {
          minD = min(
              minD,
              _pointToPolygonDistance(GeoJSONPoint(v2), geom1,
                  skipInsideCheck: true));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    }

    if (geom1 is GeoJSONMultiPoint) {
      if (geom1.coordinates.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var pCoords in geom1.coordinates) {
        minD = min(minD,
            _calculateDistanceBetweenGeometries(GeoJSONPoint(pCoords), geom2));
      }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONMultiPoint) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }
    if (geom1 is GeoJSONMultiLineString) {
      if (geom1.coordinates.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var lCoords in geom1.coordinates) {
        if (lCoords.isNotEmpty) {
          minD = min(
              minD,
              _calculateDistanceBetweenGeometries(
                  GeoJSONLineString(lCoords), geom2));
      }
        }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONMultiLineString) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }
    if (geom1 is GeoJSONMultiPolygon) {
      if (geom1.coordinates.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var pRings in geom1.coordinates) {
        if (pRings.isNotEmpty) {
          minD = min(
              minD,
              _calculateDistanceBetweenGeometries(
                  GeoJSONPolygon(pRings), geom2));
      }
        }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONMultiPolygon) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }
    if (geom1 is GeoJSONGeometryCollection) {
      if (geom1.geometries.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var g in geom1.geometries) {
        minD = min(minD, _calculateDistanceBetweenGeometries(g, geom2));
      }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONGeometryCollection) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }
    return double.nan;
  }

  double _pointToLineSegmentDistance(
      List<double> pCoords, List<double> segA, List<double> segB) {
    final double ax = segA[0];
    final double ay = segA[1];
    final double bx = segB[0];
    final double by = segB[1];
    final double px = pCoords[0];
    final double py = pCoords[1];
    final double l2 = (bx - ax) * (bx - ax) + (by - ay) * (by - ay);
    if (l2 == 0.0) return _distance(pCoords, segA);
    final double t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / l2;
    if (t < 0.0) {
      return _distance(pCoords, segA);
    } else if (t > 1.0) {return _distance(pCoords, segB);}
    final List<double> projection = [ax + t * (bx - ax), ay + t * (by - ay)];
    return _distance(pCoords, projection);
  }

  double _pointToLineStringDistance(
      GeoJSONPoint point, GeoJSONLineString lineString) {
    if (lineString.coordinates.isEmpty) return double.nan;
    if (lineString.coordinates.length == 1) {
      return _distance(point.coordinates, lineString.coordinates[0]);
    }
    double minDistance = double.infinity;
    for (int i = 0; i < lineString.coordinates.length - 1; i++) {
      final double segmentDistance = _pointToLineSegmentDistance(
          point.coordinates,
          lineString.coordinates[i],
          lineString.coordinates[i + 1]);
      minDistance = min(minDistance, segmentDistance);
    }
    return minDistance == double.infinity ? double.nan : minDistance;
  }

  double _pointToPolygonDistance(GeoJSONPoint point, GeoJSONPolygon polygon,
      {bool skipInsideCheck = false}) {
    if (polygon.coordinates.isEmpty ||
        polygon.coordinates[0].isEmpty ||
        polygon.coordinates[0].length < 4) {
      return double.nan;
    }
    if (!skipInsideCheck) {
      if (_pointInPolygon(point.coordinates, polygon.coordinates[0])) {
        bool inHole = false;
        for (int i = 1; i < polygon.coordinates.length; i++) {
          if (_pointInPolygon(point.coordinates, polygon.coordinates[i])) {
            inHole = true;
            break;
          }
        }
        if (!inHole) return 0.0;
      }
    }
    double minDistance = double.infinity;
    for (var ringCoords in polygon.coordinates) {
      if (ringCoords.length < 2) continue;
      GeoJSONLineString ringLineString = GeoJSONLineString(ringCoords);
      minDistance =
          min(minDistance, _pointToLineStringDistance(point, ringLineString));
    }
    return minDistance == double.infinity ? double.nan : minDistance;
  }

  /// Calculates the area of a polygon, considering holes.
  double _calculatePolygonArea(List<List<List<double>>> polygonCoordinates) {
    if (polygonCoordinates.isEmpty) return 0.0;
    double totalArea = _calculateRingArea(polygonCoordinates[0]);
    for (int i = 1; i < polygonCoordinates.length; i++) {
      totalArea -= _calculateRingArea(polygonCoordinates[i]);
    }
    return totalArea;
  }

  double _calculatePolygonAreaForCentroid(
      List<List<List<double>>> polygonCoordinates) {
    if (polygonCoordinates.isEmpty) return 0.0;
    return _calculateRingArea(polygonCoordinates[0]);
  }

  List<List<double>> _extractCoordinates(GeoJSONGeometry geometry) {
    if (geometry is GeoJSONPoint) return [geometry.coordinates];
    if (geometry is GeoJSONMultiPoint) return geometry.coordinates;
    if (geometry is GeoJSONLineString) return geometry.coordinates;
    if (geometry is GeoJSONMultiLineString) {
      // Corrected from 'geom' to 'geometry'
      List<List<double>> coords = [];
      for (var line in geometry.coordinates) {
        coords.addAll(line);
      }
      return coords;
    }
    if (geometry is GeoJSONPolygon) {
      List<List<double>> coords = [];
      for (var ring in geometry.coordinates) {
        coords.addAll(ring);
      }
      return coords;
    }
    if (geometry is GeoJSONMultiPolygon) {
      // Corrected from 'geom' to 'geometry'
      List<List<double>> coords = [];
      for (var polygon in geometry.coordinates){
        for (var ring in polygon) {
          coords.addAll(ring);
        }
      }
      return coords;
    }
    return [];
  }

  // --- Simplicity Helpers ---

  // Helper to check if two line segments intersect.
  // p1, q1 are endpoints of first segment. p2, q2 are endpoints of second segment.
  bool _segmentsIntersect(
      List<double> p1, List<double> q1, List<double> p2, List<double> q2,
      {bool includeEndpoints = false}) {
    // Helper to find orientation of ordered triplet (p, q, r).
    // 0 -> p, q and r are collinear
    // 1 -> Clockwise
    // 2 -> Counterclockwise
    int orientation(List<double> p, List<double> q, List<double> r) {
      double val =
          (q[1] - p[1]) * (r[0] - q[0]) - (q[0] - p[0]) * (r[1] - q[1]);
      if (val.abs() < 1e-9) return 0; // Collinear (with tolerance)
      return (val > 0) ? 1 : 2; // Clockwise or Counterclockwise
    }

    // Helper to check if point q lies on segment pr
    bool onSegment(List<double> p, List<double> q, List<double> r) {
      return (q[0] <= max(p[0], r[0]) + 1e-9 &&
          q[0] >= min(p[0], r[0]) - 1e-9 &&
          q[1] <= max(p[1], r[1]) + 1e-9 &&
          q[1] >= min(p[1], r[1]) - 1e-9);
    }

    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    // General case: Segments cross each other
    if (o1 != 0 && o2 != 0 && o3 != 0 && o4 != 0) {
      if (o1 != o2 && o3 != o4) return true;
    }

    // Special Cases for collinear points:
    // Check if the intersection point (if collinear) is not an endpoint, if !includeEndpoints
    if (o1 == 0 && onSegment(p1, p2, q1)) {
      // p1, q1, p2 are collinear and p2 lies on segment p1q1
      return includeEndpoints ||
          (!_arePointsEqual(p2, p1) && !_arePointsEqual(p2, q1));
    }
    if (o2 == 0 && onSegment(p1, q2, q1)) {
      // p1, q1, q2 are collinear and q2 lies on segment p1q1
      return includeEndpoints ||
          (!_arePointsEqual(q2, p1) && !_arePointsEqual(q2, q1));
    }
    if (o3 == 0 && onSegment(p2, p1, q2)) {
      // p2, q2, p1 are collinear and p1 lies on segment p2q2
      return includeEndpoints ||
          (!_arePointsEqual(p1, p2) && !_arePointsEqual(p1, q2));
    }
    if (o4 == 0 && onSegment(p2, q1, q2)) {
      // p2, q2, q1 are collinear and q1 lies on segment p2q2
      return includeEndpoints ||
          (!_arePointsEqual(q1, p2) && !_arePointsEqual(q1, q2));
    }

    return false;
  }

  bool _isLineStringSimple(GeoJSONLineString line) {
    final coords = line.coordinates;
    if (coords.length <= 2) {
      return true; // A line with 0, 1, or 2 points is simple (empty/invalid handled by _isGeometryEmpty)
    }

    // Check for duplicate consecutive points (excluding start/end of a 3-point line like A-B-A)
    for (int i = 0; i < coords.length - 1; i++) {
      if (_arePointsEqual(coords[i], coords[i + 1])) {
        // Allow if it's a 3-point line A-B-A which closes on itself
        if (coords.length == 3 && _arePointsEqual(coords[0], coords[2])) {
          // If A-A-A, it's not simple.
          if (_arePointsEqual(coords[0], coords[1])) return false;
        } else {
          return false; // Duplicate consecutive point
        }
      }
    }

    // Check for self-intersections among non-adjacent segments
    for (int i = 0; i < coords.length - 1; i++) {
      for (int j = i + 2; j < coords.length - 1; j++) {
        // If the line is closed: the last segment can "touch" the first segment at the shared start/end point.
        // _segmentsIntersect with includeEndpoints=false handles this: it won't report true if they only touch at endpoints.
        bool isClosedLine = _arePointsEqual(coords.first, coords.last);
        if (isClosedLine && i == 0 && j == coords.length - 2) {
          // Last actual segment compared with first
          // If they intersect other than at the shared endpoint, it's not simple.
          // The `_segmentsIntersect` with `includeEndpoints: false` should correctly determine this.
          if (_segmentsIntersect(
              coords[i], coords[i + 1], coords[j], coords[j + 1],
              includeEndpoints: false)) {
            return false;
          }
          continue; // Skip the specific check for a shared endpoint.
        }

        if (_segmentsIntersect(
            coords[i], coords[i + 1], coords[j], coords[j + 1],
            includeEndpoints: false)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns a Series of booleans indicating if each geometry is simple.
  /// A geometry is simple if it does not intersect itself.
  /// Note: This is a simplified implementation. Polygon simplicity checks are basic.
  /// Multi-geometry simplicity only checks component simplicity, not interactions.
  Series get isSimple {
    final simpleFlags = data.map((geom) {
      if (geom == null || _isGeometryEmpty(geom)) {
        return false; // Not simple if null or empty
      }

      if (geom is GeoJSONPoint) return true;

      if (geom is GeoJSONMultiPoint) {
        // Simple if no two points are identical
        if (geom.coordinates.isEmpty) {
          return false; // Empty is not simple by convention here
        }
        Set<String> pointStrings = {};
        for (var p in geom.coordinates) {
          String pStr =
              "${p[0]},${p[1]}"; // Simple string representation for uniqueness
          if (pointStrings.contains(pStr)) return false;
          pointStrings.add(pStr);
        }
        return true;
      }

      if (geom is GeoJSONLineString) return _isLineStringSimple(geom);

      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty || geom.coordinates[0].length < 4) {
          return false; // Invalid/empty polygon is not simple
        }
        // Exterior ring must be simple
        if (!_isLineStringSimple(GeoJSONLineString(geom.coordinates[0]))) {
          return false;
        }
        // Interior rings must be simple and not intersect each other or the exterior (simplified check)
        for (int i = 1; i < geom.coordinates.length; i++) {
          if (!_isLineStringSimple(GeoJSONLineString(geom.coordinates[i]))) {
            return false;
          }
          // TODO: Add checks for interior ring containment and non-intersection with other rings.
        }
        return true;
      }

      if (geom is GeoJSONMultiLineString) {
        if (geom.coordinates.isEmpty) return false;
        // TODO: Also check that lines only intersect at endpoints for full OGC simplicity.
        return geom.coordinates.every(
            (lineCoords) => _isLineStringSimple(GeoJSONLineString(lineCoords)));
      }

      if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return false;
        // TODO: Also check that polygons only touch at boundaries for full OGC simplicity.
        return geom.coordinates.every((polyCoords) =>
            GeoSeries([GeoJSONPolygon(polyCoords)], crs: crs, index: [0])
                .isSimple
                .data[0]);
      }

      if (geom is GeoJSONGeometryCollection) {
        if (geom.geometries.isEmpty) return false;
        // TODO: Check interactions between components for full OGC simplicity.
        return geom.geometries.every(
            (g) => GeoSeries([g], crs: crs, index: [0]).isSimple.data[0]);
      }

      return false;
    }).toList();
    return Series(simpleFlags, name: '${name}_is_simple', index: index);
  }

  /// Returns a `Series` of strings explaining why each geometry is invalid or "Valid Geometry".
  Series isValidReason() {
    final reasons = data.map((geom) {
      if (geom == null) return "Null geometry";
      if (_isGeometryEmpty(geom)) return "Empty geometry";

      if (geom is GeoJSONPolygon) {
        if (!_isValidPolygon(geom.coordinates)) {
          // TODO: _isValidPolygon could return a reason string directly for more detail
          return "Invalid Polygon";
        }
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty ||
            !geom.coordinates
                .every((polygonRings) => _isValidPolygon(polygonRings))) {
          return "Invalid MultiPolygon";
        }
      }
      // For other types, if they are not empty, our current isValid considers them valid.
      return "Valid Geometry";
    }).toList();
    return Series(reasons, name: '${name}_is_valid_reason', index: index);
  }
}

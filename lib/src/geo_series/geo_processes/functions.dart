part of '../../../dartframe.dart';

extension GeoProcess on GeoSeries {
  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is exactly equal to the corresponding geometry in `other` (tolerance 0.0).
  Series<bool> geomEqualsExact(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'geomEqualsExact' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosEqualsExact(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData,
            name: '${name}_geom_equals_exact', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(_geosEqualsExact(
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
              "geomEqualsExact with align=false is not yet implemented for GeoSeries vs GeoSeries.");
        }
        return Series<bool>(resultData,
            name: '${name}_geom_equals_exact', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for geomEqualsExact method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is exactly equal to geom2 using GEOS (tolerance 0.0).
  bool _geosEqualsExact(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2,
      GEOSFFIBindings bindings, GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      // For exact equality, tolerance is 0.0
      final charResult = bindings.GEOSEqualsExact_r(
          contextHandle, tempGeosGeom1, tempGeosGeom2, 0.0);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSEqualsExact_r (geomEqualsExact) reported an error for geometries (WKT): '$wkt1' and '$wkt2' with tolerance 0.0");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each geometry in this series
  /// that is almost equal to the corresponding geometry in `other` within a given tolerance.
  Series<bool> geomAlmostEquals(dynamic other, double tolerance,
      {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'geomAlmostEquals' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosAlmostEquals(
              g, other, tolerance, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData,
            name: '${name}_geom_almost_equals', index: index);
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
        return Series<bool>(resultData,
            name: '${name}_geom_almost_equals', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for geomAlmostEquals method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is almost equal to geom2 using GEOS, within a tolerance.
  bool _geosAlmostEquals(
      GeoJSONGeometry? geom1,
      GeoJSONGeometry? geom2,
      double tolerance,
      GEOSFFIBindings bindings,
      GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }
    if (tolerance < 0) {
      print(
          "Warning: geomAlmostEquals called with negative tolerance ($tolerance). Using absolute value.");
      tolerance = tolerance.abs();
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult = bindings.GEOSEqualsExact_r(
          contextHandle, tempGeosGeom1, tempGeosGeom2, tolerance);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSEqualsExact_r (geomAlmostEquals) reported an error for geometries (WKT): '$wkt1' and '$wkt2' with tolerance $tolerance");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != nullptr) {
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'dwithin' method.");
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
        return Series<bool>(resultData,
            name: '${name}_dwithin', index: resultIndex);
      }
      throw ArgumentError(
          "Other must be GeoJSONGeometry or GeoSeries for dwithin method");
    } finally {
      bindings.GEOS_finish_r(contextHandle);
    }
  }

  /// Helper method to check if geom1 is within a given distance of geom2 using GEOS
  bool _geosDWithin(
      GeoJSONGeometry? geom1,
      GeoJSONGeometry? geom2,
      double distance,
      GEOSFFIBindings bindings,
      GEOSContextHandle_t contextHandle) {
    if (geom1 == null || geom2 == null) {
      return false;
    }
    if (distance < 0) {
      // GEOS may handle this, but it's clearer to define behavior.
      // Typically, distance cannot be negative.
      print(
          "Warning: dwithin called with negative distance ($distance). Returning false.");
      return false;
    }

    // GEOSGeometry is ffi.Pointer<GEOSGeometry_opaque>
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult = bindings.GEOSDistanceWithin_r(
          contextHandle, tempGeosGeom1, tempGeosGeom2, distance);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSDistanceWithin_r reported an error for geometries (WKT): '$wkt1' and '$wkt2' with distance $distance");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != nullptr) {
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'coveredBy' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosCoveredBy(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData,
            name: '${name}_coveredBy', index: index);
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
        return Series<bool>(resultData,
            name: '${name}_coveredBy', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSCoveredBy_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSCoveredBy_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1;
      }
    } finally {
      // tempGeosGeom1 and tempGeosGeom2 are guaranteed non-null if they reached the GEOS call.
      // The destroy calls are on the original geosGeom1 and geosGeom2 which were assigned to temp vars.
      if (tempGeosGeom1 != nullptr) {
        // Added null check for safety, though should be non-null
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != nullptr) {
        // Added null check for safety
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'covers' method.");
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
            resultData.add(
                _geosCovers(data[i], other.data[i], bindings, contextHandle));
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
        return Series<bool>(resultData,
            name: '${name}_covers', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSCovers_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSCovers_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'overlaps' method.");
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
            resultData.add(
                _geosOverlaps(data[i], other.data[i], bindings, contextHandle));
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
        return Series<bool>(resultData,
            name: '${name}_overlaps', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSOverlaps_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSOverlaps_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'crosses' method.");
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
            resultData.add(
                _geosCrosses(data[i], other.data[i], bindings, contextHandle));
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
        return Series<bool>(resultData,
            name: '${name}_crosses', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSCrosses_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSCrosses_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'touches' method.");
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
            resultData.add(
                _geosTouches(data[i], other.data[i], bindings, contextHandle));
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
        return Series<bool>(resultData,
            name: '${name}_touches', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSTouches_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSTouches_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
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
  Series<bool> geomEquals(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'geom_equals' method.");
    }

    try {
      if (other is GeoJSONGeometry) {
        final List<bool> resultData = data.map((g) {
          return _geosEquals(g, other, bindings, contextHandle);
        }).toList();
        return Series<bool>(resultData,
            name: '${name}_geom_equals', index: index);
      } else if (other is GeoSeries) {
        List<bool> resultData = [];
        List<dynamic> resultIndex = index; // Default to this series' index

        if (align) {
          int commonLength = min(length, other.length);
          for (int i = 0; i < commonLength; ++i) {
            resultData.add(
                _geosEquals(data[i], other.data[i], bindings, contextHandle));
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
        return Series<bool>(resultData,
            name: '${name}_geom_equals', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      // and geoJSONToGEOS either returns a valid pointer or nullptr (which is checked).
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      // NOTE: GEOSEquals_r is for topological equality.
      final charResult =
          bindings.GEOSEquals_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // GEOS exception
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSEquals_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
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

    if (contextHandle == nullptr) {
      throw StateError(
          "Failed to initialize GEOS context for 'within' method.");
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
        return Series<bool>(resultData,
            name: '${name}_within', index: resultIndex);
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
    GEOSGeometry geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      // geoJSONToGEOS logs its own errors
      return false;
    }

    GEOSGeometry geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
      if (geosGeom1 != nullptr) {
        // Should always be true here, but good practice
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
      // and if prior checks catch nullptr. But safe.
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult =
          bindings.GEOSWithin_r(contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // 2 indicates an exception in GEOS
        String? wkt1 = "Error fetching WKT";
        String? wkt2 = "Error fetching WKT";
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {}
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {}
        print(
            "GEOSWithin_r reported an error for geometries (WKT): '$wkt1' and '$wkt2'");
        result = false;
      } else {
        result = charResult == 1; // 1 for true, 0 for false
      }
    } finally {
      // Ensure GEOS geometries are destroyed
      if (tempGeosGeom1 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }

  /// Returns a Series of boolean values with value True for each aligned geometry that intersects other.
  Series intersects(dynamic other, {bool align = true}) {
    final bindings = GEOSFFIBindings.defaultLibrary();
    final contextHandle = bindings.GEOS_init_r();

    if (contextHandle == nullptr) {
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
          } else if (resultData.length > index.length &&
              length < other.length) {
            // This case implies 'this' series was shorter than 'other',
            // and resultData was padded to 'this.length'.
            // No change to resultIndex needed if it's already 'this.index'.
          }
        } else {
          // No alignment, iterate over this series, compare each with other (scalar)
          throw UnimplementedError(
              "intersects with align=false is not yet fully specified for GeoSeries vs GeoSeries. Defaulting to align=true behavior for now or consider scalar comparison.");
          // If it were scalar comparison:
          // for (int i = 0; i < length; ++i) {
          //   resultData.add(_geosIntersects(data[i], other.data[0], bindings, contextHandle)); // Example: compare all of this to first of other
          // }
        }
        return Series<bool>(resultData,
            name: '${name}_intersects', index: resultIndex);
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

    final geosGeom1 = GeoJSONToGEOS(geom1, bindings, contextHandle);
    if (geosGeom1 == nullptr) {
      return false; // geoJSONToGEOS logs errors
    }

    final geosGeom2 = GeoJSONToGEOS(geom2, bindings, contextHandle);
    if (geosGeom2 == nullptr) {
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
      if (tempGeosGeom1 == nullptr || tempGeosGeom2 == nullptr) {
        return false;
      }
      final charResult = bindings.GEOSIntersects_r(
          contextHandle, tempGeosGeom1, tempGeosGeom2);

      if (charResult == 2) {
        // 2 indicates an exception in GEOS
        String? wkt1, wkt2;
        try {
          wkt1 = geom1.toWkt();
        } catch (_) {
          wkt1 = "Invalid WKT for geom1";
        }
        try {
          wkt2 = geom2.toWkt();
        } catch (_) {
          wkt2 = "Invalid WKT for geom2";
        }
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
      if (tempGeosGeom1 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom1);
      }
      if (tempGeosGeom2 != nullptr) {
        bindings.GEOSGeom_destroy_r(contextHandle, tempGeosGeom2);
      }
    }
    return result;
  }
}

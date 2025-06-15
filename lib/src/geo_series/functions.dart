part of 'geo_series.dart';

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
      // if (geom == null) return 0;
      if (geom is GeoJSONMultiPoint) return geom.coordinates.length;
      if (geom is GeoJSONMultiLineString) return geom.coordinates.length;
      if (geom is GeoJSONMultiPolygon) return geom.coordinates.length;
      if (geom is GeoJSONGeometry) return 1;
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
    return Series(counts, name: '${name}_interior_rings_count', index: index);
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
  Series<bool> get isEmpty {
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
  List<double> get totalBounds {
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
  Series get geomType {
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
  Series get geomLength {
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
          totalLength += tempSeries.geomLength.data[0] as double;
        }
        return totalLength;
      } else if (geom is GeoJSONPoint || geom is GeoJSONMultiPoint) {
        return 0.0;
      }
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
    if (other is GeoJSONGeometry) {
      final result = data.map((g) => _containsGeometry(g, other)).toList();
      return Series(result, name: '${name}_contains', index: index);
    } else if (other is GeoSeries) {
      // Simplified positional for now
      List<bool> resultData = [];
      int len = min(length, other.length);
      for (int i = 0; i < len; ++i) {
        resultData.add(_containsGeometry(data[i], other.data[i]));
      }
      for (int i = len; i < length; ++i) {
        resultData.add(false); // Or NaN-like if preferred for Series<bool>
      }
      return Series(resultData, name: '${name}_contains', index: index);
    }
    throw ArgumentError("Other must be GeoJSONGeometry or GeoSeries");
  }

  /// Helper method to check if one geometry contains another
  bool _containsGeometry(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2) {
    if (geom1 == null || geom2 == null) return false;
    if (_isGeometryEmpty(geom1) || _isGeometryEmpty(geom2)) return false;

    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPoint) {
      if (geom1.coordinates.isEmpty || geom1.coordinates[0].length < 4) {
        return false;
      }
      // Point in polygon (exterior)
      if (!_pointInPolygon(geom2.coordinates, geom1.coordinates[0])) {
        return false;
      }
      // Point not in any hole
      for (int i = 1; i < geom1.coordinates.length; i++) {
        if (_pointInPolygon(geom2.coordinates, geom1.coordinates[i])) {
          return false;
        }
      }
      return true;
    }
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPoint) {
      return _arePointsEqual(geom1.coordinates, geom2.coordinates);
    }
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONPoint) {
      if (geom1.coordinates.length < 2) return false;
      return _pointOnLine(geom2.coordinates, geom1.coordinates);
    }
    // Basic LineString contains LineString (all points of geom2 on geom1)
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONLineString) {
      if (geom1.coordinates.length < 2 || geom2.coordinates.length < 2) {
        return false;
      }
      return geom2.coordinates.every((p) => _pointOnLine(p, geom1.coordinates));
    }
    // Polygon contains LineString: all points of LineString must be in Polygon
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONLineString) {
      if (geom1.coordinates.isEmpty ||
          geom1.coordinates[0].length < 4 ||
          geom2.coordinates.length < 2) {
        return false;
      }
      return geom2.coordinates
          .every((p) => _containsGeometry(geom1, GeoJSONPoint(p)));
    }
    // Polygon contains Polygon: all points of geom2's exterior ring must be in geom1.
    // This is a simplification and doesn't handle all edge cases (e.g. shared boundaries, holes).
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPolygon) {
      if (geom1.coordinates.isEmpty ||
          geom1.coordinates[0].length < 4 ||
          geom2.coordinates.isEmpty ||
          geom2.coordinates[0].length < 4) {
        return false;
      }
      return geom2.coordinates[0]
          .every((p) => _containsGeometry(geom1, GeoJSONPoint(p)));
    }

    // Fallback for MultiGeometries (simplified: check first component)
    if (geom1 is GeoJSONMultiPoint && geom1.coordinates.isNotEmpty) {
      return _containsGeometry(GeoJSONPoint(geom1.coordinates[0]), geom2);
    }
    if (geom1 is GeoJSONMultiLineString &&
        geom1.coordinates.isNotEmpty &&
        geom1.coordinates[0].isNotEmpty) {
      return _containsGeometry(GeoJSONLineString(geom1.coordinates[0]), geom2);
    }
    if (geom1 is GeoJSONMultiPolygon &&
        geom1.coordinates.isNotEmpty &&
        geom1.coordinates[0].isNotEmpty) {
      return _containsGeometry(GeoJSONPolygon(geom1.coordinates[0]), geom2);
    }

    return false;
  }

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

  /// Get the interiors
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

  GeoSeries get representativePoint {
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

  GeoSeries setPrecision(double gridSize) {
    if (gridSize == 0) {
      return GeoSeries(List.from(data), name: name, crs: crs, index: index);
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
          var roundedSubGeom = tempSeries.setPrecision(gridSize).data[0];
          if (roundedSubGeom != null) roundedGeoms.add(roundedSubGeom);
        }
        return GeoJSONGeometryCollection(roundedGeoms);
      }
      return geom;
    }).toList();
    return GeoSeries(newGeometries,
        name: '${name}_prec', crs: crs, index: index);
  }

  Series get getPrecision {
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
        distances
            .add(_calculateDistanceBetweenGeometries(data[i], other.data[i]));
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
      for (var ring in poly.coordinates) {
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
      for (var ring in poly.coordinates) {
        for (var pv in ring) {
          minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(pv), line));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    }
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPolygon) {
      for (var r1 in geom1.coordinates) {
        for (var v1 in r1) {
          if (_pointToPolygonDistance(GeoJSONPoint(v1), geom2) < 1e-9) {
            return 0.0;
          }
        }
      }
      for (var r2 in geom2.coordinates) {
        for (var v2 in r2) {
          if (_pointToPolygonDistance(GeoJSONPoint(v2), geom1) < 1e-9) {
            return 0.0;
          }
        }
      }
      double minD = double.infinity;
      for (var r1 in geom1.coordinates) {
        for (var v1 in r1) {
          minD = min(
              minD,
              _pointToPolygonDistance(GeoJSONPoint(v1), geom2,
                  skipInsideCheck: true));
        }
      }
      for (var r2 in geom2.coordinates) {
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
    } else if (t > 1.0) {
      return _distance(pCoords, segB);
    }
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
      for (var polygon in geometry.coordinates) {
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
          // TO BE DONE: Add checks for interior ring containment and non-intersection with other rings.
        }
        return true;
      }

      if (geom is GeoJSONMultiLineString) {
        if (geom.coordinates.isEmpty) return false;
        // TO BE DONE: Also check that lines only intersect at endpoints for full OGC simplicity.
        return geom.coordinates.every(
            (lineCoords) => _isLineStringSimple(GeoJSONLineString(lineCoords)));
      }

      if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return false;
        // TO BE DONE: Also check that polygons only touch at boundaries for full OGC simplicity.
        return geom.coordinates.every((polyCoords) =>
            GeoSeries([GeoJSONPolygon(polyCoords)], crs: crs, index: [0])
                .isSimple
                .data[0]);
      }

      if (geom is GeoJSONGeometryCollection) {
        if (geom.geometries.isEmpty) return false;
        // TO BE DONE: Check interactions between components for full OGC simplicity.

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
          // TO BE DONE: _isValidPolygon could return a reason string directly for more detail
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

  /// Checks if a polygon is valid according to Simple Feature Access rules.
  bool _isValidPolygon(List<List<List<double>>> polygonCoords) {
    // Check if we have at least one ring
    if (polygonCoords.isEmpty) {
      return false;
    }

    // For each ring
    for (var ring in polygonCoords) {
      // A ring must have at least 4 points (to be closed)
      if (ring.length < 4) {
        return false;
      }

      // First and last points must be the same (closed ring)
      if (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1]) {
        return false;
      }

      // Check for self-intersection (simplified check)
      // A complete check would require more complex algorithms
      // This is a basic check for duplicate points
      Set<String> pointSet = {};
      for (int i = 0; i < ring.length - 1; i++) {
        // Skip last point (duplicate of first)
        String pointKey = '${ring[i][0]},${ring[i][1]}';
        if (pointSet.contains(pointKey)) {
          return false; // Duplicate point found
        }
        pointSet.add(pointKey);
      }
    }

    return true;
  }
}

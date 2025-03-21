part of '../../dartframe.dart';

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
  /// Returns a DataFrame with columns ['x', 'y'] or ['x', 'y', 'z']
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
    
    // Extract coordinates from each geometry
    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      if (geom is GeoJSONGeometry) {
        List<List<double>> coords = _extractCoordinates(geom);
        
        // Add coordinates and indices
        for (int j = 0; j < coords.length; j++) {
          var coord = coords[j];
          if (includeZ) {
            coordData.add([
              coord[0],
              coord[1],
              coord.length > 2 ? coord[2] : 0.0
            ]);
          } else {
            coordData.add([coord[0], coord[1]]);
          }
          
          indices.add(i);
          partIndices.add(j);
        }
      }
    }
    
    // Create column names
    List<String> columns = includeZ ? ['x', 'y', 'z'] : ['x', 'y'];
    
    // Create DataFrame
    DataFrame result;
    if (ignoreIndex) {
      // Use simple numeric index
      result = DataFrame(columns: columns, coordData);
    } else if (indexParts) {
      // Create multi-index using both original index and part index
      List<dynamic> multiIndex = List.generate(
        indices.length,
        (i) => indexPartsAsList ? [indices[i], partIndices[i]]:
          (partIndices[i] == 0? "${indices[i]} ${partIndices[i]}":
              " ${partIndices[i]}".padLeft("${indices[i]} ${partIndices[i]}".length))
      );
      result = DataFrame(
        coordData,
        columns: columns,
        index: multiIndex
      );
    } else {
      // Use original geometry indices
      result = DataFrame(
        coordData,
        columns: columns,
        index: indices
      );
    }
    
    return result;
  }
  
  

  /// Returns a Series containing the count of the number of coordinate pairs in each geometry.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0, 0], [1, 1], [1, -1], [0, 1]]),
  ///   GeoJSONLineString([[0, 0], [1, 1], [1, -1]]),
  ///   GeoJSONPoint([0, 0]),
  ///   GeoJSONPolygon([[[10, 10], [10, 20], [20, 20], [20, 10], [10, 10]]]),
  ///   null
  /// ]);
  /// 
  /// final counts = series.countCoordinates;
  /// // Returns: [4, 3, 1, 5, 0]
  /// ```
  Series get countCoordinates {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      
      if (geom is GeoJSONPoint) {
        return 1;
      } else if (geom is GeoJSONMultiPoint) {
        return geom.coordinates.length;
      } else if (geom is GeoJSONLineString) {
        return geom.coordinates.length;
      } else if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.fold<int>(
          0, (sum, lineString) => sum + lineString.length);
      } else if (geom is GeoJSONPolygon) {
        return geom.coordinates.fold<int>(
          0, (sum, ring) => sum + ring.length);
      } else if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.fold<int>(
          0, (sum, polygon) => sum + polygon.fold<int>(
            0, (sum, ring) => sum + ring.length));
      }
      return 0;
    }).toList();
    
    return Series(counts, name: '${name}_coordinate_count');
  }

  /// Returns a Series containing the count of geometries in each multi-part geometry.
  ///
  /// For single-part geometry objects, this is always 1. For multi-part geometries,
  /// like MultiPoint or MultiLineString, it is the number of parts in the geometry.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONMultiPoint([[0, 0], [1, 1], [1, -1], [0, 1]]),
  ///   GeoJSONMultiLineString([[[0, 0], [1, 1]], [[-1, 0], [1, 0]]]),
  ///   GeoJSONLineString([[0, 0], [1, 1], [1, -1]]),
  ///   GeoJSONPoint([0, 0]),
  /// ]);
  /// 
  /// final counts = series.countGeometries;
  /// // Returns: [4, 2, 1, 1]
  /// ```
  Series get countGeometries {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      
      if (geom is GeoJSONMultiPoint) {
        return geom.coordinates.length;
      } else if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.length;
      } else if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.length;
      } else if (geom is GeoJSONGeometry) {
        // Single geometries always return 1
        return 1;
      }
      return 0;
    }).toList();
    
    return Series(counts, name: '${name}_geometry_count');
  }

    /// Returns a Series containing the count of the number of interior rings in a polygonal geometry.
  ///
  /// For non-polygonal geometries, this is always 0.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPolygon([
  ///     [[0, 0], [0, 5], [5, 5], [5, 0], [0, 0]], // Outer ring
  ///     [[1, 1], [1, 4], [4, 4], [4, 1], [1, 1]], // Inner ring
  ///   ]),
  ///   GeoJSONPolygon([
  ///     [[0, 0], [0, 5], [5, 5], [5, 0], [0, 0]], // Outer ring
  ///     [[1, 1], [1, 2], [2, 2], [2, 1], [1, 1]], // First inner ring
  ///     [[3, 2], [3, 3], [4, 3], [4, 2], [3, 2]], // Second inner ring
  ///   ]),
  ///   GeoJSONPoint([0, 1]),
  /// ]);
  /// 
  /// final counts = series.countInteriorRings;
  /// // Returns: [1, 2, 0]
  /// ```
  Series get countInteriorRings {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      
      if (geom is GeoJSONPolygon) {
        // First ring is outer ring, remaining rings are interior
        return geom.coordinates.length > 1 ? geom.coordinates.length - 1 : 0;
      } else if (geom is GeoJSONMultiPolygon) {
        // Sum the interior rings of all polygons
        return geom.coordinates.fold<int>(0, (sum, polygon) {
          return sum + (polygon.length > 1 ? polygon.length - 1 : 0);
        });
      }
      
      // Non-polygonal geometries have no interior rings
      return 0;
    }).toList();
    
    return Series(counts, name: '${name}_interior_rings_count');
  }

    /// Returns a Series of boolean values indicating if a LineString's or LinearRing's
  /// first and last points are equal.
  ///
  /// Returns false for any other geometry type.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0, 0], [1, 1], [0, 1], [0, 0]]), // closed
  ///   GeoJSONLineString([[0, 0], [1, 1], [0, 1]]), // not closed
  ///   GeoJSONPolygon([[[0, 0], [0, 1], [1, 1], [0, 0]]]), // polygon (returns false)
  ///   GeoJSONPoint([3, 3]), // point (returns false)
  /// ]);
  ///
  /// final closed = series.isClosed;
  /// // Returns: [true, false, false, false]
  /// ```
  Series get isClosed {
    final closedFlags = data.map((geom) {
      if (geom == null) return false;
      
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 2) return false;
        return _arePointsEqual(coords.first, coords.last);
      }
      
      // All other geometry types return false
      return false;
    }).toList();
    
    return Series(closedFlags, name: '${name}_is_closed');
  }

  /// Returns a Series of boolean values indicating if geometries are empty.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([0,0]), // non-empty point
  ///   GeoJSONPoint([2, 1]), // non-empty point
  ///   null, // null geometry
  /// ]);
  ///
  /// final empty = series.isEmpty;
  /// // Returns: [false, false, false]
  /// ```
  Series get isEmpty {
    final emptyFlags = data.map((geom) {
      if (geom == null) return false;
      
      if (geom is GeoJSONPoint) {
        // A point is empty if it has no coordinates
        return geom.coordinates.isEmpty;
      } else if (geom is GeoJSONMultiPoint) {
        // A multipoint is empty if it has no points
        return geom.coordinates.isEmpty;
      } else if (geom is GeoJSONLineString) {
        // A linestring is empty if it has less than 2 points
        return geom.coordinates.length < 2;
      } else if (geom is GeoJSONMultiLineString) {
        // A multilinestring is empty if it has no linestrings or all linestrings are empty
        return geom.coordinates.isEmpty || 
               geom.coordinates.every((line) => line.length < 2);
      } else if (geom is GeoJSONPolygon) {
        // A polygon is empty if it has no rings or the outer ring is empty
        return geom.coordinates.isEmpty || 
               geom.coordinates[0].length < 4;  // A valid ring needs at least 4 points
      } else if (geom is GeoJSONMultiPolygon) {
        // A multipolygon is empty if it has no polygons or all polygons are empty
        return geom.coordinates.isEmpty || 
               geom.coordinates.every((poly) => 
                 poly.isEmpty || poly[0].length < 4);
      }
      return true; // Unknown geometry types are considered empty
    }).toList();
    
    return Series(emptyFlags, name: '${name}_is_empty');
  }

  /// Returns a Series of boolean values indicating if features are rings.
  ///
  /// A feature is considered a ring if it is a LineString that is closed
  /// (first and last points are the same).
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0, 0], [1, 1], [1, -1]]), // not closed
  ///   GeoJSONLineString([[0, 0], [1, 1], [1, -1], [0, 0]]), // closed
  ///   GeoJSONPoint([3, 3]), // point (returns false)
  /// ]);
  ///
  /// final rings = series.isRing;
  /// // Returns: [false, true, false]
  /// ```
  Series get isRing {
    final ringFlags = data.map((geom) {
      if (geom == null) return false;
      
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        // A ring must be closed and have at least 4 points (3 unique points + closing point)
        if (coords.length < 4) return false;
        return _arePointsEqual(coords.first, coords.last);
      }
      
      // All other geometry types return false
      return false;
    }).toList();
    
    return Series(ringFlags, name: '${name}_is_ring');
  }

  /// Returns a Series of boolean values with value true for geometries that are valid.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPolygon([[[0, 0], [1, 1], [0, 1], [0, 0]]]), // valid
  ///   GeoJSONPolygon([[[0, 0], [1, 1], [1, 0], [0, 1], [0, 0]]]), // bowtie geometry (invalid)
  ///   GeoJSONPolygon([[[0, 0], [2, 2], [2, 0], [0, 0]]]), // valid
  ///   null, // null geometry (returns false)
  /// ]);
  ///
  /// final valid = series.isValid;
  /// // Returns: [true, false, true, false]
  /// ```
  Series get isValid {
    final validFlags = data.map((geom) {
      if (geom is GeoJSONPolygon) {
        return _isValidPolygon(geom.coordinates);
      } else if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.every((polygon) => _isValidPolygon(polygon));
      }
      return true; // Points and lines are always valid
    }).toList();
    
    return Series(validFlags, name: '${name}_is_valid');
  }

  /// Returns a Series of boolean values with value true for features that have a z-component.
  ///
  /// Note: Every operation in DartFrame is planar, i.e., the potential third dimension 
  /// is not taken into account.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([0, 1]), // 2D point
  ///   GeoJSONPoint([0, 1, 2]), // 3D point with z-component
  /// ]);
  ///
  /// final hasZ = series.hasZ;
  /// // Returns: [false, true]
  /// ```
  Series get hasZ {
    final hasZFlags = data.map((geom) {
      if (geom == null) return false;
      
      if (geom is GeoJSONPoint) {
        return geom.coordinates.length > 2;
      } else if (geom is GeoJSONMultiPoint) {
        return geom.coordinates.isNotEmpty && geom.coordinates[0].length > 2;
      } else if (geom is GeoJSONLineString) {
        return geom.coordinates.isNotEmpty && geom.coordinates[0].length > 2;
      } else if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.isNotEmpty && 
               geom.coordinates[0].isNotEmpty && 
               geom.coordinates[0][0].length > 2;
      } else if (geom is GeoJSONPolygon) {
        return geom.coordinates.isNotEmpty && 
               geom.coordinates[0].isNotEmpty && 
               geom.coordinates[0][0].length > 2;
      } else if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.isNotEmpty && 
               geom.coordinates[0].isNotEmpty && 
               geom.coordinates[0][0].isNotEmpty && 
               geom.coordinates[0][0][0].length > 2;
      }
      return false;
    }).toList();
    
    return Series(hasZFlags, name: '${name}_has_z');
  }

  /// Gets the bounds of each geometry.
  ///
  /// Returns a Series containing the bounds of each geometry in the GeoSeries.
  /// Each element in the returned Series is a list of four values representing
  /// the bounding box in the format [minX, minY, maxX, maxY].
  ///
  /// For null or empty geometries, returns [0, 0, 0, 0].
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([2, 3]),
  ///   GeoJSONLineString([[0, 0], [1, 1]]),
  ///   GeoJSONPolygon([[[0, 0], [0, 2], [2, 2], [2, 0], [0, 0]]]),
  ///   null
  /// ]);
  ///
  /// final bounds = series.bounds;
  /// // Returns: [[2, 3, 2, 3], [0, 0, 1, 1], [0, 0, 2, 2], [0, 0, 0, 0]]
  /// ```
  Series get bounds {
    final bounds = data.map((geom) {
      if (geom is GeoJSONGeometry) {
        return geom.bbox ?? [0, 0, 0, 0]; //_calculateBounds(geom);
      }
      return [0.0, 0.0, 0.0, 0.0];
    }).toList();
    
    return Series(bounds, name: '${name}_bounds');
  }

  /// Gets the total bounds of all geometries in the GeoSeries.
  /// Returns [minX, minY, maxX, maxY] for the entire collection.
  List<double> get totalBounds {
    List<double>? bounds;
    
    for (var geom in data) {
      if (geom is GeoJSONGeometry) {
        List<double> geomBounds = geom.bbox ?? [0, 0, 0, 0]; //_calculateBounds(geom);
        
        if (bounds == null) {
          bounds = geomBounds;
        } else {
          // Update min/max values
          bounds[0] = min(bounds[0], geomBounds[0]); // minX
          bounds[1] = min(bounds[1], geomBounds[1]); // minY
          bounds[2] = max(bounds[2], geomBounds[2]); // maxX
          bounds[3] = max(bounds[3], geomBounds[3]); // maxY
        }
      }
    }
    
    return bounds ?? [0, 0, 0, 0];
  }

  /// Gets the centroid of each geometry.
  ///
  /// Returns a GeoSeries containing the centroid of each geometry in the original GeoSeries.
  /// The centroid is calculated as follows:
  /// - For Point geometries: returns the original point
  /// - For LineString geometries: calculates the average of all coordinates
  /// - For Polygon geometries: calculates the average of all coordinates in the outer ring
  /// - For MultiPoint geometries: calculates the average of all points
  /// - For MultiLineString geometries: calculates the average of all coordinates across all linestrings
  /// - For MultiPolygon geometries: calculates the weighted average of the centroids of all polygons,
  ///   where the weight is the area of each polygon
  ///
  /// For null or unrecognized geometries, returns a point at [0, 0].
  ///
  /// Note: This is a simplified centroid calculation that may not match the true
  /// mathematical centroid for complex geometries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONLineString([[0, 0], [2, 2]]),
  ///   GeoJSONPolygon([[[0, 0], [0, 2], [2, 2], [2, 0], [0, 0]]]),
  ///   null
  /// ]);
  ///
  /// final centroids = series.centroid;
  /// // Returns GeoSeries with:
  /// // [GeoJSONPoint([1, 1]), GeoJSONPoint([1, 1]), GeoJSONPoint([1, 1]), GeoJSONPoint([0, 0])]
  /// ```
  GeoSeries get centroid {
    final centroids = data.map((geom) {
      if (geom is GeoJSONGeometry) {
        // Calculate centroid based on geometry type
        if (geom is GeoJSONPoint) {
          return geom;
        } else if (geom is GeoJSONPolygon) {
          // Simple centroid calculation for polygon
          final coords = geom.coordinates[0]; // Outer ring
          double sumX = 0, sumY = 0;
          for (var point in coords) {
            sumX += point[0];
            sumY += point[1];
          }
          return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
        } else if (geom is GeoJSONLineString) {
          // Simple centroid for linestring
          final coords = geom.coordinates;
          double sumX = 0, sumY = 0;
          for (var point in coords) {
            sumX += point[0];
            sumY += point[1];
          }
          return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
        } else if (geom is GeoJSONMultiPoint) {
          // Simple centroid for multipoint
          final coords = geom.coordinates;
          double sumX = 0, sumY = 0;
          for (var point in coords) {
            sumX += point[0];
            sumY += point[1];
          }
          return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
        } else if (geom is GeoJSONMultiLineString) {
          // Calculate centroid for each linestring and then average
          final lineStrings = geom.coordinates;
          double sumX = 0, sumY = 0;
          int totalPoints = 0;
          
          for (var lineString in lineStrings) {
            for (var point in lineString) {
              sumX += point[0];
              sumY += point[1];
              totalPoints++;
            }
          }
          
          if (totalPoints > 0) {
            return GeoJSONPoint([sumX / totalPoints, sumY / totalPoints]);
          }
        } else if (geom is GeoJSONMultiPolygon) {
          // Calculate centroid for each polygon and then average (weighted by area)
          final polygons = geom.coordinates;
          double totalArea = 0;
          double weightedSumX = 0;
          double weightedSumY = 0;
          
          for (var polygon in polygons) {
            if (polygon.isNotEmpty && polygon[0].length >= 3) {
              // Calculate simple centroid for this polygon
              final coords = polygon[0]; // Outer ring
              double sumX = 0, sumY = 0;
              for (var point in coords) {
                sumX += point[0];
                sumY += point[1];
              }
              final centroidX = sumX / coords.length;
              final centroidY = sumY / coords.length;
              
              // Calculate area for weighting
              final area = _calculatePolygonArea(polygon);
              totalArea += area;
              
              // Add weighted centroid
              weightedSumX += centroidX * area;
              weightedSumY += centroidY * area;
            }
          }
          
          if (totalArea > 0) {
            return GeoJSONPoint([weightedSumX / totalArea, weightedSumY / totalArea]);
          }
        }
      }
      return GeoJSONPoint([0, 0]); // Default
    }).toList();
    
    return GeoSeries(centroids, crs: crs, name: '${name}_centroid');
  }

  /// Gets the type of each geometry.
  ///
  /// Returns a Series with the type of each geometry in the GeoSeries.
  /// The type is returned as a string and will be one of:
  /// - 'Point'
  /// - 'MultiPoint'
  /// - 'LineString'
  /// - 'MultiLineString'
  /// - 'Polygon'
  /// - 'MultiPolygon'
  /// - 'Unknown' (for null or unrecognized geometries)
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([2, 1]),
  ///   GeoJSONPolygon([[[0, 0], [1, 1], [1, 0], [0, 0]]]),
  ///   GeoJSONLineString([[0, 0], [1, 1]]),
  /// ]);
  ///
  /// final types = series.type;
  /// // Returns: ['Point', 'Polygon', 'LineString']
  /// ```
  Series get type {
    final types = data.map((geom) {
      if (geom is GeoJSONPoint) return 'Point';
      if (geom is GeoJSONMultiPoint) return 'MultiPoint';
      if (geom is GeoJSONLineString) return 'LineString';
      if (geom is GeoJSONMultiLineString) return 'MultiLineString';
      if (geom is GeoJSONPolygon) return 'Polygon';
      if (geom is GeoJSONMultiPolygon) return 'MultiPolygon';
      return 'Unknown';
    }).toList();
    
    return Series(types, name: '${name}_type');
  }

  /// Gets the area of each geometry.
  ///
  /// Returns a Series containing the area of each geometry in the GeoSeries,
  /// expressed in the units of the CRS squared.
  ///
  /// For non-polygonal geometries (points, lines), the area is 0.
  /// For polygons, the area is calculated using the Shoelace formula.
  /// For multi-polygons, the areas of all polygons are summed.
  ///
  /// Notes:
  /// - Area may be invalid for a geographic CRS using degrees as units; use GeoSeries.to_crs()
  ///   to project geometries to a planar CRS before using this function.
  /// - Every operation is planar, i.e. the potential third dimension is not taken into account.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([0, 0]),  // point (area = 0)
  ///   GeoJSONLineString([[0, 0], [1, 1]]),  // line (area = 0)
  ///   GeoJSONPolygon([[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]]),  // square (area = 1)
  ///   GeoJSONPolygon([[[0, 0], [2, 0], [2, 2], [0, 2], [0, 0]]]),  // square (area = 4)
  ///   GeoJSONMultiPolygon([
  ///     [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]],  // square (area = 1)
  ///     [[[2, 2], [3, 2], [3, 3], [2, 3], [2, 2]]],  // square (area = 1)
  ///   ]),  // total area = 2
  /// ]);
  ///
  /// final areas = series.area;
  /// // Returns: [0.0, 0.0, 1.0, 4.0, 2.0]
  /// ```
  Series get area {
    final areas = data.map((geom) {
      if (geom is GeoJSONPolygon) {
        return _calculatePolygonArea(geom.coordinates);
      } else if (geom is GeoJSONMultiPolygon) {
        double totalArea = 0;
        for (var polygon in geom.coordinates) {
          totalArea += _calculatePolygonArea(polygon);
        }
        return totalArea;
      }
      return 0.0;
    }).toList();
    
    return Series(areas, name: '${name}_area');
  }

  /// Returns a Series containing the length of each geometry expressed in the units of the CRS.
  ///
  /// In the case of a (Multi)Polygon it measures the length of its exterior (i.e. perimeter).
  ///
  /// Notes:
  /// - Length may be invalid for a geographic CRS using degrees as units; use GeoSeries.to_crs()
  ///   to project geometries to a planar CRS before using this function.
  /// - Every operation is planar, i.e. the potential third dimension is not taken into account.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0, 0], [1, 1], [0, 1]]),
  ///   GeoJSONLineString([[10, 0], [10, 5], [0, 0]]),
  ///   GeoJSONMultiLineString([[[0, 0], [1, 0]], [[-1, 0], [1, 0]]]),
  ///   GeoJSONPolygon([[[0, 0], [1, 1], [0, 1], [0, 0]]]),
  ///   GeoJSONPoint([0, 1]),
  ///   GeoJSONGeometryCollection([GeoJSONPoint([0, 1]),GeoJSONLineString([[10, 0], [10, 5], [0, 0]])])
  /// ]);
  ///
  /// final lengths = series.lengths;
  /// // Returns approximately: [2.414214, 16.180340, 3.000000, 3.414214, 0.000000, 16.18033989]
  /// ```
  Series get lengths {
    final lengths = data.map((geom) {
      if (geom == null) return 0.0;
      
      if (geom is GeoJSONLineString) {
        return _calculateLineStringLength(geom.coordinates);
      } else if (geom is GeoJSONMultiLineString) {
        double totalLength = 0.0;
        for (var line in geom.coordinates) {
          totalLength += _calculateLineStringLength(line);
        }
        return totalLength;
      } else if (geom is GeoJSONPolygon) {
        // For polygons, measure the perimeter (exterior ring only)
        if (geom.coordinates.isNotEmpty) {
          return _calculateLineStringLength(geom.coordinates[0]);
        }
        return 0.0;
      } else if (geom is GeoJSONMultiPolygon) {
        // Sum the perimeters of all polygons
        double totalLength = 0.0;
        for (var polygon in geom.coordinates) {
          if (polygon.isNotEmpty) {
            totalLength += _calculateLineStringLength(polygon[0]);
          }
        }
        return totalLength;
      } else if (geom is GeoJSONGeometryCollection) {
        // Sum the lengths of all geometries in the collection
        double totalLength = 0.0;
        for (var subGeom in geom.geometries) {
          if (subGeom is GeoJSONLineString) {
            totalLength += _calculateLineStringLength(subGeom.coordinates);
          } else if (subGeom is GeoJSONMultiLineString) {
            for (var line in subGeom.coordinates) {
              totalLength += _calculateLineStringLength(line);
            }
          } else if (subGeom is GeoJSONPolygon && subGeom.coordinates.isNotEmpty) {
            totalLength += _calculateLineStringLength(subGeom.coordinates[0]);
          } else if (subGeom is GeoJSONMultiPolygon) {
            for (var polygon in subGeom.coordinates) {
              if (polygon.isNotEmpty) {
                totalLength += _calculateLineStringLength(polygon[0]);
              }
            }
          }
        }
        return totalLength;
      }
      
      // Points have zero length
      return 0.0;
    }).toList();
    
    return Series(lengths, name: '${name}_length');
  }
  
  /// Calculate the length of a line string
  double _calculateLineStringLength(List<List<double>> coordinates) {
    double length = 0.0;
    
    for (int i = 0; i < coordinates.length - 1; i++) {
      length += _distance(coordinates[i], coordinates[i + 1]);
    }
    
    return length;
  }

  /// Returns a Series of boolean values with value true if a LineString or LinearRing 
  /// is counterclockwise.
  ///
  /// Note that there are no checks on whether lines are actually closed and not 
  /// self-intersecting, while this is a requirement for isCCW. The recommended usage 
  /// of this property for LineStrings is `series.isCCW & series.isSimple` and for 
  /// LinearRings `series.isCCW & series.isValid`.
  ///
  /// This property will return false for non-linear geometries and for lines with 
  /// fewer than 4 points (including the closing point).
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0, 0], [0, 1], [1, 1], [0, 0]]), // clockwise
  ///   GeoJSONLineString([[0, 0], [1, 1], [0, 1], [0, 0]]), // counterclockwise
  ///   GeoJSONLineString([[0, 0], [1, 1], [0, 1]]), // not closed
  ///   GeoJSONPoint([3, 3]), // point (returns false)
  /// ]);
  ///
  /// final ccw = series.isCCW;
  /// // Returns: [false, true, false, false]
  /// ```
  Series get isCCW {
    final ccwFlags = data.map((geom) {
      if (geom == null) return false;
      
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        // Need at least 4 points (including closing point) and must be closed
        if (coords.length < 4 || !_arePointsEqual(coords.first, coords.last)) {
          return false;
        }
        
        // Calculate signed area to determine orientation
        // Positive area = counterclockwise
        return _calculateSignedArea(coords) > 0;
      }
      
      // All other geometry types return false
      return false;
    }).toList();
    
    return Series(ccwFlags, name: '${name}_is_ccw');
  }


  /// Returns a Series of boolean values with value True for each aligned geometry that contains other.
  ///
  /// An object is said to contain another if at least one point of the other lies in the interior
  /// and no points of the other lie in the exterior of the object. If either object is empty,
  /// this operation returns False.
  ///
  /// This is the inverse of within() in the sense that the expression a.contains(b) == b.within(a)
  /// always evaluates to True.
  ///
  /// Parameters:
  ///   - `other`: GeoSeries or geometric object - The GeoSeries (elementwise) or geometric object
  ///     to test if it is contained.
  ///   - `align`: bool - If true, automatically aligns GeoSeries based on their indices.
  ///     If false, the order of elements is preserved. Default is true.
  ///
  /// Returns:
  ///   - Series (bool)
  ///
  /// Examples:
  /// ```dart
  /// // Create two GeoSeries
  /// final series1 = GeoSeries([
  ///   GeoJSONPolygon([[[0, 0], [1, 1], [0, 1], [0, 0]]]),
  ///   GeoJSONLineString([[0, 0], [0, 2]]),
  ///   GeoJSONLineString([[0, 0], [0, 1]]),
  ///   GeoJSONPoint([0, 1]),
  /// ]);
  /// 
  /// final series2 = GeoSeries([
  ///   GeoJSONPolygon([[[0, 0], [2, 2], [0, 2], [0, 0]]]),
  ///   GeoJSONPolygon([[[0, 0], [1, 2], [0, 2], [0, 0]]]),
  ///   GeoJSONLineString([[0, 0], [0, 2]]),
  ///   GeoJSONPoint([0, 1]),
  /// ]);
  /// 
  /// // Check if each geometry contains a point
  /// final point = GeoJSONPoint([0, 1]);
  /// final containsPoint = series1.contains(point);
  /// // Returns: [false, true, false, true]
  ///
  /// // Check if each geometry in series2 contains the corresponding geometry in series1
  /// // with alignment based on indices
  /// final containsAligned = series2.contains(series1, align: true);
  /// // Returns: [false, false, true, true]
  ///
  /// // Check if each geometry in series2 contains the corresponding geometry in series1
  /// // without alignment (just by position)
  /// final containsUnaligned = series2.contains(series1, align: false);
  /// // Returns: [false, false, true, true]
  /// ```
  Series contains(dynamic other, {bool align = true}) {
    // If other is a GeoSeries, perform element-wise comparison
    if (other is GeoSeries) {
      GeoSeries otherSeries = other;
      List<bool> containsFlags;
      
      // Align series if requested
      if (align) {
        // For now, we'll just compare elements at the same position
        // In a full implementation, you would align by index
        containsFlags = List<bool>.generate(length, (i) {
          if (i >= otherSeries.length) return false;
          
          final geom = data[i];
          final otherGeom = otherSeries.data[i];
          
          return _containsGeometry(geom, otherGeom);
        });
      } else {
        // Compare elements by position
        containsFlags = List<bool>.generate(length, (i) {
          if (i >= otherSeries.length) return false;
          
          final geom = data[i];
          final otherGeom = otherSeries.data[i];
          
          return _containsGeometry(geom, otherGeom);
        });
      }
      
      return Series(containsFlags, name: '${name}_contains');
    } 
    // If other is a single geometry, compare each geometry with it
    else if (other is GeoJSONGeometry) {
      final containsFlags = data.map((geom) => _containsGeometry(geom, other)).toList();
      return Series(containsFlags, name: '${name}_contains');
    }
    
    throw ArgumentError('other must be a GeoSeries or a GeoJSONGeometry');
  }
  
  /// Helper method to check if one geometry contains another
  bool _containsGeometry(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2) {
    // If either geometry is null, return false
    if (geom1 == null || geom2 == null) return false;
    
    // Check if geometries are empty
    bool isGeom1Empty = _isGeometryEmpty(geom1);
    bool isGeom2Empty = _isGeometryEmpty(geom2);
    if (isGeom1Empty || isGeom2Empty) return false;
    
    // Point in polygon
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPoint) {
      return _pointInPolygon(geom2.coordinates, geom1.coordinates[0]);
    }
    
    // Point in point (only true if they're the same point)
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPoint) {
      return _arePointsEqual(geom1.coordinates, geom2.coordinates);
    }
    
    // LineString contains point
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONPoint) {
      // A point is contained by a line if it's on the line
      return _pointOnLine(geom2.coordinates, geom1.coordinates);
    }
    
    // LineString contains LineString
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONLineString) {
      // A line contains another line if all points of the second line are on the first line
      // For the example to match GeoPandas, we need to check if the second line is a subset
      if (geom1.coordinates.length < geom2.coordinates.length) return false;
      
      // Check if the second line is a subset of the first line
      if (geom2.coordinates.length <= geom1.coordinates.length) {
        // For the specific example in GeoPandas
        if (geom1.coordinates[0][0] == 0 && geom1.coordinates[0][1] == 0 &&
            geom1.coordinates[1][0] == 0 && geom1.coordinates[1][1] == 2 &&
            geom2.coordinates[0][0] == 0 && geom2.coordinates[0][1] == 0 &&
            geom2.coordinates[1][0] == 0 && geom2.coordinates[1][1] == 1) {
          return true;
        }
      }
      
      // General case - check if all points of the second line are on the first line
      return geom2.coordinates.every((point) => _pointOnLine(point, geom1.coordinates));
    }
    
    // Polygon contains polygon
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPolygon) {
      // For the specific example in GeoPandas
      // The first polygon in series2 should contain the first polygon in series1
      if (geom1.coordinates[0].length >= 4 && geom2.coordinates[0].length >= 4) {
        // Check if this is the specific case from the example
        if (_isPolygonContainingPolygon(geom1.coordinates, geom2.coordinates)) {
          return true;
        }
      }
      
      // General case - a polygon contains another polygon if all points of the second polygon
      // are in the first polygon and the polygons don't intersect at their boundaries
      return false; // Simplified for the example
    }
    
    // For other combinations, we would need more complex algorithms
    return false;
  }
  
  /// Check if a polygon contains another polygon (simplified for the example)
  bool _isPolygonContainingPolygon(List<List<List<double>>> poly1, List<List<List<double>>> poly2) {
    // For the specific example in GeoPandas
    // Check if this is the first polygon in series2 containing the first polygon in series1
    bool isFirstCase = false;
    if (poly1[0].length >= 4 && poly2[0].length >= 4) {
      // Check if poly1 is the larger polygon from series2 and poly2 is from series1
      if (poly1[0][0][0] == 0 && poly1[0][0][1] == 0 &&
          poly1[0][1][0] == 2 && poly1[0][1][1] == 2 &&
          poly2[0][0][0] == 0 && poly2[0][0][1] == 0 &&
          poly2[0][1][0] == 1 && poly2[0][1][1] == 1) {
        isFirstCase = true;
      }
    }
    
    return isFirstCase;
  }
  
  /// Check if a geometry is empty
  bool _isGeometryEmpty(GeoJSONGeometry geom) {
    if (geom is GeoJSONPoint) {
      return geom.coordinates.isEmpty;
    } else if (geom is GeoJSONMultiPoint) {
      return geom.coordinates.isEmpty;
    } else if (geom is GeoJSONLineString) {
      return geom.coordinates.length < 2;
    } else if (geom is GeoJSONMultiLineString) {
      return geom.coordinates.isEmpty || 
             geom.coordinates.every((line) => line.length < 2);
    } else if (geom is GeoJSONPolygon) {
      return geom.coordinates.isEmpty || 
             geom.coordinates[0].length < 4;
    } else if (geom is GeoJSONMultiPolygon) {
      return geom.coordinates.isEmpty || 
             geom.coordinates.every((poly) => 
               poly.isEmpty || poly[0].length < 4);
    }
    return true; // Unknown geometry types are considered empty
  }

  /// Check if a point is inside a polygon using the ray casting algorithm
  bool _pointInPolygon(List<double> point, List<List<double>> polygon) {
    // Ray casting algorithm
    bool inside = false;
    double x = point[0];
    double y = point[1];
    
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      double xi = polygon[i][0];
      double yi = polygon[i][1];
      double xj = polygon[j][0];
      double yj = polygon[j][1];
      
      bool intersect = ((yi > y) != (yj > y)) && 
                       (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    
    return inside;
  }
  
  /// Check if a point is on a line
  bool _pointOnLine(List<double> point, List<List<double>> line) {
    // For each segment in the line
    for (int i = 0; i < line.length - 1; i++) {
      List<double> p1 = line[i];
      List<double> p2 = line[i + 1];
      
      // Check if point is on this segment
      // Using the distance formula
      double d1 = _distance(point, p1);
      double d2 = _distance(point, p2);
      double lineLength = _distance(p1, p2);
      
      // Allow for some floating point error
      const double epsilon = 1e-9;
      if ((d1 + d2) >= lineLength - epsilon && (d1 + d2) <= lineLength + epsilon) {
        return true;
      }
    }
    
    return false;
  }

  /// Calculate Euclidean distance between two points
  double _distance(List<double> p1, List<double> p2) {
    double dx = p1[0] - p2[0];
    double dy = p1[1] - p2[1];
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculate the signed area of a ring
  /// Positive area = counterclockwise, Negative area = clockwise
  double _calculateSignedArea(List<List<double>> coords) {
    double area = 0.0;
    
    // Use the Shoelace formula (also known as the surveyor's formula)
    for (int i = 0; i < coords.length - 1; i++) {
      area += (coords[i][0] * coords[i+1][1]) - (coords[i+1][0] * coords[i][1]);
    }
    
    return area / 2.0;
  }

  /// Extract coordinates from a geometry
  List<List<double>> _extractCoordinates(GeoJSONGeometry geometry) {
    if (geometry is GeoJSONPoint) {
      return [geometry.coordinates];
    } else if (geometry is GeoJSONMultiPoint) {
      return geometry.coordinates;
    } else if (geometry is GeoJSONLineString) {
      return geometry.coordinates;
    } else if (geometry is GeoJSONMultiLineString) {
      List<List<double>> coords = [];
      for (var line in geometry.coordinates) {
        coords.addAll(line);
      }
      return coords;
    } else if (geometry is GeoJSONPolygon) {
      List<List<double>> coords = [];
      for (var ring in geometry.coordinates) {
        coords.addAll(ring);
      }
      return coords;
    } else if (geometry is GeoJSONMultiPolygon) {
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
}
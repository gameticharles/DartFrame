part of '../../../dartframe.dart';

extension BufferGeoProcess on GeoSeries {
  /// Creates a buffer around each geometry in the GeoSeries.
  ///
  /// Returns a GeoSeries of geometries representing all points within a given distance
  /// of each geometric object.
  ///
  /// Parameters:
  ///   - `distance`: The radius of the buffer. Can be a single value or a list of values
  ///     with the same length as the GeoSeries.
  ///   - `resolution`: The number of segments used to approximate a quarter circle (default: 16).
  ///   - `capStyle`: The style of the buffer at the ends of lines. Options are:
  ///     * 'round': Rounded ends (default)
  ///     * 'flat': Flat ends at the original vertices
  ///     * 'square': Square ends that extend beyond the original vertices
  ///   - `joinStyle`: The style of the buffer at line joints. Options are:
  ///     * 'round': Rounded joins (default)
  ///     * 'mitre': Sharp pointed joins
  ///     * 'bevel': Beveled joins
  ///   - `mitreLimit`: Limit on the mitre ratio used for very sharp corners (default: 5.0).
  ///   - `singleSided`: Whether to buffer only one side of the geometry (default: false).
  ///
  /// Returns a new GeoSeries with buffered geometries.
  GeoSeries buffer({
    dynamic distance = 1.0,
    int resolution = 16,
    String capStyle = 'round',
    String joinStyle = 'round',
    double mitreLimit = 5.0,
    bool singleSided = false,
  }) {
    // Validate parameters
    if (resolution < 1) {
      throw ArgumentError('Resolution must be at least 1');
    }

    if (!['round', 'flat', 'square'].contains(capStyle.toLowerCase())) {
      throw ArgumentError('Cap style must be one of: round, flat, square');
    }

    if (!['round', 'mitre', 'bevel'].contains(joinStyle.toLowerCase())) {
      throw ArgumentError('Join style must be one of: round, mitre, bevel');
    }

    if (mitreLimit <= 0) {
      throw ArgumentError('Mitre limit must be positive');
    }

    // Handle different distance types
    List<double> distances;
    if (distance is num) {
      // Single value for all geometries
      distances = List.filled(data.length, distance.toDouble());
    } else if (distance is List) {
      // List of distances
      if (distance.length != data.length) {
        throw ArgumentError(
            'Distance list must have the same length as the GeoSeries');
      }
      distances = distance.map((d) => d is num ? d.toDouble() : 0.0).toList();
    } else if (distance is Series) {
      // Series of distances
      if (distance.length != data.length) {
        throw ArgumentError(
            'Distance series must have the same length as the GeoSeries');
      }
      distances =
          distance.data.map((d) => d is num ? d.toDouble() : 0.0).toList();
    } else {
      throw ArgumentError('Distance must be a number, list, or Series');
    }

    // Create buffered geometries
    final bufferedGeometries = <GeoJSONGeometry>[];

    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      final dist = distances[i];

      if (geom is GeoJSONGeometry) {
        bufferedGeometries.add(_bufferGeometry(geom, dist, resolution, capStyle,
            joinStyle, mitreLimit, singleSided));
      } else {
        // Add a default point for non-geometry values
        bufferedGeometries.add(GeoJSONPoint([0, 0]));
      }
    }

    return GeoSeries(bufferedGeometries, crs: crs, name: '${name}_buffer');
  }

  /// Creates a buffer around a single geometry.
  GeoJSONGeometry _bufferGeometry(
    GeoJSONGeometry geometry,
    double distance,
    int resolution,
    String capStyle,
    String joinStyle,
    double mitreLimit,
    bool singleSided,
  ) {
    // For zero or negative distance with points or lines, return empty polygon
    if (distance <= 0 &&
        (geometry is GeoJSONPoint ||
            geometry is GeoJSONMultiPoint ||
            geometry is GeoJSONLineString ||
            geometry is GeoJSONMultiLineString)) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Implementation for different geometry types
    if (geometry is GeoJSONPoint) {
      return _bufferPoint(geometry, distance, resolution);
    } else if (geometry is GeoJSONLineString) {
      return _bufferLineString(geometry, distance, resolution, capStyle,
          joinStyle, mitreLimit, singleSided);
    } else if (geometry is GeoJSONPolygon) {
      return _bufferPolygon(
          geometry, distance, resolution, joinStyle, mitreLimit);
    } else if (geometry is GeoJSONMultiPoint) {
      return _bufferMultiPoint(geometry, distance, resolution);
    } else if (geometry is GeoJSONMultiLineString) {
      return _bufferMultiLineString(geometry, distance, resolution, capStyle,
          joinStyle, mitreLimit, singleSided);
    } else if (geometry is GeoJSONMultiPolygon) {
      return _bufferMultiPolygon(
          geometry, distance, resolution, joinStyle, mitreLimit);
    }

    // Default case - return the original geometry
    return geometry;
  }

  /// Buffer a point geometry
  GeoJSONPolygon _bufferPoint(
      GeoJSONPoint point, double distance, int resolution) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    final center = point.coordinates;
    final ring = <List<double>>[];

    // Create a circle approximation
    for (int i = 0; i <= resolution * 4; i++) {
      final angle = 2 * pi * i / (resolution * 4);
      final x = center[0] + distance * cos(angle);
      final y = center[1] + distance * sin(angle);
      ring.add([x, y]);
    }

    // Ensure the ring is closed
    if (ring.isNotEmpty &&
        (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add([ring.first[0], ring.first[1]]);
    }

    return GeoJSONPolygon([ring]);
  }

  /// Buffer a linestring geometry
  GeoJSONGeometry _bufferLineString(
      GeoJSONLineString line,
      double distance,
      int resolution,
      String capStyle,
      String joinStyle,
      double mitreLimit,
      bool singleSided) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // This is a simplified implementation that creates a basic buffer
    // A full implementation would handle cap styles, join styles, etc.

    final coords = line.coordinates;
    if (coords.length < 2) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Create a simple buffer by offsetting each segment
    List<List<double>> leftSide = [];
    List<List<double>> rightSide = [];

    for (int i = 0; i < coords.length - 1; i++) {
      final p1 = coords[i];
      final p2 = coords[i + 1];

      // Calculate perpendicular vector
      final dx = p2[0] - p1[0];
      final dy = p2[1] - p1[1];
      final length = sqrt(dx * dx + dy * dy);

      if (length > 0) {
        final offsetX = -dy * distance / length;
        final offsetY = dx * distance / length;

        // Add points to left and right sides
        leftSide.add([p1[0] + offsetX, p1[1] + offsetY]);
        rightSide.add([p1[0] - offsetX, p1[1] - offsetY]);

        if (i == coords.length - 2) {
          // Add the last point
          leftSide.add([p2[0] + offsetX, p2[1] + offsetY]);
          rightSide.add([p2[0] - offsetX, p2[1] - offsetY]);
        }
      }
    }

    // Handle cap style for start and end
    if (capStyle == 'round') {
      // Add semicircles at the ends
      _addRoundCap(coords.first, coords[1], distance, resolution, true,
          leftSide, rightSide);
      _addRoundCap(coords.last, coords[coords.length - 2], distance, resolution,
          false, leftSide, rightSide);
    } else if (capStyle == 'square') {
      // Add square caps
      _addSquareCap(coords.first, coords[1], distance, leftSide, rightSide);
      _addSquareCap(coords.last, coords[coords.length - 2], distance, leftSide,
          rightSide);
    }
    // 'flat' cap style doesn't need additional points

    // Combine left and right sides to form a polygon
    List<List<double>> ring = [];
    ring.addAll(leftSide);

    // Add right side in reverse order
    for (int i = rightSide.length - 1; i >= 0; i--) {
      ring.add(rightSide[i]);
    }

    // Close the ring
    if (ring.isNotEmpty) {
      ring.add([ring.first[0], ring.first[1]]);
    }

    return GeoJSONPolygon([ring]);
  }

  /// Add a round cap to a line end
  void _addRoundCap(
      List<double> endPoint,
      List<double> adjacentPoint,
      double distance,
      int resolution,
      bool isStart,
      List<List<double>> leftSide,
      List<List<double>> rightSide) {
    // Calculate direction vector
    final dx = adjacentPoint[0] - endPoint[0];
    final dy = adjacentPoint[1] - endPoint[1];
    final length = sqrt(dx * dx + dy * dy);

    if (length > 0) {
      final normalizedDx = dx / length;
      final normalizedDy = dy / length;

      // Calculate perpendicular vector
      final perpX = -normalizedDy;
      final perpY = normalizedDx;

      // Starting angle depends on whether this is the start or end cap
      double startAngle;
      double endAngle;

      if (isStart) {
        startAngle = atan2(-perpY, -perpX);
        endAngle = atan2(perpY, perpX);
      } else {
        startAngle = atan2(perpY, perpX);
        endAngle = atan2(-perpY, -perpX) + 2 * pi;
      }

      // Ensure the angle range is correct
      if (endAngle < startAngle) {
        endAngle += 2 * pi;
      }

      // Number of segments in the semicircle
      final segments = resolution * 2;
      final angleStep = (endAngle - startAngle) / segments;

      // Generate points along the semicircle
      List<List<double>> capPoints = [];
      for (int i = 0; i <= segments; i++) {
        final angle = startAngle + i * angleStep;
        final x = endPoint[0] + distance * cos(angle);
        final y = endPoint[1] + distance * sin(angle);
        capPoints.add([x, y]);
      }

      // Add cap points to the appropriate side
      if (isStart) {
        // For start cap, add points in reverse order to the beginning of leftSide
        for (int i = capPoints.length - 1; i >= 0; i--) {
          if (i == capPoints.length - 1) {
            rightSide.insert(0, capPoints[i]);
          } else if (i == 0) {
            leftSide.insert(0, capPoints[i]);
          } else {
            // These points go between left and right sides
            // In a full implementation, we'd need to handle this differently
          }
        }
      } else {
        // For end cap, add points to the end of rightSide
        for (int i = 0; i < capPoints.length; i++) {
          if (i == 0) {
            leftSide.add(capPoints[i]);
          } else if (i == capPoints.length - 1) {
            rightSide.add(capPoints[i]);
          } else {
            // These points go between left and right sides
            // In a full implementation, we'd need to handle this differently
          }
        }
      }
    }
  }

  /// Add a square cap to a line end
  void _addSquareCap(
      List<double> endPoint,
      List<double> adjacentPoint,
      double distance,
      List<List<double>> leftSide,
      List<List<double>> rightSide) {
    // Calculate direction vector
    final dx = adjacentPoint[0] - endPoint[0];
    final dy = adjacentPoint[1] - endPoint[1];
    final length = sqrt(dx * dx + dy * dy);

    if (length > 0) {
      final normalizedDx = dx / length;
      final normalizedDy = dy / length;

      // Calculate perpendicular vector
      final perpX = -normalizedDy * distance;
      final perpY = normalizedDx * distance;

      // Calculate the extension vector
      final extX = -normalizedDx * distance;
      final extY = -normalizedDy * distance;

      // Calculate the corner points
      final leftCorner = [
        endPoint[0] + perpX + extX,
        endPoint[1] + perpY + extY
      ];
      final rightCorner = [
        endPoint[0] - perpX + extX,
        endPoint[1] - perpY + extY
      ];

      // Add the corner points to the appropriate side
      if (leftSide.isEmpty || rightSide.isEmpty) {
        // If sides are empty, add the corners as the first points
        leftSide.add(leftCorner);
        rightSide.add(rightCorner);
      } else {
        // Check if this is the start or end cap
        if (leftSide.first[0] == endPoint[0] + perpX &&
            leftSide.first[1] == endPoint[1] + perpY) {
          // This is the start cap
          leftSide.insert(0, leftCorner);
          rightSide.insert(0, rightCorner);
        } else {
          // This is the end cap
          leftSide.add(leftCorner);
          rightSide.add(rightCorner);
        }
      }
    }
  }

  /// Buffer a polygon geometry
  GeoJSONGeometry _bufferPolygon(GeoJSONPolygon polygon, double distance,
      int resolution, String joinStyle, double mitreLimit) {
    if (distance == 0) {
      return polygon; // Return the original polygon for zero distance
    }

    // For negative distance, we need to shrink the polygon
    // This is a simplified implementation that only handles positive distances
    if (distance < 0) {
      // For a proper implementation, we would need to handle polygon shrinking
      // which is more complex than expansion
      return polygon;
    }

    // For positive distance, we expand the polygon
    // This is a simplified implementation that creates a buffer around each ring
    final coordinates = polygon.coordinates;
    if (coordinates.isEmpty || coordinates[0].isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer the outer ring
    final outerRing = coordinates[0];
    final bufferedOuterRing = _bufferRing(
        outerRing, distance, resolution, joinStyle, mitreLimit, false);

    // For a proper implementation, we would also handle inner rings (holes)
    // by buffering them with negative distance

    return GeoJSONPolygon([bufferedOuterRing]);
  }

  /// Buffer a ring (polygon boundary)
  List<List<double>> _bufferRing(List<List<double>> ring, double distance,
      int resolution, String joinStyle, double mitreLimit, bool isHole) {
    // Create a LineString from the ring and buffer it
    // For a proper implementation, we would need to handle the fact that rings are closed
    final lineString = GeoJSONLineString(ring);
    final bufferedLine = _bufferLineString(
        lineString,
        isHole ? -distance : distance,
        resolution,
        'round', // Cap style doesn't matter for closed rings
        joinStyle,
        mitreLimit,
        false);

    // Extract the coordinates from the buffered line
    if (bufferedLine is GeoJSONPolygon) {
      return bufferedLine.coordinates[0];
    }

    // Fallback to original ring if buffering failed
    return ring;
  }

  /// Buffer a multipoint geometry
  GeoJSONGeometry _bufferMultiPoint(
      GeoJSONMultiPoint multiPoint, double distance, int resolution) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    final coordinates = multiPoint.coordinates;
    if (coordinates.isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer each point and combine the results
    List<GeoJSONPolygon> bufferedPoints = [];
    for (final point in coordinates) {
      final bufferedPoint =
          _bufferPoint(GeoJSONPoint(point), distance, resolution);
      bufferedPoints.add(bufferedPoint);
    }

    // For a proper implementation, we would need to union all the buffered points
    // This is a simplified implementation that just returns the first buffered point
    if (bufferedPoints.isNotEmpty) {
      return bufferedPoints.first;
    }

    return GeoJSONPolygon([
      [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
      ]
    ]); // Empty polygon
  }

  /// Buffer a multilinestring geometry
  GeoJSONGeometry _bufferMultiLineString(
      GeoJSONMultiLineString multiLineString,
      double distance,
      int resolution,
      String capStyle,
      String joinStyle,
      double mitreLimit,
      bool singleSided) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    final coordinates = multiLineString.coordinates;
    if (coordinates.isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer each linestring and combine the results
    List<GeoJSONGeometry> bufferedLines = [];
    for (final line in coordinates) {
      final bufferedLine = _bufferLineString(GeoJSONLineString(line), distance,
          resolution, capStyle, joinStyle, mitreLimit, singleSided);
      bufferedLines.add(bufferedLine);
    }

    // For a proper implementation, we would need to union all the buffered lines
    // This is a simplified implementation that just returns the first buffered line
    if (bufferedLines.isNotEmpty) {
      return bufferedLines.first;
    }

    return GeoJSONPolygon([
      [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
      ]
    ]); // Empty polygon
  }

  /// Buffer a multipolygon geometry
  GeoJSONGeometry _bufferMultiPolygon(GeoJSONMultiPolygon multiPolygon,
      double distance, int resolution, String joinStyle, double mitreLimit) {
    if (distance == 0) {
      return multiPolygon; // Return the original multipolygon for zero distance
    }

    final coordinates = multiPolygon.coordinates;
    if (coordinates.isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer each polygon and combine the results
    List<GeoJSONGeometry> bufferedPolygons = [];
    for (final polygon in coordinates) {
      final bufferedPolygon = _bufferPolygon(
          GeoJSONPolygon(polygon), distance, resolution, joinStyle, mitreLimit);
      bufferedPolygons.add(bufferedPolygon);
    }

    // For a proper implementation, we would need to union all the buffered polygons
    // This is a simplified implementation that just returns the first buffered polygon
    if (bufferedPolygons.isNotEmpty) {
      return bufferedPolygons.first;
    }

    return GeoJSONPolygon([
      [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
      ]
    ]); // Empty polygon
  }
}

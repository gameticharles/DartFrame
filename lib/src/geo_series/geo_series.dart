part of '../../dartframe.dart';

/// A GeoSeries represents a column of geometry data.
/// It extends Series with spatial functionality.
class GeoSeries extends Series {

  /// The coordinate reference system of the geometries.
  final String? crs;

  /// Creates a GeoSeries from a list of geometries.
  GeoSeries(super.values, {this.crs, super.name = 'geometry', super.index});

  /// Creates a GeoSeries from WKT strings.
  factory GeoSeries.fromWKT(List<String> wktStrings, {String? crs, String name = 'geometry', List<dynamic>? index}) {
    final geometries = wktStrings.map((wkt) => _parseWKT(wkt)).toList();
    return GeoSeries(geometries, crs: crs, name: name, index: index);
  }

  /// Creates a GeoSeries from a FeatureCollection.
  factory GeoSeries.fromFeatureCollection(
    GeoJSONFeatureCollection featureCollection, {
    String? crs,
    String name = 'geometry',
    List<dynamic>? index,
  }) {
    final geometries = featureCollection.features
        .map((feature) => feature?.geometry)
        .where((geom) => geom != null)
        .toList();
    
    return GeoSeries(geometries, crs: crs, name: name, index: index);
  }

   /// Creates a GeoSeries of Point geometries from lists of x, y(, z) coordinates.
  ///
  /// In case of geographic coordinates, it is assumed that longitude is captured 
  /// by x coordinates and latitude by y.
  ///
  /// Parameters:
  ///   x: List of x coordinates (eg. longitude for geographic coordinates)
  ///   y: List of y coordinates (eg. latitude for geographic coordinates)
  ///   z: Optional list of z coordinates for 3D points
  ///   index: Optional list to use as index for the GeoSeries
  ///   crs: Coordinate Reference System of the geometry objects
  ///   name: Name for the GeoSeries
  ///
  /// Returns:
  ///   A GeoSeries of Point geometries
  ///
  /// Example:
  /// ```dart
  /// final x = [2.5, 5, -3.0];
  /// final y = [0.5, 1, 1.5];
  /// final points = GeoSeries.fromXY(x, y, crs: "EPSG:4326");
  /// ```
  factory GeoSeries.fromXY(
    List<num> x, 
    List<num> y, {
    List<num>? z,
    List<dynamic>? index,
    String? crs,
    String name = 'geometry'
  }) {
    // Validate input
    if (x.length != y.length) {
      throw ArgumentError('x and y must have the same length');
    }
    
    if (z != null && z.length != x.length) {
      throw ArgumentError('z must have the same length as x and y');
    }
    
    // Create point geometries
    final List<GeoJSONGeometry> points = [];
    
    for (int i = 0; i < x.length; i++) {
      if (z != null) {
        // Create 3D point
        points.add(GeoJSONPoint([x[i].toDouble(), y[i].toDouble(), z[i].toDouble()]));
      } else {
        // Create 2D point
        points.add(GeoJSONPoint([x[i].toDouble(), y[i].toDouble()]));
      }
    }
    
    // Create GeoSeries with optional index
    final geoSeries = GeoSeries(points, crs: crs, name: name);
    
    // Set index if provided
    if (index != null) {
      if (index.length != x.length) {
        throw ArgumentError('index must have the same length as coordinate lists');
      }
      geoSeries.index = index;
    }
    
    return geoSeries;
  }

  /// Extracts the geometries as a list.
  ///
  /// [asGeoJSON]: If true, returns geometries as GeoJSON objects.
  /// If false, returns geometries as coordinate lists.
  List<dynamic> geometries({bool asGeoJSON = false}) {
    List<dynamic> result = [];
    
    for (GeoJSONGeometry? feature in data) {
      if (feature != null) {
        if (asGeoJSON) {
          result.add(feature);
        } else {
          // Extract coordinates based on geometry type
          if (feature is GeoJSONPoint) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONLineString) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONPolygon) {
            result.add(feature.coordinates);
          } else {
            // Default empty coordinates for unsupported geometry types
            result.add([]);
          }
        }
      }
    }
    
    return result;
  }

  /// Converts geometries to WKT strings.
  Series toWkt() {
    final wktStrings = data.map((geom) {
      if (geom is GeoJSONGeometry) {
        return geom.toWkt();
      }
      return 'POINT(0 0)';
    }).toList();
    
    return Series(wktStrings, name: '${name}_wkt', index: index);
  }

  /// Converts the GeoSeries to a Series of WKT strings.
  Series asWkt() {
    return toWkt();
  }

  /// Creates a new GeoSeries from this one, ensuring all geometries are valid.
  /// Invalid geometries are replaced with default points.
  GeoSeries makeValid() {
    final validGeometries = data.map((geom) {
      if (geom is GeoJSONGeometry) {
        if (geom is GeoJSONPolygon && !_isValidPolygon(geom.coordinates)) {
          return GeoJSONPoint([0, 0]); // Replace with default point
        } else if (geom is GeoJSONMultiPolygon && 
                  !geom.coordinates.every((polygon) => _isValidPolygon(polygon))) {
          return GeoJSONPoint([0, 0]); // Replace with default point
        }
        return geom;
      }
      return GeoJSONPoint([0, 0]); // Default
    }).toList();
    
    return GeoSeries(validGeometries, crs: crs, name: name, index: index);
  }

}

part of '../../dartframe.dart';

/// The `GeoDataFrame` class for handling geospatial data in various formats.
///
/// This class extends the functionality of DataFrame by adding support for
/// geometric data. It maintains a geometry column alongside attribute data,
/// similar to GeoPandas in Python.
///
/// Example:
/// ```dart
///   // Future<void> main(List<String> args) async {
///   // Read file
///   final geoDataFrame = await GeoDataFrame.readFile(
///     'example/GH.txt',
///     delimiter: '\t',
///     hasHeader: false,
///     coordinatesColumns: {
///       'latitude': 4,
///       'longitude': 5
///     }, // Specify column names and indices
///   );
///
///   // Get row count
///   print(geoDataFrame.featureCount);
///
///   // Delete a feature
///   geoDataFrame.deleteFeature(0);
///
///   // Access the attribute table as DataFrame
///   print(geoDataFrame.attributes);
///
///   // Use DataFrame operations on attributes
///   print(geoDataFrame.attributes.describe());
///   
///   // Add a new column to all features
///   geoDataFrame.attributes['newProperty'] = List.filled(geoDataFrame.featureCount, 'defaultValue');
///
///   // Delete a column from all features
///   geoDataFrame.attributes.drop('newProperty');
///
///   // Update a specific value
///   geoDataFrame.attributes['altitude'][1] = 230.45;
///
///   // Get a specific feature
///   var feature = geoDataFrame.getFeature(1);
///   print(feature);
///
///   // Find features based on a query
///   var foundFeatures = geoDataFrame
///       .findFeatures((feature) => 
///           feature.properties!['latitude'] > 6.5 && 
///           feature.properties!['longitude'] < 0.5);
///   print(foundFeatures.length);
///
///   // Export data to GeoJSON
///   await geoDataFrame.toFile('example/output.geojson');
/// }
///```
class GeoDataFrame {
  /// The GeoJSON FeatureCollection that stores all the geospatial data.
  final GeoJSONFeatureCollection featureCollection;

  /// The headers for the data columns (property names).
  List headers = [];

  /// The DataFrame that stores the attribute data.
  late DataFrame _attributes;

  /// The name of the geometry column.
  final String geometryColumn;

  /// The coordinate reference system (CRS) of the geometry data.
  final String? crs;

  // Private constructor for internal use.
  GeoDataFrame(
    this.featureCollection, 
    List<dynamic> headers, 
    {this.geometryColumn = 'geometry', 
    this.crs,
    }
  ) {

    // Initialize attributes with spatial properties in a single pass
    _initializeAttributesWithSpatial(headers);
  }

  /// Gets the number of features in the data.
  int get featureCount => featureCollection.features.length;

  /// Gets the number of properties in the data.
  int get propertyCount => headers.length;

    /// Gets the attribute DataFrame.
  DataFrame get attributes => _attributes;

  /// Gets the total bounds of all geometries in the GeoDataFrame.
  /// Returns [minX, minY, maxX, maxY] for the entire collection.
  List<double> get totalBounds {
    if (featureCollection.features.isEmpty) {
      return [0, 0, 0, 0];
    }
    
    // Start with the first feature's bounds
    List<double> totalBounds = featureCollection.features[0]!.bbox!;
    
    // Update with remaining features
    for (int i = 1; i < featureCollection.features.length; i++) {
      var feature = featureCollection.features[i];
      if (feature != null) {
        List<double> featureBounds = feature.bbox!;
        
        // Update min/max values
        totalBounds[0] = min(totalBounds[0], featureBounds[0]); // minX
        totalBounds[1] = min(totalBounds[1], featureBounds[1]); // minY
        totalBounds[2] = max(totalBounds[2], featureBounds[2]); // maxX
        totalBounds[3] = max(totalBounds[3], featureBounds[3]); // maxY
      }
    }
    
    return totalBounds;
  }
  
    /// Returns a GeoDataFrame containing the centroids of all geometries.
  GeoDataFrame get centroid {
    final centroidCollection = GeoJSONFeatureCollection([]);
    
    for (var feature in featureCollection.features) {
      if (feature != null) {
        // Calculate centroid
        final centroidCoords = [0.0,0.0];//feature.geometry?.centroid ?? [0,0];
        final centroidGeom = GeoJSONPoint(centroidCoords);
        
        // Create a new feature with the centroid geometry and original properties
        final centroidFeature = GeoJSONFeature(
          centroidGeom,
          properties: Map<String, dynamic>.from(feature.properties ?? {}),
        );
        
        centroidCollection.features.add(centroidFeature);
      }
    }
    
    // Create a new GeoDataFrame with the centroids
    return GeoDataFrame(
      centroidCollection,
      headers.toList(),
      geometryColumn: geometryColumn,
      crs: crs,
    );
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
      for (int i = 0; i < ring.length - 1; i++) { // Skip last point (duplicate of first)
        String pointKey = '${ring[i][0]},${ring[i][1]}';
        if (pointSet.contains(pointKey)) {
          return false; // Duplicate point found
        }
        pointSet.add(pointKey);
      }
    }
    
    return true;
  }

/// Initializes the attributes DataFrame including spatial properties in a single pass.
  void _initializeAttributesWithSpatial(List<dynamic> headers) {
    // Store the current headers to ensure we don't lose any
    this.headers = headers.toList();
    
    // Add spatial property headers if not already present
    if (!this.headers.contains('geometry')) this.headers.add('geometry');
    if (!this.headers.contains('area')) this.headers.add('area');
    if (!this.headers.contains('geom_type')) this.headers.add('geom_type');
    if (!this.headers.contains('is_valid')) this.headers.add('is_valid');
    if (!this.headers.contains('bounds')) this.headers.add('bounds');
    
    
    // Extract attribute data from features
    List<List<dynamic>> data = [];
    List<String> rowHeaders = [];
    
    for (int i = 0; i < featureCollection.features.length; i++) {
      var feature = featureCollection.features[i];
      if (feature != null) {
        // Create a row for each feature
        List<dynamic> row = [];
        
        // Add regular properties
        for (var header in headers) {
          row.add(feature.properties?[header]);
        }
        
        // Calculate and add spatial properties

        // 0. Geometry as WKT string
        row.add(feature.geometry!.toWkt());
        
        // 1. Area
        double featureArea = 0.0;
        if (feature.geometry is GeoJSONPolygon) {
          featureArea = (feature.geometry as GeoJSONPolygon).area;
        } else if (feature.geometry is GeoJSONMultiPolygon) {
          featureArea = (feature.geometry as GeoJSONMultiPolygon).area;
        }
        row.add(featureArea);
        
        // 2. Geometry type
        String geomType = 'Unknown';
        if (feature.geometry is GeoJSONPoint) {
          geomType = 'Point';
        } else if (feature.geometry is GeoJSONMultiPoint) {
          geomType = 'MultiPoint';
        } else if (feature.geometry is GeoJSONLineString) {
          geomType = 'LineString';
        } else if (feature.geometry is GeoJSONMultiLineString) {
          geomType = 'MultiLineString';
        } else if (feature.geometry is GeoJSONPolygon) {
          geomType = 'Polygon';
        } else if (feature.geometry is GeoJSONMultiPolygon) {
          geomType = 'MultiPolygon';
        }
        row.add(geomType);
        
        // 3. Validity
        bool isValid = true;
        if (feature.geometry is GeoJSONPolygon) {
          isValid = _isValidPolygon((feature.geometry as GeoJSONPolygon).coordinates);
        } else if (feature.geometry is GeoJSONMultiPolygon) {
          isValid = (feature.geometry as GeoJSONMultiPolygon).coordinates
              .every((polygon) => _isValidPolygon(polygon));
        }
        row.add(isValid);
        
        // 4. Bounds
        List<double> bounds = feature.bbox ?? [0, 0, 0, 0];
        row.add(bounds);


        
        data.add(row);
        rowHeaders.add(i.toString()); // Use feature index as row header
      }
    }
    
    // Create the DataFrame
    _attributes = DataFrame(
      columns: this.headers,
      data: data,
      rowHeader: rowHeaders,
    );
  }

  /// A constant map linking file extensions to their respective drivers.
  static const Map<String, String> _extensionToDriver = {
    ".csv": "CSV",
    ".txt": "TXT",
    ".json": "GeoJSON",
    ".geojson": "GeoJSON",
    ".geojsonl": "GeoJSONSeq",
    ".geojsons": "GeoJSONSeq",
    ".bna": "BNA",
    ".dxf": "DXF",
    ".shp": "ESRI Shapefile",
    ".dbf": "ESRI Shapefile",
    ".gpkg": "GPKG",
    ".gml": "GML",
    ".xml": "GML",
    ".kml": "KML",
    ".gpx": "GPX",
    ".gtm": "GPSTrackMaker",
    ".gtz": "GPSTrackMaker",
    ".tab": "MapInfo File",
    ".mif": "MapInfo File",
    ".mid": "MapInfo File",
    ".dgn": "DGN",
    ".fgb": "FlatGeobuf",
  };

  /// Determines the appropriate driver for a given file extension.
  ///
  /// Returns the driver as a string. If no matching driver is found, returns 'Unknown'.
  static String _getDriverForExtension(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    return _extensionToDriver[".$extension"] ?? 'Unknown';
  }

  /// Creates a GeoDataFrame from a DataFrame and a geometry column.
  ///
  /// [dataFrame]: The DataFrame containing attribute data.
  /// [geometryColumn]: The name of the column containing geometry data.
  /// [geometryType]: The type of geometry ('point', 'linestring', 'polygon').
  /// [coordinateType]: The type of coordinates ('xy', 'lonlat').
  ///
  /// Returns a new GeoDataFrame.
  static GeoDataFrame fromDataFrame(
    DataFrame dataFrame, {
    required String geometryColumn,
    String geometryType = 'point',
    String coordinateType = 'lonlat',
    String? crs,
  }) {
    // Create a feature collection
    final featureCollection = GeoJSONFeatureCollection([]);
    
    // Get column indices
    int geometryColumnIndex = dataFrame.columns.indexOf(geometryColumn);
    if (geometryColumnIndex == -1) {
      throw ArgumentError('Geometry column $geometryColumn not found in DataFrame');
    }
    
    // Create headers excluding the geometry column
    List<String> headers = dataFrame.columns
        .where((c) => c.toString() != geometryColumn)
        .map((c) => c.toString())
        .toList();
    
    // Create a feature for each row in the DataFrame
    for (int i = 0; i < dataFrame.rows.length; i++) {
      final row = dataFrame.rows[i];
      
      // Extract geometry
      final geometryData = row[geometryColumnIndex];
      GeoJSONGeometry? geometry;
      
      if (geometryType == 'point') {
        if (geometryData is List && geometryData.length >= 2) {
          // Direct coordinate list
          List<double> coords = [];
          for (var coord in geometryData) {
            coords.add(coord is num ? coord.toDouble() : 0.0);
          }
          geometry = GeoJSONPoint(coords);
        } else if (geometryData is Map) {
          // Map with x/y or lon/lat keys
          double? x, y;
          
          if (coordinateType == 'lonlat') {
            x = geometryData['longitude'] is num ? 
                geometryData['longitude'].toDouble() : 
                (geometryData['lon'] is num ? geometryData['lon'].toDouble() : null);
            
            y = geometryData['latitude'] is num ? 
                geometryData['latitude'].toDouble() : 
                (geometryData['lat'] is num ? geometryData['lat'].toDouble() : null);
          } else { // xy
            x = geometryData['x'] is num ? geometryData['x'].toDouble() : null;
            y = geometryData['y'] is num ? geometryData['y'].toDouble() : null;
          }
          
          if (x != null && y != null) {
            geometry = GeoJSONPoint([x, y]);
          }
        } else if (geometryData is String) {
          // Try to parse WKT or GeoJSON string
          try {
            // Simple WKT point parsing (POINT(x y))
            final match = RegExp(r'POINT\s*\(\s*([0-9.-]+)\s+([0-9.-]+)\s*\)')
                .firstMatch(geometryData);
            if (match != null) {
              double x = double.parse(match.group(1)!);
              double y = double.parse(match.group(2)!);
              geometry = GeoJSONPoint([x, y]);
            } else {
              // Try as GeoJSON
              final geoJson = GeoJSON.fromJSON(geometryData);
              if (geoJson is GeoJSONGeometry) {
                geometry = geoJson;
              }
            }
          } catch (e) {
            // Parsing failed, will use default geometry
          }
        }
      } else if (geometryType == 'linestring') {
        // Handle linestring geometry
        if (geometryData is List && geometryData.isNotEmpty && geometryData[0] is List) {
          List<List<double>> coords = [];
          for (var point in geometryData) {
            if (point is List && point.length >= 2) {
              coords.add([
                point[0] is num ? point[0].toDouble() : 0.0,
                point[1] is num ? point[1].toDouble() : 0.0
              ]);
            }
          }
          if (coords.isNotEmpty) {
            geometry = GeoJSONLineString(coords);
          }
        }
      } else if (geometryType == 'polygon') {
        // Handle polygon geometry
        if (geometryData is List && geometryData.isNotEmpty && geometryData[0] is List) {
          List<List<List<double>>> coords = [];
          List<List<double>> ring = [];
          
          for (var point in geometryData) {
            if (point is List && point.length >= 2) {
              ring.add([
                point[0] is num ? point[0].toDouble() : 0.0,
                point[1] is num ? point[1].toDouble() : 0.0
              ]);
            }
          }
          
          if (ring.isNotEmpty) {
            // Ensure the ring is closed
            if (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1]) {
              ring.add([ring.first[0], ring.first[1]]);
            }
            coords.add(ring);
            geometry = GeoJSONPolygon(coords);
          }
        }
      }
      
      // Use default point geometry if extraction failed
      geometry ??= GeoJSONPoint([0, 0]);
      
      // Create properties from other columns
      final properties = <String, dynamic>{};
      for (int j = 0; j < dataFrame.columns.length; j++) {
        if (j != geometryColumnIndex) {
          properties[dataFrame.columns[j].toString()] = row[j];
        }
      }
      
      // Create feature
      final feature = GeoJSONFeature(geometry, properties: properties);
      featureCollection.features.add(feature);
    }
    
    return GeoDataFrame(featureCollection, headers);
  }

  /// Creates a GeoDataFrame from a list of coordinates.
  ///
  /// [coordinates]: A list of coordinate pairs (can be [x,y], [lon,lat], etc.)
  /// [attributes]: Optional DataFrame containing attribute data.
  /// [coordinateType]: The type of coordinates ('xy', 'lonlat', etc.)
  /// [crs]: The coordinate reference system.
  ///
  /// Returns a new GeoDataFrame with Point geometries.
  static GeoDataFrame fromCoordinates(
    List<List<double>> coordinates, {
    DataFrame? attributes,
    String coordinateType = 'xy',
    String? crs,
  }) {
    // Create a feature collection
    final featureCollection = GeoJSONFeatureCollection([]);
    
    // Create a feature for each coordinate pair
    for (int i = 0; i < coordinates.length; i++) {
      final coord = coordinates[i];
      if (coord.length < 2) {
        throw ArgumentError('Each coordinate must have at least 2 values (x,y or lon,lat)');
      }
      
      // Create point geometry
      final point = GeoJSONPoint(coord);
      
      // Create properties from attributes if provided
      Map<String, dynamic>? properties;
      if (attributes != null && i < attributes.rows.length) {
        properties = {};
        for (int j = 0; j < attributes.columns.length; j++) {
          properties[attributes.columns[j].toString()] = attributes.rows[i][j];
        }
      }
      
      // Create feature
      final feature = GeoJSONFeature(point, properties: properties);
      featureCollection.features.add(feature);
    }
    
    // Determine headers from attributes or create default
    List<String> headers = [];
    if (attributes != null) {
      headers = attributes.columns.map((c) => c.toString()).toList();
    }
    
    return GeoDataFrame(
      featureCollection, 
      headers,
      geometryColumn: 'geometry',
      crs: crs,
    );
  }

  /// Extracts the geometries as a list.
  ///
  /// [asGeoJSON]: If true, returns geometries as GeoJSON objects.
  /// If false, returns geometries as coordinate lists.
  List<dynamic> geometries({bool asGeoJSON = false}) {
    List<dynamic> result = [];
    
    for (var feature in featureCollection.features) {
      if (feature != null) {
        if (asGeoJSON) {
          result.add(feature.geometry);
        } else {
          // Extract coordinates based on geometry type
          if (feature.geometry is GeoJSONPoint) {
            result.add((feature.geometry as GeoJSONPoint).coordinates);
          } else if (feature.geometry is GeoJSONLineString) {
            result.add((feature.geometry as GeoJSONLineString).coordinates);
          } else if (feature.geometry is GeoJSONPolygon) {
            result.add((feature.geometry as GeoJSONPolygon).coordinates);
          } else {
            // Default empty coordinates for unsupported geometry types
            result.add([]);
          }
        }
      }
    }
    
    return result;
  }

  /// Reads spatial data from a file, automatically determining the driver.
  ///
  /// [filePath]: The path of the file to read.
  /// [driver]: The type of driver to use. Defaults to 'Auto', which automatically determines the driver.
  /// Other parameters as per your existing implementation.
  ///
  /// Returns a `Future<GeoDataFrame>` representing the read data.
  static Future<GeoDataFrame> readFile(
    String filePath, {
    String driver = 'Auto',
    String delimiter = ',',
    bool hasHeader = true,
    String eol = '\r\n',
    String textDelimiter = '"',
    bool delimitAllFields = false,
    Map<String, int>? coordinatesColumns,
    String coordinateType = 'lonlat',
    String? crs,
  }) async {
    if (driver == 'Auto') {
      driver = _getDriverForExtension(filePath);
    }

    FileIO fileIO = FileIO();
    Stream<String> lines;

    if (filePath.isNotEmpty) {
      // Read file
      lines = fileIO.readFileAsStream(filePath);
    } else {
      throw ArgumentError('Either inputFilePath must be provided.');
    }

    // Create a new FeatureCollection to store the data
    final featureCollection = GeoJSONFeatureCollection([]);
    List<String> headers = [];

    switch (driver) {
      case 'TXT':
      case 'CSV':
        await for (String line in lines) {
          if (headers.isEmpty && hasHeader) {
            headers = line.split(delimiter).map((e) => e.trim()).toList();
            continue;
          }

          final values = line.split(delimiter).map((e) => e.trim()).toList();
          
          // Generate headers if not provided
          if (headers.isEmpty) {
            headers = List.generate(values.length, (i) => i.toString());
          }

          // Create properties map
          final properties = <String, dynamic>{};
          for (var i = 0; i < values.length; i++) {
            if (i < headers.length) {
              // Try to parse numeric values
              var value = values[i];
              var numValue = double.tryParse(value);
              properties[headers[i]] = numValue ?? value;
            }
          }

          // Extract coordinates if specified
          List<double>? coordinates;
          if (coordinatesColumns != null) {
            coordinates = [];
            
            // Support for different coordinate types
            if (coordinateType == 'lonlat' || coordinateType == 'xy') {
              // For lon/lat or x/y coordinates
              double? x, y;
              
              if (coordinateType == 'lonlat') {
                if (coordinatesColumns.containsKey('longitude') && 
                    coordinatesColumns['longitude']! < values.length) {
                  x = double.tryParse(values[coordinatesColumns['longitude']!]);
                }
                
                if (coordinatesColumns.containsKey('latitude') && 
                    coordinatesColumns['latitude']! < values.length) {
                  y = double.tryParse(values[coordinatesColumns['latitude']!]);
                }
              } else { // xy
                if (coordinatesColumns.containsKey('x') && 
                    coordinatesColumns['x']! < values.length) {
                  x = double.tryParse(values[coordinatesColumns['x']!]);
                }
                
                if (coordinatesColumns.containsKey('y') && 
                    coordinatesColumns['y']! < values.length) {
                  y = double.tryParse(values[coordinatesColumns['y']!]);
                }
              }
              
              if (x != null && y != null) {
                coordinates = [x, y];
              }
            } else if (coordinateType == 'xyz' || coordinateType == 'lonlatz') {
              // For 3D coordinates
              double? x, y, z;
              
              if (coordinateType == 'lonlatz') {
                if (coordinatesColumns.containsKey('longitude') && 
                    coordinatesColumns['longitude']! < values.length) {
                  x = double.tryParse(values[coordinatesColumns['longitude']!]);
                }
                
                if (coordinatesColumns.containsKey('latitude') && 
                    coordinatesColumns['latitude']! < values.length) {
                  y = double.tryParse(values[coordinatesColumns['latitude']!]);
                }
                
                if (coordinatesColumns.containsKey('altitude') && 
                    coordinatesColumns['altitude']! < values.length) {
                  z = double.tryParse(values[coordinatesColumns['altitude']!]);
                }
              } else { // xyz
                if (coordinatesColumns.containsKey('x') && 
                    coordinatesColumns['x']! < values.length) {
                  x = double.tryParse(values[coordinatesColumns['x']!]);
                }
                
                if (coordinatesColumns.containsKey('y') && 
                    coordinatesColumns['y']! < values.length) {
                  y = double.tryParse(values[coordinatesColumns['y']!]);
                }
                
                if (coordinatesColumns.containsKey('z') && 
                    coordinatesColumns['z']! < values.length) {
                  z = double.tryParse(values[coordinatesColumns['z']!]);
                }
              }
              
              if (x != null && y != null) {
                coordinates = [x, y];
                if (z != null) {
                  coordinates.add(z);
                }
              }
            }
          }

          // Create a Point geometry if coordinates are available
          if (coordinates != null && coordinates.length >= 2) {
            final point = GeoJSONPoint(coordinates);
            final feature = GeoJSONFeature(point, properties: properties);
            featureCollection.features.add(feature);
          } else {
            // Create a feature without geometry if coordinates are not available
            final feature = GeoJSONFeature(
              GeoJSONPoint([0, 0]), // Default point
              properties: properties
            );
            featureCollection.features.add(feature);
          }
        }
        return GeoDataFrame(featureCollection, headers, crs: crs);

      case 'ESRI Shapefile':
        // Read Shapefile - to be implemented
        // For now, return empty GeoDataFrame
        return GeoDataFrame(featureCollection, []);

      case 'GeoJSON':
        // Read GeoJSON file
        final buffer = StringBuffer();
        await for (String line in lines) {
          buffer.write(line);
        }
        
        final jsonString = buffer.toString();
        final geoJson = GeoJSON.fromJSON(jsonString);
        
        if (geoJson is GeoJSONFeatureCollection) {
          // Extract headers from the first feature's properties
          if (geoJson.features.isNotEmpty && geoJson.features[0]?.properties != null) {
            headers = geoJson.features[0]!.properties!.keys.toList();
          }
          return GeoDataFrame(geoJson, headers);
        } else if (geoJson is GeoJSONFeature) {
          // Create a feature collection with a single feature
          final collection = GeoJSONFeatureCollection([]);
          collection.features.add(geoJson);
          
          // Extract headers from the feature's properties
          if (geoJson.properties != null) {
            headers = geoJson.properties!.keys.toList();
          }
          return GeoDataFrame(collection, headers);
        } else if (geoJson is GeoJSONGeometry) {
          // Create a feature with the geometry
          final feature = GeoJSONFeature(geoJson);
          final collection = GeoJSONFeatureCollection([]);
          collection.features.add(feature);
          return GeoDataFrame(collection, []);
        }
        break;

      case 'GPX':
        var geoXml = await GeoXml.fromGpxStream(lines);
        // Convert GPX to GeoJSON FeatureCollection
        final collection = GeoJSONFeatureCollection([]);
        
        // Process waypoints
        for (var wpt in geoXml.wpts) {
          final point = GeoJSONPoint([wpt.lon??0, wpt.lat??0]);
          final properties = <String, dynamic>{
            'name': wpt.name,
            'description': wpt.desc,
            'elevation': wpt.ele,
            'time': wpt.time?.toIso8601String(),
          };
          
          // Remove null values
          properties.removeWhere((key, value) => value == null);
          
          final feature = GeoJSONFeature(point, properties: properties);
          collection.features.add(feature);
        }
        
        // Process tracks
        for (var trk in geoXml.trks) {
          for (var seg in trk.trksegs) {
            final coordinates = <List<double>>[];
            for (var pt in seg.trkpts) {
              coordinates.add([pt.lon??0, pt.lat??0]);
            }
            
            if (coordinates.isNotEmpty) {
              final lineString = GeoJSONLineString(coordinates);
              final properties = <String, dynamic>{
                'name': trk.name,
                'description': trk.desc,
              };
              
              // Remove null values
              properties.removeWhere((key, value) => value == null);
              
              final feature = GeoJSONFeature(lineString, properties: properties);
              collection.features.add(feature);
            }
          }
        }
        
        // Process routes
        for (var rte in geoXml.rtes) {
          final coordinates = <List<double>>[];
          for (var pt in rte.rtepts) {
            coordinates.add([pt.lon??0, pt.lat??0]);
          }
          
          if (coordinates.isNotEmpty) {
            final lineString = GeoJSONLineString(coordinates);
            final properties = <String, dynamic>{
              'name': rte.name,
              'description': rte.desc,
            };
            
            // Remove null values
            properties.removeWhere((key, value) => value == null);
            
            final feature = GeoJSONFeature(lineString, properties: properties);
            collection.features.add(feature);
          }
        }
        
        // Extract headers from the first feature's properties if available
        if (collection.features.isNotEmpty && collection.features[0]?.properties != null) {
          headers = collection.features[0]!.properties!.keys.toList();
        }
        
        return GeoDataFrame(collection, headers);

      case 'GML':
      case 'KML':
        var geoXml = await GeoXml.fromKmlStream(lines);
        // Convert KML to GeoJSON FeatureCollection - similar to GPX conversion
        // This is a simplified implementation
        final collection = GeoJSONFeatureCollection([]);
        
        // Process placemarks (similar to waypoints in GPX)
        for (var placemark in geoXml.wpts) {
          final point = GeoJSONPoint([placemark.lon??0, placemark.lat??0]);
          final properties = <String, dynamic>{
            'name': placemark.name,
            'description': placemark.desc,
            'elevation': placemark.ele,
          };
          
          // Remove null values
          properties.removeWhere((key, value) => value == null);
          
          final feature = GeoJSONFeature(point, properties: properties);
          collection.features.add(feature);
        }
        
        // Extract headers from the first feature's properties if available
        if (collection.features.isNotEmpty && collection.features[0]?.properties != null) {
          headers = collection.features[0]!.properties!.keys.toList();
        }
        
        return GeoDataFrame(collection, headers);

      default:
        return GeoDataFrame(featureCollection, []); // Return empty GeoDataFrame
    }

    return GeoDataFrame(featureCollection, []); // Default return
  }

  /// Exports the data to different file formats, automatically determining the driver.
  ///
  /// [filePath]: The path of the file to write to.
  /// Other parameters as per your existing implementation.
  ///
  /// Returns a `Future<void>` indicating the completion of the file writing process.
  Future<void> toFile(
    String filePath, {
    String driver = 'Auto',
    String delimiter = ',',
    bool includeHeader = true,
    String defaultEol = '\r\n',
    String defaultTextDelimiter = '"',
    bool defaultDelimitAllFields = false,
  }) async {
    if (driver == 'Auto') {
      driver = _getDriverForExtension(filePath);
    }

    FileIO fileIO = FileIO();

    switch (driver) {
      case 'TXT':
      case 'CSV':
        final buffer = StringBuffer();
        
        // Write header
        if (includeHeader && headers.isNotEmpty) {
          buffer.writeln(headers.join(delimiter));
        }

        // Write data rows
        for (var feature in featureCollection.features) {
          if (feature?.properties != null) {
            final rowValues = headers.map((h) => 
                feature!.properties![h]?.toString() ?? '').toList();
            buffer.writeln(rowValues.join(delimiter));
          }
        }

        fileIO.saveToFile(filePath, buffer.toString());
        break;

      case 'GeoJSON':
        // Export to GeoJSON
        final jsonString = featureCollection.toJSON(indent: 2);
        fileIO.saveToFile(filePath, jsonString);
        break;

      case 'ESRI Shapefile':
        // Export to Shapefile - to be implemented
        throw UnimplementedError('Shapefile export is not yet implemented');

      case 'GPX':
        // Convert GeoJSON to GPX
        var gpx = GeoXml();
        gpx.creator = "GeoEngine library";
        
        // Process Point features as waypoints
        for (var feature in featureCollection.features) {
          if (feature != null && feature.geometry is GeoJSONPoint) {
            final point = feature.geometry as GeoJSONPoint;
            final coords = point.coordinates;
            
            if (coords.length >= 2) {
              final wpt = Wpt(
                lat: coords[1],
                lon: coords[0],
                ele: feature.properties?['elevation'] ?? 0.0,
                name: feature.properties?['name'] ?? '',
                desc: feature.properties?['description'] ?? '',
              );
              gpx.wpts.add(wpt);
            }
          }
        }
        
        // Process LineString features as tracks
        for (var feature in featureCollection.features) {
          if (feature != null && feature.geometry is GeoJSONLineString) {
            final lineString = feature.geometry as GeoJSONLineString;
            final coords = lineString.coordinates;
            
            final trk = Trk();
            trk.name = feature.properties?['name'] ?? '';
            trk.desc = feature.properties?['description'] ?? '';
            
            final trkSeg = Trkseg();
            for (var coord in coords) {
              if (coord.length >= 2) {
                final trkpt = Wpt(
                  lat: coord[1],
                  lon: coord[0],
                  ele: feature.properties?['elevation'] ?? 0.0,
                );
                trkSeg.trkpts.add(trkpt);
              }
            }
            
            trk.trksegs.add(trkSeg);
            gpx.trks.add(trk);
          }
        }
        
        // Generate GPX string and save to file
        final gpxString = gpx.toGpxString(pretty: true);
        fileIO.saveToFile(filePath, gpxString);
        break;

      case 'KML':
        // Convert GeoJSON to KML
        var geoXml = GeoXml();
        geoXml.creator = "GeoEngine library";
        
        // Process Point features as placemarks
        for (var feature in featureCollection.features) {
          if (feature != null && feature.geometry is GeoJSONPoint) {
            final point = feature.geometry as GeoJSONPoint;
            final coords = point.coordinates;
            
            if (coords.length >= 2) {
              final wpt = Wpt(
                lat: coords[1],
                lon: coords[0],
                ele: feature.properties?['elevation'] ?? 0.0,
                name: feature.properties?['name'] ?? '',
                desc: feature.properties?['description'] ?? '',
              );
              geoXml.wpts.add(wpt);
            }
          }
        }
        
        // Generate KML string and save to file
        final kmlString = geoXml.toKmlString(
            pretty: true, altitudeMode: AltitudeMode.clampToGround);
        fileIO.saveToFile(filePath, kmlString);
        break;

      default:
        throw UnsupportedError('Unsupported file format: $driver');
    }
  }


  /// Creates a GeoDataFrame instance from a list of maps (rows) for backward compatibility.
  static GeoDataFrame fromRows(List<Map<String, dynamic>> rows, {List<String>? headers}) {
    final featureCollection = GeoJSONFeatureCollection([]);
    final allHeaders = headers ?? 
        (rows.isNotEmpty ? rows.first.keys.toList() : []);
    
    for (var row in rows) {
      // Extract coordinates if available
      double? lat, lon;
      if (row.containsKey('latitude')) {
        lat = row['latitude'] is double 
            ? row['latitude'] 
            : double.tryParse(row['latitude'].toString());
      }
      
      if (row.containsKey('longitude')) {
        lon = row['longitude'] is double 
            ? row['longitude'] 
            : double.tryParse(row['longitude'].toString());
      }
      
      // Create geometry
      GeoJSONGeometry geometry;
      if (lat != null && lon != null) {
        geometry = GeoJSONPoint([lon, lat]);
      } else {
        // Default point at 0,0 if no coordinates
        geometry = GeoJSONPoint([0, 0]);
      }
      
      // Create properties (excluding lat/lon)
      final properties = <String, dynamic>{};
      for (var key in row.keys) {
        if (key != 'latitude' && key != 'longitude') {
          properties[key] = row[key];
        }
      }
      
      // Create feature
      final feature = GeoJSONFeature(geometry, properties: properties);
      featureCollection.features.add(feature);
    }
    
    return GeoDataFrame(featureCollection, allHeaders);
  }
}
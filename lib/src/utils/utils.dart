part of '../../dartframe.dart';
  /// Parses a WKT string into a GeoJSON geometry.
  ///
  /// This is a simplified parser that handles basic WKT formats.
  /// For production use, consider using a more robust WKT parser.
  GeoJSONGeometry _parseWKT(String wkt) {
    wkt = wkt.trim();
    
    // Parse POINT
    if (wkt.startsWith('POINT')) {
      final coordsMatch = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)')
          .firstMatch(wkt);
      if (coordsMatch != null) {
        double x = double.parse(coordsMatch.group(1)!);
        double y = double.parse(coordsMatch.group(2)!);
        return GeoJSONPoint([x, y]);
      }
    }
    
    // Parse LINESTRING
    else if (wkt.startsWith('LINESTRING')) {
      final coordsString = wkt.substring(wkt.indexOf('(') + 1, wkt.lastIndexOf(')'));
      final coordPairs = coordsString.split(',');
      List<List<double>> coordinates = [];
      
      for (var pair in coordPairs) {
        final coords = pair.trim().split(RegExp(r'\s+'));
        if (coords.length >= 2) {
          coordinates.add([
            double.parse(coords[0]),
            double.parse(coords[1])
          ]);
        }
      }
      
      if (coordinates.isNotEmpty) {
        return GeoJSONLineString(coordinates);
      }
    }
    
    // Parse POLYGON
    else if (wkt.startsWith('POLYGON')) {
      final ringsString = wkt.substring(wkt.indexOf('(') + 1, wkt.lastIndexOf(')'));
      List<List<List<double>>> rings = [];
      
      // Split into rings (outer and inner)
      final ringStrings = _splitRings(ringsString);
      
      for (var ringString in ringStrings) {
        final coordPairs = ringString.split(',');
        List<List<double>> ring = [];
        
        for (var pair in coordPairs) {
          final coords = pair.trim().split(RegExp(r'\s+'));
          if (coords.length >= 2) {
            ring.add([
              double.parse(coords[0]),
              double.parse(coords[1])
            ]);
          }
        }
        
        if (ring.isNotEmpty) {
          rings.add(ring);
        }
      }
      
      if (rings.isNotEmpty) {
        return GeoJSONPolygon(rings);
      }
    }
    
    // Parse MULTIPOINT
    else if (wkt.startsWith('MULTIPOINT')) {
      final coordsString = wkt.substring(wkt.indexOf('(') + 1, wkt.lastIndexOf(')'));
      final coordPairs = coordsString.split(',');
      List<List<double>> coordinates = [];
      
      for (var pair in coordPairs) {
        // Remove any additional parentheses
        pair = pair.replaceAll(RegExp(r'[()]'), '').trim();
        final coords = pair.trim().split(RegExp(r'\s+'));
        if (coords.length >= 2) {
          coordinates.add([
            double.parse(coords[0]),
            double.parse(coords[1])
          ]);
        }
      }
      
      if (coordinates.isNotEmpty) {
        return GeoJSONMultiPoint(coordinates);
      }
    }
    
    // Default to a point at 0,0 if parsing fails
    return GeoJSONPoint([0, 0]);
  }
  
  /// Helper method to split polygon rings from WKT.
   List<String> _splitRings(String ringsString) {
    List<String> result = [];
    int depth = 0;
    int start = 0;
    
    for (int i = 0; i < ringsString.length; i++) {
      if (ringsString[i] == '(') {
        if (depth == 0) {
          start = i + 1;
        }
        depth++;
      } else if (ringsString[i] == ')') {
        depth--;
        if (depth == 0) {
          result.add(ringsString.substring(start, i));
        }
      }
    }
    
    return result;
  }

  /// A constant map linking file extensions to their respective drivers.
  const Map<String, String> _extensionToDriver = {
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
  String _getDriverForExtension(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    return _extensionToDriver[".$extension"] ?? 'Unknown';
  }

 /// Calculate the area of a polygon using the Shoelace formula
  double _calculatePolygonArea(List<List<List<double>>> polygonCoords) {
    if (polygonCoords.isEmpty || polygonCoords[0].length < 3) {
      return 0.0;
    }
    
    // Use the outer ring for area calculation
    final ring = polygonCoords[0];
    double area = 0.0;
    
    for (int i = 0; i < ring.length - 1; i++) {
      area += (ring[i][0] * ring[i+1][1]) - (ring[i+1][0] * ring[i][1]);
    }
    
    // Close the polygon
    area += (ring.last[0] * ring.first[1]) - (ring.first[0] * ring.last[1]);
    
    return (area.abs() / 2.0);
  }

  /// Helper method to check if two points are equal
  bool _arePointsEqual(List<double> point1, List<double> point2) {
    if (point1.length != point2.length) return false;
    for (int i = 0; i < point1.length; i++) {
      if (point1[i] != point2[i]) return false;
    }
    return true;
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

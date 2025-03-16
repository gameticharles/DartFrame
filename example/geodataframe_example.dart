import 'package:dartframe/dartframe.dart';

void main() async {
  // Example 1: Create a GeoDataFrame from a GeoJSON FeatureCollection
  final geoDataFrame = createGeoDataFrameFromSample();
  print('GeoDataFrame created with ${geoDataFrame.featureCount} features');
  print('Properties: ${geoDataFrame.attributes.columns.join(', ')}');
  
  // Print the first feature
  print('\nFirst feature:');
  print(geoDataFrame.getFeature(0));
  
  // Example 2: Access and manipulate attributes
  print('\nAccessing attributes as DataFrame:');
  print(geoDataFrame.attributes);
  
  // Add a new column to all features
  geoDataFrame.addProperty('category', defaultValue: 'education');
  print('\nAfter adding a new property:');
  print(geoDataFrame.attributes.columns);
  
  // Update a specific property
  geoDataFrame.updateProperty(0, 'category', 'university');
  print('\nAfter updating a property:');
  print(geoDataFrame.attributes['category']);
  
  // Example 3: Spatial operations
  // Find features based on a query
  var foundFeatures = geoDataFrame.findFeatures((feature) => 
      feature.properties!['title'].toString().contains('University'));
  print('\nFound ${foundFeatures.length} features containing "University" in title');
  
  // Example 4: Export to file
  // await geoDataFrame.toFile('output.geojson');
  await geoDataFrame.toFile('/Users/mac/Library/CloudStorage/GoogleDrive-gameticharles@gmail.com/My Drive/MEGAsync/CONTRACTS/2024/dartframe/example/output.geojson');
  print('\nExported to GeoJSON file');
  
  // Example 5: Create a GeoDataFrame from coordinates
  final coordinates = [
    [105.7743099, 21.0717561],
    [105.7771289, 21.0715458],
    [105.7745218, 21.0715658],
  ];
  
  final attributeDF = DataFrame(
    columns: ['name', 'description', 'value'],
    data: [
    ['Point A', 'Description A', 100],
    ['Point B', 'Description B', 200],
    ['Point C', 'Description C', 300],
  ],
  );
  
  final coordGeoDF = GeoDataFrame.fromCoordinates(
    coordinates,
    attributes: attributeDF,
    coordinateType: 'lonlat',
    crs: 'EPSG:4326',
  );
  
  print('\nGeoDataFrame from coordinates:');
  print('Features: ${coordGeoDF.featureCount}');
  print('Properties: ${coordGeoDF.attributes.columns.join(', ')}');
  
  // Example 6: Convert to different formats
  print('\nConverting to rows:');
  final rows = geoDataFrame.toRows();
  print('Number of rows: ${rows.length}');
  
  // Example 7: Create from DataFrame
  final df = DataFrame(
    columns: ['id', 'name', 'longitude', 'latitude'],
    data: [
      [1, 'Location A', 105.7743099, 21.0717561],
      [2, 'Location B', 105.7771289, 21.0715458],
      [3, 'Location C', 105.7745218, 21.0715658],
    ],
  );
  
  final fromDfGeoDF = GeoDataFrame.fromDataFrame(
    df,
    geometryColumn: 'longitude',
    geometryType: 'point',
    coordinateType: 'lonlat',
  );
  
  print('\nGeoDataFrame from DataFrame:');
  print('Features: ${fromDfGeoDF.featureCount}');
  print('Properties: ${fromDfGeoDF.attributes.columns}');
  
  // Example 8: Create from GeoJSON string
  final geoJsonString = '''
  {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": {
          "marker-color": "#7e7e7e",
          "marker-size": "medium",
          "marker-symbol": "college",
          "title": "Hanoi University of Mining and Geology",
          "department": "Geoinformation Technology",
          "address": "No.18 Vien Street - Duc Thang Ward - Bac Tu Liem District - Ha Noi, Vietnam",
          "url": "http://humg.edu.vn"
        },
        "geometry": {
          "type": "Point",
          "coordinates": [
            105.7743099,
            21.0717561
          ]
        }
      },
      {
        "type": "Feature",
        "properties": {
          "stroke": "#7e7e7e",
          "stroke-width": 2,
          "stroke-opacity": 1,
          "title": "Vien St."
        },
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [
              105.7771289,
              21.0715458
            ],
            [
              105.7745218,
              21.0715658
            ],
            [
              105.7729125,
              21.0715358
            ]
          ]
        }
      },
      {
        "type": "Feature",
        "properties": {
          "stroke": "#555555",
          "stroke-width": 2,
          "stroke-opacity": 1,
          "fill": "#ab7942",
          "fill-opacity": 0.5,
          "title": "HUMG's Office"
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [
                105.7739666,
                21.0726795
              ],
              [
                105.7739719,
                21.0721991
              ],
              [
                105.7743394,
                21.0721966
              ],
              [
                105.774331,
                21.0725269
              ],
              [
                105.7742564,
                21.072612
              ],
              [
                105.7741865,
                21.0726095
              ],
              [
                105.7741785,
                21.0726746
              ],
              [
                105.7739666,
                21.0726795
              ]
            ]
          ]
        }
      }
    ]
  }
  ''';
  
  // Parse the GeoJSON string
  final geoJson = GeoJSON.fromJSON(geoJsonString);
  
  // Create a GeoDataFrame from the parsed GeoJSON
  GeoDataFrame fromJsonGeoDF;
  if (geoJson is GeoJSONFeatureCollection) {
    // Extract all unique property keys to use as headers
    final jsonHeaders = <String>{};
    for (var feature in geoJson.features) {
      if (feature?.properties != null) {
        jsonHeaders.addAll(feature!.properties!.keys);
      }
    }
    
    fromJsonGeoDF = GeoDataFrame(
      geoJson,
      jsonHeaders.toList(),
      geometryColumn: 'geometry',
      crs: 'EPSG:4326',
    );
    
    print('\nGeoDataFrame from GeoJSON string:');
    print('Features: ${fromJsonGeoDF.featureCount}');
    print('Properties: ${fromJsonGeoDF.attributes.columns.join(', ')}');
    
    // Demonstrate querying features
    var officeFeature = fromJsonGeoDF.findFeatures(
      (feature) => feature.properties!['title'] == "HUMG's Office"
    );
    
    if (officeFeature.isNotEmpty) {
      print('\nFound office feature:');
      print('Title: ${officeFeature[0].properties!['title']}');
      print('Geometry type: ${officeFeature[0].geometry.runtimeType}');
    }
  }
}

/// Creates a sample GeoDataFrame with point, line, and polygon features
GeoDataFrame createGeoDataFrameFromSample() {
  final featureCollection = GeoJSONFeatureCollection([]);
  
  // Add a point feature
  final point = GeoJSONPoint([105.7743099, 21.0717561]);
  final pointFeature = GeoJSONFeature(point, properties: {
    'marker-color': '#7e7e7e',
    'marker-size': 'medium',
    'marker-symbol': 'college',
    'title': 'Hanoi University of Mining and Geology',
    'department': 'Geoinformation Technology',
    'address':
        'No.18 Vien Street - Duc Thang Ward - Bac Tu Liem District - Ha Noi, Vietnam',
    'url': 'http://humg.edu.vn'
  });
  featureCollection.features.add(pointFeature);
  
  // Add a line feature
  final pos1 = [105.7771289, 21.0715458];
  final pos2 = [105.7745218, 21.0715658];
  final pos3 = [105.7729125, 21.0715358];
  final lineString = GeoJSONLineString([pos1, pos2, pos3]);
  featureCollection.features.add(GeoJSONFeature(lineString, properties: {
    'stroke': '#7e7e7e',
    'stroke-width': 2,
    'stroke-opacity': 1,
    'title': 'Vien St.'
  }));
  
  // Add a polygon feature
  final p01 = [105.7739666, 21.0726795]; // The first position
  final p02 = [105.7739719, 21.0721991];
  final p03 = [105.7743394, 21.0721966];
  final p04 = [105.7743310, 21.0725269];
  final p05 = [105.7742564, 21.0726120];
  final p06 = [105.7741865, 21.0726095];
  final p07 = [105.7741785, 21.0726746];
  final p08 = [105.7739666, 21.0726795]; // The last position
  final linerRing = [p01, p02, p03, p04, p05, p06, p07, p08];
  featureCollection.features.add(
    GeoJSONFeature(
      GeoJSONPolygon([linerRing]),
      properties: {
        'stroke': '#555555',
        'stroke-width': 2,
        'stroke-opacity': 1,
        'fill': '#ab7942',
        'fill-opacity': 0.5,
        'title': "HUMG's Office"
      },
    ),
  );
  
  // Extract all unique property keys to use as headers
  final headers = <String>{};
  for (var feature in featureCollection.features) {
    if (feature?.properties != null) {
      headers.addAll(feature!.properties!.keys);
    }
  }
  
  return GeoDataFrame(
    featureCollection, 
    headers.toList(),
    geometryColumn: 'geometry',
    crs: 'EPSG:4326',
  );
}
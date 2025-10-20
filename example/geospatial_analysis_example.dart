import 'package:dartframe/dartframe.dart';

/// Comprehensive example demonstrating geospatial analysis capabilities in DartFrame
/// This example showcases the enhanced GeoDataFrame and GeoSeries functionality
/// that provides geopandas-like capabilities for spatial data analysis.
void main() async {
  print('=== DartFrame Geospatial Analysis Example ===\n');

  // 1. Creating GeoDataFrames from different sources
  print('1. CREATING GEODATAFRAMES');
  print('=' * 40);

  // Create points from coordinates
  final storeLocations = GeoDataFrame.fromCoordinates([
    [-74.0060, 40.7128], // New York
    [-118.2437, 34.0522], // Los Angeles  
    [-87.6298, 41.8781], // Chicago
    [-95.3698, 29.7604], // Houston
    [-75.1652, 39.9526], // Philadelphia
  ], attributes: DataFrame.fromRows([
    {'store_id': 1, 'name': 'NYC Store', 'sales': 150000, 'employees': 25},
    {'store_id': 2, 'name': 'LA Store', 'sales': 120000, 'employees': 20},
    {'store_id': 3, 'name': 'Chicago Store', 'sales': 100000, 'employees': 18},
    {'store_id': 4, 'name': 'Houston Store', 'sales': 90000, 'employees': 15},
    {'store_id': 5, 'name': 'Philly Store', 'sales': 80000, 'employees': 12},
  ]), coordinateType: 'lonlat', crs: 'EPSG:4326');

  print('Store Locations:');
  print(storeLocations.head());
  print('');

  // Create service areas (buffers around stores)
  final serviceAreas = storeLocations.copy();
  serviceAreas.geometry = storeLocations.geometry.buffer(distance: 0.1); // ~11km buffer

  print('Service Areas Created (0.1 degree buffer)');
  print('Number of service areas: ${serviceAreas.featureCount}');
  print('');

  // 2. Spatial Properties and Measurements
  print('2. SPATIAL PROPERTIES AND MEASUREMENTS');
  print('=' * 40);

  // Calculate areas of service zones
  final areas = serviceAreas.geometry.area;
  serviceAreas['area_sq_deg'] = areas;

  print('Service Area Measurements:');
  print(serviceAreas[['name', 'area_sq_deg']]);
  print('');

  // Calculate centroids
  final centroids = serviceAreas.geometry.centroid;
  print('Service Area Centroids:');
  for (int i = 0; i < centroids.length; i++) {
    final coords = centroids.geometries()[i];
    print('${serviceAreas['name'][i]}: ${coords}');
  }
  print('');

  // 3. Spatial Relationships
  print('3. SPATIAL RELATIONSHIPS');
  print('=' * 40);

  // Create customer points
  final customers = GeoDataFrame.fromCoordinates([
    [-74.0100, 40.7200], // Near NYC
    [-74.0020, 40.7100], // Near NYC
    [-118.2500, 34.0500], // Near LA
    [-87.6200, 41.8800], // Near Chicago
    [-95.3600, 29.7500], // Near Houston
    [-120.0000, 35.0000], // Remote location
  ], attributes: DataFrame.fromRows([
    {'customer_id': 1, 'name': 'Customer A', 'value': 5000},
    {'customer_id': 2, 'name': 'Customer B', 'value': 3000},
    {'customer_id': 3, 'name': 'Customer C', 'value': 4000},
    {'customer_id': 4, 'name': 'Customer D', 'value': 2500},
    {'customer_id': 5, 'name': 'Customer E', 'value': 3500},
    {'customer_id': 6, 'name': 'Customer F', 'value': 1000},
  ]), coordinateType: 'lonlat', crs: 'EPSG:4326');

  print('Customer Locations:');
  print(customers.head());
  print('');

  // Spatial join - find which service area each customer is in
  final customersInAreas = customers.spatialJoin(
    serviceAreas,
    how: 'left',
    predicate: 'within'
  );

  print('Customers within Service Areas:');
  print(customersInAreas[['name_left', 'name_right', 'value']]);
  print('');

  // 4. Distance Analysis
  print('4. DISTANCE ANALYSIS');
  print('=' * 40);

  // Calculate distances from each customer to nearest store
  final storeGeoms = storeLocations.geometry;
  final customerGeoms = customers.geometry;

  print('Distance from each customer to stores:');
  for (int i = 0; i < customers.featureCount; i++) {
    final customerName = customers['name'][i];
    print('\n$customerName distances:');
    
    for (int j = 0; j < storeLocations.featureCount; j++) {
      final storeName = storeLocations['name'][j];
      final distance = customerGeoms.distance(storeGeoms)[i][j];
      print('  to $storeName: ${distance.toStringAsFixed(4)} degrees');
    }
  }
  print('');

  // 5. Spatial Aggregation
  print('5. SPATIAL AGGREGATION');
  print('=' * 40);

  // Aggregate customer values by service area
  final areaStats = customersInAreas
      .where((row) => row[customersInAreas.columns.indexOf('name_right')] != null)
      .groupBy(['name_right'])
      .agg({
        'value': ['sum', 'count', 'mean'],
        'customer_id': 'count'
      });

  print('Customer Statistics by Service Area:');
  print(areaStats);
  print('');

  // 6. Geometric Operations
  print('6. GEOMETRIC OPERATIONS');
  print('=' * 40);

  // Create convex hull of all store locations
  final allStores = storeLocations.geometry;
  final convexHull = allStores.convexHull();
  
  print('Convex Hull of Store Network:');
  print('Hull geometry type: ${convexHull.geometryType}');
  print('');

  // Buffer operations with different distances
  final smallBuffer = storeLocations.geometry.buffer(distance: 0.05);
  final largeBuffer = storeLocations.geometry.buffer(distance: 0.2);

  print('Buffer Analysis:');
  print('Small buffer (0.05°) areas: ${smallBuffer.area.data}');
  print('Large buffer (0.2°) areas: ${largeBuffer.area.data}');
  print('');

  // 7. Spatial Indexing and Queries
  print('7. SPATIAL INDEXING AND QUERIES');
  print('=' * 40);

  // Build spatial index for efficient queries
  serviceAreas.buildSpatialIndex();
  print('Spatial index built for service areas');

  // Query using bounding box
  final queryBounds = [-75.0, 40.0, -73.0, 42.0]; // Northeast region
  final candidateIndices = serviceAreas.spatialQuery(queryBounds);
  
  print('Service areas in Northeast region:');
  for (final idx in candidateIndices) {
    print('  ${serviceAreas['name'][idx]}');
  }
  print('');

  // 8. Coordinate Reference System Operations
  print('8. COORDINATE REFERENCE SYSTEM OPERATIONS');
  print('=' * 40);

  print('Current CRS: ${storeLocations.crs}');
  
  // Transform to Web Mercator for area calculations
  final webMercator = storeLocations.toCrs('EPSG:3857');
  print('Transformed to Web Mercator: ${webMercator.crs}');
  
  // Calculate more accurate areas in meters
  final accurateAreas = webMercator.geometry.buffer(distance: 10000).area; // 10km buffer
  print('Accurate service area sizes (sq meters):');
  for (int i = 0; i < storeLocations.featureCount; i++) {
    print('  ${storeLocations['name'][i]}: ${accurateAreas[i].toStringAsFixed(0)} sq m');
  }
  print('');

  // 9. Overlay Operations
  print('9. OVERLAY OPERATIONS');
  print('=' * 40);

  // Create two overlapping regions
  final region1 = GeoDataFrame.fromCoordinates([
    [-75.0, 40.0], [-73.0, 40.0], [-73.0, 42.0], [-75.0, 42.0], [-75.0, 40.0]
  ], attributes: DataFrame.fromRows([
    {'region': 'Northeast', 'priority': 1}
  ]), coordinateType: 'lonlat');

  final region2 = GeoDataFrame.fromCoordinates([
    [-76.0, 39.0], [-74.0, 39.0], [-74.0, 41.0], [-76.0, 41.0], [-76.0, 39.0]
  ], attributes: DataFrame.fromRows([
    {'region': 'Mid-Atlantic', 'priority': 2}
  ]), coordinateType: 'lonlat');

  // Intersection of regions
  final intersection = region1.overlay(region2, how: 'intersection');
  print('Intersection of regions:');
  print('Intersection area: ${intersection.geometry.area[0]}');
  print('');

  // Union of regions
  final union = region1.overlay(region2, how: 'union');
  print('Union of regions:');
  print('Union area: ${union.geometry.area[0]}');
  print('');

  // 10. Spatial Analysis Summary
  print('10. SPATIAL ANALYSIS SUMMARY');
  print('=' * 40);

  // Calculate network statistics
  final totalStores = storeLocations.featureCount;
  final totalCustomers = customers.featureCount;
  final customersInNetwork = customersInAreas
      .where((row) => row[customersInAreas.columns.indexOf('name_right')] != null)
      .rowCount;
  
  final networkCoverage = (customersInNetwork / totalCustomers) * 100;
  
  print('Network Analysis Summary:');
  print('Total Stores: $totalStores');
  print('Total Customers: $totalCustomers');
  print('Customers in Service Areas: $customersInNetwork');
  print('Network Coverage: ${networkCoverage.toStringAsFixed(1)}%');
  print('');

  // Calculate average distance between stores
  final storeDistances = <double>[];
  for (int i = 0; i < totalStores; i++) {
    for (int j = i + 1; j < totalStores; j++) {
      final distance = storeGeoms.distance(storeGeoms)[i][j];
      storeDistances.add(distance);
    }
  }
  
  final avgDistance = storeDistances.reduce((a, b) => a + b) / storeDistances.length;
  print('Average distance between stores: ${avgDistance.toStringAsFixed(4)} degrees');
  
  // Find closest store pairs
  storeDistances.sort();
  print('Closest store pair distance: ${storeDistances.first.toStringAsFixed(4)} degrees');
  print('Farthest store pair distance: ${storeDistances.last.toStringAsFixed(4)} degrees');

  print('\n=== Geospatial Analysis Example Complete ===');
}
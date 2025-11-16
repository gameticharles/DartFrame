import 'package:dartframe/dartframe.dart';

/// Example demonstrating how to read from a PostgreSQL PostGIS database
/// using DataFrame.read()
///
/// ⚠️ NOTE: This example uses MOCK DATA because the database implementation
/// is a placeholder. To connect to real databases, you need to:
/// 1. Add database packages (postgres, sqlite3, mysql1)
/// 2. Implement real connection methods
/// See DATABASE_IMPLEMENTATION_NOTE.md for details.
///
/// Database: postgis_36_sample
/// Host: localhost
/// Port: 5432
/// Username: postgres
/// Password: 1234
/// Schema: public
///
/// Tables:
/// - spatial_ref_sys: Spatial reference systems
/// - mobilitydb_opcache: MobilityDB operator cache
/// - pointcloud_formats: Point cloud format definitions

Future<void> main() async {
  print('=== PostgreSQL PostGIS Database Example ===');
  print('    See DATABASE_IMPLEMENTATION_NOTE.md for real database setup\n');

  // Connection string
  const host = 'localhost';
  const port = 5432;
  const database = 'postgis_36_sample';
  const username = 'postgres';
  const password = '1234';
  const schema = 'public';

  const connectionString =
      'postgresql://$username:$password@$host:$port/$database/$schema';

  try {
    // 1. Read spatial_ref_sys table
    print('1. Reading spatial_ref_sys table:');
    final spatialRefSys = await DataFrame.read(
      '$connectionString?table=spatial_ref_sys',
    );
    print('Shape: ${spatialRefSys.shape}');
    print('Columns: ${spatialRefSys.columns}');
    print('\nFirst 5 rows:');
    print(spatialRefSys.head(5));
    print('');

    // 2. Read mobilitydb_opcache table
    print('2. Reading mobilitydb_opcache table:');
    final mobilityCache = await DataFrame.read(
      '$connectionString?table=mobilitydb_opcache',
    );
    print('Shape: ${mobilityCache.shape}');
    print('Columns: ${mobilityCache.columns}');
    if (mobilityCache.shape.rows > 0) {
      print('\nFirst 5 rows:');
      print(mobilityCache.head(5));
    } else {
      print('Table is empty');
    }
    print('');

    // 3. Read pointcloud_formats table
    print('3. Reading pointcloud_formats table:');
    final pointcloudFormats = await DataFrame.read(
      '$connectionString?table=pointcloud_formats',
    );
    print('Shape: ${pointcloudFormats.shape}');
    print('Columns: ${pointcloudFormats.columns}');
    if (pointcloudFormats.shape.rows > 0) {
      print('\nAll rows:');
      print(pointcloudFormats);
    } else {
      print('Table is empty');
    }
    print('');

    // 4. Custom query - Get specific SRIDs
    print('4. Custom query - Common spatial reference systems:');
    final commonSRIDs = await DataFrame.read(
      '$connectionString?query=SELECT srid, auth_name, auth_srid, LEFT(srtext, 80) as srtext_preview FROM spatial_ref_sys WHERE srid IN (4326, 3857, 2154, 32631) ORDER BY srid',
    );
    print(commonSRIDs);
    print('');

    // 5. Aggregate query - Count by authority
    print('5. Count spatial reference systems by authority:');
    final sridsByAuthority = await DataFrame.read(
      '$connectionString?query=SELECT auth_name, COUNT(*) as count FROM spatial_ref_sys WHERE auth_name IS NOT NULL GROUP BY auth_name ORDER BY count DESC',
    );
    print(sridsByAuthority);
    print('');

    // 6. Filtered query - EPSG systems
    print('6. EPSG spatial reference systems (first 10):');
    final epsgSRIDs = await DataFrame.read(
      '$connectionString?query=SELECT srid, auth_srid, LEFT(srtext, 60) as description FROM spatial_ref_sys WHERE auth_name = \'EPSG\' ORDER BY srid LIMIT 10',
    );
    print(epsgSRIDs);
    print('');

    // 7. Query with specific SRID (WGS84 - most common)
    print('7. WGS84 (SRID 4326) details:');
    final wgs84 = await DataFrame.read(
      '$connectionString?query=SELECT srid, auth_name, auth_srid, srtext, proj4text FROM spatial_ref_sys WHERE srid = 4326',
    );
    print(wgs84);
    print('');

    // 8. Query with range
    print('8. Spatial reference systems in range 4300-4330:');
    final sridRange = await DataFrame.read(
      '$connectionString?query=SELECT srid, auth_name, auth_srid, LEFT(srtext, 50) as description FROM spatial_ref_sys WHERE srid BETWEEN 4300 AND 4330 ORDER BY srid',
    );
    print(sridRange);
    print('');

    print('✅ Successfully demonstrated PostgreSQL API (using mock data)');
    print('\n📝 To connect to real databases:');
    print('   1. Add database packages to pubspec.yaml');
    print('   2. Implement real connection methods');
    print('   3. See DATABASE_IMPLEMENTATION_NOTE.md for details');
  } catch (e) {
    print('❌ Error: $e');
    print('\nMake sure:');
    print('  1. PostgreSQL is running');
    print('  2. Database "$database" exists');
    print('  3. PostGIS extension is installed');
    print('  4. Connection details are correct:');
    print('     Host: $host');
    print('     Port: $port');
    print('     Username: $username');
    print('     Password: $password');
    print('  5. User has read permissions on the tables');
    print('\nTo create the database and install PostGIS:');
    print('  CREATE DATABASE $database;');
    print('  \\c $database');
    print('  CREATE EXTENSION postgis;');
  }
}

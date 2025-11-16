import 'package:dartframe/dartframe.dart';

/// Examples demonstrating SmartLoader with real databases:
/// 1. Northwind SQLite database
/// 2. PostgreSQL PostGIS database

Future<void> main() async {
  print('=== SmartLoader Database Examples ===\n');

  // Example 1: Northwind SQLite Database
  await example1NorthwindSQLite();

  // Example 2: PostgreSQL PostGIS Database
  await example2PostgreSQLPostGIS();

  // Example 3: Advanced queries
  await example3AdvancedQueries();

  // Example 4: Writing data back to databases
  await example4WritingToDatabase();
}

/// Example 1: Reading from Northwind SQLite Database
///
/// The Northwind database is a sample database that was provided with
/// Microsoft Access as a tutorial schema for managing small business
/// customers, orders, inventory, purchasing, suppliers, shipping, and employees.
Future<void> example1NorthwindSQLite() async {
  print('--- Example 1: Northwind SQLite Database ---\n');

  try {
    // Path to the Northwind database
    const dbPath = 'example/data/northwind_small.sqlite';

    // 1. Load Customers table
    print('1. Loading Customers table...');
    final customers = await DataFrame.read('sqlite://$dbPath?table=Customer');
    print('Customers shape: ${customers.shape}');
    print('Columns: ${customers.columns}');
    print('First 5 customers:');
    print(customers.head(5));
    print('');

    // 2. Load Orders table
    print('2. Loading Orders table...');
    final orders = await DataFrame.read('sqlite://$dbPath?table=Order');
    print('Orders shape: ${orders.shape}');
    print('First 3 orders:');
    print(orders.head(3));
    print('');

    // 3. Load Products table
    print('3. Loading Products table...');
    final products = await DataFrame.read('sqlite://$dbPath?table=Product');
    print('Products shape: ${products.shape}');
    print('Columns: ${products.columns}');
    print('First 5 products:');
    print(products.head(5));
    print('');

    // 4. Load Employees table
    print('4. Loading Employees table...');
    final employees = await DataFrame.read('sqlite://$dbPath?table=Employee');
    print('Employees shape: ${employees.shape}');
    print('Employee names:');
    if (employees.columns.contains('FirstName') &&
        employees.columns.contains('LastName')) {
      for (int i = 0; i < employees.shape.rows && i < 5; i++) {
        print(
            '  ${employees['FirstName'][i]} ${employees['LastName'][i]} - ${employees['Title'][i]}');
      }
    }
    print('');

    // 5. Load Suppliers table
    print('5. Loading Suppliers table...');
    final suppliers = await DataFrame.read('sqlite://$dbPath?table=Supplier');
    print('Suppliers shape: ${suppliers.shape}');
    print('First 3 suppliers:');
    print(suppliers.head(3));
    print('');

    // 6. Custom query - Get orders with customer information
    print('6. Custom query - Orders with customer names...');
    final ordersWithCustomers = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT o.Id, o.OrderDate, c.FirstName, c.LastName, o.TotalAmount FROM "Order" o JOIN Customer c ON o.CustomerId = c.Id LIMIT 10',
    );
    print('Orders with customers:');
    print(ordersWithCustomers);
    print('');

    // 7. Custom query - Products by category
    print('7. Custom query - Products with categories...');
    final productsByCategory = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT p.ProductName, p.UnitPrice, c.CategoryName FROM Product p LEFT JOIN Category c ON p.CategoryId = c.Id LIMIT 10',
    );
    print('Products by category:');
    print(productsByCategory);
    print('');

    // 8. Aggregate query - Order statistics
    print('8. Aggregate query - Order statistics by customer...');
    final orderStats = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT c.FirstName || " " || c.LastName as CustomerName, COUNT(o.Id) as OrderCount, SUM(o.TotalAmount) as TotalSpent FROM Customer c LEFT JOIN "Order" o ON c.Id = o.CustomerId GROUP BY c.Id ORDER BY TotalSpent DESC LIMIT 10',
    );
    print('Top customers by spending:');
    print(orderStats);
    print('');
  } catch (e) {
    print('Error reading Northwind database: $e');
    print(
        'Make sure the database file exists at: example/data/northwind_small.sqlite');
  }

  print('');
}

/// Example 2: Reading from PostgreSQL PostGIS Database
///
/// PostGIS is a spatial database extender for PostgreSQL that adds support
/// for geographic objects.
Future<void> example2PostgreSQLPostGIS() async {
  print('--- Example 2: PostgreSQL PostGIS Database ---\n');

  try {
    // Connection string for PostgreSQL
    const connectionString =
        'postgresql://postgres:1234@localhost:5432/postgis_36_sample';

    // 1. Load spatial_ref_sys table
    print('1. Loading spatial_ref_sys table...');
    final spatialRefSys = await DataFrame.read(
      '$connectionString?table=spatial_ref_sys',
    );
    print('Spatial reference systems shape: ${spatialRefSys.shape}');
    print('Columns: ${spatialRefSys.columns}');
    print('First 5 spatial reference systems:');
    print(spatialRefSys.head(5));
    print('');

    // 2. Load mobilitydb_opcache table
    print('2. Loading mobilitydb_opcache table...');
    final mobilityCache = await DataFrame.read(
      '$connectionString?table=mobilitydb_opcache',
    );
    print('MobilityDB opcache shape: ${mobilityCache.shape}');
    print('First 5 rows:');
    print(mobilityCache.head(5));
    print('');

    // 3. Load pointcloud_formats table
    print('3. Loading pointcloud_formats table...');
    final pointcloudFormats = await DataFrame.read(
      '$connectionString?table=pointcloud_formats',
    );
    print('Pointcloud formats shape: ${pointcloudFormats.shape}');
    print('Columns: ${pointcloudFormats.columns}');
    print('All pointcloud formats:');
    print(pointcloudFormats);
    print('');

    // 4. Custom query - Get specific SRID information
    print('4. Custom query - Common spatial reference systems...');
    final commonSRIDs = await DataFrame.read(
      '$connectionString?query=SELECT srid, auth_name, auth_srid, srtext FROM spatial_ref_sys WHERE srid IN (4326, 3857, 2154, 32631) ORDER BY srid',
    );
    print('Common SRIDs (WGS84, Web Mercator, etc.):');
    print(commonSRIDs);
    print('');

    // 5. Custom query - Count by authority
    print('5. Aggregate query - Count SRIDs by authority...');
    final sridsByAuthority = await DataFrame.read(
      '$connectionString?query=SELECT auth_name, COUNT(*) as count FROM spatial_ref_sys WHERE auth_name IS NOT NULL GROUP BY auth_name ORDER BY count DESC LIMIT 10',
    );
    print('SRIDs by authority:');
    print(sridsByAuthority);
    print('');

    // 6. Query with filtering
    print('6. Filtered query - EPSG spatial reference systems...');
    final epsgSRIDs = await DataFrame.read(
      '$connectionString?query=SELECT srid, auth_srid, LEFT(srtext, 50) as srtext_preview FROM spatial_ref_sys WHERE auth_name = \'EPSG\' AND srid < 4400 ORDER BY srid LIMIT 10',
    );
    print('EPSG SRIDs:');
    print(epsgSRIDs);
    print('');
  } catch (e) {
    print('Error reading PostgreSQL database: $e');
    print('Make sure PostgreSQL is running and accessible at:');
    print('  Host: localhost');
    print('  Port: 5432');
    print('  Database: postgis_36_sample');
    print('  Username: postgres');
    print('  Password: 1234');
  }

  print('');
}

/// Example 3: Advanced Queries
Future<void> example3AdvancedQueries() async {
  print('--- Example 3: Advanced Queries ---\n');

  try {
    const dbPath = 'example/data/northwind_small.sqlite';

    // 1. Join multiple tables
    print('1. Complex join - Order details with product and customer info...');
    final orderDetails = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT o.Id as OrderId, o.OrderDate, c.FirstName || " " || c.LastName as Customer, p.ProductName, od.Quantity, od.UnitPrice, (od.Quantity * od.UnitPrice) as LineTotal FROM "Order" o JOIN Customer c ON o.CustomerId = c.Id JOIN OrderDetail od ON o.Id = od.OrderId JOIN Product p ON od.ProductId = p.Id LIMIT 20',
    );
    print('Order details:');
    print(orderDetails);
    print('');

    // 2. Subquery - Products above average price
    print('2. Subquery - Products above average price...');
    final expensiveProducts = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT ProductName, UnitPrice FROM Product WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Product) ORDER BY UnitPrice DESC LIMIT 10',
    );
    print('Expensive products:');
    print(expensiveProducts);
    print('');

    // 3. Date filtering
    print('3. Date filtering - Recent orders...');
    final recentOrders = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT Id, OrderDate, CustomerId, TotalAmount FROM "Order" WHERE OrderDate >= date(\'now\', \'-1 year\') ORDER BY OrderDate DESC LIMIT 10',
    );
    print('Recent orders:');
    print(recentOrders);
    print('');

    // 4. Aggregation with HAVING
    print('4. Aggregation - Customers with multiple orders...');
    final frequentCustomers = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT c.FirstName || " " || c.LastName as Customer, COUNT(o.Id) as OrderCount, AVG(o.TotalAmount) as AvgOrderValue FROM Customer c JOIN "Order" o ON c.Id = o.CustomerId GROUP BY c.Id HAVING COUNT(o.Id) > 2 ORDER BY OrderCount DESC LIMIT 10',
    );
    print('Frequent customers:');
    print(frequentCustomers);
    print('');
  } catch (e) {
    print('Error in advanced queries: $e');
  }

  print('');
}

/// Example 4: Writing Data Back to Databases
Future<void> example4WritingToDatabase() async {
  print('--- Example 4: Writing Data to Databases ---\n');

  try {
    // Create a sample DataFrame
    final df = DataFrame.fromMap({
      'product_name': ['Widget A', 'Widget B', 'Widget C'],
      'price': [19.99, 29.99, 39.99],
      'stock': [100, 50, 75],
      'category': ['Electronics', 'Electronics', 'Hardware'],
    });

    print('Sample DataFrame to write:');
    print(df);
    print('');

    // 1. Write to SQLite (create new table)
    print('1. Writing to SQLite database...');
    await df.write('sqlite://output_test.db?table=products', options: {
      'ifExists': 'replace',
      'index': false,
    });
    print('✓ Written to SQLite: output_test.db, table: products');
    print('');

    // 2. Read it back to verify
    print('2. Reading back from SQLite...');
    final loadedFromSQLite =
        await DataFrame.read('sqlite://output_test.db?table=products');
    print('Loaded from SQLite:');
    print(loadedFromSQLite);
    print('');

    // 3. Append more data
    final moreData = DataFrame.fromMap({
      'product_name': ['Widget D', 'Widget E'],
      'price': [49.99, 59.99],
      'stock': [25, 30],
      'category': ['Hardware', 'Software'],
    });

    print('3. Appending more data...');
    await moreData.write('sqlite://output_test.db?table=products', options: {
      'ifExists': 'append',
      'index': false,
    });
    print('✓ Appended to SQLite');
    print('');

    // 4. Read all data
    print('4. Reading all data after append...');
    final allData =
        await DataFrame.read('sqlite://output_test.db?table=products');
    print('All products:');
    print(allData);
    print('Total rows: ${allData.shape.rows}');
    print('');

    // 5. Write to PostgreSQL (if available)
    print('5. Writing to PostgreSQL (if available)...');
    try {
      await df.write(
        'postgresql://postgres:1234@localhost:5432/postgis_36_sample?table=test_products',
        options: {
          'ifExists': 'replace',
          'index': false,
          'chunkSize': 1000,
        },
      );
      print('✓ Written to PostgreSQL: test_products table');

      // Read it back
      final loadedFromPG = await DataFrame.read(
        'postgresql://postgres:1234@localhost:5432/postgis_36_sample?table=test_products',
      );
      print('Loaded from PostgreSQL:');
      print(loadedFromPG);
    } catch (e) {
      print('PostgreSQL not available or error: $e');
    }
    print('');
  } catch (e) {
    print('Error writing to database: $e');
  }

  print('');
}

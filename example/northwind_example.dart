import 'package:dartframe/dartframe.dart';

/// Simple example demonstrating how to read from the Northwind SQLite database
/// using DataFrame.read()
///
/// The Northwind database contains:
/// - Customers
/// - Orders
/// - Products
/// - Employees
/// - Suppliers
/// - Categories
/// - OrderDetails
/// - Shippers

Future<void> main() async {
  print('=== Northwind Database Example ===\n');

  const dbPath = 'example/data/northwind_small.sqlite';

  try {
    // 1. Simple table read
    print('1. Reading Customers table:');
    final customers = await DataFrame.read('sqlite://$dbPath?table=Customer');
    print(customers.head(5));
    print('Total customers: ${customers.shape.rows}\n');

    // 2. Reading with a simple query
    print('2. Reading Orders with custom query:');
    final orders = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT * FROM "Order" LIMIT 10',
    );
    print(orders);
    print('');

    // 3. Join query - Orders with customer names
    print('3. Orders with customer information:');
    final ordersWithCustomers = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT o.Id, o.OrderDate, c.ContactName, c.CompanyName, o.Freight FROM "Order" o JOIN Customer c ON o.CustomerId = c.Id LIMIT 10',
    );
    print(ordersWithCustomers);
    print('');

    // 4. Products information
    print('4. Products:');
    final products = await DataFrame.read('sqlite://$dbPath?table=Product');
    print(products.head(10));
    print('Total products: ${products.shape.rows}\n');

    // 5. Employees
    print('5. Employees:');
    final employees = await DataFrame.read('sqlite://$dbPath?table=Employee');
    print(employees);
    print('');

    // 6. Aggregate query - Top customers
    print('6. Top 10 customers by total spending:');
    final topCustomers = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT c.ContactName as CustomerName, c.CompanyName, COUNT(o.Id) as OrderCount, ROUND(SUM(o.Freight), 2) as TotalFreight FROM Customer c LEFT JOIN "Order" o ON c.Id = o.CustomerId GROUP BY c.Id ORDER BY TotalFreight DESC LIMIT 10',
    );
    print(topCustomers);
    print('');

    // 7. Product categories
    print('7. Products by category:');
    final productsByCategory = await DataFrame.read(
      'sqlite://$dbPath?query=SELECT c.CategoryName, COUNT(p.Id) as ProductCount, ROUND(AVG(p.UnitPrice), 2) as AvgPrice FROM Category c LEFT JOIN Product p ON c.Id = p.CategoryId GROUP BY c.Id ORDER BY ProductCount DESC',
    );
    print(productsByCategory);
    print('');

    print('✅ Successfully read from Northwind database!');
  } catch (e) {
    print('❌ Error: $e');
    print('\nMake sure:');
    print('  1. The database file exists at: $dbPath');
    print('  2. The file is a valid SQLite database');
    print('  3. You have read permissions');
  }
}

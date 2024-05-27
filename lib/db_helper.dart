import 'package:mysql1/mysql1.dart';
import '../models/user.dart';
import '../models/product.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static MySqlConnection? _connection;
  static bool _isConnected = false;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<MySqlConnection> get connection async {
    if (_connection != null && _isConnected) return _connection!;
    _connection = await _initDB();
    return _connection!;
  }

  Future<MySqlConnection> _initDB() async {
    try {
      var settings = ConnectionSettings(
        host: 'srv1402.hstgr.io',  // replace with your host
        port: 3306,                // replace with your port
        user: 'u646358860_autodoc',  // replace with your username
        password: 'OFcoD7U:v',     // replace with your password
        db: 'u646358860_autodoc',  // replace with your database name
      );
      print('Connecting to the database...');
      var conn = await MySqlConnection.connect(settings);
      _isConnected = true;
      print('Successfully connected to the database.');
      return conn;
    } catch (e) {
      print('Error connecting to the database: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection?.close();
      _connection = null;
      _isConnected = false;
      print('Database connection closed.');
    }
  }

  Future<void> createTables() async {
    final conn = await connection;
    await conn.query('''
      CREATE TABLE IF NOT EXISTS users (
        id INT PRIMARY KEY AUTO_INCREMENT,
        email VARCHAR(255) NOT NULL,
        password VARCHAR(255) NOT NULL
      )
    ''');
    await conn.query('''
      CREATE TABLE IF NOT EXISTS cart (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255) NOT NULL,
        quantity INT NOT NULL,
        user_id INT NOT NULL
      )
    ''');
    await conn.query('''
      CREATE TABLE IF NOT EXISTS products (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL,
        quantity INT NOT NULL
      )
    ''');
    await conn.query('''
      CREATE TABLE IF NOT EXISTS orders (
        order_id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        product_name VARCHAR(255) NOT NULL,
        quantity INT NOT NULL,
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Insert default products if the table is empty
    var results = await conn.query('SELECT COUNT(*) AS count FROM products');
    var count = results.first['count'] as int;
    if (count == 0) {
      await conn.query('''
        INSERT INTO products (name, description, price, quantity) VALUES
        ('Brake Pads', 'High-quality brake pads for superior stopping power.', 29.99, 50),
        ('Oil Filter', 'Durable oil filter for extended engine protection.', 15.99, 100),
        ('Air Filter', 'Efficient air filter to keep your engine clean.', 12.99, 80),
        ('Spark Plugs', 'Long-lasting spark plugs for improved ignition.', 9.99, 150),
        ('Car Battery', 'Reliable car battery with a long lifespan.', 99.99, 20)
      ''');
    }
  }

  Future<void> registerUser(String email, String password) async {
    final conn = await connection;
    try {
      await conn.query('INSERT INTO users (email, password) VALUES (?, ?)', [email, password]);
    } catch (e) {
      print('Error registering user: $e');
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final conn = await connection;
    try {
      var results = await conn.query('SELECT * FROM users WHERE email = ? AND password = ?', [email, password]);
      if (results.isNotEmpty) {
        var result = results.first;
        return User.fromMap({
          'id': result['id'],
          'email': result['email'],
          'password': result['password'],
        });
      }
      return null;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  Future<void> addItemToCart(String name, int quantity, int userId) async {
    final conn = await connection;
    try {
      await conn.query('INSERT INTO cart (name, quantity, user_id) VALUES (?, ?, ?)', [name, quantity, userId]);
    } catch (e) {
      print('Error adding item to cart: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final conn = await connection;
    try {
      var results = await conn.query('SELECT * FROM cart WHERE user_id = ?', [userId]);
      return results.map((result) => {
        'id': result['id'],
        'name': result['name'],
        'quantity': result['quantity'],
        'user_id': result['user_id'],
      }).toList();
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  Future<void> removeItemFromCart(int id) async {
    final conn = await connection;
    try {
      await conn.query('DELETE FROM cart WHERE id = ?', [id]);
    } catch (e) {
      print('Error removing item from cart: $e');
    }
  }

  Future<void> clearCart(int userId) async {
    final conn = await connection;
    try {
      await conn.query('DELETE FROM cart WHERE user_id = ?', [userId]);
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  Future<void> checkout(int userId) async {
    final conn = await connection;
    try {
      var cartItems = await getCartItems(userId);
      for (var item in cartItems) {
        var productResults = await conn.query('SELECT quantity FROM products WHERE name = ?', [item['name']]);
        if (productResults.isNotEmpty) {
          var currentQuantity = productResults.first['quantity'] as int;
          var newQuantity = currentQuantity - (item['quantity'] as int);
          if (newQuantity >= 0) {
            await conn.query('UPDATE products SET quantity = ? WHERE name = ?', [newQuantity, item['name']]);
            await conn.query('INSERT INTO orders (user_id, product_name, quantity) VALUES (?, ?, ?)', [item['user_id'], item['name'], item['quantity']]);
          } else {
            print('Insufficient stock for ${item['name']}');
          }
        }
      }
      await clearCart(userId);
    } catch (e) {
      print('Error during checkout: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    final conn = await connection;
    try {
      var results = await conn.query('SELECT * FROM products');
      return results.map((result) {
        var descriptionBlob = result['description'];
        var descriptionString = descriptionBlob.toString();  // Convert to string directly
        return Product(
          id: result['id'] as int,
          name: result['name'] as String,
          description: descriptionString,
          price: result['price'] as double,
          quantity: result['quantity'] as int,
        );
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }
}

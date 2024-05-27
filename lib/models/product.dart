class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;

  Product({required this.id, required this.name, required this.description, required this.price, required this.quantity});

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] as double,
      quantity: map['quantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
    };
  }
}

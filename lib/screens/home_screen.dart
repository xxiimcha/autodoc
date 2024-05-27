import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DBHelper dbHelper = DBHelper();
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  void fetchProducts() async {
    products = await dbHelper.getProducts();
    setState(() {});
  }

  void addToCart(Product product) async {
    await dbHelper.addItemToCart(product.name, 1, widget.userId); // Default quantity is 1 for now
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AutoDoc - Car Parts'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(products[index].name),
            subtitle: Text(products[index].description),
            trailing: IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {
                addToCart(products[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

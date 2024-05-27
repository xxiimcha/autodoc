import 'package:flutter/material.dart';
import '../db_helper.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  CartScreen({required this.userId});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  DBHelper dbHelper = DBHelper();
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  void fetchCartItems() async {
    cartItems = await dbHelper.getCartItems(widget.userId);
    setState(() {});
  }

  void removeFromCart(int id) async {
    await dbHelper.removeItemFromCart(id);
    fetchCartItems();
  }

  void checkout() async {
    await dbHelper.checkout(widget.userId);
    fetchCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cartItems[index]['name']),
                  subtitle: Text('Quantity: ${cartItems[index]['quantity']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      removeFromCart(cartItems[index]['id']);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: checkout,
              child: Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}

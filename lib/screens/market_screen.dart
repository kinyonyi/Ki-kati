import 'package:flutter/material.dart';
import 'package:ki_kati/screens/market_create_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search functionality
            },
          ),
        ],
      ),
      body: ListTile(
        leading: Image.network(
            'https://via.placeholder.com/100'), // Replace with item image URL
        title: const Text('Item Title'), // Replace with item title
        subtitle: const Text('Price: 1000'), // Replace with item price
        onTap: () {
          /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsScreen(itemId: index.toString()),
                ),
              );
              */
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MarketCreateScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

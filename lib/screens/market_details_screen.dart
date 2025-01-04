import 'package:flutter/material.dart';

class MarketDetailsScreen extends StatefulWidget {
  final String itemId;

  const MarketDetailsScreen({super.key, required this.itemId});

  @override
  State<MarketDetailsScreen> createState() => _MarketDetailsScreenState();
}

class _MarketDetailsScreenState extends State<MarketDetailsScreen> {
  void _updateItem(BuildContext context) {
    // Navigate to update item screen
  }

  void _deleteItem(BuildContext context) {
    // Call API to delete item
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _updateItem(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteItem(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width, // 100% screen width
              child: Image.network(
                'https://via.placeholder.com/300',
                fit: BoxFit.cover, // Ensures the image scales proportionally
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Item Title',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Price: \$100',
                style: TextStyle(fontSize: 14)), // Replace with actual price
            const SizedBox(height: 8),
            const Text('Category: Electronics',
                style: TextStyle(fontSize: 14)), // Replace with actual category
            const SizedBox(height: 8),
            const Text('Location: City, Country',
                style: TextStyle(fontSize: 14)), // Replace with actual location
            const SizedBox(height: 8),
            const Text('Quantity: 10',
                style: TextStyle(fontSize: 14)), // Replace with actual quantity
            const SizedBox(height: 16),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
                'This is a sample description for the market item. Replace this with the actual item description.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

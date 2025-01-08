import 'package:flutter/material.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/screens/market_seller_items_screen.dart';
import 'package:ki_kati/screens/market_update_screen.dart';

class MarketDetailsScreen extends StatefulWidget {
  final String itemId;

  const MarketDetailsScreen({super.key, required this.itemId});

  @override
  State<MarketDetailsScreen> createState() => _MarketDetailsScreenState();
}

class _MarketDetailsScreenState extends State<MarketDetailsScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  Map<String, dynamic>? itemDetails;
  bool isLoading = false;

  Future<void> getItemDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/market/${widget.itemId}');
      setState(() {
        itemDetails = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Load Item Details')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteItem() async {
    try {
      final response = await httpService.delete('/market/${widget.itemId}');
      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getItemDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text(
          'Item Details',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          // Update Item Option
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketUpdateScreen(
                    itemId: widget.itemId,
                    initialData: itemDetails, // Pass the current item details
                  ),
                ),
              );
            },
          ),
          // Delete Item Option
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Item',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  content: const Text(
                    'Are you sure you want to delete this item?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemDetails == null
              ? const Center(child: Text('No details available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the first image
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Image.network(
                          "https://ki-kati.com/${itemDetails!['media'][0]}",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display additional images in a scrollable row
                      if (itemDetails!['media'].length > 1)
                        SizedBox(
                          height: 120,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: itemDetails!['media']
                                  .sublist(1)
                                  .map<Widget>(
                                    (mediaUrl) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          "https://ki-kati.com/$mediaUrl",
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 50),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Title and other details
                      Text(
                        itemDetails!['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: \$${itemDetails!['price']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: ${itemDetails!['category']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location: ${itemDetails!['location']['city']}, ${itemDetails!['location']['region']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quantity: ${itemDetails!['quantity']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      const Divider(),

                      // Description Section
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        itemDetails!['description'] ?? 'No Description',
                        style: const TextStyle(fontSize: 14),
                      ),

                      const Divider(),
                      // Seller Details
                      const Text(
                        'Seller Information:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seller: ${itemDetails!['seller']['username']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Button to View Seller's Items
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MarketSellerItemsScreen(
                                userId: itemDetails!['seller']['_id'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.store),
                        label: const Text('View Seller Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

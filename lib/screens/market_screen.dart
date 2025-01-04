import 'package:flutter/material.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/screens/market_create_screen.dart';
import 'package:ki_kati/screens/market_details_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  List<Map<String, dynamic>> items = [];
  bool isLoading = false;

  Future<void> getMarketItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/market');
      setState(() {
        items = List.from(response);
      });
    } catch (e) {
      setState(() {
        items = [];
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Load Market Items')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getMarketItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
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
        leading: Image.network('https://via.placeholder.com/100'),
        title: const Text('Item Title'), // Replace with item title
        subtitle: const Text('Price: 1000'), // Replace with item price
        trailing: const Icon(Icons.arrow_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketDetailsScreen(itemId: 1.toString()),
            ),
          );
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

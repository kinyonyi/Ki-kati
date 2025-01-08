import 'package:flutter/material.dart';
import 'package:ki_kati/components/http_servive.dart';
import 'package:ki_kati/screens/market_details_screen.dart';

class MarketSellerItemsScreen extends StatefulWidget {
  final String userId;

  const MarketSellerItemsScreen({super.key, required this.userId});

  @override
  State<MarketSellerItemsScreen> createState() =>
      _MarketSellerItemsScreenState();
}

class _MarketSellerItemsScreenState extends State<MarketSellerItemsScreen> {
  final HttpService httpService = HttpService("https://ki-kati.com/api");
  List<Map<String, dynamic>> sellerItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = false;

  Future<void> getSellerItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/market/user/${widget.userId}');
      setState(() {
        sellerItems = List.from(response);
        filteredItems = sellerItems; // Initially, show all items
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Load Seller Items')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _searchItems(String query) {
    final results = sellerItems.where((item) {
      final title = item['title']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredItems = results;
    });
  }

  @override
  void initState() {
    super.initState();
    getSellerItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text('Seller Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SellerSearchDelegate(
                  items: sellerItems,
                  onSearch: _searchItems,
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: getSellerItems, // Pull-to-refresh callback
              child: filteredItems.isEmpty
                  ? const Center(child: Text('No items available'))
                  : ListView.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) => const Divider(
                        thickness: 0.2,
                        color: Colors.grey,
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final media = item['media'] as List<dynamic>;
                        final imageUrl = media.isNotEmpty
                            ? "https://ki-kati.com/${media[0]}"
                            : 'https://via.placeholder.com/100';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 5.0,
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              item['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Price: ${item['price']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.arrow_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarketDetailsScreen(
                                    itemId: item['_id'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class SellerSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> items;
  final Function(String) onSearch;

  SellerSearchDelegate({required this.items, required this.onSearch});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal, // Match parent screen's style
        foregroundColor: Colors.white, // White text and icons
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none, // No borders for search input
        hintStyle: TextStyle(color: Colors.white70), // Hint text style
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = items.where((item) {
      final title = item['title']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final media = item['media'] as List<dynamic>;
        final imageUrl = media.isNotEmpty
            ? "https://ki-kati.com/${media[0]}"
            : 'https://via.placeholder.com/100';

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(item['title'] ?? 'No Title'),
          subtitle: Text('Price: ${item['price']}'),
          onTap: () {
            // Navigate to item details if needed
          },
        );
      },
    );
  }
}

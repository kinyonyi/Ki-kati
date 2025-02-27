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
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = false;

  Future<void> getMarketItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await httpService.get('/market');
      setState(() {
        items = List.from(response);
        filteredItems = items; // Initially, filteredItems are all items
      });
    } catch (e) {
      setState(() {
        items = [];
        filteredItems = [];
      });
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

  void _searchItems(String query) {
    final results = items.where((item) {
      final title = item['title']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredItems = results;
    });
  }

  void _navigateToDetails(String itemId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketDetailsScreen(itemId: itemId),
      ),
    );

    if (result == true) {
      // Refresh the data if item was deleted
      getMarketItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text(
          'Market Items',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MarketSearchDelegate(
                  items: items,
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
              onRefresh: getMarketItems, // Pull-to-refresh callback
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
                            onTap: () => _navigateToDetails(item['_id']),
                          ),
                        );
                      },
                    ),
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

class MarketSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> items;
  final Function(String) onSearch;

  MarketSearchDelegate({required this.items, required this.onSearch});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal, // Teal background
        foregroundColor: Colors.white, // White text and icons
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none, // No border
        focusedBorder: InputBorder.none, // No border when focused
        enabledBorder: InputBorder.none, // No border when enabled
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketDetailsScreen(
                  itemId: item['_id'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

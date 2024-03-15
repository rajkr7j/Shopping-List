import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:shopping_list/data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final String? baseUrl = dotenv.env['baserUrl'];
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    try {
      final url = Uri.https('$baseUrl', 'shopping-list.json');
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }
      print(response.body);
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries.firstWhere(
          (element) => element.value.title == item.value['category'],
        );
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category.value,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong!. Please try again later.';
      });
    }
  }

  Future<void> _refresh() async {
    _error = null;
    _loadItem();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Refreshed',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Saved',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('$baseUrl', 'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(context) {
    Widget content = Center(
      child: Text(
        'No items added yet. This list is empty',
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .color!
                  .withOpacity(0.5),
            ),
      ),
    );

    if (_isLoading) {
      content = const Padding(
        padding: EdgeInsets.only(right: 60, left: 60),
        child: Center(
          child: CircularProgressIndicator(),
          // child: LinearProgressIndicator(),
        ),
      );
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          final item = _groceryItems[index];
          return Dismissible(
            key: ValueKey(item.id),
            onDismissed: (direction) {
              _removeItem(item);
            },
            background: Container(
              color: Theme.of(context).colorScheme.error.withOpacity(.5),
            ),
            child: ListTile(
              onTap: () {},
              leading: Container(
                width: 24,
                height: 24,
                color: item.category.color,
              ),
              title: Text(
                item.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                item.quantity.toString(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .color!
                    .withOpacity(0.5),
              ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Groceries',
        ),
        actions: [
          ElevatedButton.icon(
            label: const Text('Add'),
            onPressed: _addItem,
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      // body: content,
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

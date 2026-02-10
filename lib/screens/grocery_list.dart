import 'dart:convert';
import "package:flutter/material.dart";

import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/screens/new_item.dart';
import 'package:shopping_list/models/grocery_item.dart';

class GroceryListScreen extends StatefulWidget{
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https("shopping-list-ed003-default-rtdb.firebaseio.com", "shopping-list-app.json");
    try {
    final response = await http.get(url);

    if(response.statusCode >= 400) {
      setState(() {
        _error = "Failed to fetch items. Please try again later.";        
      });
    }

    if(response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> itemsData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for(final item in itemsData.entries) {
        final category = categories.entries.firstWhere(
          (catItem) => catItem.value.title == item.value['category']
        ).value;

        loadedItems.add(
          GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
           category: category,
           )
        );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
    } catch(error) {
      setState(() {
        _error = "Something went wrong. Please try again later.";
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen()));

    if (newItem == null){
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https("shopping-list-ed003-default-rtdb.firebaseio.com", "shopping-list-app/${item.id}.json");

    final response  = await http.delete(url);

    if (response.statusCode >= 400) {
      // optional add error message

      setState(() {
        _groceryItems.insert(index, item);
      });
    }
    
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text("Add some items to fill your list."),);

    // show loading when we are waiting for items to show up
    if(_isLoading){
      content = Center(child:
      CircularProgressIndicator()
      ,);
    }

    if(_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (BuildContext ctx, int index) {
          // allow item to be swipeable to remove it
          return Dismissible(
            key: ValueKey(_groceryItems[index].id),
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            child: 
            ListTile(
              leading: Icon(Icons.rectangle, color: _groceryItems[index].category.color,),
              trailing: Text(_groceryItems[index].quantity.toString()),
              title: Text(_groceryItems[index].name),),
          );
          
        });
    }
    if(_error != null) {
      content = Center(child: Text(_error!),);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
        ],
      ),
      // show message if list is empty if not show list of items
      body: 
        content
    );
  }
}
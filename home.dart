import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/categories.dart';
import 'package:shopping_list/data.dart';
import 'package:shopping_list/new_item.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GroceryItem> valuesgot = [];
  var isloading = true;
  String? error;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    load_items();
  }

  void load_items() async {
    final url = Uri.https('shopping-list-3a890-default-rtdb.firebaseio.com',
        'shopping_list.json');
    final response = await http.get(url);
    final Map<String, dynamic> datagot = json.decode(response.body);
    //json.encode converts data into maps and decode does the reverse.
    //we are converting it into the format of GroceryItem
    if (response.statusCode >= 400) {
      setState(() {
        error = 'Error';
      });
    }
    if (response.body == 'null') {
      //firebase specifcally returns a null string but not the boolean value null, it depends from each backend, somemight return 0 or null boolean value or a 404 stauscode or something else.
      //if there are no items in the firebase then we return by setting isloading to false such that we dont see any spinner
      setState(() {
        isloading = false;
      });
      return;
    }
    final List<GroceryItem> loaditems = [];
    for (final x in datagot.entries) {
      final category = categories.entries
          .firstWhere(
            (a) => a.value.title == x.value['category'],
          )
          .value; //firstwhere searches for the first matcing value with the condition and only returns 1 value.
      //entries is an iterable list for further clarity go to yt.
      //categories has 2 values, item and title, we have to find the correct title for each & every item, so we do it inside the for loop.
      loaditems.add(
        GroceryItem(
            id: x.key,
            name: x.value['name'],
            quantity: x.value['quantity'],
            category: category),
      );
    }
    setState(() {
      valuesgot = loaditems;
      isloading = false;
    });
  }

  void additem() async {
    /* final newvalues = */
    final newvalues = await Navigator.of(context).push<GroceryItem>(
      //<> this specifies that the returned future value is either of the type GroceryItem or null
      MaterialPageRoute(
        builder: (ctx) =>
            const NewItem(), //push returns a future datatype that is i.e; newitem.
      ),
    );
    if (newvalues == null) {
      return;
    }

    setState(() {
      valuesgot.add(newvalues);
    });
    load_items(); //when new items are loaded then they are sent to firebase and later recieved from firebase by a user defined fns i.e load_items();
  }

  void removeitem(GroceryItem item) async {
    final index = valuesgot.indexOf(item);
    setState(() {
      valuesgot.remove(item);
    });
    final url = Uri.https('shopping-list-3a890-default-rtdb.firebaseio.com',
        'shopping_list/${item.id}.json');
    //The difference between delete and add is in the url, for delete we specify the unique id i.e item.id to delete the item in firebase.
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        valuesgot.insert(index, item);
      });
    }
  }
  //try {experimental code} catch(error){fallback code when error occurs}

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'No data',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
    if (isloading) {
      content = const Center(
        child: CircularProgressIndicator.adaptive(), //shows a loading spinner
      );
    }
    if (valuesgot.isNotEmpty) {
      content = ListView.builder(
        itemCount: valuesgot.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            var x = valuesgot[index].category;
            var y = valuesgot[index].id;
            var z = valuesgot[index].quantity;
            var v = valuesgot[index].name;
            GroceryItem abc =
                GroceryItem(id: y, name: v, quantity: z, category: x);
            removeitem(valuesgot[index]);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 3),
                content:
                    const Text('value removed'), //${valuesgot[index].category}
                action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      setState(() {
                        valuesgot.insert(index, abc);
                      });
                      load_items();
                    }),
              ),
            );
          },
          key: ValueKey(valuesgot[index].id),
          child: ListTile(
            title: Text(
              valuesgot[index].name,
              style: const TextStyle(color: Colors.black),
            ),
            leading: Container(
              width: 24,
              height: 24,
              color: valuesgot[index].category.color,
            ),
            trailing: Text(
              valuesgot[index].quantity.toString(),
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ),
      );
    }
    if (error != null) {
      content = Center(
        child: Text(error!),
      );
    }
    return Scaffold(
        backgroundColor: Colors.grey,
        appBar: AppBar(
          title: const Text('Groceries'),
          actions: [
            IconButton(
              onPressed: additem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content);
  }
}

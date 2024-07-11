import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:shopping_list/categories.dart';
import 'package:shopping_list/data.dart';
import 'package:http/http.dart'
    as http; //this says that all the data from http.dart must be bundled into as <http>, You can replace http with any other name.

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  var enteredname = '';
  var enteredquantity = 1;
  var selectedcategory = categories[Categories.carbs]!;
  var uuid = const Uuid();
  var isSending = false;
  void resetform() {
    formkey.currentState!.reset();
  }

  final formkey = GlobalKey<
      FormState>(); //<Formstate> represents that the global key is created for the Form() . Formstate is produced by Form() widget.
  /*
Global key is used to access the underlying widgets i.e; deals with internal state 
A key that is unique across the entire app.
-->Reparent means changing the parent.
Global keys uniquely identify elements. Global keys provide access to other objects that are associated with those elements.
Widgets that have global keys reparent their subtrees when they are moved from one location in the tree to another location in the tree.

In order to reparent its subtree, a widget must arrive at its new location in the tree in the same animation frame in which it was removed from its old location in the tree.
Reparenting an Element using a global key is relatively expensive, as this operation will trigger a call to State.deactivate on the associated State and all of its descendants; 
then force all widgets that depends on an InheritedWidget to rebuild.

GlobalKeys should not be re-created on every build. They should usually be long-lived objects owned by a State object.
Creating a new GlobalKey on every build will throw away the state of the subtree associated with the old key and create a new fresh subtree for the new key. 
Besides harming performance, this can also cause unexpected behavior in widgets in the subtree. 
 */
  void saveitem() async {
    if (formkey.currentState!.validate()) {
      /*if formkey.currentState!.validate() returns true only then the value is saved.
      currentstate is never null as it is only initiated when the button is pressed
      .validate() is a method provided by the form widget that will reach out to all the form fields & execute the validator fns.*/

      formkey.currentState!.save(); //saves the entered values
      setState(() {
        isSending = true;
      });

      final url = Uri.https('shopping-list-3a890-default-rtdb.firebaseio.com',
          'shopping_list.json'); //uri is a spl. class that has many fns; one of which is https which creates an URL to the backend.
      //Got url from firebase, we don't have to add https as the https() will automatically add it.
      //The second argument is for the path or subdomain like maps in https://www.google.com/maps, it creates a sub folder in firebase.

      final response = await http.post(
        //Post returns a future value to indicate whether the post is succesfull or not, we can do that by 2 methods
        //1. then() and 2. async() and await()
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'name': enteredname,
            'quantity': enteredquantity,
            'category': selectedcategory.title
          },
        ),
      );
      /* .then((response) {
        //useresponse
      }) */

      /* https.post() requires and url to send data
      Headers are the meta data & body is the data being sent
      We need to send data(body) in the format of headers, then we need to encode our grocery items to a json
      So we use json.encode() to convert data to json.
      we use {} map in json.encode as encode knows how to convert maps to json  */

      if (!context.mounted) {
        return;
        //we want context if it is only part of the screen contex.mounted is false is a widget isn't a part of the screen.
        //If we have widget that isn't part of the screen anymore we return ; and none of the below code is executed.
      }

      final Map<String, dynamic> resData = json.decode(response.body);
      Navigator.of(context).pop(GroceryItem(
          //id: uuid.v4(), we can use this but firebase generates a unique ID for every entry and this uuid.v4() would be of a waste.
          //The unique String is stored as name, so we use resData['name'] to acces it.
          id: resData['name'],
          name: enteredname,
          quantity: enteredquantity,
          category:
              selectedcategory)); //to exit the screen whenever a value is entered.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: formkey,
          //Used to display a form like strucutre
          child: Column(
            children: [
              TextFormField(
                //Can use instead of Text field as it has many form-specific widgets that integrate with the form stucture better.
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: //Validator takes a  fns that validates the input values, If the value is invalid it retuns the user defined string.
                    (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length >=
                          50) /*The value shouldn't be a single letter value [value.trim().length <= 1];Trim() removes the excess space from both the ends*/ {
                    return 'Value length must be between 1 and 50 ';
                  }
                  return null;
                },
                onSaved: (Value) {
                  /* if (Value = null) {
                    return;
                  } this is an alternative for !*/
                  enteredname = Value!;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      //Text feild has no contraints in a row so to keep in limits we use exapanded
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: enteredquantity
                          .toString(), //if the entered value is Null,then initial value is used.
                      validator: //Validator takes a  fns that validates the input values, If the value is invalid it retuns the user defined string.
                          (value) {
                        if (value == null ||
                                value.isEmpty ||
                                int.tryParse(value)! < 0 ||
                                int.tryParse(value)! >
                                    50 //int.tryparse(source) converts a string to a number; if conversion isn't possible it returns null. But ! helps us override that condition.
                            ) {
                          return 'Value  be between 1 and 50';
                        }
                        return null;
                      },
                      onSaved: (Value1) {
                        enteredquantity = int.tryParse(Value1!)!;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    //We can't have nested Rows and colums
                    child: DropdownButtonFormField(
                        //we used dropdownbuttonformfield instead of dropdownbutton due to more easability.
                        items: [
                          for (final x in categories.entries)
                            DropdownMenuItem(
                              value: x //we can even use x.key instead of x.value
                                  .value, //hover the cursor over value & read it budd.
                              //categories is a map and we converted it to a list using .entries
                              child: Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    color: x.value.color,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(x.value.title),
                                  //every map has key:value. So here we are accesing the (x)categories.value.title
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedcategory = value!;
                          });
                        }),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSending == true ? null : resetform,
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: isSending == true
                        ? null
                        : saveitem, //the button will be disabled after clicking once such that multiple HTTPS requests aren't made
                    child: isSending == true
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

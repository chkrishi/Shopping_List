import 'package:shopping_list/categories.dart';

class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
  });

  final String id;
  final String name;
  final int quantity;
  final Category category;
  /* class Category {-->This Category is being used here
  const Category(this.title, this.color);

  final String title;
  final Color color;
} */
}

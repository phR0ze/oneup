import 'package:flutter/material.dart';
import '../../model/category.dart';

class CategoryCreateView extends StatelessWidget {
  const CategoryCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 400, // arbitrary width
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Create a new category', style: textTheme.titleLarge),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: Colors.black),
                  hintStyle:  TextStyle(color: Colors.black45),
                  hintText: 'Enter a name for the new category',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text('Save'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.green),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryEditView extends StatelessWidget {
  const CategoryEditView({super.key, this.category});

  // When category is null we need to create a new category otherwise edit the existing one
  final Category? category;

  @override
  Widget build(BuildContext context) {

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This is a typical dialog.'),
            const SizedBox(height: 15),
            TextButton(
              child: const Text('Close'),
              onPressed: () { Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}

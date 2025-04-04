import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../model/category.dart';
import '../../utils/utils.dart';
import '../widgets/category.dart';
import '../widgets/section.dart';
import 'input.dart';
import 'settings.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var categories = state.categories;

    return Section(title: 'Categories',
      onBack: () => { state.setCurrentView(const SettingsView()) },
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        direction: Axis.horizontal,
        children: categories.map((x) {
          return CategoryWidget(category: x);
        }).toList(),
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('Add Category', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => showDialog<String>(context: context,
            builder: (dialogContext) => InputView(
              title: 'Create a new category',
              inputLabel: 'Category Name',
              buttonName: 'Save',
              onSubmit: (val) {
                addCategory(dialogContext, state, val.trim());
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Add the new category or show a snackbar if it already exists
void addCategory(BuildContext context, AppState state, String name) {
  if (utils.notEmptyAndNoSymbols(context, state, name)) {
    if (!state.addCategory(name)) {
      utils.showSnackBarFailure(context, 'Category "$name" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'Category "$name" created successfully!');
    }
  }
}

// Add the new user or show a snackbar if it already exists
void updateCategory(BuildContext context, AppState state, Category category) {
  if (utils.notEmptyAndNoSymbols(context, state, category.name)) {
    if (!state.updateCategory(category)) {
      utils.showSnackBarFailure(context, 'Category "${category.name}" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'Category "${category.name}" updated successfully!');
    }
  }
}

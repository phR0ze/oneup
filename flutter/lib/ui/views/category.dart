import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appstate.dart';
import '../../model/category_old.dart';
import '../../utils/utils.dart';
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
    var textStyle = Theme.of(context).textTheme.headlineSmall;

    // Categories sorted by name
    var categories = state.categories;

    return Section(title: 'Categories',
      onBack: () => { state.setCurrentView(const SettingsView()) },

      // Categories sorted by name
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, index) {
          var category = categories[index];
          return ListTile(
            leading: Icon(size: 30, Icons.category),
            title: Text(category.name, style: textStyle),
            onTap: () => showDialog<String>(context: context,
              builder: (dialogContext) => InputView(
                title: 'Edit Category',
                inputLabel: 'Category Name',
                buttonName: 'Save',
                onSubmit: (val, [String? _]) {
                  updateCategory(dialogContext, state,
                    category.copyWith(name: val.trim()));
                },
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                state.removeCategory(category.name);
              },
            ),
          );
        },
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
              onSubmit: (val, [String? _]) {
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
  if (utils.notEmptyAndNoSymbols(context, name)) {
    if (!state.addCategory(name)) {
      utils.showSnackBarFailure(context, 'Category "$name" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'Category "$name" created successfully!');
    }
  }
}

// Add the new user or show a snackbar if it already exists
void updateCategory(BuildContext context, AppState state, CategoryOld category) {
  if (utils.notEmptyAndNoSymbols(context, category.name)) {
    if (!state.updateCategory(category)) {
      utils.showSnackBarFailure(context, 'Category "${category.name}" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'Category "${category.name}" updated successfully!');
    }
  }
}

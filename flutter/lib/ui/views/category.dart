import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../model/category.dart';
import '../widgets/category.dart';
import '../widgets/section.dart';
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
          return CategoryWidget(name: x.name);
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
            builder: (dialogContext) => CategoryCreateView(),
          ),
        ),
      ),
    );
  }
}

class CategoryCreateView extends StatefulWidget {
  const CategoryCreateView({super.key});

  @override
  State<CategoryCreateView> createState() => _CategoryCreateViewState();
}

class _CategoryCreateViewState extends State<CategoryCreateView> {
  late TextEditingController categoryFieldController;

  @override
  void initState() {
    super.initState();
    categoryFieldController = TextEditingController();
  }

  @override
  void dispose() {
    categoryFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;

  // This additional scaffold is needed to allow for the snackbar to be shown
  // above the dialog view. It uses the transparent color to be see through.
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Dialog(
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
                  controller: categoryFieldController,
                  autofocus: true, // take the focus immediately
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle:  TextStyle(color: Colors.black45),
                    hintText: 'Enter a name for the new category',
                    border: const OutlineInputBorder(),
                  ),
      
                  // Also support enter key to for adding and closing as well
                  onSubmitted: (val) {
                    addCategory(context, state, val.trim());
                  },
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
      
                    // Ensure that the save button saves and closes
                    onPressed: () {
                      addCategory(context, state, categoryFieldController.text.trim());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
  );
  }
}

// Add the new category or show a snackbar if it already exists
void addCategory(BuildContext context, AppState state, String name) {
  var exp = RegExp(r'[^a-z0-9 ]', caseSensitive: false);

  // Sanitize the category input name first
  if (name.isEmpty || exp.hasMatch(name)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Symbols are not allowed in category names'),
        duration: const Duration(seconds: 2),
      ),
    );
  } else {
    if (!state.addCategory(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$name" already exists!'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

// TODO: Finish edit category dialog view
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

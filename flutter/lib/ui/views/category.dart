import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
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

/// A view for editing the user
class CategoryEditView extends StatefulWidget {
  const CategoryEditView({super.key, required this.category });
  final Category category;

  @override
  State<CategoryEditView> createState() => _CategoryEditViewState();
}

class _CategoryEditViewState extends State<CategoryEditView> {
  late TextEditingController nameCtrlr;

  @override
  void initState() {
    super.initState();
    nameCtrlr = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrlr.dispose();
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
            width: Const.dialogWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Edit Category', style: textTheme.titleLarge),
                  SizedBox(height: 15),
                  TextField(
                    controller: nameCtrlr,
                    autofocus: true, // take the focus immediately
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: TextStyle(color: Colors.black),
                      hintStyle:  TextStyle(color: Colors.black45),
                      hintText: widget.category.name,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (val) {
                      updateCategory(context, state, widget.category.copyWith(name: val.trim()));
                    },
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: Text('Save'),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.green),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        updateCategory(context, state,
                          widget.category.copyWith(name: nameCtrlr.text.trim()));
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/appstate.dart';
import '../../widgets/section.dart';
import '../../widgets/input.dart';
import 'settings.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineSmall;

    return FutureBuilder(
      future: state.getCategories(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var categories = snapshot.data!;
        return Section(title: 'Categories',
          onEnterKey: () => _showAddCategoryDialog(context, state),
          onEscapeKey: () => { state.setCurrentView(const SettingsView()) },
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbVisibility: WidgetStateProperty.all(true),
              trackVisibility: WidgetStateProperty.all(true),
            ),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, index) {
                var category = categories[index];
                return ListTile(
                  leading: Icon(size: 30, Icons.category),
                  title: Text(category.name, style: textStyle),
                  subtitle: Text('Id: ${category.id},  Created: ${category.createdAt.toLocal().toString()},  Updated: ${category.updatedAt.toLocal().toString()}'),
                  onTap: () => showDialog<String>(context: context,
                    builder: (dialogContext) => InputView(
                      title: 'Edit Category',
                      inputLabel: 'Category Name',
                      buttonName: 'Save',
                      initialValue: category.name,
                      onSubmit: (val, [String? _1, int? _2, bool? _3]) async {
                        await state.updateCategory(dialogContext, category.id, val.trim());
                      },
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                          await state.removeCategory(context, category.id);
                        },
                  ),
                );
              },
            ),
          ),
          trailing: Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton(
              child: const Text('Add Category', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () => _showAddCategoryDialog(context, state),
            ),
          ),
        );
      },
    );
  }
}

/// Show a dialog to create a new category
void _showAddCategoryDialog(BuildContext context, AppState state) {
  showDialog<String>(context: context,
    builder: (dialogContext) => InputView(
      title: 'Create a new category',
      inputLabel: 'Name',
      buttonName: 'Save',
      onSubmit: (val, [String? _1, int? _2, bool? _3]) async {
        await state.addCategory(dialogContext, val.trim());
      },
    ),
  );
}

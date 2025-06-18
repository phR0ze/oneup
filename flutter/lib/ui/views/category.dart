import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appstate.dart';
import '../widgets/section.dart';
import 'input.dart';
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
                    initialValue: category.name,
                    onSubmit: (val, [String? _]) async {
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
                  onSubmit: (val, [String? _]) async {
                    await state.addCategory(dialogContext, val.trim());
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

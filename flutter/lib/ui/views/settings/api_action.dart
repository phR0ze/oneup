import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/appstate.dart';
import '../../widgets/section.dart';
import '../../widgets/input.dart';
import 'settings.dart';
import '../../../model/api_action.dart';
import '../../../model/category.dart';

class ApiActionView extends StatelessWidget {
  const ApiActionView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineSmall;

    return FutureBuilder(
      future: Future.wait([
        state.getActions(context),
        state.getCategories(context),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var actions = (snapshot.data as List)[0] as List<ApiAction>;
        var categories = (snapshot.data as List)[1] as List<Category>;

        return Section(title: 'Actions',
          onBack: () => { state.setCurrentView(const SettingsView()) },
          child: ListView.builder(
            itemCount: actions.length,
            itemBuilder: (_, index) {
              var action = actions[index];
              var defaultCategory = categories.firstWhere((c) => c.id == 1);
              var category = categories.firstWhere((c) => c.id == action.categoryId,
                orElse: () => defaultCategory);
              return ListTile(
                leading: const Icon(size: 30, Icons.flash_on),
                title: Text('${action.desc}', style: textStyle),
                subtitle: Text('Value: ${action.value} | Category: ${category.name}'),
                onTap: () => showDialog<String>(context: context,
                  builder: (dialogContext) => InputView(
                    title: 'Edit Action',
                    inputLabel: 'Action Description',
                    inputLabel2: 'Value',
                    buttonName: 'Save',
                    initialValue: action.desc,
                    initialValue2: action.value.toString(),
                    dropdownItems: categories.map((c) => (c.id, c.name)).toList(),
                    dropdownLabel: 'Category',
                    initialDropdownValue: action.categoryId,
                    onSubmit: (val, [String? val2, int? val3]) async {
                      await state.updateAction(dialogContext, action.id, val.trim(),
                        int.parse(val2!), val3!);
                    },
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await state.removeAction(context, action.id);
                  },
                ),
              );
            },
          ),
          trailing: Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton(
              child: const Text('Add Action', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () => showDialog<String>(context: context,
                builder: (dialogContext) => InputView(
                  title: 'Create a new action',
                  inputLabel: 'Description',
                  inputLabel2: 'Value',
                  buttonName: 'Save',
                  dropdownItems: categories.map((c) => (c.id, c.name)).toList(),
                  dropdownLabel: 'Category',
                  initialDropdownValue: categories.first.id,
                  onSubmit: (val, [String? val2, int? val3]) async {
                    await state.addAction(dialogContext, val.trim(), int.parse(val2!), val3!);
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

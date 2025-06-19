import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/appstate.dart';
import '../../widgets/section.dart';
import '../../widgets/input.dart';
import 'settings.dart';

class RoleView extends StatelessWidget {
  const RoleView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineSmall;

    return FutureBuilder(
      future: state.getRoles(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var roles = snapshot.data!;

        return Section(title: 'Roles',
          onEscapeKey: () => state.setCurrentView(const SettingsView()),
          child: ListView.builder(
            itemCount: roles.length,
            itemBuilder: (_, index) {
              var role = roles[index];
              return ListTile(
                leading: const Icon(size: 30, Icons.badge),
                title: Text(role.name, style: textStyle),
                subtitle: Text('Id: ${role.id},  Created: ${role.createdAt.toLocal().toString()},  Updated: ${role.updatedAt.toLocal().toString()}'),

                onTap: () => showDialog<String>(context: context,
                  builder: (dialogContext) => InputView(
                    title: 'Edit Role',
                    inputLabel: 'Role Name',
                    buttonName: 'Save',
                    initialValue: role.name,
                    onSubmit: (val, [String? val2, int? val3]) async {
                      await state.updateRole(dialogContext, role.id, val.trim());
                    },
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await state.removeRole(context, role.id);
                  },
                ),
              );
            },
          ),
          trailing: Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton(
              child: const Text('Add Role', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () => showDialog<String>(context: context,
                builder: (dialogContext) => InputView(
                  title: 'Create a new role',
                  inputLabel: 'Name',
                  buttonName: 'Save',
                  onSubmit: (val, [String? val2, int? val3]) async {
                    await state.addRole(dialogContext, val.trim());
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
import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings/settings.dart';
import 'package:provider/provider.dart';
import '../../../providers/appstate.dart';
import '../../widgets/section.dart';
import '../../widgets/input.dart';

class UserView extends StatelessWidget {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineMedium;

    return FutureBuilder(
      future: state.getUsers(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var users = snapshot.data!;
        return Section(title: 'Users',
          onEnterKey: () => _showAddUserDialog(context, state),
          onEscapeKey: () => state.setCurrentView(const SettingsView()),
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbVisibility: WidgetStateProperty.all(true),
              trackVisibility: WidgetStateProperty.all(true),
            ),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, index) {
                var user = users[index];
                return FutureBuilder(
                  future: state.getUserRoles(context, user.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(
                        leading: Icon(size: 30, Icons.person),
                        title: CircularProgressIndicator(),
                      );
                    }

                    var roles = snapshot.data!;
                    return ListTile(
                      leading: const Icon(size: 30, Icons.person),
                      title: Text(user.username, style: textStyle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user.email}'),
                          Text('Roles: ${roles.map((r) => r.name).join(", ")}'),
                        ],
                      ),
                      onTap: () => showDialog<String>(context: context,
                        builder: (dialogContext) => InputView(
                          title: 'Edit User',
                          inputLabel: 'User Name',
                          inputLabel2: 'Email', 
                          buttonName: 'Save',
                          initialValue: user.username,
                          initialValue2: user.email,
                          onSubmit: (val, [String? val2, int? _]) async {
                            await state.updateUser(dialogContext,
                              user.copyWith(username: val.trim(), email: val2!.trim()));
                          },
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await state.removeUser(context, user.id);
                        },
                      ),
                    );
                  }
                );
              },
            ),
          ),
          trailing: Padding(
            padding: const EdgeInsets.all(10),
            child: TextButton(
              child: const Text('Create new user', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () => _showAddUserDialog(context, state),
            ),
          ),
        );
      },
    );
  }
}

/// Show a dialog to create a new user
void _showAddUserDialog(BuildContext context, AppState state) {
  showDialog<String>(context: context,
    builder: (dialogContext) => InputView(
      title: 'Create a new user',
      inputLabel: 'Username',
      inputLabel2: 'Email',
      buttonName: 'Save',
      onSubmit: (val, [String? val2, int? _]) async {
        await state.addUser(dialogContext, val.trim(), val2!.trim());
      },
    ),
  );
}

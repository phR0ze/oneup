import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../model/user.dart';
import '../../utils/utils.dart';
import '../widgets/section.dart';
import 'input.dart';

class UserView extends StatelessWidget {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineMedium;

    // Users sorted by name
    var users = state.users;
    users.sort((x, y) => x.name.compareTo(y.name));

    return Section(title: 'Users',
      onBack: () => { state.setCurrentView(const SettingsView()) },

      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, index) {
          var user = users[index];
          return ListTile(
            leading: const Icon(size: 30, Icons.person),
            title: Text(user.name, style: textStyle),
            onTap: () => showDialog<String>(context: context,
              builder: (dialogContext) => InputView(
                title: 'Edit User',
                inputLabel: 'User Name',
                buttonName: 'Save',
                onSubmit: (val) {
                  updateUser(dialogContext, state,
                    user.copyWith(name: val.trim()));
                },
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                state.removeUser(user.name);
              },
            ),
          );
        },
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('Create new user', style: TextStyle(fontSize: 18)),
          
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => showDialog<String>(context: context,
            builder: (dialogContext) => InputView(
              title: 'Create a new user',
              inputLabel: 'User Name',
              buttonName: 'Save',
              onSubmit: (val) {
                addUser(dialogContext, state, val.trim());
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Add the new user or show a snackbar if it already exists
void addUser(BuildContext context, AppState state, String name) {
  if (utils.notEmptyAndNoSymbols(context, state, name)) {
    var user = User(state.users.length + 1, name, []);

    if (!state.addUser(user)) {
      utils.showSnackBarFailure(context, 'User "$name" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'User "$name" created successfully!');
    }
  }
}

// Add the new user or show a snackbar if it already exists
void updateUser(BuildContext context, AppState state, User user) {
  if (utils.notEmptyAndNoSymbols(context, state, user.name)) {
    if (!state.updateUser(user)) {
      utils.showSnackBarFailure(context, 'User "${user.name}" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'User "${user.name}" updated successfully!');
    }
  }
}

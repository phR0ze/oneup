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

    return FutureBuilder(
      future: state.getUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var users = snapshot.data!;
        return Section(title: 'Users',
          onBack: () => { state.setCurrentView(const SettingsView()) },

          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) {
              var user = users[index];
              return ListTile(
                leading: const Icon(size: 30, Icons.person),
                title: Text(user.username, style: textStyle),
                onTap: () => showDialog<String>(context: context,
                  builder: (dialogContext) => InputView(
                    title: 'Edit User',
                    inputLabel: 'User Name',
                    buttonName: 'Save',
                    onSubmit: (val) {
                      updateUser(dialogContext, state,
                        user.copyWith(username: val.trim()));
                    },
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    removeUser(context, state, user);
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
                  onSubmit: (val) async {
                    addUser(dialogContext, state, val.trim());
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

// Add the new user or show a snackbar if it already exists
void addUser(BuildContext context, AppState state, String username) {
  if (utils.notEmptyAndNoSymbols(context, state, username)) {
    try {
      state.addUser(username, "");
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'User "$username" created successfully!');
    } catch (error) {
      utils.showSnackBarFailure(context, 'User "$username" creation failed: $error');
    };
  }
}

// Add the new user or show a snackbar if it already exists
void updateUser(BuildContext context, AppState state, User user) {
  if (utils.notEmptyAndNoSymbols(context, state, user.username)) {
    try {
      state.updateUser(user.id, user.username, "");
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'User "${user.username}" updated successfully!');
    } catch (error) {
      utils.showSnackBarFailure(context, 'User "${user.username}" update failed: $error');
    };
  }
}

// Delete the user or show a snackbar if it fails
void removeUser(BuildContext context, AppState state, User user) {
  try {
    state.removeUser(user.id);
    Navigator.pop(context);
    utils.showSnackBarSuccess(context, 'User "${user.username}" deleted successfully!');
  } catch (error) {
    utils.showSnackBarFailure(context, 'User "${user.username}" deletion failed: $error');
  }
}

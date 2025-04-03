import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
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
      onBack: () => {
        state.setCurrentView(const SettingsView())
      },
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, index) {
          var user = users[index];
      
          return ListTile(
            leading: const Icon(size: 30, Icons.person),
            title: Text(user.name, style: textStyle),
            onTap: () {
              print("User: ${user.name}");
            },
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
  var exp = RegExp(r'[^a-z0-9 ]', caseSensitive: false);

  // Sanitize the category input name first
  if (name.isEmpty || exp.hasMatch(name)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Symbols are not allowed in user names'),
        duration: const Duration(seconds: 2),
      ),
    );
  } else {
    if (!state.addUser(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User"$name" already exists!'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

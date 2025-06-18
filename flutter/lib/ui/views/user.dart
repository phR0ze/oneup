import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../providers/appstate.dart';
import '../widgets/section.dart';
import 'input.dart';

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
          onBack: () => { state.setCurrentView(const SettingsView()) },

          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) {
              var user = users[index];
              return ListTile(
                leading: const Icon(size: 30, Icons.person),
                title: Text(user.username, style: textStyle),
                subtitle: Text('Email: ${user.email}'),
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
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await state.removeUser(context, user.id);
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
                  inputLabel: 'Username',
                  inputLabel2: 'Email',
                  buttonName: 'Save',
                  onSubmit: (val, [String? val2, int? _]) async {
                    await state.addUser(dialogContext, val.trim(), val2!.trim());
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

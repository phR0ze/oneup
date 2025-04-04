import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
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
              showDialog<String>(context: context,
                builder: (dialogContext) => UserEditView(user: user),
              );
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

/// A view for editing the user
class UserEditView extends StatefulWidget {
  const UserEditView({super.key, required this.user });
  final User user;

  @override
  State<UserEditView> createState() => _UserEditViewState();
}

class _UserEditViewState extends State<UserEditView> {
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
                  Text('Edit User', style: textTheme.titleLarge),
                  SizedBox(height: 15),
                  TextField(
                    controller: nameCtrlr,
                    autofocus: true, // take the focus immediately
                    decoration: InputDecoration(
                      labelText: 'User Name',
                      labelStyle: TextStyle(color: Colors.black),
                      hintStyle:  TextStyle(color: Colors.black45),
                      hintText: widget.user.name,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (val) {
                      updateUser(context, state, widget.user.copyWith(name: val.trim()));
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
                        updateUser(context, state,
                          widget.user.copyWith(name: nameCtrlr.text.trim()));
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

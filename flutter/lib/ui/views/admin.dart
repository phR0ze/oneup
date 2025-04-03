import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../widgets/section.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  late TextEditingController passwordCtrlr;

  @override
  void initState() {
    super.initState();
    passwordCtrlr = TextEditingController();
  }

  @override
  void dispose() {
    passwordCtrlr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var titleStyle = Theme.of(context).textTheme.headlineMedium;

    return Section(title: 'Admin',
      onBack: () => {
        state.setCurrentView(const SettingsView())
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 25),
                child: Text('Password', style: titleStyle),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  maxLength: 32,
                  controller: passwordCtrlr,
                  decoration: InputDecoration(
                    labelText: 'Set password',
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle:  TextStyle(color: Colors.black45),
                    hintText: 'Enter a new password for the admin',
                    border: const OutlineInputBorder(),
                  ),
                
                  // Also support enter key to for adding and closing as well
                  onSubmitted: (val) {
                    updatePassword(context, state, val.trim());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('Save', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => {
            updatePassword(context, state, passwordCtrlr.text.trim()),
          }
        ),
      ),
    );
  }
}

/// View to present the user with an admin password dialog to authorize an action.
class AuthorizeView extends StatefulWidget {
  const AuthorizeView({super.key});

  @override
  State<AuthorizeView> createState() => _AuthorizeViewState();
}

class _AuthorizeViewState extends State<AuthorizeView> {
  late TextEditingController passwordCtrlr;

  @override
  void initState() {
    super.initState();
    passwordCtrlr = TextEditingController();
  }

  @override
  void dispose() {
    passwordCtrlr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

  // This additional scaffold is needed to allow for the snackbar to be shown
  // above the dialog view. It uses the transparent color to be see through.
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: 400, // arbitrary width
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Authorize Action', style: textTheme.titleLarge),
                SizedBox(height: 15),
                TextField(
                  controller: passwordCtrlr,
                  autofocus: true, // take the focus immediately
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle:  TextStyle(color: Colors.black45),
                    hintText: 'Enter current admin password',
                    border: const OutlineInputBorder(),
                  ),
      
                  // Also support enter key to for adding and closing as well
                  onSubmitted: (val) {
                    //addCategory(context, state, val.trim());
                  },
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: const Text('Authorize'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
      
                    // Ensure that the save button saves and closes
                    onPressed: () {
                      //addCategory(context, state, passwordCtrlr.text.trim());
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

// Check that the user is authorized to perform the action
bool authorizeAction() {
  return false;
}

// Add the new category or show a snackbar if it already exists
void updatePassword(BuildContext context, AppState state, String name) {
  var exp = RegExp(r'[^a-z0-9 ]', caseSensitive: false);

  // Sanitize the category input name first
  if (name.isEmpty || exp.hasMatch(name)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Blank password is not allowed'),
        duration: const Duration(seconds: 2),
      ),
    );
  } else {
    if (!state.addCategory(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$name" already exists!'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}
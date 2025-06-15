import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/section.dart';
import 'input.dart';
import 'dart:async';

enum _fields {
  password,
}

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  Map<_fields, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controllers.forEach((key, value) {
      value.dispose();
    });
    controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

    var labelStyle = TextStyle(color: Colors.black38, fontSize: 18);
    var floatingLabelStyle = TextStyle(color: Colors.black, fontSize: 20);

    // Dynamically create controllers as needed
    for (var key in _fields.values) {
      if (!controllers.containsKey(key)) {
        controllers[key] = TextEditingController();
      }
      if (key == _fields.password) {
        controllers[key]!.text = state.adminPass;
      }
    }

    return Section(title: 'Admin',
      onBack: () => {
        state.setCurrentView(const SettingsView())
      },
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              maxLength: 32,
              obscureText: true,
              controller: controllers[_fields.password],
              decoration: InputDecoration(
                floatingLabelStyle: floatingLabelStyle,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: 'Password',
                labelStyle: labelStyle,
                hintStyle: labelStyle,
                hintText: 'Enter the password to set for the admin account', 
                border: const OutlineInputBorder(),
              ),

              // Also support enter key
              onSubmitted: (val) {
                updateAdminPassword(context, state, val.trim());
              },
            ),
          ],
        ),
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
            updateAdminPassword(context, state, controllers[_fields.password]!.text.trim())
          },
        ),
      ),
    );
  }
}

// Check that the user is authorized to perform the action
Future<void> authorizeAction(BuildContext context, AppState state) async {
  if (state.isAdminAuthorized()) {
    return;
  }
  final completer = Completer<void>();
  showDialog<String>(context: context,
    builder: (dialogContext) => InputView(
      title: 'Authorize Action',
      inputLabel: 'Admin Password',
      buttonName: 'Authorize',
      obscureText: true,
      onSubmit: (val, [String? _]) async {
        state.login(null, val.trim()).then((_) {
          utils.showSnackBarSuccess(context, 'Login successful!');
          Navigator.pop(context);
          completer.complete();
        }).catchError((error) {
          utils.showSnackBarFailure(context, 'Login failed: $error');
        });
      },
  ));
  return completer.future;
}

// Add the new category or show a snackbar if it already exists
void updateAdminPassword(BuildContext context, AppState state, String password) {
  if (utils.notEmpty(context, password)) {
    state.updateAdminPassword(password);
    state.currentView = const SettingsView();
    utils.showSnackBarSuccess(context, 'Password updated successfully!');
  }
}
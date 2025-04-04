import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/section.dart';
import 'input.dart';

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
                  obscureText: true,
                  controller: passwordCtrlr,
                  decoration: InputDecoration(
                    labelText: 'Set password',
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle:  TextStyle(color: Colors.black45),
                    hintText: 'Enter a new password for the admin',
                    border: const OutlineInputBorder(),
                  ),
                  // Also support enter key
                  onSubmitted: (val) {
                    updateAdminPassword(context, state, val.trim());
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
            updateAdminPassword(context, state, passwordCtrlr.text.trim())
          },
        ),
      ),
    );
  }
}

// Check that the user is authorized to perform the action
void authorizeAction(BuildContext context, AppState state) {
  if (state.isAdminAuthorized) {
    return;
  }
  showDialog<String>(context: context,
    builder: (dialogContext) => InputView(
      title: 'Authorize Action',
      inputLabel: 'Admin Password',
      buttonName: 'Authorize',
      obscureText: true,
      onSubmit: (val) {
        state.adminAuthorize(val.trim());
        if (!state.isAdminAuthorized) {
          utils.showSnackBarFailure(context, 'Invalid password!');
        } else {
          Navigator.pop(context);
        }
      },
  ));
}

// Add the new category or show a snackbar if it already exists
void updateAdminPassword(BuildContext context, AppState state, String password) {
  if (utils.notEmpty(context, state, password)) {
    state.updateAdminPassword(password);
    state.currentView = const SettingsView();
    utils.showSnackBarSuccess(context, 'Password updated successfully!');
  }
}
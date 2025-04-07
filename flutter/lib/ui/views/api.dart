import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/section.dart';
import 'input.dart';

enum _fields {
  address,
  token,
}

class ServerView extends StatefulWidget {
  const ServerView({super.key});

  @override
  State<ServerView> createState() => _ServerViewState();
}

class _ServerViewState extends State<ServerView> {
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
    var titleStyle = Theme.of(context).textTheme.headlineMedium;

    // Dynamically create controllers as needed
    for (var key in _fields.values) {
      if (!controllers.containsKey(key)) {
        controllers[key] = TextEditingController();
      }
    }

    return Section(title: 'API',
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
                child: Text('Address', style: titleStyle),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  maxLength: 32,
                  controller: controllers[_fields.address],
                  decoration: InputDecoration(
                    labelText: 'Server address',
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle:  TextStyle(color: Colors.black45),
                    hintText: 'Enter the DNS name or IP address of the server',
                    border: const OutlineInputBorder(),
                  ),
                  // Also support enter key
                  onSubmitted: (val) {
                    //updateServerPassword(context, state, val.trim());
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 25),
                child: Text('Token', style: titleStyle),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  maxLength: 32,
                  controller: controllers[_fields.token],
                  decoration: InputDecoration(
                    labelText: 'Server token',
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle:  TextStyle(color: Colors.black45),
                    hintText: 'Paste in server token',
                    border: const OutlineInputBorder(),
                  ),
                  // Also support enter key
                  onSubmitted: (val) {
                    updateServerToken(context, state, val.trim());
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
            //updateServerPassword(context, state, passwordCtrlr.text.trim())
          },
        ),
      ),
    );
  }
}

// Add the new category or show a snackbar if it already exists
void updateServerToken(BuildContext context, AppState state, String password) {
  if (utils.notEmpty(context, state, password)) {
    state.updateAdminPassword(password);
    state.currentView = const SettingsView();
    utils.showSnackBarSuccess(context, 'Password updated successfully!');
  }
}
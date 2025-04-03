import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../widgets/section.dart';

class UserView extends StatelessWidget {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var titleStyle = Theme.of(context).textTheme.headlineMedium;

    return Section(title: 'Users',
      onBack: () => {
        state.setCurrentView(const SettingsView())
      },
      child: Text("test"),

      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('Create new user', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => {
            // updateAdminPassword(context, state, passwordCtrlr.text.trim())
          },
        ),
      ),
    );
  }
}

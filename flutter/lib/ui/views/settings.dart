import 'package:flutter/material.dart';
import 'package:oneup/ui/views/today.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../widgets/section.dart';
import 'admin.dart';
import 'category.dart';
import 'user.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var isAdminAuthorized = state.isAdminAuthorized;
    var textStyle = Theme.of(context).textTheme.headlineMedium;

    return Section(title: 'Settings',
      indicator: Icon(
        isAdminAuthorized ? Icons.lock_open : Icons.lock,
        size: 20,
        color: isAdminAuthorized ? Colors.green : Colors.red
      ),
      onBack: () => {
        state.setCurrentView(const TodayView())
      },
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(size: 30, Icons.admin_panel_settings),
            title: Text('Admin', style: textStyle),
            onTap: () {
              authorizeAction(context, state);
              if (isAdminAuthorized) {
                state.setCurrentView(const AdminView());
              }
            },
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.people),
            title: Text('Users', style: textStyle),
            onTap: () {
              authorizeAction(context, state);
              if (isAdminAuthorized) {
                state.setCurrentView(const UserView());
              }
            },
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.category),
            title: Text('Categories', style: textStyle),
            onTap: () {
              authorizeAction(context, state);
              if (isAdminAuthorized) {
                state.setCurrentView(const CategoryView());
              }
            },
          ),
        ],
      ),
      trailing: isAdminAuthorized ? Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('De-authorize', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => {
            state.adminDeauthorize(),
          },
        ),
      ) : null,
    );
  }
}

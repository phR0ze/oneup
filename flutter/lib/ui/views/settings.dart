import 'package:flutter/material.dart';
import 'package:oneup/ui/views/api.dart';
import 'package:provider/provider.dart';
import '../../providers/appstate.dart';
import '../widgets/section.dart';
import 'admin.dart';
import 'category.dart';
import 'range.dart';
import 'user.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

    var textStyle = Theme.of(context).textTheme.headlineMedium;

    return Section(title: 'Settings',
      indicator: Icon(
        state.isAdminAuthorized() ? Icons.lock_open : Icons.lock,
        size: 20,
        color: state.isAdminAuthorized() ? Colors.green : Colors.red
      ),
      onBack: () => {
        state.setCurrentView(const RangeView(range: Range.today))
      },
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(size: 30, Icons.admin_panel_settings),
            title: Text('Admin', style: textStyle),
            onTap: () async {
              await authorizeAction(context, state);
              if (state.isAdminAuthorized()) {
                print('isAdminAuthorized: ${state.isAdminAuthorized()}');
                state.setCurrentView(const AdminView());
              }
            },
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.people),
            title: Text('Users', style: textStyle),
            onTap: () async {
              await authorizeAction(context, state);
              if (state.isAdminAuthorized()) {
                state.setCurrentView(const UserView());
              }
            },
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.category),
            title: Text('Categories', style: textStyle),
            onTap: () async {
              await authorizeAction(context, state);
              if (state.isAdminAuthorized()) {
                state.setCurrentView(const CategoryView());
              }
            },
          ),

          ListTile(
            leading: const Icon(size: 30, Icons.cable),
            title: Text('API', style: textStyle),
            onTap: () async {
              await authorizeAction(context, state);
              if (state.isAdminAuthorized()) {
                state.setCurrentView(const ServerView());
              }
            },
          ),
        ],
      ),
      trailing: state.isAdminAuthorized() ? Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('De-authorize', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => {
            state.deauthorize(),
          },
        ),
      ) : null,
    );
  }
}

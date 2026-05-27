import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings/api.dart';
import 'package:oneup/ui/views/settings/profile.dart';
import 'package:provider/provider.dart';
import '../../../providers/appstate.dart';
import '../../../utils/utils.dart';
import '../../widgets/section.dart';
import 'admin.dart';
import 'action.dart';
import 'category.dart';
import 'role.dart';
import '../range.dart';
import 'user.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    final isAdmin = state.isAdminAuthorized();
    final mobile = utils.isMobile(MediaQuery.of(context).size.width);
    var textStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: mobile ? 21 : null);

    return Section(title: 'Settings',
      indicator: Icon(
        isAdmin ? Icons.lock_open : Icons.lock,
        size: 20,
        color: isAdmin ? Colors.green : Colors.red
      ),
      onEscapeKey: () => {
        state.setCurrentView(const RangeView(range: Range.today))
      },
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(size: 30, Icons.manage_accounts),
            title: Text('Profile', style: textStyle),
            onTap: () => state.setCurrentView(const ProfileView()),
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.admin_panel_settings),
            title: Text('Admin', style: textStyle),
            onTap: () async {
              await authorizeAction(context, state);
              if (state.isAdminAuthorized()) {
                state.setCurrentView(const AdminView());
              }
            },
          ),
          if (isAdmin) ListTile(
            leading: const Icon(size: 30, Icons.people),
            title: Text('Users', style: textStyle),
            onTap: () => state.setCurrentView(const UserView()),
          ),
          if (isAdmin) ListTile(
            leading: const Icon(size: 30, Icons.badge),
            title: Text('Roles', style: textStyle),
            onTap: () => state.setCurrentView(const RoleView()),
          ),
          if (isAdmin) ListTile(
            leading: const Icon(size: 30, Icons.flash_on),
            title: Text('Actions', style: textStyle),
            onTap: () => state.setCurrentView(const ActionView()),
          ),
          if (isAdmin) ListTile(
            leading: const Icon(size: 30, Icons.category),
            title: Text('Categories', style: textStyle),
            onTap: () => state.setCurrentView(const CategoryView()),
          ),
          if (isAdmin) ListTile(
            leading: const Icon(size: 30, Icons.cable),
            title: Text('API', style: textStyle),
            onTap: () => state.setCurrentView(const ServerView()),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: Text(isAdmin ? 'De-authorize' : 'Authorize',
            style: TextStyle(fontSize: mobile ? 14 : 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(isAdmin ? Colors.red : Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () async {
            if (isAdmin) {
              state.deauthorize();
            } else {
              await authorizeAction(context, state);
            }
          },
        ),
      ),
    );
  }
}

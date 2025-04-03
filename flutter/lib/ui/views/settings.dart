import 'package:flutter/material.dart';
import 'package:oneup/ui/views/today.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../widgets/section.dart';
import 'admin.dart';
import 'category.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    var textStyle = Theme.of(context).textTheme.headlineMedium;
    var state = context.watch<AppState>();

    return Section(title: 'Settings',
      onBack: () => {
        state.setCurrentView(const TodayView())
      },
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(size: 30, Icons.admin_panel_settings),
            title: Text('Admin', style: textStyle),
            onTap: () {
              state.setCurrentView(const AdminView());
            },
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.people),
            title: Text('Users', style: textStyle),
          ),
          ListTile(
            leading: const Icon(size: 30, Icons.category),
            title: Text('Categories', style: textStyle),
            onTap: () {
              state.setCurrentView(const CategoryView());
            },
          ),
        ],
      ),
    );
  }
}

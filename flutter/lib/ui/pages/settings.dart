import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // var state = context.watch<AppState>();
    // var categories = state.categories;

    return ListView(
      children: <Widget>[
        Text("Settings Page"),
      ],
    );
  }
}

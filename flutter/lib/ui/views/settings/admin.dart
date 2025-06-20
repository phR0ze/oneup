import 'package:flutter/material.dart';
import 'package:oneup/ui/views/settings/settings.dart';
import 'package:provider/provider.dart';
import '../../../providers/appstate.dart';
import '../../widgets/section.dart';
import '../../widgets/input.dart';
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
  late FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode();
    // Focus the password field after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    controllers.forEach((key, value) {
      value.dispose();
    });
    controllers.clear();
    _passwordFocusNode.dispose();
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
    }

    return Section(title: 'Admin',
      onEnterKey: () async {
        await state.updateAdminPassword(context, controllers[_fields.password]!.text.trim(),
          () => state.setCurrentView(const SettingsView())
        );
      },
      onEscapeKey: () => {
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
              textInputAction: TextInputAction.done,
              focusNode: _passwordFocusNode,
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
          onPressed: () async {
            await state.updateAdminPassword(context, controllers[_fields.password]!.text.trim(),
              () => state.setCurrentView(const SettingsView())
            );
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
  await showDialog<String>(context: context,
    builder: (dialogContext) => InputView(
      title: 'Authorize Action',
      inputLabel: 'Admin Password',
      buttonName: 'Authorize',
      obscureText: true,
      onSubmit: (val, [String? _1, int? _2]) async {
        await state.login(dialogContext, null, val.trim());
      },
  ));
}

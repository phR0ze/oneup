import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oneup/ui/views/settings/settings.dart';
import '../../../providers/appstate.dart';
import '../../../utils/utils.dart';
import '../../widgets/section.dart';

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
    var labelStyle = TextStyle(color: Colors.black38, fontSize: 18);
    var floatingLabelStyle = TextStyle(color: Colors.black, fontSize: 20);

    // Dynamically create controllers as needed
    for (var key in _fields.values) {
      if (!controllers.containsKey(key)) {
        controllers[key] = TextEditingController();
      }
      if (key == _fields.address) {
        controllers[key]!.text = state.apiAddress;
      }
      if (key == _fields.token) {
        // controllers[key]!.text = state.apiToken;
      }
    }

    return Section(title: 'API',
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
              controller: controllers[_fields.address],
              decoration: InputDecoration(
                floatingLabelStyle: floatingLabelStyle,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: 'Server address',
                labelStyle: labelStyle,
                hintStyle: labelStyle,
                hintText: 'Enter the DNS name or IP address of the server',
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              maxLines: 10,
              minLines: 7,
              controller: controllers[_fields.token],
              decoration: InputDecoration(
                floatingLabelStyle: floatingLabelStyle,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: 'Server token',
                labelStyle: labelStyle,
                hintText: 'Paste in server token generated by server cli',
                hintStyle: labelStyle,
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
          onPressed: () {
            updateApiValues(context, state,
              controllers[_fields.address]!.text.trim(),
              controllers[_fields.token]!.text.trim()
            );
          },
        ),
      ),
    );
  }
}

// TODO: Update the server address in the app state
void updateApiValues(BuildContext context, AppState state, String address, String token) {
  if (!utils.notEmpty(context, token)) {
    return;
  }
}
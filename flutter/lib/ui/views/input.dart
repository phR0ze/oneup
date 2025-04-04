import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../const.dart';
import '../../utils/utils.dart';

/// View to present the user with an admin password dialog to authorize an action.
class InputView extends StatefulWidget {
  const InputView({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.buttonName,
    required this.onSubmit,
    this.obscureText = false,
  });

  /// The [title] for the input view
  final String title;

  /// The [inputLabel] for the input field
  final String inputLabel;

  /// The [buttonName] for the button
  final String buttonName;

  /// The [onSubmit] callback used to submit the input
  final Function(String) onSubmit;

  /// The [obscureText] flag to obscure the text input
  final bool obscureText;

  @override
  State<InputView> createState() => _InputViewState();
}

class _InputViewState extends State<InputView> {
  late TextEditingController inputCtrlr;

  @override
  void initState() {
    super.initState();
    inputCtrlr = TextEditingController();
  }

  @override
  void dispose() {
    inputCtrlr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

  // This additional scaffold is needed to allow for the snackbar to be shown
  // above the dialog view. It uses the transparent color to be see through.
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: Const.dialogWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                // Title
                Text(widget.title, style: textTheme.titleLarge),
                SizedBox(height: 15),

                // Input controller
                // Set to take the focus immediately and thus is the KeyEvent handler
                Focus(
                  onKeyEvent: (node, event) {
                      return utils.dismissDialogOnEscapeKey(context, event);
                  },

                  // The actual text field
                  child: TextField(
                    controller: inputCtrlr,
                    autofocus: true, // take the focus immediately
                    obscureText: widget.obscureText,
                    decoration: InputDecoration(
                      labelText: widget.inputLabel,
                      labelStyle: TextStyle(color: Colors.black),
                      hintStyle:  TextStyle(color: Colors.black45),
                      hintText: widget.inputLabel,
                      border: const OutlineInputBorder(),
                    ),
                        
                    // Also support enter key to for adding and closing as well
                    onSubmitted: (val) {
                      widget.onSubmit(val.trim());
                    },
                  ),
                ),
                const SizedBox(height: 15),

                // Action buttons at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    // Cancel button
                    TextButton(
                      child: Text('Cancel'),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 5),

                    // Action button
                    TextButton(
                      child: Text(widget.buttonName),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.green),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      onPressed: () {
                        widget.onSubmit(inputCtrlr.text.trim());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
  );
  }
}

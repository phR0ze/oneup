import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../const.dart';

/// View to present the user with inputs and an accept button.
class InputView extends StatefulWidget {
  const InputView({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.buttonName,
    required this.onSubmit,
    this.obscureText = false,
    this.inputLabel2,
    this.obscureText2 = false,
  });

  /// The [title] for the input view
  final String title;

  /// The [inputLabel] for the input field
  final String inputLabel;

  /// The [buttonName] for the button
  final String buttonName;

  /// The [onSubmit] callback used to submit the input
  final Function(String, [String?]) onSubmit;

  /// The [obscureText] flag to obscure the text input
  final bool obscureText;

  /// The optional [inputLabel2] for the second input field
  final String? inputLabel2;

  /// The [obscureText2] flag to obscure the second text input
  final bool obscureText2;

  @override
  State<InputView> createState() => _InputViewState();
}

class _InputViewState extends State<InputView> {
  late TextEditingController inputCtrlr;
  late TextEditingController inputCtrlr2;
  late FocusNode focusNode1;
  late FocusNode focusNode2;

  @override
  void initState() {
    super.initState();
    inputCtrlr = TextEditingController();
    inputCtrlr2 = TextEditingController();
    focusNode1 = FocusNode();
    focusNode2 = FocusNode();
  }

  @override
  void dispose() {
    inputCtrlr.dispose();
    inputCtrlr2.dispose();
    focusNode1.dispose();
    focusNode2.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.inputLabel2 != null) {
      widget.onSubmit(inputCtrlr.text.trim(), inputCtrlr2.text.trim());
    } else {
      widget.onSubmit(inputCtrlr.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // This additional scaffold is needed to allow for the snackbar to be shown
    // above the dialog view. It uses the transparent color to be see through.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        },
        child: Dialog(
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

                  // First Input controller
                  TextField(
                    controller: inputCtrlr,
                    focusNode: focusNode1,
                    autofocus: true,
                    obscureText: widget.obscureText,
                    decoration: InputDecoration(
                      labelText: widget.inputLabel,
                      labelStyle: TextStyle(color: Colors.black),
                      hintStyle: TextStyle(color: Colors.black45),
                      hintText: widget.inputLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  if (widget.inputLabel2 != null) ...[
                    const SizedBox(height: 15),
                    // Second Input controller
                    TextField(
                      controller: inputCtrlr2,
                      focusNode: focusNode2,
                      obscureText: widget.obscureText2,
                      decoration: InputDecoration(
                        labelText: widget.inputLabel2,
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black45),
                        hintText: widget.inputLabel2,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ],
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
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


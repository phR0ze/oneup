import 'package:flutter/material.dart';
import '../../const.dart';
import '../../utils/utils.dart';

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
    this.initialValue,
    this.initialValue2,
    this.dropdownItems,
    this.dropdownLabel,
    this.initialDropdownValue,
    this.checkboxLabel,
    this.initialCheckboxValue,
  });

  /// The [title] for the input view
  final String title;

  /// The [inputLabel] for the input field
  final String inputLabel;

  /// The [buttonName] for the button
  final String buttonName;

  /// The [onSubmit] callback used to submit the input
  final Function(String, [String?, int?, bool?]) onSubmit;

  /// The [obscureText] flag to obscure the text input
  final bool obscureText;

  /// The optional [inputLabel2] for the second input field
  final String? inputLabel2;

  /// The [obscureText2] flag to obscure the second text input
  final bool obscureText2;

  /// The optional [initialValue] for the first input field
  final String? initialValue;

  /// The optional [initialValue2] for the second input field
  final String? initialValue2;

  /// The optional list of dropdown items as tuples of (id, label)
  final List<(int, String)>? dropdownItems;

  /// The optional label for the dropdown
  final String? dropdownLabel;

  /// The optional initial value for the dropdown
  final int? initialDropdownValue;

  /// The optional label for the checkbox
  final String? checkboxLabel;

  /// The optional initial value for the checkbox
  final bool? initialCheckboxValue;

  @override
  State<InputView> createState() => _InputViewState();
}

class _InputViewState extends State<InputView> {
  late TextEditingController inputCtrlr;
  late TextEditingController inputCtrlr2;
  late FocusNode viewFocusNode;
  int? selectedDropdownValue;
  bool? checkboxValue;

  @override
  void initState() {
    super.initState();
    inputCtrlr = TextEditingController(text: widget.initialValue);
    inputCtrlr2 = TextEditingController(text: widget.initialValue2);
    viewFocusNode = FocusNode();
    selectedDropdownValue = widget.initialDropdownValue;
    checkboxValue = widget.initialCheckboxValue;
  }

  @override
  void dispose() {
    inputCtrlr.dispose();
    inputCtrlr2.dispose();
    viewFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    var val2 = null;
    if (widget.inputLabel2 != null) {
      val2 = inputCtrlr2.text.trim();
    }
    if (selectedDropdownValue != null) {
      widget.onSubmit(inputCtrlr.text.trim(), val2, selectedDropdownValue, checkboxValue);
    } else {
      widget.onSubmit(inputCtrlr.text.trim(), val2, null, checkboxValue);
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
        focusNode: viewFocusNode,
        onKeyEvent: (event) {
          utils.dismissDialogOnEscapeKey(context, event);
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
                  if (widget.dropdownItems != null) ...[
                    const SizedBox(height: 15),
                    // Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedDropdownValue,
                      decoration: InputDecoration(
                        labelText: widget.dropdownLabel ?? 'Select an option',
                        labelStyle: TextStyle(color: Colors.black),
                        border: const OutlineInputBorder(),
                      ),
                      items: widget.dropdownItems!.map((item) {
                        return DropdownMenuItem<int>(
                          value: item.$1,
                          child: Text(item.$2),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDropdownValue = value;
                        });
                      },
                    ),
                  ],
                  if (widget.checkboxLabel != null) ...[
                    const SizedBox(height: 15),
                    // Checkbox
                    CheckboxListTile(
                      title: Text(widget.checkboxLabel!),
                      value: checkboxValue ?? false,
                      onChanged: (value) {
                        setState(() {
                          checkboxValue = value;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
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


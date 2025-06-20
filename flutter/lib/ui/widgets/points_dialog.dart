import 'package:flutter/material.dart';
import '../../const.dart';
import '../../utils/utils.dart';
import 'animated_button.dart';

/// Dialog to present the user with points adjustment buttons and a total display.
class PointsDialog extends StatefulWidget {
  const PointsDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.initialTotal = 0,
  });

  /// The [title] for the dialog
  final String title;

  /// The [onSave] callback used when the user clicks Save
  final Function(int) onSave;

  /// The [initialTotal] for the total points display
  final int initialTotal;

  @override
  State<PointsDialog> createState() => _PointsDialogState();
}

class _PointsDialogState extends State<PointsDialog> {
  late TextEditingController totalController;
  late FocusNode viewFocusNode;

  @override
  void initState() {
    super.initState();
    totalController = TextEditingController(text: widget.initialTotal.toString());
    viewFocusNode = FocusNode();
  }

  @override
  void dispose() {
    totalController.dispose();
    viewFocusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    final total = int.parse(totalController.text);
    widget.onSave(total);
    Navigator.pop(context);
  }

  void _updateTotal(int value) {
    final currentTotal = int.parse(totalController.text);
    final newTotal = currentTotal + value;
    
    // Limit the value to -999 to 999 to display it in the text field properly
    final limitedTotal = newTotal.clamp(-999, 999);
    
    setState(() {
      totalController.text = limitedTotal.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KeyboardListener(
        focusNode: viewFocusNode,
        autofocus: true,
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
                  const SizedBox(height: 20),

                  // Total display
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                      child: TextField(
                        controller: totalController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Points adjustment buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedButton(
                          text: '+1',
                          fgColor: Colors.white,
                          bgColor: Colors.green,
                          padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                          onTap: () => _updateTotal(1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedButton(
                          text: '+5',
                          fgColor: Colors.white,
                          bgColor: Colors.green,
                          padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                          onTap: () => _updateTotal(5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedButton(
                          text: '-1',
                          fgColor: Colors.white,
                          bgColor: Colors.red,
                          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                          onTap: () => _updateTotal(-1),
                        ),
                      ),
                      AnimatedButton(
                        text: '-5',
                        fgColor: Colors.white,
                        bgColor: Colors.red,
                        padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                        onTap: () => _updateTotal(-5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action buttons at the bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
                      TextButton(
                        child: const Text('Cancel'),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.red),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 5),

                      // Save button
                      TextButton(
                        child: const Text('Save'),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.green),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                        ),
                        onPressed: _handleSave,
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
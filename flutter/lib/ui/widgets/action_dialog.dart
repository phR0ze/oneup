import 'package:flutter/material.dart';
import '../../const.dart';
import '../../utils/utils.dart';
import 'animated_button.dart';

/// Dialog to allow the user to create a new action.
/// - The user can specify the action description and the points value
class ActionCreateDialog extends StatefulWidget {
  const ActionCreateDialog({
    super.key,
    required this.title,
    required this.onSave,
  });

  /// The [title] for the dialog
  final String title;

  /// The [onSave] callback used when the user clicks Save
  final Function(String, int) onSave;

  @override
  State<ActionCreateDialog> createState() => _ActionCreateDialogState();
}

class _ActionCreateDialogState extends State<ActionCreateDialog> {
  late TextEditingController descController;
  late TextEditingController totalController;
  bool _isDescriptionValid = false;

  @override
  void initState() {
    super.initState();
    totalController = TextEditingController(text: '0');
    descController = TextEditingController();
    descController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    descController.removeListener(_onDescriptionChanged);
    descController.dispose();
    totalController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    final trimmedText = descController.text.trim();
    setState(() {
      _isDescriptionValid = trimmedText.length >= 5 && trimmedText.length < 20;
    });
  }

  void _handleSave() {
    final desc = descController.text;
    final total = int.parse(totalController.text);
    widget.onSave(desc, total);
    Navigator.pop(context);
  }

  void _updateTotal(int value) {
    final currentTotal = int.parse(totalController.text);
    final newTotal = currentTotal + value;
    
    // Limit the value to -99 to 99 to display it in the text field properly
    final limitedTotal = newTotal.clamp(-99, 99);
    
    setState(() {
      totalController.text = limitedTotal.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap from bubbling up
              child: Focus(
                onKeyEvent: (node, event) {
                  return utils.dismissDialogOnEscapeKey(context, event);
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

                          // Action description field
                          TextField(
                            controller: descController,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: Colors.black),
                              hintStyle: TextStyle(color: Colors.black45),
                              hintText: 'Enter description...',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Total display and increment buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                              
                              // Points adjustment buttons
                              Row(
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
                                  backgroundColor: WidgetStateProperty.all(
                                    _isDescriptionValid ? Colors.green : Colors.grey,
                                  ),
                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                ),
                                onPressed: _isDescriptionValid ? _handleSave : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
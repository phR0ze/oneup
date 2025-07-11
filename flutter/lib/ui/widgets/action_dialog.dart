import 'package:flutter/material.dart';
import '../../const.dart';
import '../../utils/utils.dart';
import 'animated_button.dart';

/// Dialog to allow the user to create a new action.
/// - The user can specify the action description and the points value
class ActionDialog extends StatefulWidget {
  const ActionDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.initialValue = 0,
    this.initialDescription,
  });

  /// The [title] for the dialog
  final String title;

  /// The [onSave] callback used when the user clicks Save
  final Function(String, int) onSave;

  /// The [initialValue] to display in the total controller (defaults to 0)
  final int initialValue;

  /// The [initialDescription] to display in the description field (if provided, makes field non-editable when initialValue > 0)
  final String? initialDescription;

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  late TextEditingController descController;
  late TextEditingController totalController;
  bool _isDescriptionValid = false;
  bool _isTotalValid = false;

  @override
  void initState() {
    super.initState();
    totalController = TextEditingController(text: widget.initialValue.toString());
    descController = TextEditingController(text: widget.initialDescription ?? '');
    descController.addListener(_onDescriptionChanged);
    totalController.addListener(_onTotalChanged);
    
    // Validate initial values to ensure proper validation state
    _onDescriptionChanged();
    _onTotalChanged();
  }

  @override
  void dispose() {
    descController.removeListener(_onDescriptionChanged);
    totalController.removeListener(_onTotalChanged);
    descController.dispose();
    totalController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    final trimmedText = descController.text.trim();
    setState(() {
      _isDescriptionValid = widget.initialValue > 0 ||
        trimmedText.length >= 5 && trimmedText.length < 20;
    });
  }

  void _onTotalChanged() {
    final total = int.tryParse(totalController.text) ?? 0;
    setState(() {
      _isTotalValid = total != 0;
    });
  }

  bool get _isFormValid => _isDescriptionValid && _isTotalValid;

  void _handleSave() {
    final desc = descController.text;
    final total = int.parse(totalController.text);
    widget.onSave(desc, total);
    // Don't need to pop here as the creation of the action is handling the pop
    // on success and keeping it open on failures.
    //Navigator.pop(context);
  }

  void _updateTotal(int value) {
    final currentTotal = int.parse(totalController.text);
    final newTotal = currentTotal + value;
    
    // Limit the value to -99 to 99 to display it in the text field properly
    final limitedTotal = newTotal.clamp(-99, 99);
    
    setState(() {
      totalController.text = limitedTotal.toString();
    });
    
    // Trigger validation after updating the total
    _onTotalChanged();
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
                            autofocus: widget.initialValue == 0,
                            readOnly: widget.initialValue > 0,
                            style: textTheme.titleLarge,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: Colors.black),
                              hintStyle: TextStyle(color: Colors.black45),
                              hintText: widget.initialValue == 0 ? 'Enter description...' : null,
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
                                    _isFormValid ? Colors.green : Colors.grey,
                                  ),
                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                ),
                                onPressed: _isFormValid ? _handleSave : null,
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
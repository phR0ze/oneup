import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../const.dart';

class utils {
  static final symbolsExp = RegExp(r'[^a-z0-9 ]', caseSensitive: false);

  /// Trigger the correct callback based on the handlers specified
  static KeyEventResult onKeys(BuildContext context, KeyEvent event,
    List<(Function(BuildContext, KeyEvent, Function()?), Function()?)> handlers)
  {
    for (var (handler, callback) in handlers) {
      var result = handler(context, event, callback);
      if (result == KeyEventResult.handled) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Trigger the callback when the escape key is pressed
  /// - typically used to navigate back to the previous screen or to dismiss a dialog
  static KeyEventResult onEscapeKey(BuildContext context,
    KeyEvent event, Function()? callback)
  {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      callback?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Trigger the callback when the enter key is pressed
  static KeyEventResult onEnterKey(BuildContext context,
    KeyEvent event, Function()? callback)
 {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      callback?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Dismiss the dialog when the escape key is pressed
  static KeyEventResult dismissDialogOnEscapeKey(BuildContext context, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Show a snackbar failure with a message
  static void showSnackBarFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  /// Show a snackbar success with a message
  static void showSnackBarSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black26,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Calculate the content padding based on the screen size
  static double contentPadding(BoxConstraints constraints) {
    var contentPadding = constraints.maxWidth >= Const.contentWidth ?
      (constraints.maxWidth - Const.contentWidth)/2.0 : Const.contentPadding;

    return contentPadding;
  }

  // Validate empty user input
  static bool notEmpty(BuildContext context, String value) {
    if (value.isEmpty) {
      showSnackBarFailure(context, 'Empty value is not allowed');
      return false;
    }
    return true;
  }

  // Validate user input for symbols
  static bool noSymbols(BuildContext context, String value) {
    if (symbolsExp.hasMatch(value)) {
      showSnackBarFailure(context, 'Symbols and numbers are not allowed');
      return false;
    }
    return true;
  }

  // Validate user input for symbols and empty string
  static bool notEmptyAndNoSymbols(BuildContext context, String value) {
    if (!notEmpty(context, value)) {
      return false;
    }
    if (!noSymbols(context, value)) {
      return false;
    }
    return true;
  }
}
import 'package:flutter/material.dart';

/// A button that animates when hovered over
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.text,
    required this.fgColor,
    required this.bgColor,
    this.padding = const EdgeInsets.all(3),
    this.onTap,
  });

  /// Text to display on the button
  final String text;

  /// Color of the text and button border
  final Color fgColor;

  /// Color of the button background
  final Color bgColor;

  /// Padding around the text
  final EdgeInsets padding;

  /// Callback function when the button is tapped
  final Function()? onTap;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    var textStyle = Theme.of(context).textTheme.headlineSmall!
      .copyWith(color: widget.fgColor, fontSize: 25);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isHover ? widget.fgColor: widget.bgColor, width: 2),
      ),
      child: InkWell(

        // Text in button
        child: Padding(
          padding: widget.padding,
          child: Text(widget.text, style: textStyle),
        ),

        // Notify decoration to change on hover
        onHover: (val) {
          setState(() { isHover = val; });
        },

        // Button action
        onTap: widget.onTap?.call,
      ),
    );
  }
}
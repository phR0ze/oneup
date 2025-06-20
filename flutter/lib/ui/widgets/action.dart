import 'package:flutter/material.dart';
import '../../const.dart';

/// Action and points combination widget that is used in the range view
/// to display the action description and the points for that action.
class ActionWidget extends StatefulWidget {
  const ActionWidget({
    super.key,
    required this.desc,
    required this.points,
    this.backgroundColor,
    this.onTap,
    this.toggle = false,
  });

  /// The action description
  final String desc;

  /// The points for the action
  final int points;

  /// The background color for the points
  final Color? backgroundColor;

  /// Optional callback function that gets called when the widget is tapped
  final VoidCallback? onTap;

  /// Whether the toggle functionality is enabled
  final bool toggle;

  @override
  State<ActionWidget> createState() => _ActionWidgetState();
}

class _ActionWidgetState extends State<ActionWidget> {
  var isHover = false;
  late var backgroundColor;
  late var originalBackgroundColor;
  var isToggled = false;

  @override
  void initState() {
    super.initState();
    backgroundColor = widget.backgroundColor ?? 
      (widget.toggle ? Colors.grey : (widget.points >= 0 ? Colors.green : Colors.red));
    originalBackgroundColor = backgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge!.copyWith(
        color: Colors.white,
    );

    // Animated container for the action which is composed in a row fashion
    final actionRow = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Container for the action description
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              border: Border(
                left: BorderSide(
                  width: 2, 
                  color: isHover ? backgroundColor : Const.pointsBorderColor
                ),
                top: BorderSide(
                  width: 2, 
                  color: isHover ? backgroundColor : Const.pointsBorderColor
                ),
                bottom: BorderSide(
                  width: 2, 
                  color: isHover ? backgroundColor : Const.pointsBorderColor
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
              child: Text(
                widget.desc,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Container for the points value
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(
                  width: 2, 
                  color: isHover ? backgroundColor : Const.pointsBorderColor
                ),
                right: BorderSide(
                  width: 2, 
                  color: isHover ? backgroundColor : Const.pointsBorderColor
                ),
                bottom: BorderSide(
                  width: 2, 
                  color: isHover ? backgroundColor : Const.pointsBorderColor
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
              child: Text(widget.points.toString(), style: textStyle),
            ),
          ),
        ],
      ),
    );

    // Now optionally wrap the action row in a mouse region to show the hover effect
    return widget.onTap != null 
        ? MouseRegion(
            onEnter: (_) => setState(() => isHover = true),
            onExit: (_) => setState(() => isHover = false),
            child: GestureDetector(
              onTap: () {
                // Only perform toggle functionality if toggle is enabled
                if (widget.toggle) {
                  // Toggle background color based on points value
                  setState(() {
                    if (isToggled) {
                      // Return to original color
                      backgroundColor = originalBackgroundColor;
                      isToggled = false;
                    } else {
                      // Set to green for positive points or red for negative points
                      backgroundColor = widget.points >= 0 ? Colors.green : Colors.red;
                      isToggled = true;
                    }
                  });
                }
                
                // Call the original onTap callback if provided
                widget.onTap?.call();
              }, 
              child: actionRow
            ),
          ) 
        : actionRow;
  }
}
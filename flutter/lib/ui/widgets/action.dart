import 'package:flutter/material.dart';
import '../../const.dart';

/// Action and points combination widget that is used in the range view
/// to display the action description and the points for that action.
class ActionWidget extends StatelessWidget {
  const ActionWidget({
    super.key,
    required this.desc,
    required this.points,
    this.backgroundColor = Const.neutralPointsValueBgColor,
    this.onTap,
  });

  /// The action description
  final String desc;

  /// The points for the action
  final int points;

  /// The background color for the points container
  final Color backgroundColor;

  /// Optional callback function that gets called when the widget is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge!.copyWith(
        color: Colors.white,
    );

    final widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            border: Border(
              left: BorderSide(width: 2, color: Const.pointsBorderColor),
              top: BorderSide(width: 2, color: Const.pointsBorderColor),
              bottom: BorderSide(width: 2, color: Const.pointsBorderColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
            child: Text(
              desc,
              style: theme.textTheme.titleLarge!.copyWith(
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(width: 2, color: Const.pointsBorderColor),
              right: BorderSide(width: 2, color: Const.pointsBorderColor),
              bottom: BorderSide(width: 2, color: Const.pointsBorderColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
            child: Text(points.toString(), style: textStyle),
          ),
        ),
      ],
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: widget) : widget;
  }
}
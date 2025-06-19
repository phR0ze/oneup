import 'package:flutter/material.dart';
import '../../const.dart';

/// Action and points combination widget that is used in the range view
/// to display the action description and the points for that action.
class ActionPoints extends StatelessWidget {
  const ActionPoints({
    super.key,
    required this.desc,
    required this.points,
  });

  /// The action description
  final String desc;

  /// The points for the action
  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge!.copyWith(
        color: Colors.white,
    );

    return  Row(
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
            color: Const.neutralPointsValueBgColor,
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
  }
}
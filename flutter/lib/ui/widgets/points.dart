import 'package:flutter/material.dart';
import '../../const.dart';

/// Category and points combination widget
class Points extends StatelessWidget {
  const Points({
    super.key,
    required this.category,
    required this.points,
  });

  /// The category name
  final String category;

  /// The points value
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
              category,
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
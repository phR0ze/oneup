import 'package:flutter/material.dart';
import '../../const.dart';
import '../../state/model/user.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.star});
  final User user;
  final bool star;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointStyle = theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
    );
    final userTitleStyle = theme.textTheme.displayMedium!.copyWith(
      color: Const.userTileTitleColor,
      fontSize: Const.userTileTitleSize,
    );

    return Container(
      //color: Const.userBgColor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Const.userTileBorderColor, width: 2),
        //color: Const.userTileBgColor,
        // boxShadow: [
        //   BoxShadow(
        //     color: Const.userTileShadowColor,
        //     blurRadius: 5.0,
        //     spreadRadius: 1.0,
        //     offset: Offset(0, 3),
        //   ),
        // ],
      ),
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  if (star) Icon(Icons.star_sharp,
                    size: Const.userStarSize,
                    color: Const.userTileStarColor),
                  Text(user.name, style: userTitleStyle),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  // Positive points
                  Card(
                    color: Const.userTilePosPointsBgColor,
                    child: Padding(
                    padding: const EdgeInsets.all(Const.pointCardPadding),
                    child: SizedBox(
                        width: Const.pointCardWidth,
                        child: Center(
                            child: Text(user.points.toString(), style: pointStyle))),
                    )
                  ),

                  // Negative points
                  Card(
                    color: Const.userTileNegPointsBgColor,
                    child: Padding(
                      padding: const EdgeInsets.all(Const.pointCardPadding),
                      child: SizedBox(
                        width: Const.pointCardWidth,
                        child: Center(
                          child: Text(user.points.toString(), style: pointStyle))),
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () {
          print("UserTile: ${user.name} was tapped");
        },
      ),
    );
  }
}

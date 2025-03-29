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
    final displayMedium = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: Const.userBgColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  if (star) Icon(Icons.star_sharp,
                    size: Const.userStarSize,
                    color: Const.userStarColor),
                  Text(user.name, style: displayMedium),
                ],
              ),
              Row(
                children: [
                  // Positive points
                  Card(
                    color: Const.userPosPointsBgColor,
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
                    color: Const.userNegPointsBgColor,
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

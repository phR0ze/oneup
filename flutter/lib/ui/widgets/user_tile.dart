import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../providers/appstate.dart';

/// UserTile is responsible for displaying a user with their points.
/// - includes the user title
/// - aggregate positive and negative points
/// - onTap to trigger the user points editor
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.order,
    required this.pos,
    required this.neg,
    this.total = false,
    this.onTap,
    this.mobile = false,
  });

  /// User to use as the data source
  final String user;

  /// Order of the user in the list, used to display medals
  final int order;

  /// Positive points to display
  final int pos;

  /// Negative points to display
  final int neg;

  /// Total points to display
  final bool total;

  /// Callback used for the onTap event
  final Function()? onTap;

  /// Whether to use mobile-scaled sizing
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointStyle = theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontSize: mobile ? 16 : null,
    );
    final titleStyle = theme.textTheme.displaySmall!.copyWith(
        fontSize: mobile ? 27 : null,
    );
    final avatar = context.watch<AppState>().avatar;

    // Material + Ink ensures InkWell paints its hover/splash effects on a local
    // Material surface rather than the root Scaffold Material. Without this, ink
    // effects bypass any ClipPath ancestors and render above clip boundaries.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Const.userTileBorderRadius),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Const.userTileBorderRadius),
          border: Border.all(color: Const.userTileBorderColor, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Const.userTileBorderRadius),
        child: Row(
          children: [
    
            // User face and star
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.black12, width: 2),
                    ),
                    child: Icon(avatar.icon,
                      size: mobile ? 90 : 120,
                      color: avatar.color,
                    ),
                  ),
                  if (order == 0) Positioned(
                    top: mobile ? -35 : Const.userTileGoldMedalTop,
                    left: mobile ? -35 : Const.userTileGoldMedalLeft,
                    child: Icon(Icons.star,
                      color: const Color.fromARGB(255, 255, 217, 79),
                      size: mobile ? 60 : 80),
                  ),
                  if (order == 1) Positioned(
                    top: mobile ? -30 : Const.userTileSilverMedalTop,
                    left: mobile ? -30 : Const.userTileSilverMedalLeft,
                    child: Icon(Icons.star_sharp,
                      color: const Color.fromARGB(255, 197, 197, 197),
                      size: mobile ? 45 : 60),
                  ),
                  if (order == 2) Positioned(
                    top: mobile ? -26 : Const.userTileBronzeMedalTop,
                    left: mobile ? -26 : Const.userTileBronzeMedalLeft,
                    child: Icon(Icons.star_sharp,
                      color: const Color.fromARGB(255, 202, 135, 110),
                      size: mobile ? 38 : 50),
                  ),
                ],
              ),
            ),
    
            // User name and points
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              
                  // User name
                  Padding(
                    padding: EdgeInsets.only(left: mobile ? 2 : 0),
                    child: Text(user, style: titleStyle),
                  ),
    
                  // Spacer
                  SizedBox(height: 10),
    
                  // User points
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
    
                      // Total points
                      if (total)
                        Card(
                          color: Const.neutralPointsValueBgColor,
                          child: Padding(
                          padding: const EdgeInsets.all(Const.pointCardPadding),
                          child: SizedBox(
                              width: 100,
                              child: Center(
                                  child: Text(pos.toString(), style: pointStyle))),
                          )
                        ),
              
                      // Positive points
                      if (!total)
                        Card(
                          color: Const.posPointsBgColor,
                          child: Padding(
                          padding: const EdgeInsets.all(Const.pointCardPadding),
                          child: SizedBox(
                              width: mobile ? 55 : Const.pointCardWidth,
                              child: Center(
                                  child: Text(pos.toString(), style: pointStyle))),
                          )
                        ),

                      // Negative points
                      if (!total)
                        Card(
                          color: Const.negPointsBgColor,
                          child: Padding(
                            padding: const EdgeInsets.all(Const.pointCardPadding),
                            child: SizedBox(
                              width: mobile ? 55 : Const.pointCardWidth,
                              child: Center(
                                child: Text(neg.toString(), style: pointStyle))),
                          )
                        ),
                    ],
                  ),
                ],
              ),
            ),  
          ],
        ),
    
          // Activate the user points editor
          onTap: onTap?.call,
        ),
      ),
    );
  }
}

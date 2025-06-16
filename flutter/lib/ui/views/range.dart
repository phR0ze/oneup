import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/points.dart';
import '../widgets/user_tile.dart';
import 'points.dart';

/// Track which view is currently being displayed
enum Range {
  today,
  week,
  priorWeek,
}

/// Displays the points for each user in date window.
class RangeView extends StatelessWidget {
  const RangeView({
    super.key,
    required this.range,
  });

  /// User rank view type
  final Range range;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var categories = state.categories;

    // Pull user points data for the given date window then reverse sort
    // users by points so that the highest points are first
    var users = state.users;
    users.sort((x, y) => y.points.fold(0, (a, v) => a + v.value)
      .compareTo(x.points.fold(0, (a, v) => a + v.value)));

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (range == Range.week || range == Range.priorWeek) {
          return utils.navigateOnEscapeKey(context, event,
            () => state.setCurrentView(const RangeView(range: Range.today)));
        } else {
          return KeyEventResult.ignored;
        }
      },
      child: ListView.builder(
        clipBehavior: Clip.none, // don't clip the star over the edge
        itemCount: users.length,
        itemBuilder: (_, index) {
          var user = users[index];
          user.points.sort((x, y) => x.categoryName.compareTo(y.categoryName));
          var pos = user.points.where((x) => x.value > 0).fold(0, (a, v) => a + v.value);
          var neg = user.points.where((x) => x.value < 0).fold(0, (a, v) => a + v.value);
      
          return Padding(
            padding: const EdgeInsets.only(bottom: Const.userTileSpacing),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                
                    // User
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                      child: UserTile(
                        user: user.name,
                        order: user.points.isNotEmpty && index < 3 ? index : -1,
                        pos: pos, neg: neg,
                        onTap: () {
                          state.setCurrentView(PointsView(user: user));
                        }
                      ),
                    ),
      
                    // Brace
                    if (user.points.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 6, 6, 0),
                        child: Image.asset(Const.assetCurlyBraceImage),
                      ),
      
                    // Points
                    if (user.points.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            direction: Axis.horizontal,
      
                            // Get a sum of the points for each category and convert it to a Points widget
                            // lf the sum is not 0.
                            children: categories.map((x) => (
                              x.name,
                              user.points.where((y) => y.categoryId == x.id).fold(0, (a, v) => a + v.value))
                            ).where((x) => x.$2 != 0).map((x) {
                              return Points(category: x.$1, points: x.$2);
                            }).toList(),
                          ),
                        ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

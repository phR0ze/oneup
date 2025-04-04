import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../model/appstate.dart';
import '../widgets/points.dart';
import '../widgets/user_tile.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var users = state.users;
    var categories = state.categories;

    // Reverse sort users by points so that the highest points are first
    users.sort((x, y) => y.points.fold(0, (a, v) => a + v.value)
      .compareTo(x.points.fold(0, (a, v) => a + v.value)));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        clipBehavior: Clip.none, // don't clip the star over the edge
        itemCount: users.length,
        itemBuilder: (_, index) {
          var user = users[index];
          user.points.sort((x, y) => x.categoryName.compareTo(y.categoryName));
      
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
                      child: UserTile(user: user, order: user.points.isNotEmpty && index < 3 ? index : -1),
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

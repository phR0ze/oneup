import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../state/state.dart';
import '../widgets/points.dart';
import '../widgets/user_tile.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var users = state.users;

    // Reverse sort users by points so that the highest points are first
    users.sort((x, y) => y.points.fold(0, (a, v) => a + v.value)
      .compareTo(x.points.fold(0, (a, v) => a + v.value)));

    return ListView.builder(
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
                  UserTile(user: user, order: user.points.isNotEmpty && index < 3 ? index : -1),

                  // Points
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        direction: Axis.horizontal,
                        children: user.points.map((x) {
                          var category = state.categories.firstWhere((y) => y.id == x.categoryId);
                          return Points(category: category.name, points: x.value);
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
    );
  }
}

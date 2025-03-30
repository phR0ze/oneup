import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../state/state.dart';
import '../widgets/user_tile.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var users = state.users;

    // Reverse sort users by points so that the highest points are first
    users.sort((x, y) => y.points.compareTo(x.points));

    return ListView.builder(
      clipBehavior: Clip.none,
      itemCount: users.length,
      itemBuilder: (_, index) {
        var user = users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Const.userTileSpacing),
          child: UserTile(user: user, order: user.points > 0 && index < 3 ? index : -1),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/state.dart';
import '../widgets/user_tile.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var users = state.users;
    users.sort((x, y) => y.points.compareTo(x.points)); // reverse sort

    return Container(
      constraints: BoxConstraints(minWidth: 300, maxWidth: 600),
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, index) {
          var user = users[index];
          return UserTile(user: user, star: user.points > 0 && index == 0);
        },
      ),
    );
  }
}

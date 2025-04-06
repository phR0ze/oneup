import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/user_tile.dart';
import 'input.dart';
import 'today.dart';

class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var users = state.users;

    // Reverse sort users by points so that the highest points are first
    users.sort((x, y) => y.points.fold(0, (a, v) => a + v.value)
      .compareTo(x.points.fold(0, (a, v) => a + v.value)));

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        return utils.navigateOnEscapeKey(context, event,
          () => state.setCurrentView(const TodayView()));
      },
      child: Wrap(
        spacing: 30,
        runSpacing: 30,
        children: () {
          var tiles = <Widget>[];
          for (var i = 0; i < users.length; i++) {
            var user = users[i];
            var points = user.points.fold(0, (a, v) => a + v.value);
      
            tiles.add(
              UserTile(
                user: user.name,
                order: user.points.isNotEmpty && i < 3 ? i : -1,
                pos: points, neg: 0, total: true,
      
                onTap: () => showDialog<String>(context: context,
                  builder: (dialogContext) => InputView(
                    title: 'Cash out Rewards',
                    inputLabel: 'Cash out Amount',
                    buttonName: 'Save',
                    onSubmit: (val) {
                      int? intVal = int.tryParse(val);
                      if (intVal == null || intVal <= 0 || intVal > points) {
                        utils.showSnackBarFailure(context, 'Invalid cash out amount!');
                      } else {
                        state.cashOut(user.id, intVal);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              )
            );
          }
          return tiles;
        }().toList(),
      ),
    );
  }
}
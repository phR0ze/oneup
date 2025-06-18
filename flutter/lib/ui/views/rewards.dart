import 'package:flutter/material.dart';
import 'package:oneup/ui/views/range.dart';
import 'package:provider/provider.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/user_tile.dart';
import '../widgets/input.dart';
import '../../model/user.dart';
import '../../model/points.dart';

class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        return utils.navigateOnEscapeKey(context, event,
          () => state.setCurrentView(const RangeView(range: Range.today)));
      },
      child: FutureBuilder<List<User>>(
        future: state.getUsers(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!;
          return FutureBuilder<List<List<Points>>>(
            future: Future.wait(users.map((u) => state.getPoints(context, u.id, null))),
            builder: (context, pointsSnapshot) {
              if (!pointsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var userPoints = pointsSnapshot.data!;
              // Sort users by points
              var sortedUsers = List.generate(users.length, (i) => (users[i], userPoints[i]));
              sortedUsers.sort((x, y) {
                var xPoints = x.$2.fold(0, (a, v) => a + v.value);
                var yPoints = y.$2.fold(0, (a, v) => a + v.value);
                return yPoints.compareTo(xPoints);
              });

              return Wrap(
                spacing: 30,
                runSpacing: 30,
                children: () {
                  var tiles = <Widget>[];
                  for (var i = 0; i < sortedUsers.length; i++) {
                    var (user, points) = sortedUsers[i];
                    var totalPoints = points.fold(0, (a, v) => a + v.value);
            
                    tiles.add(
                      UserTile(
                        user: user.username,
                        order: totalPoints > 0 && i < 3 ? i : -1,
                        pos: totalPoints,
                        neg: 0,
                        total: true,
                        onTap: () => showDialog<String>(context: context,
                          builder: (dialogContext) => InputView(
                            title: 'Cash out Rewards',
                            inputLabel: 'Cash out Amount',
                            buttonName: 'Save',
                            onSubmit: (val, [String? _1, int? _2]) async {
                              int? intVal = int.tryParse(val);
                              if (intVal == null || intVal <= 0 || intVal > totalPoints) {
                                utils.showSnackBarFailure(context, 'Invalid cash out amount!');
                              } else {
                                await state.cashOut(context, user.id, intVal);
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
              );
            },
          );
        },
      ),
    );
  }
}
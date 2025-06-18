import 'package:flutter/material.dart';
import 'package:oneup/ui/views/range.dart';
import 'package:provider/provider.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/user_tile.dart';
import '../widgets/input.dart';
import '../../model/user.dart';

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
          return FutureBuilder<List<int>>(
            future: Future.wait(users.map((u) => state.getSum(context, u.id, null, null))),
            builder: (context, pointsSnapshot) {
              if (!pointsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Sort users by points
              var userPoints = pointsSnapshot.data!;
              var sortedUsers = List.generate(users.length, (i) => (users[i], userPoints[i]));
              sortedUsers.sort((x, y) {
                return y.$2.compareTo(x.$2);
              });

              return Wrap(
                spacing: 30,
                runSpacing: 30,
                children: () {
                  var tiles = <Widget>[];
                  for (var i = 0; i < sortedUsers.length; i++) {
                    var (user, points) = sortedUsers[i];
            
                    tiles.add(
                      UserTile(
                        user: user.username,
                        order: points > 0 && i < 3 ? i : -1,
                        pos: points,
                        neg: 0,
                        total: true,
                        onTap: () => showDialog<String>(context: context,
                          builder: (dialogContext) => InputView(
                            title: 'Cash out Rewards',
                            inputLabel: 'Cash out Amount',
                            buttonName: 'Save',
                            onSubmit: (val, [String? _1, int? _2]) async {
                              int? intVal = int.tryParse(val);
                              if (intVal == null || intVal <= 0 || intVal > points) {
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
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
        return utils.onEscapeKey(context, event,
          () => state.setCurrentView(const RangeView(range: Range.today)));
      },
      child: FutureBuilder<List<User>>(
        future: state.getUsersWithoutAdminRole(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!;
          return FutureBuilder<List<(User, int)>>(
            future: Future.wait(users.map((u) async {
              final points = await state.getPointsSum(context, u.id, null, null);
              final rewards = await state.getRewardSum(context, u.id, null);
              return (u, points - rewards);
            })),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Sort users by the most points
              var sortedUsers = snapshot.data!;
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
                            onSubmit: (val, [String? _1, int? _2, bool? _3]) async {
                              int? intVal = int.tryParse(val);
                              if (intVal == null || intVal <= 0 || intVal > points) {
                                utils.showSnackBarFailure(context, 'Invalid cash out amount!');
                              } else {
                                await state.cashOut(context, user.id, intVal);
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
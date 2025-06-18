import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/points.dart' as widget;
import '../widgets/user_tile.dart';
import 'today.dart';
import '../../model/user.dart';
import '../../model/points.dart' as model;

/// Track which view is currently being displayed
enum Range {
  today,
  week,
  priorWeek,
}

/// Displays the points for each user in the selected window of time.
class RangeView extends StatelessWidget {
  const RangeView({
    super.key,
    required this.range,
  });

  /// The range of time to display points for
  final Range range;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

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
      child: FutureBuilder<List<User>>(
        future: state.getUsers(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!;
          return FutureBuilder<List<List<model.Points>>>(
            future: Future.wait(users.map((u) => state.getPoints(context, u.id, null, null))),
            builder: (context, pointsSnapshot) {
              if (!pointsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var userPoints = pointsSnapshot.data!;
              // Sort users by points
              var sortedUsers = List.generate(users.length, (i) => (users[i], userPoints[i]));
              sortedUsers.sort((x, y) {
                var xPoints = x.$2.fold(0, (a, v) => a + (v).value);
                var yPoints = y.$2.fold(0, (a, v) => a + (v).value);
                return yPoints.compareTo(xPoints);
              });

              return ListView.builder(
                clipBehavior: Clip.none, // don't clip the star over the edge
                itemCount: sortedUsers.length,
                itemBuilder: (_, index) {
                  var (user, points) = sortedUsers[index];
                  points.sort((x, y) => (x).actionId.compareTo((y).actionId));
                  var pos = points.where((x) => (x).value > 0).fold(0, (a, v) => a + (v).value);
                  var neg = points.where((x) => (x).value < 0).fold(0, (a, v) => a + (v).value);
              
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
                                user: user.username,
                                order: points.isNotEmpty && index < 3 ? index : -1,
                                pos: pos, neg: neg,
                                onTap: () {
                                  state.setCurrentView(TodayView(user: user));
                                }
                              ),
                            ),
                      
                            // Brace
                            if (points.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 6, 6, 0),
                                child: Image.asset(Const.assetCurlyBraceImage),
                              ),
                      
                            // Points
                            if (points.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    direction: Axis.horizontal,
                                    children: points.map((p) => 
                                      widget.Points(category: (p).actionId.toString(), points: p.value)
                                    ).toList(),
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
            },
          );
        },
      ),
    );
  }
}

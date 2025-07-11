import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../model/api_action.dart';
import '../../model/category.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/action_widget.dart' as widget;
import '../widgets/user_tile.dart';
import 'points.dart';
import '../../model/user.dart';
import '../../model/points.dart' as model;

/// Track which view is currently being displayed
enum Range {
  today,
  week,
  priorWeek,
}

/// Displays the points for each user in the selected window of time. This view is responsible for
/// displaying the users in the order of their points, and for displaying the points for each user
/// in the order of their actions i.e. a leader board.
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
          return utils.onEscapeKey(context, event,
            () => state.setCurrentView(const RangeView(range: Range.today)));
        } else {
          return KeyEventResult.ignored;
        }
      },
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          state.getUsersWithoutAdminRole(context),
          state.getActions(context),
          state.getCategories(context),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get the date range based on the selected range
          var now = DateTime.now();
          (DateTime, DateTime)? dateRange;
          switch (range) {
            case Range.today:
              dateRange = (
                DateTime(now.year, now.month, now.day),
                DateTime(now.year, now.month, now.day, 23, 59, 59)
              );
            case Range.week:
              var weekStart = now.subtract(Duration(days: now.weekday - 1));
              dateRange = (
                DateTime(weekStart.year, weekStart.month, weekStart.day),
                DateTime(now.year, now.month, now.day, 23, 59, 59)
              );
            case Range.priorWeek:
              var weekStart = now.subtract(Duration(days: now.weekday - 1));
              var priorWeekStart = weekStart.subtract(const Duration(days: 7));
              dateRange = (
                DateTime(priorWeekStart.year, priorWeekStart.month, priorWeekStart.day),
                DateTime(weekStart.year, weekStart.month, weekStart.day).subtract(const Duration(seconds: 1))
              );
          }

          // Now that we have all users and actions
          var users = snapshot.data![0] as List<User>;
          var actions = snapshot.data![1] as List<ApiAction>;
          var categories = snapshot.data![2] as List<Category>;

          // Get the points for each user within the given date range
          return FutureBuilder<List<List<model.Points>>>(
            future: Future.wait(users.map((u) => state.getPoints(context, u.id, null, dateRange))),
            builder: (context, pointsSnapshot) {
              if (!pointsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Now sort the users by the sum of their points
              var sortedUsers = List.generate(users.length, (i) => (users[i], pointsSnapshot.data![i]));
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

                  // Group points by action and sum their values
                  var groupedPoints = <String, int>{};
                  for (var point in points) {
                    var actionDesc = actions.firstWhere((a) => a.id == point.actionId).desc;
                    groupedPoints[actionDesc] = (groupedPoints[actionDesc] ?? 0) + point.value;
                  }

                  // Sort the grouped points by action description (case-insensitive)
                  var sortedGroupedPoints = groupedPoints.entries.toList()
                    ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

                  // Also calculate the sum of positive and negative points for the user
                  var pos_total = points.where((x) => (x).value > 0).fold(0, (a, v) => a + (v).value);
                  var neg_total = points.where((x) => (x).value < 0).fold(0, (a, v) => a + (v).value);
              
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Const.userTileSpacing),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          
                            // Display the user
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                              child: UserTile(
                                user: user.username,
                                order: points.isNotEmpty && index < 3 ? index : -1,
                                pos: pos_total, neg: neg_total,
                                onTap: () {
                                  state.setCurrentView(PointsView(
                                    user: user,
                                    actions: actions.where((a) => a.approved).toList(),
                                    categories: categories));
                                }
                              ),
                            ),
                      
                            // Display the brace
                            if (groupedPoints.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 6, 6, 0),
                                child: Image.asset(Const.assetCurlyBraceImage),
                              ),
                      
                            // Display the points
                            if (groupedPoints.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    direction: Axis.horizontal,
                                    children: sortedGroupedPoints.map((entry) => 
                                      widget.ActionWidget(
                                        desc: entry.key,
                                        points: entry.value,
                                      )
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

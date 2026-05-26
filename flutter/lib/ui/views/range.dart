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
  custom,
}

/// Displays the points for each user in the selected window of time. This view is responsible for
/// displaying the users in the order of their points, and for displaying the points for each user
/// in the order of their actions i.e. a leader board.
class RangeView extends StatelessWidget {
  const RangeView({
    super.key,
    required this.range,
    this.selectedDate,
  });

  /// The range of time to display points for
  final Range range;

  /// For Range.custom: any date within the desired week
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    final screenWidth = MediaQuery.of(context).size.width;
    final mobile = utils.isMobile(screenWidth);

    // On mobile, right padding lives here (not in layout.dart) so the ListView
    // widget itself reaches the screen edge and the scrollbar appears there.
    final mobileRightPad = mobile ? 44.0 : 0.0;

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (range == Range.week || range == Range.priorWeek || range == Range.custom) {
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
            case Range.custom:
              if (selectedDate != null) {
                var ws = selectedDate!.subtract(Duration(days: selectedDate!.weekday - 1));
                dateRange = (
                  DateTime(ws.year, ws.month, ws.day),
                  DateTime(ws.year, ws.month, ws.day, 23, 59, 59).add(const Duration(days: 6)),
                );
              }
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dateRange != null)
                    Padding(
                      padding: EdgeInsets.only(right: mobileRightPad),
                      child: Text(
                        range == Range.today
                          ? '${_fmtDate(dateRange.$1)}, ${dateRange.$1.year}'
                          : _fmtRange(dateRange.$1, dateRange.$2, range),
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    // ClipPath clips the top edge (stops content scrolling over the date
                    // text) while extending 50px to the left so medal icons can still
                    // overflow into the layout padding without being cut off.
                    child: ClipPath(
                      clipper: const _MedalOverflowClipper(),
                      child: ListView.builder(
                        clipBehavior: Clip.none,
                        // top: 40 reserves space for medal icons — gold medal is
                        // positioned at top:-40 inside the tile's Stack (8px inner
                        // padding), so it lands at y=8 within the ClipPath boundary.
                        padding: EdgeInsets.only(top: 40, right: mobileRightPad),
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
              
                  final userTile = UserTile(
                    user: user.username,
                    order: points.isNotEmpty && index < 3 ? index : -1,
                    pos: pos_total, neg: neg_total,
                    onTap: () {
                      state.setCurrentView(PointsView(
                        user: user,
                        actions: actions.where((a) => a.approved).toList(),
                        categories: categories));
                    }
                  );

                  final actionChips = groupedPoints.isNotEmpty
                    ? Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        direction: Axis.horizontal,
                        children: sortedGroupedPoints.map((entry) =>
                          widget.ActionWidget(desc: entry.key, points: entry.value)
                        ).toList(),
                      )
                    : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Const.userTileSpacing),
                    child: mobile
                      // Mobile: stacked layout, no brace, chips below tile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            userTile,
                            if (actionChips != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: actionChips,
                              ),
                          ],
                        )
                      // Desktop: side-by-side with brace
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                              child: SizedBox(width: 330, child: userTile),
                            ),
                            if (actionChips != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 6, 6, 0),
                                child: Image.asset(Const.assetCurlyBraceImage),
                              ),
                            if (actionChips != null)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: actionChips,
                                ),
                              ),
                          ],
                        ),
                  );
                },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// Clips the ListView at its top edge to prevent items scrolling over the date
// text, while extending 50px left so medal icons can overflow into the layout
// padding without being cut off.
class _MedalOverflowClipper extends CustomClipper<Path> {
  const _MedalOverflowClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(-50, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(-50, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

String _monthAbbr(int m) => const [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
][m];

String _fmtDate(DateTime d) => '${_monthAbbr(d.month)} ${d.day}';

String _fmtRange(DateTime start, DateTime end, Range _) =>
  '${_fmtDate(start)} – ${_fmtDate(end)}, ${start.year}';

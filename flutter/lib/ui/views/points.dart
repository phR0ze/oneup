import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/api_action.dart';
import '../../model/category.dart';
import '../../providers/appstate.dart';
import '../../model/user.dart';
import '../widgets/section.dart';
import '../widgets/action.dart';
import '../widgets/points_dialog.dart';
import 'range.dart';

/// Displays the view responsible for adding points to a user once the user is selected from the
/// range view.
class PointsView extends StatefulWidget {
  const PointsView({ super.key, required this.user, required this.actions,
    required this.categories,
  });

  /// The user to add points to.
  final User user;

  /// All actions to display in the view for selection
  final List<ApiAction> actions;

  /// All categories to display in the view for selection
  final List<Category> categories;

  @override
  State<PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends State<PointsView> {
  Map<String, ApiAction> tappedActions = {};
  int totalPoints = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineMedium;

    // Move "Unspecified" action to the front, keep rest in alphabetical order
    var sortedActions = List<ApiAction>.from(widget.actions);
    var unspecifiedAction = sortedActions.where((action) => action.desc == 'Unspecified').firstOrNull;
    if (unspecifiedAction != null) {
      sortedActions.remove(unspecifiedAction);
      sortedActions.insert(0, unspecifiedAction);
    }

    return Section(title: "${widget.user.username}'s Points",
      onEscapeKey: () => state.setCurrentView(const RangeView(range: Range.today)),

      // ScrollbarTheme allows for always showing the scrollbar when the content is scrollable
      // instead of only showing it when the user scrolls.
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
          trackVisibility: WidgetStateProperty.all(true),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              direction: Axis.horizontal,
              children: sortedActions.map((action) {
                return ActionWidget(
                  desc: action.desc,
                  points: action.value,

                  // Toggle action view state for all actions except unspecified
                  toggle: action.desc != 'Unspecified',

                  // Show points dialog for unspecified and toggle action for others
                  onTap: () => action.desc == 'Unspecified'
                    ? _showUnspecifiedPointsDialog(action) : _toggleAction(action)
                );
              }).toList(),
            ),
          ),
        ),
      ),

      // Trailing portion with the total points and the activate points button
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                  child: Text(
                    totalPoints.toString(),
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                )
              ),
            ),
            Expanded(child: Container()),
            TextButton(
              child: const Text('Activate Points', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {

                // Wait on all the futures to complete before navigating back to the range view
                var futures = <Future<void>>[];

                // Add points to the user for each tapped action
                for (var action in tappedActions.values) {
                  futures.add(state.addPoints(context, widget.user.id, action.id, action.value));
                }
                await Future.wait(futures);

                // Navigate back to the range view
                state.setCurrentView(const RangeView(range: Range.today));
              }
            ),
          ],
        ),
      ),
    );
  }


  /// Show the points adjustment dialog
  void _showUnspecifiedPointsDialog(ApiAction action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PointsDialog(
          title: 'Adjust Points for ${action.desc}',
          initialTotal: action.value,
          onSave: (points) {
            setState(() {
              totalPoints += points;

              // Use the original action to track the points
              var i = widget.actions.indexOf(action);
              var adjustedAction = action.copyWith(value: points);
              widget.actions[i] = adjustedAction;

              // Ensure only a non zero value is added to the tapped actions map
              if (points != 0) {
                tappedActions[action.desc] = adjustedAction;
              } else {
                // Don't want to be adding zero value actions to the tapped actions map
                tappedActions.remove(action.desc);
              }
            });
          },
        );
      },
    );
  }

  /// Add or remove the action from the tapped actions map
  void _toggleAction(ApiAction action) {
    setState(() {
      if (tappedActions.containsKey(action.desc)) {
        tappedActions.remove(action.desc);
        totalPoints -= action.value;
      } else {
        tappedActions[action.desc] = action;
        totalPoints += action.value;
      }
    });
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/api_action.dart';
import '../../model/category.dart';
import '../../providers/appstate.dart';
import '../../model/user.dart';
import '../widgets/section.dart';
import '../widgets/action_widget.dart';
import '../widgets/action_dialog.dart';
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

    return Section(title: "${widget.user.username}'s Points",
      onEscapeKey: () => state.setCurrentView(const RangeView(range: Range.today)),

      // New Action button to the right of the title
      action: TextButton(
          child: const Text('Propose Action', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.blue),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return ActionDialog(
                  title: 'Propose Action',
                  onSave: (desc, points) async {

                    // Create the action in the database with approved set to false so it
                    // can be approved by an admin for future use by others.
                    var newAction = await state.addAction(context, desc, points, false, 1);

                    // Temporarily inject a new action in the approved list for use choice
                    if (newAction != null) {
                      setState(() {
                        widget.actions.add(newAction);
                      });
                    }
                  },
                );
              },
            );
          }
        ), 

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
              children: widget.actions.map((action) {
                return ActionWidget(
                  key: ValueKey('${action.desc}_${action.value}'),
                  desc: action.desc,
                  points: action.value,

                  // Enable toggle appearance for actions
                  toggle: true,

                  // Pass the selection state from the parent
                  isSelected: tappedActions.containsKey(action.desc),

                  // Parent widget will handle the visual effects.
                  // This is the logic of updating the tracking for the actions
                  onTap: () async {

                    // First, handle the toggle logic
                    if (tappedActions.containsKey(action.desc)) {
                      setState(() {
                        var removedAction = tappedActions.remove(action.desc);
                        totalPoints -= removedAction!.value;
                      });
                    } else {

                      // Then launch the Adjust Points dialog
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return ActionDialog(
                            title: 'Adjust Points',
                            initialValue: action.value,
                            initialDescription: action.desc,
                            onSave: (_, points) async {
                              setState(() {

                                // Update the action in the actions list for reuse
                                var adjustedAction = action.copyWith(value: points);
                                for (var i = 0; i < widget.actions.length; i++) {
                                  if (widget.actions[i].desc == action.desc) {
                                    widget.actions[i] = adjustedAction;
                                    break;
                                  }
                                }

                                // Add the adjusted action to the tappedActions map
                                tappedActions[action.desc] = adjustedAction;
                                totalPoints += adjustedAction.value;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    }
                  }
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
                  child: Text(totalPoints.toString(), textAlign: TextAlign.center, style: textStyle),
                )
              ),
            ),
            Spacer(),
            TextButton(
              child: const Text('Activate Points', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {

                // Add points to the user for each tapped action
                var futures = <Future<void>>[];
                for (var action in tappedActions.values) {
                  futures.add(state.addPoints(context, widget.user.id, action.id, action.value));
                }

                // Wait on all the futures to complete before navigating back to the range view
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
}

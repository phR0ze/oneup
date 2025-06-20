import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/api_action.dart';
import '../../model/category.dart';
import '../../providers/appstate.dart';
import '../../model/user.dart';
import '../widgets/animated_button.dart';
import '../widgets/section.dart';
import '../widgets/action.dart';
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
  Map<String, (int, TextEditingController)> pointsControllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pointsControllers.forEach((key, value) {
      value.$2.dispose();
    });
    pointsControllers.clear();
    super.dispose();
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

    // Dynamically create text controllers for each action as needed to track how many times that
    for (var action in sortedActions) {
      if (!pointsControllers.containsKey(action.desc)) {
        pointsControllers[action.desc] = (action.id, TextEditingController(text: '0'));
      }
    }
    if (!pointsControllers.containsKey('Total')) {
      pointsControllers['Total'] = (0, TextEditingController(text: '0'));
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the action widget with current points
                    ActionWidget(
                      desc: action.desc,
                      points: action.value,
                      backgroundColor: action.value == 0 ? Colors.grey : action.value > 0 
                        ? Colors.green : Colors.red,
                      onTap: () => updatePoints(pointsControllers['Total']!.$2,
                        pointsControllers[action.desc]!.$2, action.value),
                    ),
                    
                    // Display buttons below the action widget
                    if (action.value == 0 || action.desc == 'Unspecified')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AnimatedButton(
                                text: '+1', 
                                fgColor: Colors.white, 
                                bgColor: Colors.green,
                                padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                                onTap: () => updatePoints(pointsControllers['Total']!.$2, pointsControllers[action.desc]!.$2, 1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AnimatedButton(
                                text: '+5', 
                                fgColor: Colors.white, 
                                bgColor: Colors.green,
                                padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                                onTap: () => updatePoints(pointsControllers['Total']!.$2, pointsControllers[action.desc]!.$2, 5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AnimatedButton(
                                text: '-1', 
                                fgColor: Colors.white, 
                                bgColor: Colors.red,
                                padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                                onTap: () => updatePoints(pointsControllers['Total']!.$2, pointsControllers[action.desc]!.$2, -1),
                              ),
                            ),
                            AnimatedButton(
                              text: '-5', 
                              fgColor: Colors.white, 
                              bgColor: Colors.red,
                              padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                              onTap: () => updatePoints(pointsControllers['Total']!.$2, pointsControllers[action.desc]!.$2, -5),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AnimatedButton(
                          text: '+${action.value}', 
                          fgColor: Colors.white, 
                          bgColor: Colors.green,
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                          onTap: () => updatePoints(pointsControllers['Total']!.$2, pointsControllers[action.desc]!.$2, action.value),
                        ),
                      ),
                  ],
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
                  child: TextField(
                    controller: pointsControllers['Total']!.$2,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
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

                // Add points to the user
                for (var entry in pointsControllers.entries) {
                  var key = entry.key;
                  var ctlr = entry.value.$2;
                  if (key != 'Total') {
                    var value = int.parse(ctlr.text);
                    if (value != 0) {
                      futures.add(state.addPoints(context, widget.user.id, entry.value.$1, value));
                    }
                  }
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
}

/// Update the points controller value
void updatePoints(TextEditingController? totalCtl, TextEditingController? pointsCtl, int value) {
  if (pointsCtl == null || totalCtl == null) {
    return;
  }

  var total = int.parse(totalCtl.text);
  var category = int.parse(pointsCtl.text);

  // Limit the value to -999 to 999 to display it in the text field properly
  for (var i = 0; i < value.abs(); i++) {
    if (value > 0 && total + 1 <= 999 && category + 1 <= 999) {
      total++;
      category++;
    } else if (value < 0 && total - 1 >= -999 && category - 1 >= -999) {
      total--;
      category--;
    }
  }

  totalCtl.text = total.toString();
  pointsCtl.text = category.toString();
}

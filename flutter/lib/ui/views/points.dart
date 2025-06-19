import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/api_action.dart';
import '../../model/category.dart';
import '../../providers/appstate.dart';
import '../../model/user.dart';
import '../widgets/animated_button.dart';
import '../widgets/section.dart';
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
  Map<String, TextEditingController> pointsControllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pointsControllers.forEach((key, value) {
      value.dispose();
    });
    pointsControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineMedium;

    // Dynamically create text controllers for each action as needed
    for (var action in widget.actions) {
      if (!pointsControllers.containsKey(action.desc)) {
        pointsControllers[action.desc] = TextEditingController(text: '0');
      }
    }
    if (!pointsControllers.containsKey('Total')) {
      pointsControllers['Total'] = TextEditingController(text: '0');
    }

    return Section(title: "${widget.user.username}'s Points",
      onEscapeKey: () => { state.setCurrentView(const RangeView(range: Range.today)) },

      // Actions sorted by name
      child: ListView.builder(
        itemCount: widget.actions.length,
        itemBuilder: (_, index) {
          var action = widget.actions[index];
          var pointsCtlr = pointsControllers[action.desc];
          var totalCtlr = pointsControllers['Total'];

          return ListTile(

            // Points
            leading: Container(
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                child: TextField(
                  controller: pointsCtlr,
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

            // Category
            title: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 4),
              child: Text(action.desc, style: textStyle),
            ),

            // Buttons to be displayed for each action
            // If the action has a non-zero value then display a specific positive button
            // for that specific value and if the action's value is zero then display
            // +1, +5, -1, -5 buttons by default.
            trailing: SizedBox(width: 196,
              child: action.value == 0 
                ? Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: AnimatedButton(text: '+1', fgColor: Colors.white, bgColor: Colors.green,
                          padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                          onTap: () => updatePoints(totalCtlr, pointsCtlr, 1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: AnimatedButton(text: '+5', fgColor: Colors.white, bgColor: Colors.green,
                          padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                          onTap: () => updatePoints(totalCtlr, pointsCtlr, 5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: AnimatedButton(text: '-1', fgColor: Colors.white, bgColor: Colors.red,
                          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                          onTap: () => updatePoints(totalCtlr, pointsCtlr, -1),
                        ),
                      ),
                      AnimatedButton(text: '-5', fgColor: Colors.white, bgColor: Colors.red,
                        padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                        onTap: () => updatePoints(totalCtlr, pointsCtlr, -5),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      AnimatedButton(
                        text: '+${action.value}', 
                        fgColor: Colors.white, 
                        bgColor: Colors.green,
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                        onTap: () => updatePoints(totalCtlr, pointsCtlr, action.value),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
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
                    controller: pointsControllers['Total'],
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
                  var ctlr = entry.value;
                  if (key != 'Total') {
                    var value = int.parse(ctlr.text);
                    if (value != 0) {
                      var action = widget.actions.firstWhere((x) => x.desc == key);
                      futures.add(state.addPoints(context, widget.user.id, action.id, value));
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

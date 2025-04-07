import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../model/user.dart';
import '../widgets/animated_button.dart';
import '../widgets/section.dart';
import 'range.dart';

class PointsView extends StatefulWidget {
  const PointsView({
    super.key,
    required this.user,
  });

  /// The user to add points to.
  final User user;

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

    // Categories sorted by name
    var categories = state.categories;
    categories.sort((x, y) => x.name.compareTo(y.name));

    // Dynamically create text controllers for each category as needed
    for (var category in categories) {
      if (!pointsControllers.containsKey(category.name)) {
        pointsControllers[category.name] = TextEditingController(text: '0');
      }
    }
    if (!pointsControllers.containsKey('Total')) {
      pointsControllers['Total'] = TextEditingController(text: '0');
    }

    return Section(title: "${widget.user.name}'s Points",
      onBack: () => { state.setCurrentView(const RangeView(range: Range.today)) },

      // Categories sorted by name
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, index) {
          var category = categories[index];
          var pointsCtlr = pointsControllers[category.name];
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
              child: Text(category.name, style: textStyle),
            ),

            // Buttons
            trailing: SizedBox(width: 196,
              child: Row(
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
              onPressed: () {
                // Add points to the user
                pointsControllers.forEach((key, ctlr) {
                  if (key != 'Total') {
                    var value = int.parse(ctlr.text);
                    if (value != 0) {
                      var category = state.categories.firstWhere((x) => x.name == key);
                      state.addPoints(widget.user.id, category.id, value);
                    }
                  }
                });

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
void updatePoints(TextEditingController? totalCtlr, TextEditingController? pointsCtlr, int value) {
  if (pointsCtlr == null || totalCtlr == null) {
    return;
  }

  var total = int.parse(totalCtlr.text);
  var category = int.parse(pointsCtlr.text);

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

  totalCtlr.text = total.toString();
  pointsCtlr.text = category.toString();
}

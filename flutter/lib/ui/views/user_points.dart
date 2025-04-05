import 'package:flutter/material.dart';
import 'package:oneup/ui/views/today.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../model/user.dart';
import '../widgets/animated_button.dart';
import '../widgets/section.dart';

class UserPointsView extends StatefulWidget {
  const UserPointsView({
    super.key,
    required this.user,
  });

  /// The user to add points to.
  final User user;

  @override
  State<UserPointsView> createState() => _UserPointsViewState();
}

class _UserPointsViewState extends State<UserPointsView> {
  Map<String, TextEditingController> textControllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    textControllers.forEach((key, value) {
      value.dispose();
    });
    textControllers.clear();
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
      if (!textControllers.containsKey(category.name)) {
        textControllers[category.name] = TextEditingController();
      }
    }

    return Section(title: "${widget.user.name}'s Points",
      onBack: () => { state.setCurrentView(const TodayView()) },

      // Categories sorted by name
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, index) {
          var category = categories[index];
          return ListTile(

            // Points
            leading: Container(
              width: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                child: TextField(
                  controller: textControllers[category.name],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
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
                      onTap: () => print('Add 1 point to ${widget.user.name} in ${category.name}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: AnimatedButton(text: '+5', fgColor: Colors.white, bgColor: Colors.green,
                      padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                      onTap: () => print('Add 5 points to ${widget.user.name} in ${category.name}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: AnimatedButton(text: '-1', fgColor: Colors.white, bgColor: Colors.red,
                      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                      onTap: () => print('Sub 1 point from ${widget.user.name} in ${category.name}'),
                    ),
                  ),
                  AnimatedButton(text: '-5', fgColor: Colors.white, bgColor: Colors.red,
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                    onTap: () => print('Sub 5 points from ${widget.user.name} in ${category.name}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('Activate Points', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => print('Points activated'),
          // onPressed: () => showDialog<String>(context: context,
          //   builder: (dialogContext) => InputView(
          //     title: 'Create a new user',
          //     inputLabel: 'User Name',
          //     buttonName: 'Save',
          //     onSubmit: (val) {
          //       addUser(dialogContext, state, val.trim());
          //     },
          //   ),
          // ),
        ),
      ),
    );
  }
}

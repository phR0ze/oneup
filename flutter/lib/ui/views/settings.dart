import 'package:flutter/material.dart';
import 'package:oneup/ui/views/category.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../widgets/category.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var categories = state.categories;

    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
      
          // Title
          Positioned(
            top: -32,
            child: Text('Categories', style: Theme.of(context).textTheme.headlineLarge),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
           
              // Category wrapped box
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black26, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          direction: Axis.horizontal,
                          children: categories.map((x) {
                            return CategoryWidget(name: x.name);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          
              // Add category button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    splashColor: Colors.green,
                    onTap: () => showDialog<String>(context: context,
                      useRootNavigator: false,
                      builder: (BuildContext context) => CategoryCreateView(),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../model/appstate.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key, required this.name});
  final String name;

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    final textStyle = Theme.of(context).textTheme.titleLarge;;

    return  Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Const.pointsBorderColor, width: 2),
          ),
          child: Padding(
            // isHover padding changes allow for increased button size to not affect alignment
            padding: EdgeInsets.fromLTRB(8, isHover ? 1 : 2, isHover ? 2 : 5, isHover ? 1 : 2),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: isHover ? 12 : 15),
                  child: Text(widget.name, style: textStyle),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isHover ? Colors.white : Colors.red, width: 2),
                  ),
                  child: InkWell(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isHover ? 26 : 20,
                    ),
                    onHover: (val) {
                      setState(() { isHover = val; });
                    },
                    onTap: () {
                      // Don't allow deleteing categories if there are associated points
                      state.removeCategory(widget.name);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
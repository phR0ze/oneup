import 'package:flutter/material.dart';
import '../../const.dart';

class Category extends StatefulWidget {
  const Category({super.key, required this.name});
  final String name;

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge!.copyWith(
        color: Colors.black87,
    );

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
                      // state.removeCategory(widget.name);
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
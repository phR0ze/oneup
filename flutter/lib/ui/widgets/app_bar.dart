import 'package:flutter/material.dart';
import '../../const.dart';

PreferredSizeWidget build(BuildContext context, BoxConstraints constraints) {
  // Calculate content padding to keep the content centered at size 800 else maxWidth.
  var contentPadding = constraints.maxWidth > Const.contentWidth ?
    (constraints.maxWidth - Const.contentWidth)/2.0 : 0.0;

  return AppBar(
    toolbarHeight: Const.appBarHeight,
    flexibleSpace: Column(
      children: [

        // Top color strip
        Container(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth, height: Const.appBarStripeHeight),
          child: Row(
            children: [
              Flexible(flex: 1, child: Container( color: Const.todayIconColor)),
              Flexible(flex: 1, child: Container( color: Const.rewardsIconColor)),
              Flexible(flex: 1, child: Container( color: Const.weekIconColor)),
              Flexible(flex: 1, child: Container( color: Const.priorWeekIconColor)),
              Flexible(flex: 1, child: Container( color: Const.settingsIconColor)),
            ],
          ),
        ),

        // Top Navbar
        Container(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth, height: Const.appBarHeight - Const.appBarStripeHeight),
          color: Const.appBarBgColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MenuItem(title: 'today', icon: Icons.home, iconColor: Const.todayIconColor),
                MenuItem(title: 'rewards', icon: Icons.stars_rounded, iconColor: Const.rewardsIconColor),
                MenuItem(title: 'categories', icon: Icons.category, iconColor: Const.categoriesIconColor),
                MenuItem(title: 'week', icon: Icons.calendar_view_week, iconColor: Const.weekIconColor),
                MenuItem(title: 'prior week', icon: Icons.calendar_view_month, iconColor: Const.priorWeekIconColor),
                MenuItem(title: 'settings', icon: Icons.settings, iconColor: Const.settingsIconColor),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class MenuItem extends StatefulWidget {
  const MenuItem({super.key, required this.title, required this.icon, required this.iconColor});

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuTextStyle = theme.textTheme.titleLarge!.copyWith(
      color: Const.appBarMenuTitleColor,
      fontWeight: FontWeight.w700,
    );

    // Nice bounce effect on hover by changing the padding
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isHover ? Colors.grey[300]! : Colors.white,
            width: 4,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: isHover ? 0 : 5, bottom: !isHover ? 0 : 5),
      child: InkWell(
        child: Row(children: [
          Icon(widget.icon, size: Const.appBarMenuIconSize, color: widget.iconColor),
          SizedBox(width: 10),
          Text(widget.title.toUpperCase(), style: menuTextStyle),
        ]),
        onHover: (val) {
          setState(() {
            isHover = val;
          });
        },
        onTap: () {
          print("Menu item ${widget.title} clicked");
        },
      ),
    );
  }
}
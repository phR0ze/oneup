import 'package:flutter/material.dart';
import '../../const.dart';

PreferredSizeWidget build(BuildContext context, BoxConstraints constraints) {
  // Calculate content padding to keep the content centered at size 800 else maxWidth.
  var contentWidth = 1000.0;
  var contentPadding = constraints.maxWidth > contentWidth ?
    (constraints.maxWidth - contentWidth)/2.0 : 0.0;

  // Font theme settings
  final theme = Theme.of(context);
  final menuTextStyle = theme.textTheme.titleLarge!.copyWith(
    color: Colors.black,
    fontWeight: FontWeight.w700,
  );

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
              Flexible(flex: 1, child: Container( color: Colors.green[200])),
              Flexible(flex: 1, child: Container( color: Colors.amber)),
              Flexible(flex: 1, child: Container( color: Colors.orange)),
              Flexible(flex: 1, child: Container( color: Colors.red[200])),
              Flexible(flex: 1, child: Container( color: Colors.deepPurple[200])),
            ],
          ),
        ),

        // Top Navbar
        Container(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth, height: Const.appBarHeight - Const.appBarStripeHeight),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MenuItem(title: 'today', icon: Icons.home, iconColor: Colors.green[200]!),
                MenuItem(title: 'rewards', icon: Icons.stars_rounded, iconColor: Colors.amber),
                MenuItem(title: 'categories', icon: Icons.category, iconColor: Colors.blue[200]!),
                MenuItem(title: 'week', icon: Icons.calendar_view_week, iconColor: Colors.orange),
                MenuItem(title: 'prior week', icon: Icons.calendar_view_month, iconColor: Colors.red[200]!),
                MenuItem(title: 'settings', icon: Icons.settings, iconColor: Colors.deepPurple[200]!),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class MenuItem extends StatelessWidget {
  const MenuItem({super.key, required this.title, required this.icon, required this.iconColor});

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuTextStyle = theme.textTheme.titleLarge!.copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w700,
    );

    return Row(children: [
      Icon(icon, size: Const.appBarMenuIconSize, color: iconColor),
      SizedBox(width: 10),
      Text(title.toUpperCase(), style: menuTextStyle),
    ]);
  }
}
import 'package:flutter/material.dart';
import 'package:oneup/ui/views/rewards.dart';
import 'package:oneup/ui/views/settings.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../model/appstate.dart';
import '../../utils/utils.dart';
import '../views/range.dart';
import 'logo.dart';

PreferredSizeWidget build(BuildContext context, BoxConstraints constraints) {
  var contentPadding = utils.contentPadding(constraints);

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

        // Logo and Navbar
        Container(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth, height: Const.appBarHeight - Const.appBarStripeHeight*2),
          color: Const.appBarBgColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Logo(),
                MenuItem(title: 'today', icon: Icons.home,
                  iconColor: Const.todayIconColor, view: const RangeView(range: Range.today)),
                MenuItem(title: 'week', icon: Icons.calendar_view_week,
                  iconColor: Const.weekIconColor, view: const RangeView(range: Range.week)),
                MenuItem(title: 'prior week', icon: Icons.calendar_view_month,
                  iconColor: Const.priorWeekIconColor, view: const RangeView(range: Range.priorWeek)),
                MenuItem(title: 'rewards', icon: Icons.stars_rounded,
                  iconColor: Const.rewardsIconColor, view: const RewardsView()),
                MenuItem(title: 'settings', icon: Icons.settings,
                  iconColor: Const.settingsIconColor, view: SettingsView()),
              ],
            ),
          ),
        ),

        // Bottom color strip with shadow
        Container(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth, height: Const.appBarStripeHeight),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                spreadRadius: 0,
                blurRadius: 10,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
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

      ],
    ),
  );
}

class MenuItem extends StatefulWidget {
  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.view,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget view;

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

    final theme = Theme.of(context);
    final menuTextStyle = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w700,
    );

    // Indicate if this menu item if hovered or selected
    var hoverOrSelected = isHover || isView(state.currentView, widget.view);

    // Nice bounce effect on hover by changing the padding
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: hoverOrSelected ? Colors.grey[300]! : Colors.white,
            width: 4,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: hoverOrSelected ? 0 : 5, bottom: !hoverOrSelected ? 0 : 5),
      child: InkWell(
        child: Row(children: [
          Icon(widget.icon, size: Const.appBarMenuIconSize, color: widget.iconColor),
          SizedBox(width: 10),
          Text(widget.title.toUpperCase(), style: menuTextStyle),
        ]),
        onHover: (val) {
          setState(() { isHover = val; });
        },
        onTap: () {
          state.setCurrentView(widget.view);
        },
      ),
    );
  }
}

/// Check if the left and right views are the same
bool isView(Widget left, Widget right) {
  if (left is RangeView && right is RangeView) {
    return left.range == right.range;
  } else {
    return left.runtimeType == right.runtimeType;
  }
}
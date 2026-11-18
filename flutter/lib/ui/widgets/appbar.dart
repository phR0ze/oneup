import 'package:flutter/material.dart';
import 'package:oneup/ui/views/rewards.dart';
import 'package:oneup/ui/views/settings/settings.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../views/range.dart';
import 'logo.dart';
import 'prior_picker.dart';

PreferredSizeWidget build(BuildContext context, BoxConstraints constraints, bool mobile) {
  final contentPadding = utils.contentPadding(constraints);

  if (mobile) {
    return _buildMobileAppBar(constraints);
  }

  return AppBar(
    toolbarHeight: Const.appBarHeight,
    flexibleSpace: Column(
      children: [

        // Top color strip
        Container(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth, height: Const.appBarStripeHeight),
          child: _colorStripe(),
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
                MenuItem(
                  title: 'prior',
                  icon: Icons.calendar_view_month,
                  iconColor: Const.priorIconColor,
                  view: const RangeView(range: Range.prior),
                  onTap: (ctx, state) => _pickPrior(ctx, state),
                ),
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
                color: Colors.black.withValues(alpha: 0.4),
                spreadRadius: 0,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: _colorStripe(),
        ),

      ],
    ),
  );
}

PreferredSizeWidget _buildMobileAppBar(BoxConstraints constraints) {
  const mobileBarHeight = 65.0; // 5px stripe + 55px content + 5px stripe
  const stripeHeight = Const.appBarStripeHeight;
  const contentHeight = mobileBarHeight - stripeHeight * 2;

  return AppBar(
    toolbarHeight: mobileBarHeight,
    automaticallyImplyLeading: false,
    flexibleSpace: Column(
      children: [

        // Top color strip
        SizedBox(
          width: constraints.maxWidth,
          height: stripeHeight,
          child: _colorStripe(),
        ),

        // Logo + hamburger row
        Container(
          height: contentHeight,
          width: constraints.maxWidth,
          color: Const.appBarBgColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Logo(),
              const Spacer(),
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, size: 32, color: Colors.black87),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ],
          ),
        ),

        // Bottom color strip with shadow
        Container(
          height: stripeHeight,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _colorStripe(),
        ),

      ],
    ),
  );
}

Widget _colorStripe() {
  return Row(
    children: [
      Flexible(flex: 1, child: Container(color: Const.todayIconColor)),
      Flexible(flex: 1, child: Container(color: Const.rewardsIconColor)),
      Flexible(flex: 1, child: Container(color: Const.weekIconColor)),
      Flexible(flex: 1, child: Container(color: Const.priorIconColor)),
      Flexible(flex: 1, child: Container(color: Const.settingsIconColor)),
    ],
  );
}

Widget buildDrawer(BuildContext context) {
  return Drawer(
    width: 254,
    child: _DrawerContent(),
  );
}

class _DrawerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    void navigate(Widget view) {
      state.setCurrentView(view);
      Navigator.pop(context);
    }

    final titleStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Const.appBarBgColor),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.scale(
              scale: 1.3,
              alignment: Alignment.centerLeft,
              child: const Logo(),
            ),
          ),
        ),
        _DrawerNavItem(
          title: 'Today',
          icon: Icons.home,
          iconColor: Const.todayIconColor,
          titleStyle: titleStyle,
          isSelected: isView(state.currentView, const RangeView(range: Range.today)),
          onTap: () => navigate(const RangeView(range: Range.today)),
        ),
        _DrawerNavItem(
          title: 'Week',
          icon: Icons.calendar_view_week,
          iconColor: Const.weekIconColor,
          titleStyle: titleStyle,
          isSelected: isView(state.currentView, const RangeView(range: Range.week)),
          onTap: () => navigate(const RangeView(range: Range.week)),
        ),
        _DrawerNavItem(
          title: 'Prior',
          icon: Icons.calendar_view_month,
          iconColor: Const.priorIconColor,
          titleStyle: titleStyle,
          isSelected: isView(state.currentView, const RangeView(range: Range.prior)),
          onTap: () async {
            if (await _pickPrior(context, state) && context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        _DrawerNavItem(
          title: 'Rewards',
          icon: Icons.stars_rounded,
          iconColor: Const.rewardsIconColor,
          titleStyle: titleStyle,
          isSelected: isView(state.currentView, const RewardsView()),
          onTap: () => navigate(const RewardsView()),
        ),
        _DrawerNavItem(
          title: 'Settings',
          icon: Icons.settings,
          iconColor: Const.settingsIconColor,
          titleStyle: titleStyle,
          isSelected: state.currentView is SettingsView,
          onTap: () => navigate(SettingsView()),
        ),
      ],
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.titleStyle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final TextStyle titleStyle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 32),
      title: Text(title, style: titleStyle),
      selected: isSelected,
      selectedTileColor: iconColor.withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}

class MenuItem extends StatefulWidget {
  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.view,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget view;
  final void Function(BuildContext, AppState)? onTap;

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

    var hoverOrSelected = isHover || isView(state.currentView, widget.view);

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
          if (widget.onTap != null) {
            widget.onTap!(context, state);
          } else {
            state.setCurrentView(widget.view);
          }
        },
      ),
    );
  }
}

/// Check if the left and right views are the same
bool isView(Widget left, Widget right) {
  if (left is RangeView && right is RangeView) {
    if (_isPrior(left.range) && _isPrior(right.range)) return true;
    return left.range == right.range;
  } else {
    return left.runtimeType == right.runtimeType;
  }
}

bool _isPrior(Range r) => r == Range.prior || r == Range.customDay || r == Range.customWeek;

/// Show the prior picker, seeded from the current prior selection if there is one, otherwise
/// defaulting to last week. Navigates to the chosen day or week and returns true if one was picked.
Future<bool> _pickPrior(BuildContext context, AppState state) async {
  PriorSelection initial = (date: DateTime.now().subtract(const Duration(days: 7)), week: true);
  final cv = state.currentView;
  if (cv is RangeView && cv.selectedDate != null
      && (cv.range == Range.customDay || cv.range == Range.customWeek)) {
    initial = (date: cv.selectedDate!, week: cv.range == Range.customWeek);
  }
  final picked = await showDialog<PriorSelection>(
    context: context,
    builder: (_) => PriorPickerDialog(initial: initial),
  );
  if (picked == null) return false;
  state.setCurrentView(RangeView(
    range: picked.week ? Range.customWeek : Range.customDay,
    selectedDate: picked.date,
  ));
  return true;
}

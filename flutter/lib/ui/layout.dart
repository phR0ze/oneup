import 'package:flutter/material.dart';
import '../const.dart';
import 'pages/today.dart';
import 'widgets/drawer.dart' as drawer;
import 'widgets/app_bar.dart' as appBar;

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = TodayPage();
        break;
      case 1:
        page = Placeholder();
        break;
      case 2:
        page = Placeholder();
        break;
      case 3:
        page = Placeholder();
        break;
      case 4:
        page = Placeholder();
        break;
      case 5:
        page = Placeholder();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        var contentPadding = constraints.maxWidth > Const.contentWidth ?
          (constraints.maxWidth - Const.contentWidth)/2.0 : 0.0;

        return Scaffold(
          appBar: appBar.build(context, constraints),
          body: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, 0),
            child: TodayPage(),
          ),
          // drawer: drawer.build(context),
          // body: Row(
          //   children: [
          //     NavigationRail(
          //       extended: constraints.maxWidth >= 800,
          //       backgroundColor: Const.sideNavBgColor,
          //       unselectedLabelTextStyle: theme.textTheme.titleLarge,
          //       selectedLabelTextStyle: theme.textTheme.titleLarge,
          //       //indicatorColor: theme.colorScheme.onPrimaryContainer,
          //       destinations: [
          //         NavigationRailDestination(
          //           icon: Icon(Icons.home),
          //           label: Text('Today'),
          //         ),
          //         NavigationRailDestination(
          //           icon: Icon(Icons.stars_rounded),
          //           label: Text('Rewards'),
          //         ),
          //         NavigationRailDestination(
          //           icon: Icon(Icons.category),
          //           label: Text('Categories'),
          //         ),
          //         NavigationRailDestination(
          //           icon: Icon(Icons.calendar_view_week),
          //           label: Text('Week'),
          //         ),
          //         NavigationRailDestination(
          //           icon: Icon(Icons.calendar_month),
          //           label: Text('Prior Week'),
          //         ),
          //         NavigationRailDestination(
          //           icon: Icon(Icons.settings),
          //           label: Text('Settings'),
          //         ),
          //       ],
          //       selectedIndex: selectedIndex,
          //       onDestinationSelected: (value) {
          //         setState(() {
          //           selectedIndex = value;
          //         });
          //       },
          //     ),
          //     Expanded(
          //       child: Padding(
          //         padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          //         child: page,
          //       ),
          //     ),
          //   ],
          // ),
        );
      }
    );
  }
}


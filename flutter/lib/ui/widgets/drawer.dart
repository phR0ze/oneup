import 'package:flutter/material.dart';
import '../../const.dart';

Widget build(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(Const.appName, style: Theme.of(context).textTheme.headlineMedium),
        ),
        ListTile(
          title: const Text('Today'),
          leading: const Icon(Icons.home),
          // selected: state.currentRoute == 0,
          onTap: () {
            // ref.read(appStateProvider.notifier).setCurrentRoute(0);
            // dismissSnackBar();
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('Rewards'),
          leading: const Icon(Icons.stars_rounded),
          // selected: state.currentRoute == 1,
          onTap: () {
            // ref.read(appStateProvider.notifier).setCurrentRoute(1);
            // showSnackBar('Gallery is not yet implmented');
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('Settings'),
          leading: const Icon(Icons.settings),
          // selected: state.currentRoute == 2,
          onTap: () {
            // ref.read(appStateProvider.notifier).setCurrentRoute(2);
            // showSnackBar('Settings is not yet implemented');
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('Settings'),
          leading: const Icon(Icons.settings),
          // selected: state.currentRoute == 2,
          onTap: () {
            // ref.read(appStateProvider.notifier).setCurrentRoute(2);
            // showSnackBar('Settings is not yet implemented');
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
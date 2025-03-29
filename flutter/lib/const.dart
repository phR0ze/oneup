import 'package:flutter/material.dart';

class Const {
  static const appName = 'One-Up';
  static const appVer = '0.0.1';

  static const pointCardPadding = 3.0;
  static const pointCardWidth= 75.0;
  static const userStarSize = 50.0;
  static const userCardWidth = 150.0;

  static const appBarHeight = 90.0;
  static const appBarStripeHeight = 5.0;
  static const appBarMenuIconSize = 25.0;

  // Colors
  static const userStarColor = Colors.yellow;
  static const userBgColor = Colors.black54;
  static const userPosPointsBgColor = Colors.green;
  static const userNegPointsBgColor = Colors.red;
  static const sideNavBgColor = Colors.black12;
  static const appBarBgColor = Colors.black45;

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,

    // Card
    primary: Colors.black12,                  // hover shadow for navigation
    onPrimary: Colors.white,                  // text
    shadow: Colors.black,                     // shadow    

    primaryContainer: Colors.black12,         // NavigationBar background
    onPrimaryContainer: Colors.white,         // ?

    secondary: Colors.blue,                   // ?
    onSecondary: Colors.deepOrange,           // ?   
    secondaryContainer: Colors.amberAccent,   // NavigationBar selected highlight
    onSecondaryContainer: Colors.black,       // NavigationBar selected icon

    // Un-accounted for below here
    tertiary: Colors.orange,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Colors.amber,
    onTertiaryContainer: Color(0xFF001E2E),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFCFCFF),
    onSurface: Color(0xFF1A1C1E),
    surfaceContainerHighest: Colors.purple,
    onSurfaceVariant: Color(0xFF41474D),
    outline: Colors.greenAccent,
    onInverseSurface: Color(0xFFF0F0F3),
    inverseSurface: Colors.redAccent,
    inversePrimary: Colors.pinkAccent,
    surfaceTint: Colors.indigo,
    outlineVariant: Color(0xFFC1C7CE),
    scrim: Colors.blue,
  );

}
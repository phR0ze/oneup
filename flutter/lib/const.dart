import 'package:flutter/material.dart';

class Const {
  static const appName = 'One-Up';
  static const appVer = '0.0.1';
  static const appTitleColor = Colors.black;

  // Assets
  static const assetAppIcon = 'assets/icons/one-up-100.png';
  static const assetAppArrowIcon = 'assets/icons/arrow-50.png';

  // Sizing and padding
  static const contentPadding = 25.0;
  static const contentPaddingTop = 35.0;

  static const pointCardPadding = 3.0;
  static const pointCardWidth= 75.0;

  static const appBarHeight = 80.0;
  static const appBarStripeHeight = 5.0;
  static const appBarMenuIconSize = 25.0;
  static const contentWidth = 1000.0;
  static const userTileTitleSize = 40.0;
  static const userTileBorderRadius = 20.0;

  // Colors
  static const appBarBgColor = Colors.white;
  static const appBarMenuTitleColor = Colors.black;
  static const appBarMenuTitleSize = Colors.black;
  static final todayIconColor = Colors.green[200]!;
  static const rewardsIconColor = Colors.amber;
  static const weekIconColor = Colors.orange;
  static final priorWeekIconColor = Colors.red[200]!;
  static final settingsIconColor = Colors.deepPurple[200]!;

  // User
  static const userTileSpacing = 30.0;

  static const userTileGoldMedalTop = -40.0;
  static const userTileGoldMedalLeft = -40.0;
  static const userTileGoldMedal = Icon(Icons.star,
    color: Color.fromARGB(255, 255, 217, 79), size: 80);

  static const userTileSilverMedalTop = -33.0;
  static const userTileSilverMedalLeft = -33.0;
  static const userTileSilverMedal = Icon(Icons.star_sharp,
    color: Color.fromARGB(255, 197, 197, 197), size: 60);

  static const userTileBronzeMedalTop = -28.0;
  static const userTileBronzeMedalLeft = -28.0;
  static const userTileBronzeMedal = Icon(Icons.star_sharp,
    color: Color.fromARGB(255, 202, 135, 110), size: 50);

  static const userTileTitleColor = Colors.black;
  static const userTileBgColor = Colors.black12;
  static const userTileBorderColor = Colors.amber;
  static const userTileShadowColor = Colors.black12;
  static const userTilePosPointsBgColor = Colors.green;
  static const userTileNegPointsBgColor = Colors.red;

  static const sideNavBgColor = Colors.black12;

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
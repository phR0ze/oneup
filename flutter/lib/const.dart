import 'package:flutter/material.dart';

class Const {
  static const appName = 'One-Up';
  static const appVer = '0.0.1';

  // Text
  static const titlesColor = Colors.black;

  // Assets
  static const assetAppImage = 'assets/images/one-up-100.png';
  static const assetAppArrowImage = 'assets/images/arrow-50.png';
  static const assetCurlyBraceImage = 'assets/images/curly-brace-130.png';

  // Sizing and padding
  static const dialogWidth = 400.0;
  static const sectionContentHeight = 400.0;
  static const contentPadding = 25.0;
  static const contentPaddingTop = 50.0;

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
  static final pointsBorderColor = Colors.black12;
  static final categoryBgColor = Colors.blue[200]!;

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

  static const userTileBgColor = Colors.black12;
  static const userTileBorderColor = Colors.amber;
  static const userTileShadowColor = Colors.black12;
  static final posPointsBgColor = Colors.green[400];
  static final negPointsBgColor = Colors.red[400];
  static final pointsLabelBgColor = Colors.blue[300];
  static final rewardPointsValueBgColor = Colors.blue[300];
  static const neutralPointsValueBgColor = Colors.amber;

  static const sideNavBgColor = Colors.black12;

  // ColorScheme provides unified colors across the entire app.
  // - Surface colors used for backgrounds and large low-emphasis areas of the screen
  // - 'on' colors are used for drawing content on top of their matching counterparts
  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary colors are used for key components
    // - prominent buttons
    // - active states

    // Secondary colors are used for less prominent components
    // - filter chips
    // - expanded color expression

    // Tertiary colors are used for contrast and accents to balance primary and secondary colors
    // - heightened attention to input field
    // - more for dev discreation and boarder color expression

    // Card
    primary: Colors.black12,                  // hover shadow for navigation
    onPrimary: Colors.white,                  // text

    outline: Colors.black45,              // input widget outline
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
    onSurface: Color(0xFF1A1C1E),

    // AppBar bg, 
    surface: Color(0xFFFCFCFF),
    surfaceTint: Colors.indigo,
    surfaceContainerHighest: Colors.purple,

    onSurfaceVariant: Color(0xFF41474D),
    onInverseSurface: Color(0xFFF0F0F3),
    inverseSurface: Colors.redAccent,
    inversePrimary: Colors.pinkAccent,
    outlineVariant: Color(0xFFC1C7CE),
    scrim: Colors.blue,
  );

}
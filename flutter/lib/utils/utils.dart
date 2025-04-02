import 'package:flutter/material.dart';

import '../const.dart';

class utils {

  // Calculate the content padding based on the screen size
  static double contentPadding(BoxConstraints constraints) {
    var contentPadding = constraints.maxWidth >= Const.contentWidth ?
      (constraints.maxWidth - Const.contentWidth)/2.0 : Const.contentPadding;

    return contentPadding;
  }
}
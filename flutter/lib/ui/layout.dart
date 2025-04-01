import 'package:flutter/material.dart';
import '../const.dart';
import 'pages/today.dart';
import 'widgets/app_bar.dart' as appbar;

class Layout extends StatelessWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var contentPadding = constraints.maxWidth > Const.contentWidth ?
          (constraints.maxWidth - Const.contentWidth)/2.0 : Const.contentPadding;

        return Scaffold(
          appBar: appbar.build(context, constraints),
          body: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, Const.contentPaddingTop, contentPadding, 0),
            child: TodayPage(),
          ),
        );
      }
    );
  }
}


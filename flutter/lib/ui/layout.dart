import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../const.dart';
import '../model/appstate.dart';
import '../utils/utils.dart';
import 'widgets/appbar.dart' as appbar;

class Layout extends StatelessWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var view = state.currentView;

    return LayoutBuilder(
      builder: (context, constraints) {
        var contentPadding = utils.contentPadding(constraints) + 20;

        return Scaffold(
          appBar: appbar.build(context, constraints),
          body: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, Const.contentPaddingTop, contentPadding, 0),
            child: view,
          ),
        );
      }
    );
  }
}


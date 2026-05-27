import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../const.dart';
import '../providers/appstate.dart';
import '../utils/utils.dart';
import 'views/range.dart';
import 'views/rewards.dart';
import 'widgets/appbar.dart' as appbar;

class Layout extends StatelessWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var view = state.currentView;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = utils.isMobile(constraints.maxWidth);
        final hPadding = mobile ? 24.0 : utils.contentPadding(constraints) + 20;

        return Scaffold(
          appBar: appbar.build(context, constraints, mobile),
          drawer: mobile ? appbar.buildDrawer(context) : null,
          body: Padding(
            // RangeView manages its own right padding on mobile so the ListView
            // widget reaches the screen edge and its scrollbar appears there.
            // All other views get the normal symmetric padding.
            padding: EdgeInsets.fromLTRB(
              hPadding,
              mobile ? Const.contentPaddingTop - 10 : Const.contentPaddingTop,
              mobile && (view is RangeView || view is RewardsView) ? 0.0 : hPadding,
              0,
            ),
            child: view,
          ),
        );
      }
    );
  }
}

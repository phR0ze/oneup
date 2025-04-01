import 'package:flutter/material.dart';
import '../../const.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return  Container(height: 50, width: 200,
      // color: Colors.blue,
      clipBehavior: Clip.none,
      child: Stack(
        children: <Widget>[

          // App icon
          Image.asset(Const.assetAppImage, height: 50),

          Positioned(top: 27, left: 120,
            child: Image.asset(Const.assetAppArrowImage, height: 20),
          ),

          // App name
          Positioned(top: 4, left: 55,
            child: Text('One', style: theme.textTheme.titleLarge!.copyWith(
                color: Const.appTitleColor,
                fontSize: 40.0,
                fontWeight: FontWeight.bold,
              )
            )),
          Positioned(top: -2, left: 120,
            child: Text('up', style: theme.textTheme.titleLarge!.copyWith(
                color: Const.appTitleColor,
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              )
            )),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
 final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      top: false,
      child: Scaffold(
        body: Scrollbar(
          controller: scrollController,
          child: CustomScrollView(controller: scrollController, slivers: [
            SliverFillViewport(
              delegate: SliverChildListDelegate(
                [
                  Container(color: Colors.red, height: 150.0),
                  Container(color: Colors.purple, height: 150.0),
                  Container(color: Colors.green, height: 150.0),
                ]
              ),
              viewportFraction: 0.3
            ),
          ]),
        ),
      ),
    );
  }
}

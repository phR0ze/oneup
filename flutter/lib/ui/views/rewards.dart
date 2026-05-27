import 'package:flutter/material.dart';
import 'package:oneup/ui/views/range.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../providers/appstate.dart';
import '../../utils/utils.dart';
import '../widgets/user_tile.dart';
import '../widgets/input.dart';
import '../../model/user.dart';

class RewardsView extends StatefulWidget {
  const RewardsView({super.key});

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    final mobile = utils.isMobile(MediaQuery.of(context).size.width);
    final mobileRightPad = mobile ? 19.0 : 0.0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        return utils.onEscapeKey(context, event,
          () => state.setCurrentView(const RangeView(range: Range.today)));
      },
      child: FutureBuilder<List<User>>(
        future: state.getUsersWithoutAdminRole(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!;
          return FutureBuilder<List<(User, int)>>(
            future: Future.wait(users.map((u) async {
              final points = await state.getPointsSum(context, u.id, null, null);
              final rewards = await state.getRewardSum(context, u.id, null);
              return (u, points - rewards);
            })),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Sort users by the most points
              var sortedUsers = snapshot.data!;
              sortedUsers.sort((x, y) {
                return y.$2.compareTo(x.$2);
              });

              return ClipPath(
                clipper: const _MedalOverflowClipper(),
                child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Padding(
                padding: EdgeInsets.only(top: 30, bottom: Const.userTileSpacing, right: mobileRightPad),
                child: Wrap(
                spacing: 30,
                runSpacing: 30,
                children: () {
                  var tiles = <Widget>[];
                  for (var i = 0; i < sortedUsers.length; i++) {
                    var (user, points) = sortedUsers[i];
            
                    final tile = UserTile(
                      user: user.username,
                      order: points > 0 && i < 3 ? i : -1,
                      pos: points,
                      neg: 0,
                      total: true,
                      mobile: mobile,
                      onTap: () => showDialog<String>(context: context,
                        builder: (dialogContext) => InputView(
                          title: 'Cash out Rewards',
                          inputLabel: 'Cash out Amount',
                          buttonName: 'Save',
                          onSubmit: (val, [String? _1, int? _2, bool? _3]) async {
                            int? intVal = int.tryParse(val);
                            if (intVal == null || intVal <= 0 || intVal > points) {
                              utils.showSnackBarFailure(context, 'Invalid cash out amount!');
                            } else {
                              await state.cashOut(context, user.id, intVal);
                            }
                          },
                        ),
                      ),
                    );
                    tiles.add(mobile ? tile : SizedBox(width: 330, child: tile));
                  }
                  return tiles;
                }().toList(),
              ))));
            },
          );
        },
      ),
    );
  }
}

class _MedalOverflowClipper extends CustomClipper<Path> {
  const _MedalOverflowClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(-50, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(-50, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../model/api_action.dart';
import '../../model/category.dart';
import '../../providers/appstate.dart';
import '../../model/user.dart';
import '../widgets/section.dart';
import '../widgets/action_widget.dart';
import '../widgets/action_dialog.dart';
import 'range.dart';
import '../../utils/utils.dart';

/// Displays the view responsible for adding points to a user once the user is selected from the
/// range view.
class PointsView extends StatefulWidget {
  const PointsView({ super.key, required this.user, required this.actions,
    required this.categories,
  });

  /// The user to add points to.
  final User user;

  /// All actions to display in the view for selection
  final List<ApiAction> actions;

  /// All categories to display in the view for selection
  final List<Category> categories;

  @override
  State<PointsView> createState() => _PointsViewState();
}

// Prevents the search TextField from consuming the Escape key so it can
// bubble up to the Section's escape handler and navigate back.
class _PassEscapeAction extends Action<DismissIntent> {
  @override
  bool consumesKey(DismissIntent intent) => false;
  @override
  Object? invoke(DismissIntent intent) => null;
}

class _PointsViewState extends State<PointsView> {
  Map<String, ApiAction> tappedActions = {};
  int totalPoints = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Automatically focus the search field when the view loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel the previous timer
    _debounceTimer?.cancel();
    
    // Set a new timer for 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase().trim();
        });
      }
    });
  }

  List<ApiAction> get _filteredActions {
    if (_searchQuery.isEmpty) {
      return widget.actions;
    }
    final filtered = widget.actions
        .where((action) => action.desc.toLowerCase().contains(_searchQuery))
        .toList();
    
    // Debug logging
    // print('Search query: "$_searchQuery"');
    // print('Total actions: ${widget.actions.length}');
    // print('Filtered actions: ${filtered.length}');
    
    return filtered;
  }

  Widget _buildActionSection({bool mobile = false}) {
    final filteredActions = _filteredActions;
    
    if (filteredActions.isEmpty && _searchQuery.isNotEmpty) {
      // Show propose button when no actions match the search
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No actions found matching "${_searchController.text}".',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextButton(
              child: const Text('Propose Action', style: TextStyle(fontSize: 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () => _showProposeDialog(_searchController.text),
            ),
          ],
        ),
      );
    }

    if (filteredActions.isEmpty && _searchQuery.isEmpty) {
      return const Center(
        child: Text(
          'No actions available.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: filteredActions.map((action) {
        return ActionWidget(
          key: ValueKey('${action.desc}_${action.value}'),
          desc: action.desc,
          points: action.value,
          toggle: true,
          mobile: mobile,
          isSelected: tappedActions.containsKey(action.desc),
          onTap: () async {
            if (tappedActions.containsKey(action.desc)) {
              setState(() {
                var removedAction = tappedActions.remove(action.desc);
                totalPoints -= removedAction!.value;
              });
            } else {
              _showAdjustDialog(action);
            }
          },
        );
      }).toList(),
    );
  }

  void _showProposeDialog(String initialDescription) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ActionDialog(
          title: 'Propose Action',
          initialDescription: initialDescription,
          onSave: (desc, points) async {
            var newAction = await state.addAction(context, desc, points, false, 1);
            if (newAction != null) {
              setState(() {
                _insertActionInSortedPosition(newAction);
                // Automatically select the newly added action
                tappedActions[newAction.desc] = newAction;
                totalPoints += newAction.value;
                // Clear search to show the new action
                _searchController.clear();
              });
            }
          },
        );
      },
    );
  }

  /// Insert the new action in the correct alphabetical position
  void _insertActionInSortedPosition(ApiAction newAction) {
    // Find the correct position to insert the new action
    int insertIndex = 0;
    for (int i = 0; i < widget.actions.length; i++) {
      if (newAction.desc.toLowerCase().compareTo(widget.actions[i].desc.toLowerCase()) < 0) {
        insertIndex = i;
        break;
      }
      insertIndex = i + 1;
    }
    
    // Insert the action at the correct position
    widget.actions.insert(insertIndex, newAction);
  }

  void _showAdjustDialog(ApiAction action) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ActionDialog(
          title: 'Adjust Points',
          initialValue: action.value,
          initialDescription: action.desc,
          onSave: (_, points) async {
            setState(() {
              var adjustedAction = action.copyWith(value: points);
              for (var i = 0; i < widget.actions.length; i++) {
                if (widget.actions[i].desc == action.desc) {
                  widget.actions[i] = adjustedAction;
                  break;
                }
              }
              tappedActions[action.desc] = adjustedAction;
              totalPoints += adjustedAction.value;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    final mobile = utils.isMobile(MediaQuery.of(context).size.width);
    var textStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontSize: mobile ? 21 : null,
    );

    return Section(
      title: "${widget.user.username}'s Points",
      onEscapeKey: () => state.setCurrentView(const RangeView(range: Range.today)),
      action: SizedBox(
        width: mobile ? double.infinity : 300,
        child: Actions(
          actions: {DismissIntent: _PassEscapeAction()},
          child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(fontSize: mobile ? 14 : 18),
          decoration: InputDecoration(
            hintText: 'Filter actions...',
            prefixIcon: Icon(Icons.search, size: mobile ? 21 : 28),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            isDense: true,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {},
        ),
      ),
      ),
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
          trackVisibility: WidgetStateProperty.all(true),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionSection(mobile: mobile),
          ),
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                  child: Text(
                    totalPoints.toString(),
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              child: Text('Activate Points', style: TextStyle(fontSize: mobile ? 14 : 18)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {
                var futures = <Future<void>>[];
                for (var action in tappedActions.values) {
                  futures.add(state.addPoints(context, widget.user.id, action.id, action.value));
                }
                await Future.wait(futures);
                state.setCurrentView(const RangeView(range: Range.today));
              },
            ),
          ],
        ),
      ),
    );
  }
}

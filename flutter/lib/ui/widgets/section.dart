import 'package:flutter/material.dart';

import '../../utils/utils.dart';

/// Section provides a content container with:
/// - title
/// - back button
/// - outlined content space
/// - trailing widget for actions
class Section extends StatefulWidget {
  const Section({
    super.key,
    required this.title,
    required this.onEscapeKey,
    required this.child,
    this.indicator,
    this.action,
    this.trailing,
    this.onEnterKey,
  });
  
  /// The [title] for the section
  final String title;

  /// The [onEscapeKey] callback used to navigate back to the previous screen
  final Function()? onEscapeKey;

  /// The [child] contained by the section.
  final Widget child;

  /// The [indicator] provides a visual cue for the section
  final Widget? indicator;

  /// The [action] provides a visual cue for the section
  final Widget? action;

  /// The [trailing] widget to be displayed below to the right of the content
  final Widget? trailing;

  /// Optional callback to trigger when the enter key is pressed
  final Function()? onEnterKey;

  @override
  State<Section> createState() => _SectionState();
}

class _SectionState extends State<Section> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(
      builder: (context, constraints) {
      final mobile = utils.isMobile(constraints.maxWidth);

      return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        return utils.onKeys(context, event, [
          (utils.onEnterKey, widget.onEnterKey),
          (utils.onEscapeKey, widget.onEscapeKey),
        ]);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [

          // Header
          Row(
            children: [

              // Back button
              Transform.translate(
                offset: Offset(mobile ? -10 : 0, 0),
              child: Container(
                padding: EdgeInsets.all(isHover ? 0 : 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isHover ? Colors.black12: Colors.transparent,
                ),
                child: InkWell(
                  child: Icon(
                    Icons.arrow_back,
                    size: isHover ? 38 : 30,
                  ),
                  onHover: (val) {
                    setState(() { isHover = val; });
                  },
                  onTap: widget.onEscapeKey?.call,
                ),
              ),
              ),

              // Spacer
              SizedBox(width: mobile ? 10 : 20),

              // Title
              Text(widget.title, style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontSize: mobile ? 24 : null,
              )),

              // Indicator
              if (widget.indicator != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 10),
                  child: widget.indicator!,
                ),

              // On desktop, action sits inline to the right of the title
              if (!mobile && widget.action != null) ...[
                const Spacer(),
                widget.action!,
              ],
            ],
          ),

          // On mobile, action gets its own row below the title
          if (mobile && widget.action != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [Expanded(child: widget.action!)]),
            ),

          // Content — Expanded fills all remaining vertical space
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26, width: 2),
              ),
              child: Padding(
                padding: mobile
                  ? const EdgeInsets.fromLTRB(0, 0, 0, 20)
                  : const EdgeInsets.all(20),
                child: widget.child,
              ),
            ),
          ),

          // Trailing widget
          if (widget.trailing != null)
            widget.trailing!
        ],
      ),
    );
    });
  }
}
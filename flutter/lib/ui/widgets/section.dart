import 'package:flutter/material.dart';

/// Section provides a content container with:
/// - title
/// - back button
/// - outlined content space
/// - trailing widget for actions
class Section extends StatefulWidget {
  const Section({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.trailing,
  });
  
  /// The [title] for the section
  final String title;

  /// The [onBack] callback used to navigate back to the previous screen
  final VoidCallback? onBack;

  /// The [child] contained by the section.
  final Widget child;

  /// The [trailing] widget to be displayed below to the right of the content
  final Widget? trailing;

  @override
  State<Section> createState() => _SectionState();
}

class _SectionState extends State<Section> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // Header
        Row(
          children: [

            // Back button
            Container(
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
                onTap: widget.onBack?.call,
              ),
            ),

            // Spacer
            SizedBox(width: 20),

            // Title
            Text(widget.title, style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
    
        // Content
        Row(
          children: [
            Expanded(
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),

        // Trailing widget
        if (widget.trailing != null)
          widget.trailing!
      ],
    );
  }
}
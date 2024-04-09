import 'package:flutter/material.dart';

class VisibilityController extends StatefulWidget {
  final Widget expandedChild;
  final Widget collapsedChild;

  const VisibilityController({
    Key? key,
    required this.expandedChild,
    required this.collapsedChild,
  }) : super(key: key);

  @override
  _VisibilityControllerState createState() => _VisibilityControllerState();
}

class _VisibilityControllerState extends State<VisibilityController> {
  ScrollPosition? scrollPosition;
  bool isExpanded = true; // Initially assume it's expanded

  @override
  void dispose() {
    removeListener();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    removeListener();
    addListener();
  }

  void addListener() {
    scrollPosition = Scrollable.of(context).position;
    scrollPosition?.addListener(positionListener);
  }

  void removeListener() {
    scrollPosition?.removeListener(positionListener);
  }

  void positionListener() {
    final FlexibleSpaceBarSettings? settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    bool expanded =
        settings == null || settings.currentExtent > settings.minExtent;

    if (isExpanded != expanded) {
      setState(() {
        isExpanded = expanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: isExpanded
          ? Container(
              key: ValueKey<bool>(true),
              alignment: Alignment.topLeft,
              child: widget.expandedChild,
            )
          : Container(
              key: ValueKey<bool>(false),
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.only(left: 32.0), // Adjust as needed for alignment
              child: widget.collapsedChild,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Screens/donor_screen.dart' as dos;
import 'package:FoodHood/Components/colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final List<String> labels;
  final Color color;
  final bool isReserved;
  final dos.OrderState currentState;

  const ProgressBar({
    Key? key,
    required this.progress,
    required this.labels,
    required this.color,
    required this.isReserved,
    required this.currentState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double padding = 16.0;
    final double availableWidth =
        MediaQuery.of(context).size.width - padding * 2;
    final double itemExtent = availableWidth / labels.length;

    return Container(
      height: 60,
      alignment: Alignment.topCenter,
      child: FixedTimeline.tileBuilder(
        theme: TimelineThemeData(
          direction: Axis.horizontal,
          connectorTheme: ConnectorThemeData(space: 6.0, thickness: 3.0),
          nodePosition: 0,
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemCount: labels.length,
          itemExtentBuilder: (_, __) => itemExtent,
          oppositeContentsBuilder: (context, index) => Container(),
          contentsBuilder: (context, index) => _buildContent(context, index),
          indicatorBuilder: (_, index) =>
              _buildIndicator(index, context: context),
          connectorBuilder: (_, index, __) =>
              _buildConnector(index, context: context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int index) {
    final bool isCurrentState = labels[index] == _getStateText(currentState);
    return Padding(
        padding: EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0, right: 4.0),
        child: Text(
          labels[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: isReserved && isCurrentState
                ? CupertinoDynamicColor.resolve(CupertinoColors.label, context)
                : CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel, context),
          ),
        ));
  }

  Widget _buildIndicator(int index, {required BuildContext context}) {
    final int progressIndex = (progress * labels.length).toInt();
    return index < progressIndex
        ? DotIndicator(color: accentColor.resolveFrom(context))
        : OutlinedDotIndicator(
            borderWidth: 2.0, color: accentColor.resolveFrom(context));
  }

  Widget _buildConnector(int index, {required BuildContext context}) {
    final int progressIndex = (progress * labels.length).toInt();
    return index < progressIndex
        ? SolidLineConnector(
            color: tertiaryColor.resolveFrom(context), thickness: 4.0)
        : DashedLineConnector(
            color: tertiaryColor.resolveFrom(context), thickness: 3.0, dash: 3.0);
  }

  String _getStateText(dos.OrderState state) {
    switch (state) {
      case dos.OrderState.reserved:
        return "Reserved";
      case dos.OrderState.confirmed:
        return "Confirmed";
      case dos.OrderState.delivering:
        return "Delivering";
      case dos.OrderState.readyToPickUp:
        return "Dropped Off";
      default:
        return "Not Reserved";
    }
  }
}

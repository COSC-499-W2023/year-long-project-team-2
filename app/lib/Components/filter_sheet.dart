import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:FoodHood/Components/colors.dart';

class FilterSheet extends StatefulWidget {
  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String collectionDay = 'Today';
  List<String> selectedFoodTypes = [];
  List<String> selectedDietPreferences = [];
  RangeValues collectionTime = RangeValues(0, 24);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDragHandle(),
        _buildCustomNavigationBar(context),
        _buildFilterOptions(context),
        _buildBottomButtons(context),
      ],
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavigationBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Filter',
              style: TextStyle(
                  fontSize: 28,
                  letterSpacing: -1.3,
                  fontWeight: FontWeight.bold)),
          GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(FeatherIcons.x,
                  size: 24,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch to full width
          children: [
            _buildTitle('Collection day'),
            _buildSegmentedControl(),
            _buildTitle('Collection time'),
            _buildSlider(context),
            _buildTitle('Food types'),
            _buildCupertinoChoiceButtons(
                ['Meals', 'Bread & pastries', 'Groceries', 'Other'],
                selectedFoodTypes),
            _buildTitle('Diet preferences'),
            _buildCupertinoChoiceButtons(
                ['Vegetarian', 'Vegan'], selectedDietPreferences),
            SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              letterSpacing: -0.5,
              color: CupertinoColors.label.resolveFrom(context),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0), // Ensure full width
      child: CupertinoSlidingSegmentedControl<String>(
        children: {
          'Today': Text('Today'),
          'Tomorrow': Text('Tomorrow'),
        },
        onValueChanged: (String? value) {
          if (value != null) {
            setState(() {
              collectionDay = value;
            });
          }
        },
        groupValue: collectionDay,
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: SliderTheme(
          data: SliderThemeData(
            thumbColor: accentColor,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15.0),
          ),
          child: RangeSlider(
            values: collectionTime,
            activeColor: accentColor,
            inactiveColor: accentColor.withOpacity(0.3),
            min: 0,
            max: 24,
            divisions: 24,
            onChanged: (RangeValues newRange) {
              setState(() {
                collectionTime = newRange;
              });
            },
            labels: RangeLabels(
              _formatTime(collectionTime.start),
              _formatTime(collectionTime.end),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to format the time
  String _formatTime(double time) {
    final hours = time.toInt();
    final minutes = ((time - hours) * 60).toInt();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Widget _buildCupertinoChoiceButtons(
      List<String> options, List<String> selectedOptions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: options
            .map((option) => CupertinoButton(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  borderRadius: BorderRadius.circular(100),
                  color: selectedOptions.contains(option)
                      ? accentColor.resolveFrom(context)
                      : CupertinoColors.tertiarySystemBackground
                          .resolveFrom(context),
                  child: Text(option,
                      style: TextStyle(
                          color: selectedOptions.contains(option)
                              ? CupertinoColors.white
                              : CupertinoColors.label.resolveFrom(context))),
                  onPressed: () {
                    setState(() {
                      if (selectedOptions.contains(option)) {
                        selectedOptions.remove(option);
                      } else {
                        selectedOptions.add(option);
                      }
                    });
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            child: Text('Clear All',
                style: TextStyle(
                    color:
                        CupertinoColors.secondaryLabel.resolveFrom(context))),
            onPressed: () {
              setState(() {
                // Clear filter logic
              });
            },
          ),
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            color: accentColor,
            borderRadius: BorderRadius.circular(100),
            child: Text('Apply',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: CupertinoColors.white)),
            onPressed: () {
              // Apply filter logic
            },
          ),
        ],
      ),
    );
  }
}

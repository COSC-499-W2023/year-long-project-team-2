// saved_screen.dart 
// a page that displays the user's saved posts

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components.dart'; // Ensure this is the correct path to component.dart

// TODO: Implement SavedScreen
class SavedScreen extends StatelessWidget {
  // must be final otherwise the SavedScreen class is marked as immutable
  final TextEditingController textController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground, // background color
      child: CustomScrollView(
        slivers: <Widget>[
          buildMainNavigationBar(context, 'Saved'), // navigation bar
          SliverFillRemaining(
            child: Column(
              // TODO: Implement SavedScreen
              
            ),
          ),
        ],
      ),
    );
  }
}

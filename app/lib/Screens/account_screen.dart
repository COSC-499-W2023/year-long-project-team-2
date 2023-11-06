// account_screen.dart
// a page that displays the user's account information and settings

import 'package:flutter/cupertino.dart';
import '../components.dart';

class AccountScreen extends StatelessWidget {
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground, // background color
      child: CustomScrollView(
        slivers: <Widget>[
          buildMainNavigationBar(context, 'Account'), // navigation bar
          SliverFillRemaining(
            child: Column(
              
            ),
          ),
        ],
      ),
    );
  }
}

// navigation_screen.dart
// a page that displays the navigation bar and controls the navigation between the different pages of the app

import 'package:FoodHood/Screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:FoodHood/Screens/browse_screen.dart';
import 'package:FoodHood/Screens/new_post_screen.dart';
import 'package:FoodHood/Screens/saved_screen.dart';
import 'package:FoodHood/Screens/account_screen.dart';

// TODO: Implement NavigationScreen
class NavigationScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  // TODO: Add more parameters if necessary
  const NavigationScreen({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar( // tab bar
        height: 55,
        iconSize: 24,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        activeColor: Color(0xFF337586), // active tab color
        items: const [ // tab bar items
          BottomNavigationBarItem(icon: Icon(FeatherIcons.home)),
          BottomNavigationBarItem(icon: Icon(FeatherIcons.map)),
          BottomNavigationBarItem(icon: Icon(FeatherIcons.plusSquare)),
          BottomNavigationBarItem(icon: Icon(FeatherIcons.archive)),
          BottomNavigationBarItem(icon: Icon(FeatherIcons.user)),
        ],
      ),
      tabBuilder: (context, index) {
        // tab view content here
        // tab will show based on the 'index' parameter
        return CupertinoTabView(
          builder: (BuildContext context) {
            switch (index) {
              case 0:
                return HomeScreen();
              case 1:
                return BrowseScreen();
              case 2:
                return NewPostScreen();
              case 3:
                return SavedScreen();  
              case 4:
                return AccountScreen();
              // Add more cases for each screen
              default:
                return HomeScreen();
            }
          },
        );
      },
    );
  }
}

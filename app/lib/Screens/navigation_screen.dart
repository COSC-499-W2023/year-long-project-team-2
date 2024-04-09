import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/account_screen.dart';
import 'package:FoodHood/Screens/bookmark_screen.dart';
import 'package:FoodHood/Screens/browse_screen.dart';
import 'package:FoodHood/Screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class NavigationScreen extends StatelessWidget {
  static final List<Widget> _screens = [
    HomeScreen(),
    BrowseScreen(),
    BookmarkScreen(),
    AccountScreen(),
  ];
  static final List<BottomNavigationBarItem> _navBarItems = [
    const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.rectangle_stack),
        label: "Home",
        activeIcon: Icon(CupertinoIcons.rectangle_stack_fill)),
    const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.compass),
        label: "Browse",
        activeIcon: Icon(CupertinoIcons.compass_fill)),
    const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.bookmark),
        label: "Bookmarks",
        activeIcon: Icon(CupertinoIcons.bookmark_fill)),
    const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        label: "Account",
        activeIcon: Icon(CupertinoIcons.person_fill)),
  ];

  final int selectedIndex;

  final Function(int) onItemTapped;

  const NavigationScreen(
      {super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact(); // Add haptic feedback here
          onItemTapped(index);
        },
        iconSize: 24,
        backgroundColor:
            CupertinoDynamicColor.resolve(groupedBackgroundColor, context)
                .withOpacity(0.8),
        border: const Border(top: BorderSide.none),
        activeColor: accentColor.resolveFrom(context),
        inactiveColor:
            CupertinoColors.label.resolveFrom(context).withOpacity(0.6),
        items: _navBarItems,
      ),
      tabBuilder: (context, index) => _screens[index],
    );
  }
}

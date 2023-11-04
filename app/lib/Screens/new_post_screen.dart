
// new_post_screen.dart 
// a page that create a new post.
import 'package:flutter/cupertino.dart';
import '../components.dart'; // Ensure this is the correct path to component.dart

// TODO: Implement NewPostScreen
class NewPostScreen extends StatelessWidget {
  // must be final otherwise the NewPostScreen class is marked as immutable
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground, // background color
      child: CustomScrollView(
        slivers: <Widget>[
          buildMainNavigationBar(context, 'New Post'), // navigation bar
          SliverFillRemaining(
            child: Column(
              // TODO: Implement NewPostScreen
              
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/donee_screen.dart';

class ReserveButton extends StatefulWidget {
  final bool isReserved;
  final String postId;
  final String userId;

  const ReserveButton({
    Key? key,
    required this.isReserved,
    required this.postId,
    required this.userId,
  }) : super(key: key);

  @override
  _ReserveButtonState createState() => _ReserveButtonState();
}

class _ReserveButtonState extends State<ReserveButton> {
  late bool _isReserved;

  @override
  void initState() {
    super.initState();
    _isReserved = widget.isReserved;
  }

  void _handleReservation() async {
    if (!_isReserved) {
      HapticFeedback.mediumImpact();
      try {
        // Add a reserved_by field and update the post status in the post detail document
        await FirebaseFirestore.instance
            .collection('post_details')
            .doc(widget.postId)
            .update({'reserved_by': widget.userId, 'post_status': "pending"});

        // Get the current reserved posts of the user
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .get();

        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null) {
          // Initialize reserved_posts as an empty list if it doesn't exist
          List<String> reservedPosts =
              List<String>.from(userData['reserved_posts'] ?? []);

          // Append the postId to the reserved_posts list
          reservedPosts.add(widget.postId);

          // Update the user document with the new reserved_posts list
          await FirebaseFirestore.instance
              .collection('user')
              .doc(widget.userId)
              .set({'reserved_posts': reservedPosts}, SetOptions(merge: true));
        }

        setState(() {
          _isReserved = true;
        });
      } catch (error) {
        print('Error reserving post: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reserve post. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CupertinoButton(
        color: _isReserved
            ? accentColor.resolveFrom(context).withOpacity(0.2)
            : accentColor.resolveFrom(context).withOpacity(0.8),
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(14),
        child: Text(
          _isReserved
              ? 'Reserved'
              : 'Reserve', // Reflect reservation status in the text
          style: TextStyle(
            color: _isReserved
                ? Colors.grey
                : CupertinoColors.white, // Grey text to indicate disabled state
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.90,
          ),
        ),
        onPressed: _isReserved
            ? null
            : () {
                // Pass null to disable the button
                _handleReservation();
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => DoneePath(
                            postId: widget.postId,
                          )),
                );
              },
      ),
    );
  }
}

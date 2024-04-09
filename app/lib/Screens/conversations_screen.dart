import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/message_screen.dart';
import 'package:FoodHood/Services/AuthService.dart';
import 'package:FoodHood/Services/MessageService.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

class ConversationsScreen extends StatelessWidget {
  final MessageService messageService = MessageService();

  final AuthService authService = AuthService();
  ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              transitionBetweenRoutes: false, 
              backgroundColor: CupertinoDynamicColor.resolve(
                groupedBackgroundColor, context).withOpacity(0.8),
              largeTitle: Text('Messages'),
              border: null,
              leading: GestureDetector(
                child: Icon(FeatherIcons.chevronLeft,
                size: 24,
                    color: CupertinoColors.label.resolveFrom(context)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Compose',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                onPressed: () {},
              ),
            ),
            _buildMessageList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
  final Future<String?> currentUserIDFuture = authService.getUserId();
  return FutureBuilder<String?>(
    future: currentUserIDFuture,
    builder: (context, currentUserSnapshot) {
      if (!currentUserSnapshot.hasData) {
        return SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        );
      }
      final currentUserID = currentUserSnapshot.data;
      return StreamBuilder<QuerySnapshot>(
        stream: messageService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SliverFillRemaining(
              child: Center(
                child: Text('An error occurred. Please try again later.'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            var docs = snapshot.data!.docs.where((doc) => doc.id != currentUserID).toList(); // Filtering out the current user
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  var documentSnapshot = docs[index];
                  var userID = documentSnapshot.id;
                  var userData = documentSnapshot.data() as Map<String, dynamic>;
                  return _buildMessageCard(context, userData, userID);
                },
                childCount: docs.length,
              ),
            );
          } else {
            // Handle the case when there is no data
            return SliverFillRemaining(
              child: Center(
                child: Text('No messages found.'),
              ),
            );
          }
        },
      );
    },
  );
}


  Widget _buildMessageCard(
      BuildContext context, Map<String, dynamic> userData, String userID) {
    String profileURL = userData["profileImagePath"] ?? '';
    String title =
        '${userData["firstName"] ?? ''} ${userData["lastName"] ?? ''}'.trim();

    // Using StreamBuilder to listen for the latest message updates
    return StreamBuilder<Map<String, dynamic>?>(
      stream: messageService.getLastMessageStream(userID),
      builder: (context, snapshot) {
        String lastMessage = '';
        String time = '';

        // Checking if the stream has data and extracting the message details
        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData) {
          final data = snapshot.data;
          lastMessage = data?['message'] ?? '';
          DateTime timestamp =
              (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          time = DateFormat('h:mm a').format(timestamp);
        }

        // Building the list tile with the message details
        return CupertinoListTile(
          profileURL: profileURL,
          title: title,
          messagePreview: lastMessage,
          time: time,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => MessageScreen(receiverID: userID),
              ),
            );
          },
        );
      },
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final String profileURL;
  final String title;
  final String messagePreview;
  final String time;
  final VoidCallback onTap;

  const CupertinoListTile({
    Key? key,
    required this.profileURL,
    required this.title,
    required this.messagePreview,
    required this.time,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var parser = EmojiParser();
    bool containsEmoji = parser.hasEmoji(messagePreview);
    String emojiStrippedMessage =
        containsEmoji ? parser.emojify(messagePreview) : messagePreview;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: CupertinoColors.systemGrey4.resolveFrom(context),
              backgroundImage: profileURL.isNotEmpty
                  ? CachedNetworkImageProvider(profileURL)
                  : null,
              child: profileURL.isEmpty
                  ? Text(
                      title.isNotEmpty ? title[0].toUpperCase() : "",
                      style: TextStyle(
                          fontSize: 20,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context)),
                    )
                  : null,
            ),
            SizedBox(width: 16),
            // Message preview and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label.resolveFrom(context),
                        fontWeight: FontWeight.w600,
                      )),
                  if (messagePreview.isNotEmpty) ...[
                    Text(
                      emojiStrippedMessage,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: containsEmoji
                            ? Colors.transparent
                            : CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Text(time,
                style: TextStyle(
                    fontSize: 14,
                    color:
                        CupertinoColors.secondaryLabel.resolveFrom(context))),
            Icon(CupertinoIcons.forward,
                size: 18,
                color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          ],
        ),
      ),
    );
  }
}

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/public_profile_screen.dart';
import '../auth_service.dart';
import '../firestore_service.dart';

class MessageScreenPage extends StatefulWidget {
  @override
  _MessageScreenPageState createState() => _MessageScreenPageState();
}

class _MessageScreenPageState extends State<MessageScreenPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> recommendedMessages = [
    "Sure, see you then!",
    "On my way.",
    "Can we reschedule?",
    "Let me check my calendar.",
    "Running late, sorry!",
  ];

  final AuthService _authService = AuthService(FirebaseAuth.instance);
  late String myUid;

  @override
  void initState() {
    super.initState();

    // Fetch the user ID when the widget initializes
    _authService.getUserId().then((userId) {
      setState(() {
        myUid = userId ?? ''; // Set the user ID to the variable, defaulting to an empty string if null
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: CupertinoDynamicColor.resolve(
        backgroundColor,
        context,
      ),
      body: SafeArea(
        child: _buildPageContent(),
      ),
    );
  }

  Widget _buildPageContent() {
    return Column(
      children: <Widget>[
        Expanded(
          child: _buildMessagesList(),
        ),
        _buildMessageInput(),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      leading: _buildBackButton(),
      backgroundColor: CupertinoDynamicColor.resolve(
        backgroundColor,
        context,
      ),
      centerTitle: false,
      title: _buildContactName(),
      actions: [_buildTrailingItems()],
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildTrailingItems() {
    return Container(
      padding: EdgeInsets.only(right: 16),
      child: Row(
        children: [
          _buildOnlineIndicator(),
          _buildLastSeenText(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: Icon(FeatherIcons.chevronLeft,
          size: 22, color: CupertinoColors.label.resolveFrom(context)),
      onPressed: () => Navigator.of(context).pop(),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
    );
  }

  Widget _buildContactName() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => PublicProfileScreen()),
        );
      },
      child: Text(
        'Harry Styles',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: CupertinoColors.label.resolveFrom(context),
          letterSpacing: -1.3,
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Container(
      width: 10,
      height: 10,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.activeGreen,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLastSeenText() {
    return Text(
      'Last seen a minute ago',
      style: TextStyle(
        fontSize: 14,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMessagesList() {
    int lastReadMessageIndex = messages
        .lastIndexWhere((message) => !message["received"] && message["read"]);

    return Expanded(
      child: ListView.builder(
        controller: _scrollController, // Use the controller here

        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          bool shouldShowReadReceipt = index == lastReadMessageIndex;

          return Column(
            crossAxisAlignment: message["received"]
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              _buildMessage(
                message["text"],
                received: message["received"],
              ),
              // Show read receipt only for the last read message sent by the user
              if (shouldShowReadReceipt)
                Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    right: !message["received"] ? 16 : 0,
                    left: message["received"] ? 16 : 0,
                  ),
                  child: Text(
                    "Read",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessage(String message, {bool received = true}) {
    return Container(
      margin: EdgeInsets.only(
        top: 8,
        left: received ? 16 : 0,
        right: received ? 0 : 16,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: received
            ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
            : accentColor,
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.6,
          color: received
              ? CupertinoColors.label.resolveFrom(context)
              : CupertinoColors.white,
        ),
      ),
    );
  }

  Widget _buildQuickMessageSuggestions() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      height: 40, // Adjust the height as necessary
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendedMessages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _quickMessageTap(recommendedMessages[index]),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  recommendedMessages[index],
                  style: TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _quickMessageTap(String message) {
    _messageController.text = message;
  }

  Widget _buildMessageInput() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickMessageSuggestions(), // Quick message suggestions row
          Container(
            margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: TextField(
              controller: _messageController,
              style: TextStyle(
                fontSize: 16.0, // Custom font size
                color: CupertinoColors.label.resolveFrom(context),
                letterSpacing: -0.6, // Custom letter spacing
                fontWeight: FontWeight.w400, // Custom font weight
                // Add any other TextStyle properties you need
              ),
              decoration: InputDecoration(
                hintText: "Message Harry",
                hintStyle: TextStyle(
                  letterSpacing: -0.6,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                suffixIcon: GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin:
                        EdgeInsets.all(12), // Symmetric padding for the icon
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FeatherIcons.arrowUp,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      setState(() {
        messages.add({
          "text": messageText,
          "received": false, // Assuming the user is sending the message
          "read": false, // New messages start as unread
        });
      });
      _messageController.clear();

      // Automatically scroll to the latest message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Simulate receiving a reply after a delay
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          messages.add({
            "text": "Auto-reply to: $messageText",
            "received": true,
            "read": true,
          });

          // Mark the user's last message as read
          if (messages.isNotEmpty) {
            messages[messages.length - 2]["read"] = true;
          }
        });

        // Scroll to the bottom to show the auto-reply
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

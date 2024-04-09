import 'package:FoodHood/Components/components.dart';
import 'package:FoodHood/Components/Message/message_bubble.dart';
import 'package:FoodHood/Components/Message/message_input_row.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/profile_screen.dart';
import 'package:FoodHood/Services/AuthService.dart';
import 'package:FoodHood/Services/MessageService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:pull_down_button/pull_down_button.dart';

class MessageScreen extends StatefulWidget {
  final String receiverID;

  const MessageScreen({super.key, required this.receiverID});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();

  late MessageService messageService;
  late AuthService authService;
  late Future<String> receiverName;
  late String? senderID;
  late Future<String> receiverImage;

  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: CupertinoDynamicColor.resolve(backgroundColor, context),
      body: SafeArea(child: _buildPageContent(context)),
    );
  }

  Future<String> getReceiverName() async {
    var receiverData = await messageService.getReceiverData(widget.receiverID);
    return receiverData["firstName"] + " " + receiverData["lastName"];
  }

  void getSenderID() async {
    senderID = await authService.getUserId();
  }

  @override
  void initState() {
    super.initState();
    messageService = MessageService();
    authService = AuthService();
    receiverName = getReceiverName();
    getSenderID();

    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible) {
        Future.delayed(Duration(milliseconds: 400), scrollDown);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        const Duration(milliseconds: 400),
        () => scrollDown(),
      );
    });

    setupMessageListener();
  }

  void setupMessageListener() async {
    String? userId = await authService.getUserId();
    if (!mounted) return;
    if (userId != null) {
      messageService
          .getMessages(userId, widget.receiverID)
          .listen((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          scrollDown();
        }
      });
    }
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void sendMessage() async {
    final message = messageController.text;
    if (message.isNotEmpty) {
      await messageService.sendMessage(widget.receiverID, message);
      messageController.clear();
      scrollDown();
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: CupertinoButton(
          child: Icon(FeatherIcons.chevronLeft,
              size: 24, color: CupertinoColors.label.resolveFrom(context)),
          onPressed: () => Navigator.of(context).pop()),
      backgroundColor: CupertinoDynamicColor.resolve(backgroundColor, context)
          .withOpacity(0.1),
      centerTitle: false,
      title: GestureDetector(
        onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) =>
                    ProfileScreen(userId: widget.receiverID))),
        child: FutureBuilder<String>(
          future: receiverName,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context)));
            } else {
              return Text("",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context)));
            }
          },
        ),
      ),
      actions: <Widget>[
        PullDownButton(
          itemBuilder: (context) => [
            PullDownMenuItem(
              title: 'Block user',
              icon: FeatherIcons.user,
              isDestructive: true,
              onTap: () {},
            ),
          ],
          buttonBuilder: (context, showMenu) => CupertinoButton(
            onPressed: showMenu,
            padding: EdgeInsets.zero,
            child: Icon(FeatherIcons.moreVertical,
                size: 18, color: CupertinoColors.label.resolveFrom(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(
      DocumentSnapshot document, String senderID, BuildContext context) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    return MessageBubble(
        message: data['message'],
        isCurrentUser: data['senderID'] == senderID,
        timestamp: data['timestamp'],
        messageID: document.id,
        conversationID: document.reference.parent.parent!.id);
  }

  Widget _buildMessageList(BuildContext context) {
    return FutureBuilder<String?>(
      future: authService.getUserId(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('An error occurred. Please try again later.'),
          );
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final String currentUserId = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream:
                messageService.getMessages(currentUserId, widget.receiverID),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FeatherIcons.messageSquare,
                            size: 38,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context)),
                        const SizedBox(height: 16),
                        Text(
                          "No messages found.",
                          style: TextStyle(
                              fontSize: 16,
                              letterSpacing: -0.4,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context)),
                        ),
                      ],
                    ),
                  );
                }
                DateTime? previousDate;
                return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      controller: scrollController,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot document =
                            docs[docs.length - 1 - index];
                        final DateTime messageDate =
                            document['timestamp'].toDate();

                        bool isNewDay = previousDate == null ||
                            messageDate.day != previousDate?.day;
                        previousDate = messageDate;

                        return Column(
                          children: [
                            if (isNewDay)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  determineDate(messageDate),
                                  style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: -0.2,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context)),
                                ),
                              ),
                            MessageBubble(
                              message: document['message'],
                              isCurrentUser:
                                  document['senderID'] == currentUserId,
                              timestamp: document['timestamp'],
                              conversationID:
                                  document.reference.parent.parent!.id,
                              messageID: document.id,
                            ),
                          ],
                        );
                      },
                    ));
              } else if (snapshot.hasError) {
                return const Text("Error loading messages");
              }
              return const SizedBox();
            },
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: _buildMessageList(context)),
        FutureBuilder<String>(
          future: receiverName,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text("Error loading name");
            } else {
              return MessageInputRow(
                  firstName: snapshot.data?.split(' ').first ?? '',
                  messageController: messageController,
                  sendMessage: sendMessage,
                  focusNode: focusNode);
            }
          },
        ),
      ],
    );
  }
}

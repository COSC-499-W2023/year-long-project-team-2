import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/components.dart';
import 'package:FoodHood/Services/MessageService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'dart:ui' as ui;

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isCurrentUser;
  final Timestamp timestamp;
  final String conversationID;
  final String messageID;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.timestamp,
    required this.conversationID,
    required this.messageID,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  Widget? emojiOverlay;
  final MessageService messageService = MessageService();
  static final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment:
          widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Align(
        alignment:
            widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          children: [
            _messageContent(context),
            if (emojiOverlay != null) _emojiOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _messageContent(BuildContext context) => Column(
        crossAxisAlignment: widget.isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildPullDownButton(context),
          _buildTimestamp(),
        ],
      );

  Widget _buildPullDownButton(BuildContext context) => PullDownButton(
        itemBuilder: (context) => [
          _copyTextMenuItem(),
          const PullDownMenuDivider.large(),
          const PullDownMenuTitle(title: Text('Reactions')),
          _likeMenuItem(),
          _thumbsUpMenuItem(),
          if (widget.isCurrentUser) ...[
            const PullDownMenuDivider.large(),
            _deleteMessageMenuItem(),
          ],
        ],
        buttonBuilder: (context, showMenu) => GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              showMenu();
            },
            child: _bubbleBackground(context)),
      );

  PullDownMenuItem _deleteMessageMenuItem() => PullDownMenuItem(
        isDestructive: true,
        title: 'Remove Message',
        icon: CupertinoIcons.trash,
        onTap: () => _deleteMessage(),
      );

  void _deleteMessage() async {
    try {
      await messageService.deleteMessage(
          widget.conversationID, widget.messageID);
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  PullDownMenuItem _copyTextMenuItem() => PullDownMenuItem(
        title: 'Copy text',
        icon: CupertinoIcons.doc_on_clipboard,
        onTap: () => Clipboard.setData(ClipboardData(text: widget.message)),
      );

  PullDownMenuItem _likeMenuItem() => PullDownMenuItem(
        title: 'Heart',
        icon: CupertinoIcons.heart_fill,
        iconColor: babyPink,
        onTap: () => _reactToMessage(
            '❤️', Icon(CupertinoIcons.heart_fill, size: 32, color: babyPink)),
      );

  PullDownMenuItem _thumbsUpMenuItem() => PullDownMenuItem(
        title: 'Thumbs up',
        icon: CupertinoIcons.hand_thumbsup_fill,
        iconColor: blue,
        onTap: () => _reactToMessage(
            '👍', const Text('👍', style: TextStyle(fontSize: 28))),
      );

  Widget _bubbleBackground(BuildContext context) => BubbleBackground(
        isCurrentUser: widget.isCurrentUser,
        colors: widget.isCurrentUser
            ? [lighten(blue, 0.1), darken(blue, 0.1)]
            : [
                CupertinoColors.systemGrey5.resolveFrom(context),
                CupertinoColors.systemGrey4.resolveFrom(context)
              ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(widget.message,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.6,
                  color: _getTextColor(context))),
        ),
      );

  Widget _buildTimestamp() => Container(
        margin: EdgeInsets.only(
            left: widget.isCurrentUser ? 0 : 16,
            right: widget.isCurrentUser ? 16 : 0,
            top: 0,
            bottom: 4),
        child: Text(determineDateTime(widget.timestamp),
            style: TextStyle(
                fontSize: 10,
                letterSpacing: -0.2,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context))),
      );

  Color _getTextColor(BuildContext context) => widget.isCurrentUser
      ? CupertinoColors.white
      : CupertinoColors.label.resolveFrom(context);

  Widget _emojiOverlay() => Positioned(
        top: 0,
        left: widget.isCurrentUser ? 0 : null,
        right: widget.isCurrentUser ? null : 0,
        child: Container(child: emojiOverlay),
      );

  void _reactToMessage(String reaction, Widget overlay) {
    messageService.reactToMessage(
        widget.conversationID, widget.messageID, reaction);
    setState(() => emojiOverlay = overlay);
  }

  @override
  void initState() {
    super.initState();
    fetchAndSetReactions();
  }

  void fetchAndSetReactions() async {
    final reactions = await messageService.getReactions(
        widget.conversationID, widget.messageID);
    if (!mounted) return;
    if (reactions != null && reactions.isNotEmpty) {
      if (reactions.containsValue('❤️')) {
        setState(() {
          emojiOverlay =
              Icon(CupertinoIcons.heart_fill, size: 32, color: babyPink);
        });
      } else if (reactions.containsValue('👍')) {
        setState(() {
          emojiOverlay = const Text('👍', style: TextStyle(fontSize: 28));
        });
      }
    }
  }

  static bool isOnlyEmoji(String text) => emojiRegex.hasMatch(text);
}

class BubbleBackground extends StatelessWidget {
  const BubbleBackground({
    super.key,
    required this.colors,
    this.child,
    required this.isCurrentUser,
  });

  final List<Color> colors;
  final Widget? child;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(isCurrentUser ? 18 : 0),
          bottomRight: Radius.circular(isCurrentUser ? 0 : 18),
        ),
        child: CustomPaint(
          painter: BubblePainter(
            scrollable: Scrollable.of(context),
            bubbleContext: context,
            colors: colors,
          ),
          child: child,
        ),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  BubblePainter({
    required ScrollableState scrollable,
    required BuildContext bubbleContext,
    required List<Color> colors,
  })  : _scrollable = scrollable,
        _bubbleContext = bubbleContext,
        _colors = colors,
        super(repaint: scrollable.position);

  final ScrollableState _scrollable;
  final BuildContext _bubbleContext;
  final List<Color> _colors;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollableBox = _scrollable.context.findRenderObject() as RenderBox;
    final scrollableRect = Offset.zero & scrollableBox.size;
    final bubbleBox = _bubbleContext.findRenderObject() as RenderBox;

    final origin =
        bubbleBox.localToGlobal(Offset.zero, ancestor: scrollableBox);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        scrollableRect.topCenter,
        scrollableRect.bottomCenter,
        _colors,
        [0.0, 1.0],
        TileMode.clamp,
        Matrix4.translationValues(-origin.dx, -origin.dy, 0.0).storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return oldDelegate._scrollable != _scrollable ||
        oldDelegate._bubbleContext != _bubbleContext ||
        oldDelegate._colors != _colors;
  }
}

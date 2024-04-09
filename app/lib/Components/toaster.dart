import 'package:flutter/cupertino.dart';

class Toaster {
  static void show(BuildContext context, String message) {
    var overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToasterOverlay(
        message: message,
        onDismiss: () => overlayEntry?.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToasterOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ToasterOverlay({
    Key? key,
    required this.message,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _ToasterOverlayState createState() => _ToasterOverlayState();
}

class _ToasterOverlayState extends State<_ToasterOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation; // Define fade animation

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn)); // Initialize fade animation

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 2)).then((_) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 68.0,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          // Use FadeTransition for opacity animation
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(61, 0, 0, 0),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

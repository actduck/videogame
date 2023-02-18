import 'package:flutter/material.dart';

class BlinkingContainer extends StatefulWidget {
  final Widget child;

  BlinkingContainer({Key? key, required this.child}) : super(key: key);

  @override
  _BlinkingContainerState createState() => _BlinkingContainerState();
}

class _BlinkingContainerState extends State<BlinkingContainer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = new AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

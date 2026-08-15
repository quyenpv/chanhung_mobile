import 'package:flutter/material.dart';

/// Restrained entrance motion derived from the Fitness template family.
class TemplateEntrance extends StatefulWidget {
  const TemplateEntrance({
    super.key,
    required this.child,
    this.order = 0,
  });

  final Widget child;
  final int order;

  @override
  State<TemplateEntrance> createState() => _TemplateEntranceState();
}

class _TemplateEntranceState extends State<TemplateEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final staggerStart = widget.order.clamp(0, 5) * .08;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(staggerStart, 1, curve: Curves.fastOutSlowIn),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _position = Tween<Offset>(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

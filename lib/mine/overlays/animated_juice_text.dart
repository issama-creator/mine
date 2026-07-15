import 'package:flutter/material.dart';

/// Pops and glows when combo / frenzy / perfect text changes.
class AnimatedJuiceText extends StatefulWidget {
  const AnimatedJuiceText({
    super.key,
    required this.text,
    required this.style,
    this.glowColor,
  });

  final String text;
  final TextStyle style;
  final Color? glowColor;

  @override
  State<AnimatedJuiceText> createState() => _AnimatedJuiceTextState();
}

class _AnimatedJuiceTextState extends State<AnimatedJuiceText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 1.22), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedJuiceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? widget.style.color ?? Colors.white;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        alignment: Alignment.centerLeft,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.glowColor != null)
            Text(
              widget.text,
              style: widget.style.copyWith(
                color: glow.withValues(alpha: 0.35),
                shadows: [
                  Shadow(blurRadius: 14, color: glow.withValues(alpha: 0.85)),
                  Shadow(blurRadius: 28, color: glow.withValues(alpha: 0.45)),
                ],
              ),
            ),
          Text(widget.text, style: widget.style),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

// Kullanım:
//   AnimatedPressButton(
//     onPressed: () => doSomething(),
//     child: const Text('Devam'),
//   )

class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double scaleAmount;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.scaleAmount = 0.96,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  void _onTap() {
    if (widget.onPressed != null) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ?? cs.primary;
    final br = widget.borderRadius ?? BorderRadius.circular(16);
    final pd = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16);

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.onPressed != null ? _onTap : null,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: widget.onPressed != null
              ? bg
              : cs.onSurface.withValues(alpha: 0.12),
          borderRadius: br,
          child: InkWell(
            onTap: null,
            borderRadius: br,
            splashColor: cs.onPrimary.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: pd,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: widget.onPressed != null
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.38),
                    ),
                child: IconTheme(
                  data: IconThemeData(
                    color: widget.onPressed != null
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.38),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

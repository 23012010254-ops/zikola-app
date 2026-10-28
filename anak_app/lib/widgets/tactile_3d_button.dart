import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';

class Tactile3DButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color? shadowColor;
  final Color textColor;
  final double depth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool isFullWidth;
  final bool enabled;
  final bool playSound;

  const Tactile3DButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    this.onPressed,
    this.backgroundColor = const Color(0xFF10B981), // default emerald green
    this.shadowColor,
    this.textColor = Colors.white,
    this.depth = 5.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    this.width,
    this.height,
    this.isFullWidth = false,
    this.enabled = true,
    this.playSound = true,
  });

  @override
  State<Tactile3DButton> createState() => _Tactile3DButtonState();
}

class _Tactile3DButtonState extends State<Tactile3DButton> {
  bool _isPressed = false;

  Color _getShadowColor() {
    if (widget.shadowColor != null) return widget.shadowColor!;
    final hsl = HSLColor.fromColor(widget.backgroundColor);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    if (widget.playSound) {
      AudioService().playClick();
    }
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() {
      _isPressed = false;
    });
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadowColor = widget.enabled && widget.onPressed != null
        ? _getShadowColor()
        : const Color(0xFF94A3B8);
    final effectiveBgColor = widget.enabled && widget.onPressed != null
        ? widget.backgroundColor
        : const Color(0xFFE2E8F0);
    final effectiveTextColor = widget.enabled && widget.onPressed != null
        ? widget.textColor
        : const Color(0xFF94A3B8);

    final double activeDepth = widget.depth;
    final double currentOffset = _isPressed ? activeDepth : 0.0;
    final double remainingDepth = activeDepth - currentOffset;

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 8),
          ],
          if (widget.text != null)
            Text(
              widget.text!,
              style: TextStyle(
                color: effectiveTextColor,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOutQuad,
        width: widget.isFullWidth ? double.infinity : widget.width,
        height: widget.height != null ? (widget.height! + activeDepth) : null,
        padding: EdgeInsets.only(top: currentOffset, bottom: remainingDepth),
        child: Container(
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveShadowColor,
                offset: Offset(0, remainingDepth),
                blurRadius: 0,
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}

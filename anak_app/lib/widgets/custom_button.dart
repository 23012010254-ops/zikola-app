import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CustomButtonVariant { primary, secondary, outline, text, google }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow>? boxShadow;

    switch (widget.variant) {
      case CustomButtonVariant.primary:
        bgColor = AppTheme.orange500;
        textColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: AppTheme.orange500.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ];
        break;
      case CustomButtonVariant.secondary:
        bgColor = AppTheme.sky300;
        textColor = AppTheme.gray900;
        break;
      case CustomButtonVariant.outline:
        bgColor = Colors.transparent;
        textColor = AppTheme.gray800;
        borderSide = const BorderSide(color: AppTheme.gray200, width: 2);
        break;
      case CustomButtonVariant.text:
        bgColor = Colors.transparent;
        textColor = AppTheme.orange500;
        break;
      case CustomButtonVariant.google:
        bgColor = AppTheme.gray800;
        textColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: AppTheme.gray800.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ];
        break;
    }

    if (widget.isLoading || widget.onPressed == null) {
      if (widget.variant == CustomButtonVariant.primary) bgColor = AppTheme.orange300;
      if (widget.variant == CustomButtonVariant.google) bgColor = AppTheme.gray200;
      if (widget.variant == CustomButtonVariant.google) textColor = AppTheme.gray400;
    }

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null && !widget.isLoading ? (_) {
        _controller.reverse();
        widget.onPressed!();
      } : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(borderSide),
            boxShadow: widget.onPressed != null && !widget.isLoading ? boxShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.isLoading ? 'Loading...' : widget.text,
                style: AppTheme.buttonText.copyWith(
                  color: textColor,
                  fontFamily: widget.variant == CustomButtonVariant.google ? 'Nunito' : 'Fredoka',
                  fontWeight: widget.variant == CustomButtonVariant.google ? FontWeight.w600 : FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

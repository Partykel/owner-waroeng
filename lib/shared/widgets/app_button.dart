import '../../core/services/app_feedback.dart';
import 'package:owner_waroeng/shared/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AppButtonType { primary, secondary, danger, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildButton(BuildContext context) {
    final VoidCallback? callback = isLoading || onPressed == null
        ? null
        : () {
            AppFeedback.play();
            onPressed!();
          };
    if (type == AppButtonType.text) {
      return TextButton(onPressed: callback, child: _buildChild(context));
    }

    return ElevatedButton(
      onPressed: callback,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(context),
        foregroundColor: _getForegroundColor(context),
        elevation: 0,
        minimumSize: Size(48, 54),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppPalette.of(context).controlRadius,
          ),
        ),
      ),
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.text
                ? AppPalette.of(context).primary
                : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 18),
          SizedBox(width: 8),
          Flexible(child: Text(text, textAlign: TextAlign.center)),
        ],
      );
    }

    return Text(text, textAlign: TextAlign.center);
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case AppButtonType.primary:
        return AppPalette.of(context).primary;
      case AppButtonType.secondary:
        return AppPalette.of(context).surfaceMuted;
      case AppButtonType.danger:
        return AppPalette.of(context).danger;
      case AppButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(BuildContext context) {
    if (type == AppButtonType.text) {
      return AppPalette.of(context).primary;
    }
    return type == AppButtonType.secondary
        ? AppPalette.of(context).textPrimary
        : Colors.white;
  }
}

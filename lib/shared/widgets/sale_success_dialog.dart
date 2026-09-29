import '../../core/services/app_feedback.dart';
import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../constants/app_colors.dart';

Future<void> showSaleSuccess(BuildContext context, double total) {
  AppFeedback.play(success: true);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    animationStyle: AnimationStyle(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
    ),
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Penjualan tersimpan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 420),
                builder: (context, value, _) => Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: CustomPaint(
                    painter: _CheckPainter(
                      value,
                      AppPalette.of(context).primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                CurrencyFormatter.format(total),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Penjualan dan stok sudah diperbarui.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress, this.color);
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .12, size.height * .52)
      ..lineTo(size.width * .4, size.height * .8)
      ..lineTo(size.width * .9, size.height * .2);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress || old.color != color;
}

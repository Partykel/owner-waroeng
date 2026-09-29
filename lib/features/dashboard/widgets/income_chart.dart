import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// One finite sequence: seven 350 ms bars, then the supplied 1930 ms sprite.
class IncomeChart extends StatefulWidget {
  const IncomeChart({
    super.key,
    required this.data,
    required this.scrollController,
  });
  final List<Map<String, dynamic>> data;
  final ScrollController scrollController;
  @override
  State<IncomeChart> createState() => _IncomeChartState();
}

class _IncomeChartState extends State<IncomeChart>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  bool _entered = false, _scheduled = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  static const _durations = [
    180,
    70,
    70,
    90,
    60,
    60,
    60,
    70,
    90,
    100,
    90,
    70,
    60,
    60,
    60,
    60,
    70,
    60,
    70,
    80,
    70,
    70,
    90,
    170,
  ];
  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4380),
    );
    widget.scrollController.addListener(_schedule);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant IncomeChart old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController.removeListener(_schedule);
      widget.scrollController.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state != AppLifecycleState.resumed) {
      _entered = false;
      _animation.reset();
      return;
    }
    _schedule();
  }

  @override
  void didChangeMetrics() => _schedule();
  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _checkVisibility();
    });
  }

  void _checkVisibility() {
    final render = context.findRenderObject();
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (render is! RenderBox ||
        viewport is! RenderBox ||
        !render.hasSize ||
        !viewport.hasSize) {
      return;
    }
    final rect = render.localToGlobal(Offset.zero) & render.size;
    final view = viewport.localToGlobal(Offset.zero) & viewport.size;
    final visible = rect.intersect(view);
    final active =
        TickerMode.valuesOf(context).enabled &&
        _lifecycle == AppLifecycleState.resumed &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (!active || visible.isEmpty) {
      _entered = false;
      _animation.reset();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _entered = true;
      _animation.value = 1;
      return;
    }
    if (!_entered && visible.height / rect.height >= .35) {
      _entered = true;
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context), now = DateTime.now();
    final incomes = {
      for (final row in widget.data)
        row['date'] as String: (row['income'] as num).toDouble(),
    };
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final values = [
      for (final day in days)
        incomes[DateFormat('yyyy-MM-dd').format(day)] ?? 0.0,
    ];
    if (values.every((v) => v == 0)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('Belum ada data penjualan minggu ini'),
      );
    }
    final maximum = math.max(1000.0, values.reduce(math.max)) * 1.05;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final ms = _animation.value * 4380;
          var elapsed = 0, frame = 23;
          for (var i = 0; i < _durations.length; i++) {
            elapsed += _durations[i];
            if (ms - 2450 < elapsed) {
              frame = i;
              break;
            }
          }
          final celebrating =
              ms >= 2450 &&
              ms < 4380 &&
              !MediaQuery.disableAnimationsOf(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 64, bottom: 14),
                child: Text('Dalam ribuan rupiah'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(7, (i) {
                  final fraction = Curves.easeOutCubic.transform(
                    ((ms - i * 350) / 350).clamp(0.0, 1.0),
                  );
                  final height = 150 * values[i] / maximum;
                  return Expanded(
                    child: Semantics(
                      label:
                          '${DateFormat('EEEE', 'id_ID').format(days[i])}, ${CurrencyFormatter.format(values[i])}',
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 150,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    for (final y in [0.0, 50.0, 100.0])
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: y,
                                        child: Divider(
                                          height: 1,
                                          color: palette.divider,
                                        ),
                                      ),
                                    FractionallySizedBox(
                                      widthFactor: .7,
                                      child: Container(
                                        key: ValueKey('income-bar-$i'),
                                        height: height * fraction,
                                        decoration: BoxDecoration(
                                          color: palette.primary.withValues(
                                            alpha: i == 6 ? 1 : .65,
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(5),
                                              ),
                                        ),
                                      ),
                                    ),
                                    if (i == 6 && celebrating)
                                      Positioned(
                                        bottom: math.max(0, height - 40),
                                        height: 92,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: OverflowBox(
                                            maxWidth: 80,
                                            maxHeight: 92,
                                            minWidth: 80,
                                            minHeight: 92,
                                            alignment: Alignment.bottomCenter,
                                            child: SizedBox(
                                              key: const ValueKey(
                                                'chart-celebration',
                                              ),
                                              width: 80,
                                              height: 92,
                                              child: ClipRect(
                                                child: OverflowBox(
                                                  alignment: Alignment.topLeft,
                                                  maxWidth: 1920,
                                                  minWidth: 1920,
                                                  maxHeight: 92,
                                                  minHeight: 92,
                                                  child: Transform.translate(
                                                    offset: Offset(
                                                      -frame * 80.0,
                                                      0,
                                                    ),
                                                    child: Image.asset(
                                                      'assets/animations/cuteGirl-spritesheet.png',
                                                      width: 1920,
                                                      height: 92,
                                                      fit: BoxFit.fill,
                                                      filterQuality:
                                                          FilterQuality.none,
                                                      errorBuilder: (_, _, _) =>
                                                          const SizedBox(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('E', 'id_ID').format(days[i]),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Tooltip(
                                message: CurrencyFormatter.format(values[i]),
                                child: Text(
                                  NumberFormat.compact(
                                    locale: 'id_ID',
                                  ).format(values[i] / 1000),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

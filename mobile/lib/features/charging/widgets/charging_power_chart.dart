import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/providers/core_providers.dart';

class ChargingPowerChart extends StatelessWidget {
  final List<PowerSample> samples;
  final double currentPowerKw;
  final bool hasConnectionError;
  final VoidCallback? onRetry;

  const ChargingPowerChart({
    super.key,
    required this.samples,
    required this.currentPowerKw,
    this.hasConnectionError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart_rounded, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Charging Power',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Real-time power delivery curve (kW)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentPowerKw.toStringAsFixed(1)} kW',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),

          if (hasConnectionError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Unable to update charging data',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                  if (onRetry != null)
                    InkWell(
                      onTap: onRetry,
                      child: const Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            height: 180,
            width: double.infinity,
            child: samples.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart_rounded, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'Waiting for charging data...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Telemetry streaming from charger',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    painter: _ChargingPowerChartPainter(
                      samples: samples,
                      isDark: isDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChargingPowerChartPainter extends CustomPainter {
  final List<PowerSample> samples;
  final bool isDark;

  _ChargingPowerChartPainter({
    required this.samples,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    const double leftPadding = 36.0;
    const double bottomPadding = 24.0;
    const double rightPadding = 12.0;
    const double topPadding = 12.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    double maxKw = samples.map((e) => e.powerKw).reduce(math.max);
    if (maxKw < 30.0) maxKw = 30.0;
    maxKw = (maxKw / 10).ceil() * 10.0;

    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      fontSize: 10,
      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 3; i++) {
      final double val = (maxKw / 3) * i;
      final double y = topPadding + chartHeight - (i / 3) * chartHeight;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      textPainter.text = TextSpan(text: '${val.toInt()} kW', style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final List<Offset> points = [];
    final int count = samples.length;

    for (int i = 0; i < count; i++) {
      final sample = samples[i];
      final double x = count == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i / (count - 1)) * chartWidth;
      final double y = topPadding + chartHeight - (sample.powerKw / maxKw) * chartHeight;
      points.add(Offset(x, y));
    }

    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlP1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlP2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p2.dx, p2.dy);
    }

    final Path fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, topPadding + chartHeight);
    fillPath.lineTo(points.first.dx, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF16A34A).withOpacity(0.35),
            const Color(0xFF16A34A).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    final lastPoint = points.last;
    final dotOuterPaint = Paint()
      ..color = const Color(0xFF16A34A).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(lastPoint, 7, dotOuterPaint);
    canvas.drawCircle(lastPoint, 3.5, dotInnerPaint);

    if (count > 0) {
      final startTimeStr = DateFormat('HH:mm').format(samples.first.timestamp);
      final endTimeStr = DateFormat('HH:mm').format(samples.last.timestamp);

      textPainter.text = TextSpan(text: startTimeStr, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding, topPadding + chartHeight + 4));

      textPainter.text = TextSpan(text: endTimeStr, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding + chartWidth - textPainter.width, topPadding + chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _ChargingPowerChartPainter oldDelegate) {
    return oldDelegate.samples != samples || oldDelegate.isDark != isDark;
  }
}

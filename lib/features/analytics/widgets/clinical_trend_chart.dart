import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/vitals/vital_type.dart';
import '../../../data/models/vital_reading.dart';
import '../models/analytics_models.dart';

class ClinicalTrendChart extends StatelessWidget {
  final AnalyticsSummary summary;
  final bool showPulseOnBp;
  final bool isDark;

  const ClinicalTrendChart({
    super.key,
    required this.summary,
    this.showPulseOnBp = true,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return _buildEmptyState(context);
    }

    final vital = summary.vitalType;
    final isBp = vital == VitalType.bloodPressure;
    final readings = summary.readings;

    // Determine Y-axis bounds based on readings and clinical zones
    final double minY;
    final double maxY;
    if (isBp) {
      final minVal = summary.minPrimary ?? 70;
      final maxVal = summary.maxPrimary ?? 150;
      minY = (minVal - 20).clamp(40.0, 200.0);
      maxY = (maxVal + 25).clamp(100.0, 260.0);
    } else if (vital == VitalType.oxygenSaturation) {
      minY = 86.0;
      maxY = 100.0;
    } else {
      final minVal = summary.minPrimary ?? 50;
      final maxVal = summary.maxPrimary ?? 150;
      minY = (minVal * 0.85).clamp(0.0, 500.0);
      maxY = (maxVal * 1.15).clamp(minY + 20, 600.0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header & Legends
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(vital.icon, size: 18, color: vital.color),
                  const SizedBox(width: 8),
                  Text(
                    '${vital.displayName} Trend',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              _buildLegend(isBp, vital),
            ],
          ),
          const SizedBox(height: 16),

          // Main Line Chart
          SizedBox(
            height: 230,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LineChart(
                _buildChartData(readings, isBp, vital, minY, maxY),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Time of day hint footer
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildTimeBadge('☀️ AM (Morning)', const Color(0xFFF59E0B)),
              _buildTimeBadge('🌙 PM (Evening)', const Color(0xFF6366F1)),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(
    List<VitalReading> readings,
    bool isBp,
    VitalType vital,
    double minY,
    double maxY,
  ) {
    // Generate spots indexed from 0 to readings.length - 1
    final primarySpots = <FlSpot>[];
    final secondarySpots = <FlSpot>[];
    final tertiarySpots = <FlSpot>[];

    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      final x = i.toDouble();
      primarySpots.add(FlSpot(x, r.valuePrimary));
      if (r.valueSecondary != null) {
        secondarySpots.add(FlSpot(x, r.valueSecondary!));
      }
      if (r.valueTertiary != null && showPulseOnBp) {
        tertiarySpots.add(FlSpot(x, r.valueTertiary!));
      }
    }

    final lineBars = <LineChartBarData>[];

    // Primary line (Systolic for BP, value for other vitals)
    lineBars.add(
      LineChartBarData(
        spots: primarySpots,
        isCurved: readings.length > 2,
        curveSmoothness: 0.25,
        preventCurveOverShooting: true,
        color: isBp ? const Color(0xFFC2185B) : vital.color,
        barWidth: 3.0,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final reading = readings[index];
            final slot = TimeOfDaySlot.fromDateTime(reading.recordedAt);
            return FlDotCirclePainter(
              radius: 4.5,
              color: slot.color,
              strokeWidth: 2.2,
              strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            );
          },
        ),
      ),
    );

    // Secondary line (Diastolic for BP)
    if (isBp && secondarySpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: secondarySpots,
          isCurved: readings.length > 2,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          color: const Color(0xFF0D9488),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3.5,
                color: const Color(0xFF0D9488),
                strokeWidth: 1.8,
                strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              );
            },
          ),
        ),
      );
    }

    // Tertiary line (Pulse for BP)
    if (isBp && tertiarySpots.isNotEmpty && showPulseOnBp) {
      lineBars.add(
        LineChartBarData(
          spots: tertiarySpots,
          isCurved: false,
          color: const Color(0xFFEF4444).withValues(alpha: 0.7),
          barWidth: 1.8,
          dashArray: [4, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3.0,
                color: const Color(0xFFEF4444),
                strokeWidth: 1.0,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      );
    }

    return LineChartData(
      minX: 0,
      maxX: (readings.length - 1).toDouble().clamp(0.0, double.infinity),
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      // Target range background reference bands (clamped within [minY, maxY])
      rangeAnnotations: _buildRangeAnnotations(vital, isBp, minY, maxY),
      // Between bars fill for Blood Pressure ribbon
      betweenBarsData: isBp && secondarySpots.isNotEmpty
          ? [
              BetweenBarsData(
                fromIndex: 0,
                toIndex: 1,
                color: const Color(0xFFC2185B).withValues(alpha: 0.12),
              ),
            ]
          : [],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: isBp ? 20 : (maxY - minY > 50 ? 25 : 10),
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          strokeWidth: 0.8,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: isBp ? 30 : (maxY - minY > 50 ? 30 : 15),
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= readings.length) {
                return const SizedBox.shrink();
              }

              // Show titles on first, last, and every few intervals to avoid overlap
              final total = readings.length;
              final shouldShow = total <= 7 ||
                  idx == 0 ||
                  idx == total - 1 ||
                  idx % (total ~/ 4).clamp(1, 10) == 0;

              if (!shouldShow) return const SizedBox.shrink();

              final date = readings[idx].recordedAt;
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  DateFormat('M/d').format(date),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) =>
              isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
          tooltipBorderRadius: BorderRadius.circular(14),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final idx = touchedSpots.first.spotIndex;
            if (idx >= readings.length) return [];
            final reading = readings[idx];
            final timeStr = DateFormat('MMM d • h:mm a').format(reading.recordedAt);
            final slot = TimeOfDaySlot.fromDateTime(reading.recordedAt);
            final target = TargetZone.evaluate(reading);

            return [
              LineTooltipItem(
                '${reading.formattedValue}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$timeStr (${slot.label})\n',
                    style: TextStyle(
                      color: slot.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'Zone: ${target.label}',
                    style: TextStyle(
                      color: target.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      ),
      lineBarsData: lineBars,
    );
  }

  RangeAnnotations _buildRangeAnnotations(
    VitalType vital,
    bool isBp,
    double minY,
    double maxY,
  ) {
    final annotations = <HorizontalRangeAnnotation>[];

    void addBand(double y1, double y2, Color color) {
      final clampedY1 = y1.clamp(minY, maxY);
      final clampedY2 = y2.clamp(minY, maxY);
      if (clampedY2 > clampedY1) {
        annotations.add(
          HorizontalRangeAnnotation(
            y1: clampedY1,
            y2: clampedY2,
            color: color,
          ),
        );
      }
    }

    if (isBp) {
      // Normal target band (< 120 Systolic, < 80 Diastolic)
      addBand(
        60,
        120,
        const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05),
      );
      addBand(
        120,
        140,
        const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.08 : 0.05),
      );
    } else if (vital == VitalType.glucose) {
      addBand(
        70,
        130,
        const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05),
      );
    } else if (vital == VitalType.heartRate) {
      addBand(
        60,
        100,
        const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05),
      );
    } else if (vital == VitalType.oxygenSaturation) {
      addBand(
        95,
        100,
        const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05),
      );
    }

    return RangeAnnotations(horizontalRangeAnnotations: annotations);
  }

  Widget _buildLegend(bool isBp, VitalType vital) {
    if (isBp) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem('SYS', const Color(0xFFC2185B)),
          const SizedBox(width: 8),
          _legendItem('DIA', const Color(0xFF0D9488)),
          if (showPulseOnBp) ...[
            const SizedBox(width: 8),
            _legendItem('Pulse', const Color(0xFFEF4444)),
          ],
        ],
      );
    }
    return _legendItem(vital.defaultUnit, vital.color);
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBadge(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Color(0xFF0D9488),
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No ${summary.vitalType.displayName} Records Found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the time filter above or record new vital signs on the Record tab.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

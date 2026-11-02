import 'package:flutter/material.dart';
import '../../../core/vitals/vital_type.dart';
import '../../../data/models/vital_reading.dart';

/// A single day tile in the monthly calendar grid.
///
/// Displays:
/// - Day number (with highlight if today)
/// - Locked styling + lock icon if the date is in the future
/// - Bulleted mini info of up to 2 most recent vital signs (with colored dots matching vital tints)
/// - "+N more" badge if there are more than 2 readings
class CalendarDayTile extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isFuture;
  final List<VitalReading> readings;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;

  const CalendarDayTile({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isFuture,
    required this.readings,
    required this.onTap,
    required this.onLockedTap,
  });

  @override
  State<CalendarDayTile> createState() => _CalendarDayTileState();
}

class _CalendarDayTileState extends State<CalendarDayTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Ensure readings are sorted by recordedAt DESC so the 2 most recent are always previewed
    final sortedReadings = List<VitalReading>.from(widget.readings)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final topReadings = sortedReadings.take(2).toList();

    // Background and border styling
    Color bgColor;
    Border? border;
    List<BoxShadow>? shadows;

    if (widget.isToday) {
      bgColor = isDark
          ? const Color(0xFF0F766E).withValues(alpha: 0.35)
          : const Color(0xFFCCFBF1);
      border = Border.all(
        color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
        width: 1.8,
      );
      shadows = [
        BoxShadow(
          color: (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488))
              .withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (widget.isFuture) {
      bgColor = isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.40)
          : const Color(0xFFF1F5F9).withValues(alpha: 0.60);
      border = Border.all(
        color: isDark
            ? const Color(0xFF334155).withValues(alpha: 0.35)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.50),
        width: 1.0,
      );
    } else if (widget.isCurrentMonth) {
      bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      border = Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        width: 1.0,
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      // Trailing days from previous or next month
      bgColor = isDark
          ? const Color(0xFF101726).withValues(alpha: 0.50)
          : const Color(0xFFF8FAFC);
      border = Border.all(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.50)
            : const Color(0xFFF1F5F9),
        width: 1.0,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: AnimatedScale(
        scale: (reduceMotion || !_isPressed) ? 1.0 : 0.955,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.isFuture ? widget.onLockedTap : widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: border,
                boxShadow: shadows,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header: number (with FittedBox to prevent overflow) + locked indicator or today badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: widget.isToday
                              ? const EdgeInsets.symmetric(
                                  horizontal: 3.5, vertical: 1.0)
                              : EdgeInsets.zero,
                          decoration: widget.isToday
                              ? BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2DD4BF)
                                      : const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(5),
                                )
                              : null,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${widget.date.day}',
                              style: TextStyle(
                                fontSize: widget.isToday ? 11 : 12,
                                fontWeight: widget.isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: widget.isToday
                                    ? (isDark
                                        ? const Color(0xFF0F172A)
                                        : Colors.white)
                                    : (widget.isFuture || !widget.isCurrentMonth
                                        ? (isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFF94A3B8))
                                        : (isDark
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(0xFF1E293B))),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.isFuture) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFF94A3B8),
                        ),
                      ] else if (widget.readings.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Preview up to 2 recent recorded vital signs safely constrained inside Expanded + ClipRect
                  if (!widget.isFuture && topReadings.isNotEmpty)
                    Expanded(
                      child: ClipRect(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final r in topReadings)
                              _buildMiniBulletItem(r, isDark),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBulletItem(VitalReading r, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bullet dot matching vital tint color from reserved keywords card
          Container(
            width: 4.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: r.type.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3.0),
          Expanded(
            child: Text(
              _formatMiniSummary(r),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.8,
                height: 1.1,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMiniSummary(VitalReading r) {
    switch (r.type) {
      case VitalType.glucose:
        return 'Glu ${r.valuePrimary.toInt()}';
      case VitalType.bloodPressure:
        final sec =
            r.valueSecondary != null ? '/${r.valueSecondary!.toInt()}' : '';
        final pulse =
            r.valueTertiary != null ? ' p${r.valueTertiary!.toInt()}' : '';
        return 'BP ${r.valuePrimary.toInt()}$sec$pulse';
      case VitalType.heartRate:
        return 'HR ${r.valuePrimary.toInt()}';
      case VitalType.temperature:
        return 'T ${r.valuePrimary.toStringAsFixed(1)}°';
      case VitalType.oxygenSaturation:
        return 'SpO2 ${r.valuePrimary.toInt()}%';
      case VitalType.respiratoryRate:
        return 'RR ${r.valuePrimary.toInt()}';
      case VitalType.weight:
        return 'Wt ${r.valuePrimary.toStringAsFixed(1)}';
    }
  }
}

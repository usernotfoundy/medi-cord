import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/vitals/vital_type.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../manual_entry/manual_entry_sheet.dart';
import '../../record/record_controller.dart';

/// Modal dialog displaying all vital signs recorded for a selected calendar date.
///
/// Designed after the floating modal card in the calendar layout reference,
/// with fluid frosted glass depth, physical scale transitions (0.94 -> 1.0),
/// and tactile interactions per Emil Kowalski and Apple Design guidelines.
class DayVitalModal extends StatelessWidget {
  final DateTime date;
  final List<VitalReading> readings;
  final WidgetRef ref;
  final VitalRepository repo;

  const DayVitalModal({
    super.key,
    required this.date,
    required this.readings,
    required this.ref,
    required this.repo,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<VitalReading> readings,
    required WidgetRef ref,
    required VitalRepository repo,
  }) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => DayVitalModal(
        date: date,
        readings: readings,
        ref: ref,
        repo: repo,
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        if (reduceMotion) {
          return child;
        }

        // Emil Kowalski modal curve: snappy easeOutCubic entry, easeInCubic exit
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        // Scale starts at 0.94 -> 1.0 (never 0)
        final scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(curved);
        // Subtle vertical lift (3% slide)
        final slideAnim = Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved);

        return Stack(
          children: [
            // Frosted glass backdrop blur (sigma 8)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8.0 * anim.value,
                  sigmaY: 8.0 * anim.value,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: slideAnim,
                child: ScaleTransition(
                  scale: scaleAnim,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(date);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
          maxWidth: 480,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.only(
                  left: 20, right: 14, top: 18, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: isDark ? 0.20 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Vital Sign Logs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Date Subheader Banner
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateFormatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: readings.isNotEmpty
                          ? (isDark
                              ? const Color(0xFF0D9488).withValues(alpha: 0.25)
                              : const Color(0xFFCCFBF1))
                          : (isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.4)
                              : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${readings.length} ${readings.length == 1 ? "entry" : "entries"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: readings.isNotEmpty
                            ? (isDark
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFF0D9488))
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Content Area: list of readings or empty state
            Flexible(
              child: readings.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shrinkWrap: true,
                      itemCount: readings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final r = readings[index];
                        return _buildVitalCard(context, r, isDark);
                      },
                    ),
            ),

            const Divider(height: 1, thickness: 1),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        ManualEntrySheet.show(context, initialDate: date);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Reading'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFF0D9488),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2DD4BF).withValues(alpha: 0.4)
                              : const Color(0xFF0D9488).withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.3)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Vital Signs Recorded',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No readings logged for this date. You can add a manual past entry if you forgot to log.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(BuildContext context, VitalReading r, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(r.recordedAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vital Type Icon Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: r.type.color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: r.type.color.withValues(alpha: isDark ? 0.45 : 0.30),
              ),
            ),
            child: Icon(
              r.type.icon,
              size: 20,
              color: r.type.color,
            ),
          ),
          const SizedBox(width: 12),

          // Vital Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatVitalValue(r),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF0F172A),
                  ),
                ),
                if (r.type == VitalType.bloodPressure &&
                    r.valueTertiary != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F)
                          .withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFD32F2F)
                            .withValues(alpha: isDark ? 0.40 : 0.25),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: Color(0xFFD32F2F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pulse: ${r.valueTertiary!.toInt()} bpm',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (r.note != null && r.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFFF87171)
                  : const Color(0xFFDC2626),
            ),
            tooltip: 'Delete Reading',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Delete Reading?'),
                  content: Text(
                    'Are you sure you want to delete this ${r.type.displayName} reading? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && r.id != null) {
                HapticFeedback.mediumImpact();
                await repo.deleteReading(r.id!);
                ref.invalidate(readingsListProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatVitalValue(VitalReading r) {
    switch (r.type) {
      case VitalType.glucose:
        return '${r.valuePrimary.toInt()} ${r.unit}';
      case VitalType.bloodPressure:
        final sec = r.valueSecondary != null
            ? ' / ${r.valueSecondary!.toInt()}'
            : '';
        final pulse = r.valueTertiary != null
            ? ' • Pulse ${r.valueTertiary!.toInt()} bpm'
            : '';
        return '${r.valuePrimary.toInt()}$sec ${r.unit}$pulse';
      case VitalType.heartRate:
        return '${r.valuePrimary.toInt()} ${r.unit}';
      case VitalType.temperature:
        return '${r.valuePrimary.toStringAsFixed(1)} ${r.unit}';
      case VitalType.oxygenSaturation:
        return '${r.valuePrimary.toInt()} ${r.unit}';
      case VitalType.respiratoryRate:
        return '${r.valuePrimary.toInt()} ${r.unit}';
      case VitalType.weight:
        return '${r.valuePrimary.toStringAsFixed(1)} ${r.unit}';
    }
  }
}

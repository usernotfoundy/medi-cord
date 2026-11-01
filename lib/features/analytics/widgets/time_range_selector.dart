import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../analytics_controller.dart';
import '../models/analytics_models.dart';

class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: TimeRangePreset.values.map((preset) {
                final isSelected = filter.timeRangePreset == preset;
                final isCustom = preset == TimeRangePreset.custom;

                return Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      if (isCustom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          initialDateRange: DateTimeRange(
                            start: filter.customStart,
                            end: filter.customEnd,
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: const Color(0xFF0D9488),
                                  brightness: isDark
                                      ? Brightness.dark
                                      : Brightness.light,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          ref
                              .read(analyticsFilterProvider.notifier)
                              .setCustomRange(picked.start, picked.end);
                        }
                      } else {
                        ref
                            .read(analyticsFilterProvider.notifier)
                            .setTimeRange(preset);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFF0D9488)
                                : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCustom) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0D9488))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            preset.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (filter.timeRangePreset == TimeRangePreset.custom) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: 14,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(filter.customStart)} – ${DateFormat('MMM d, yyyy').format(filter.customEnd)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


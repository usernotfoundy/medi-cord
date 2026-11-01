import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/vitals/vital_type.dart';
import '../analytics_controller.dart';

class VitalTypeSelector extends ConsumerWidget {
  const VitalTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      analyticsFilterProvider.select((s) => s.selectedVital),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: VitalType.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final vital = VitalType.values[index];
          final isSelected = vital == selected;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Material(
              color: isSelected
                  ? vital.color
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white),
              borderRadius: BorderRadius.circular(22),
              elevation: isSelected ? 2 : 0,
              shadowColor: vital.color.withValues(alpha: 0.35),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(analyticsFilterProvider.notifier)
                      .setVitalType(vital);
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? vital.color
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vital.icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : vital.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vital.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155)),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


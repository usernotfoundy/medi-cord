import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/vitals/vital_type.dart';
import '../../../data/models/vital_reading.dart';
import '../../record/record_controller.dart';
import '../history_filter_controller.dart';

/// Emil Kowalski & Apple Design styled modal bottom sheet for filtering history logs.
/// Lets users select Vital Sign and Date Range in an unhurried, comfortable modal
/// with instant match preview and atomic "Apply Filters" action.
class HistoryFilterSheet extends ConsumerStatefulWidget {
  const HistoryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HistoryFilterSheet(),
    );
  }

  @override
  ConsumerState<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<HistoryFilterSheet> {
  late VitalType? _tempVital;
  late HistoryDatePreset _tempPreset;
  late DateTime? _tempCustomDate;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(historyFilterProvider);
    _tempVital = currentFilter.selectedVital;
    _tempPreset = currentFilter.datePreset;
    _tempCustomDate = currentFilter.customDate;
  }

  bool get _hasActiveFilter =>
      _tempVital != null || _tempPreset != HistoryDatePreset.all;

  void _resetFilter() {
    HapticFeedback.lightImpact();
    setState(() {
      _tempVital = null;
      _tempPreset = HistoryDatePreset.all;
      _tempCustomDate = null;
    });
  }

  void _applyFilter() {
    HapticFeedback.mediumImpact();
    ref.read(historyFilterProvider.notifier).applyFilter(
          HistoryFilterState(
            selectedVital: _tempVital,
            datePreset: _tempPreset,
            customDate: _tempCustomDate,
          ),
        );
    Navigator.of(context).pop();
  }

  Future<void> _pickCustomDate(bool isDark) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tempCustomDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2DD4BF),
                    surface: Color(0xFF1E293B),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    surface: Colors.white,
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tempPreset = HistoryDatePreset.custom;
        _tempCustomDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final readingsAsync = ref.watch(readingsListProvider);
    final allReadings = readingsAsync.value ?? [];

    // Calculate dynamic preview count for tentative filter
    final tempState = HistoryFilterState(
      selectedVital: _tempVital,
      datePreset: _tempPreset,
      customDate: _tempCustomDate,
    );
    final previewCount = filterHistoryReadings(allReadings, tempState).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with Title & Reset Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCCFBF1),
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Logs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Filter by vital sign or date range',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _hasActiveFilter ? _resetFilter : null,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      disabledForegroundColor: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF94A3B8),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Options Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Vital Sign
                    _buildSectionHeader(
                      title: 'VITAL SIGN',
                      subtitle: 'Show only specific measurement type',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // "All Vitals" Chip
                        _FilterOptionChip(
                          label: 'All Vitals',
                          icon: Icons.grid_view_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempVital == null,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _tempVital = null);
                          },
                        ),
                        // Individual Vital Type Chips
                        for (final vital in VitalType.values)
                          _FilterOptionChip(
                            label: vital.displayName,
                            icon: vital.icon,
                            accentColor: vital.color,
                            isSelected: _tempVital == vital,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _tempVital =
                                    _tempVital == vital ? null : vital;
                              });
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Date Range
                    _buildSectionHeader(
                      title: 'DATE RANGE',
                      subtitle: 'Filter logs recorded within a period',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterOptionChip(
                          label: 'All Dates',
                          icon: Icons.calendar_today_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempPreset == HistoryDatePreset.all,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tempPreset = HistoryDatePreset.all;
                              _tempCustomDate = null;
                            });
                          },
                        ),
                        _FilterOptionChip(
                          label: 'Today',
                          icon: Icons.today_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempPreset == HistoryDatePreset.today,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tempPreset = HistoryDatePreset.today;
                              _tempCustomDate = null;
                            });
                          },
                        ),
                        _FilterOptionChip(
                          label: 'Yesterday',
                          icon: Icons.history_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempPreset == HistoryDatePreset.yesterday,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tempPreset = HistoryDatePreset.yesterday;
                              _tempCustomDate = null;
                            });
                          },
                        ),
                        _FilterOptionChip(
                          label: 'Past 7 Days',
                          icon: Icons.date_range_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempPreset == HistoryDatePreset.past7Days,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tempPreset = HistoryDatePreset.past7Days;
                              _tempCustomDate = null;
                            });
                          },
                        ),
                        _FilterOptionChip(
                          label: 'Past 30 Days',
                          icon: Icons.calendar_month_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempPreset == HistoryDatePreset.past30Days,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tempPreset = HistoryDatePreset.past30Days;
                              _tempCustomDate = null;
                            });
                          },
                        ),
                        _FilterOptionChip(
                          label: _tempPreset == HistoryDatePreset.custom &&
                                  _tempCustomDate != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(_tempCustomDate!)
                              : 'Specific Date...',
                          icon: Icons.event_rounded,
                          accentColor: const Color(0xFF0D9488),
                          isSelected: _tempPreset == HistoryDatePreset.custom,
                          isDark: isDark,
                          onTap: () => _pickCustomDate(isDark),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Pinned Apply Button Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _hasActiveFilter
                                ? 'Show $previewCount Results'
                                : 'Show All Logs',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

/// Tactile selectable chip for filter options
class _FilterOptionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FilterOptionChip> createState() => _FilterOptionChipState();
}

class _FilterOptionChipState extends State<_FilterOptionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: widget.isDark ? 0.22 : 0.12)
        : (widget.isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9));

    final borderColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: widget.isDark ? 0.7 : 0.6)
        : (widget.isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0));

    final textColor = widget.isSelected
        ? (widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))
        : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569));

    final iconColor = widget.isSelected
        ? widget.accentColor
        : (widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: iconColor),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  letterSpacing: -0.1,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 5),
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: widget.accentColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


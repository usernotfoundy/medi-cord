import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/preferences_service.dart';
import '../history_filter_controller.dart';
import 'history_filter_sheet.dart';

/// Compact, non-intrusive filter header for the History List View.
///
/// Kept clean and airy:
/// - Displays total/filtered record count on the left
/// - Displays an elegant "Filter" action button on the right with an active badge
/// - When filters are active, displays a slim row of dismissible filter tags and "Clear all"
class HistoryFilterBar extends ConsumerWidget {
  final int totalCount;
  final int filteredCount;

  const HistoryFilterBar({
    super.key,
    required this.totalCount,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final showVoiceTranscript = ref.watch(showVoiceTranscriptProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasActive = filter.hasActiveFilter;
    final activeCount = filter.activeFilterCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Sub-Bar: Log Count + Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Log Count Display
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasActive
                          ? Icons.filter_alt_outlined
                          : Icons.format_list_bulleted_rounded,
                      size: 15,
                      color: hasActive
                          ? const Color(0xFF0D9488)
                          : (isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hasActive
                            ? 'Showing $filteredCount of $totalCount logs'
                            : '$totalCount recorded ${totalCount == 1 ? "log" : "logs"}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              hasActive ? FontWeight.w700 : FontWeight.w600,
                          letterSpacing: -0.1,
                          color: hasActive
                              ? (isDark
                                  ? const Color(0xFF2DD4BF)
                                  : const Color(0xFF0F766E))
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Buttons: Voice Transcript Toggle + Filter Trigger
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TranscriptToggleButton(
                    isVisible: showVoiceTranscript,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(showVoiceTranscriptProvider.notifier)
                          .toggle();
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterButton(
                    hasActive: hasActive,
                    activeCount: activeCount,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      HistoryFilterSheet.show(context);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Active Filter Chips Strip (only visible when filters are applied)
          if (hasActive) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Selected Vital Chip
                  if (filter.selectedVital != null) ...[
                    _ActiveFilterTag(
                      label: filter.selectedVital!.displayName,
                      icon: filter.selectedVital!.icon,
                      color: filter.selectedVital!.color,
                      isDark: isDark,
                      onRemove: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(historyFilterProvider.notifier)
                            .clearVital();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Selected Date Chip
                  if (filter.datePreset != HistoryDatePreset.all) ...[
                    _ActiveFilterTag(
                      label: filter.dateDisplayLabel,
                      icon: filter.datePreset.icon,
                      color: const Color(0xFF0D9488),
                      isDark: isDark,
                      onRemove: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(historyFilterProvider.notifier)
                            .clearDateFilter();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],

                  // "Clear all" button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(historyFilterProvider.notifier).reset();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

/// Tactile Filter Trigger Button
class _FilterButton extends StatefulWidget {
  final bool hasActive;
  final int activeCount;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterButton({
    required this.hasActive,
    required this.activeCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.hasActive
        ? (widget.isDark
            ? const Color(0xFF0D9488).withValues(alpha: 0.25)
            : const Color(0xFFCCFBF1))
        : (widget.isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9));

    final borderColor = widget.hasActive
        ? const Color(0xFF0D9488)
        : (widget.isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0));

    final textColor = widget.hasActive
        ? (widget.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E))
        : (widget.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: widget.hasActive ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 15,
                color: textColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: textColor,
                ),
              ),
              if (widget.hasActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.activeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini dismissible pill tag for an active filter
class _ActiveFilterTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onRemove;

  const _ActiveFilterTag({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.5 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 11,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile button to toggle visibility of voice transcripts on history cards
class _TranscriptToggleButton extends StatefulWidget {
  final bool isVisible;
  final bool isDark;
  final VoidCallback onTap;

  const _TranscriptToggleButton({
    required this.isVisible,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TranscriptToggleButton> createState() =>
      _TranscriptToggleButtonState();
}

class _TranscriptToggleButtonState extends State<_TranscriptToggleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isVisible
        ? (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
        : (widget.isDark
            ? const Color(0xFF0D9488).withValues(alpha: 0.18)
            : const Color(0xFFCCFBF1).withValues(alpha: 0.8));

    final borderColor = widget.isVisible
        ? (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
        : (widget.isDark
            ? const Color(0xFF2DD4BF).withValues(alpha: 0.6)
            : const Color(0xFF0D9488).withValues(alpha: 0.5));

    final iconColor = widget.isVisible
        ? (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
        : (widget.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E));

    final textColor = widget.isVisible
        ? (widget.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))
        : (widget.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E));

    return Tooltip(
      message: widget.isVisible
          ? 'Hide voice records'
          : 'Unhide voice records',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: widget.isVisible ? 1.0 : 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isVisible
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  size: 15,
                  color: iconColor,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.isVisible ? 'Hide Voice' : 'Unhide Voice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

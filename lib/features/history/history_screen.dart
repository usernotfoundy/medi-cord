import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/text_size_button.dart';
import '../../core/theme/theme_toggle_switch.dart';
import '../../data/db/app_database.dart';
import '../../data/models/vital_reading.dart';
import '../manual_entry/manual_entry_header_button.dart';
import '../manual_entry/manual_entry_sheet.dart';
import '../record/record_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(readingsListProvider);
    final repo = ref.watch(vitalRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Saved Vital Logs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor?.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        actions: [
          const ManualEntryHeaderButton(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              AppDatabase.ensureInitialized();
              ref.invalidate(readingsListProvider);
            },
          ),
          const TextSizeButton(),
          const ThemeToggleSwitch(),
        ],
      ),
      body: readingsAsync.when(
        data: (readings) {
          if (readings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D9488).withValues(alpha: 0.2)
                            : const Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF14B8A6).withValues(alpha: 0.4)
                              : const Color(0xFF99F6E4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 38,
                        color: isDark
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Vital Signs Recorded Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Switch to the Record tab and hold the mic to record your first vital sign (e.g. "Glucose 120").',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ManualEntrySheet.show(context);
                      },
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: const Text('Add Past Reading Manually'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF0D9488),
            onRefresh: () async {
              AppDatabase.ensureInitialized();
              ref.invalidate(readingsListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final item = readings[index];
                final isFirstInGroup = index == 0 ||
                    !_isSameDay(readings[index - 1].recordedAt, item.recordedAt);

                final card = _buildReadingCard(
                  context,
                  item,
                  ref,
                  repo,
                  index,
                  reduceMotion,
                  isDark,
                );

                if (isFirstInGroup) {
                  final dayCount = _getDayCount(readings, item.recordedAt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateHeader(
                        context,
                        item.recordedAt,
                        index == 0,
                        isDark,
                        dayCount,
                      ),
                      card,
                      const SizedBox(height: 12),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: card,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D9488)),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF450A0A).withValues(alpha: 0.5)
                          : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF991B1B)
                            : const Color(0xFFFEE2E2),
                      ),
                    ),
                    child: const Icon(
                      Icons.sync_problem_rounded,
                      color: Color(0xFFDC2626),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Database Reconnecting',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecting to local SQLite database...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      AppDatabase.ensureInitialized();
                      ref.invalidate(readingsListProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reload Database'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getDayCount(List<VitalReading> readings, DateTime date) {
    return readings.where((r) => _isSameDay(r.recordedAt, date)).length;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final readingDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(readingDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7 && difference > 0) {
      return DateFormat('EEEE, MMM d').format(date);
    } else if (now.year == date.year) {
      return DateFormat('MMMM d').format(date);
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  Widget _buildDateHeader(
    BuildContext context,
    DateTime date,
    bool isFirst,
    bool isDark,
    int dayCount,
  ) {
    final title = _formatDateHeader(date);
    final isToday = title == 'Today';
    final isYesterday = title == 'Yesterday';

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4 : 20,
        bottom: 10,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isToday
                  ? (isDark
                      ? const Color(0xFF0D9488).withValues(alpha: 0.22)
                      : const Color(0xFFCCFBF1))
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? (isDark
                        ? const Color(0xFF2DD4BF).withValues(alpha: 0.5)
                        : const Color(0xFF99F6E4))
                    : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isToday
                      ? Icons.today_rounded
                      : (isYesterday
                          ? Icons.history_rounded
                          : Icons.calendar_today_rounded),
                  size: 14,
                  color: isToday
                      ? (isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF0F766E))
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isToday
                        ? (isDark
                            ? const Color(0xFF5EEAD4)
                            : const Color(0xFF0F766E))
                        : (isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$dayCount ${dayCount == 1 ? "log" : "logs"}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(
    BuildContext context,
    VitalReading item,
    WidgetRef ref,
    dynamic repo,
    int index,
    bool reduceMotion,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final vital = item.type;
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(item.recordedAt);

    final card = Dismissible(
      key: Key('vital_${item.id}'),
      direction: DismissDirection.endToStart,
      onResize: () => HapticFeedback.selectionClick(),
      confirmDismiss: (_) => _showDeleteConfirmation(context, item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        if (item.id != null) {
          await repo.deleteReading(item.id!);
          ref.invalidate(readingsListProvider);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: vital.color.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(vital.icon, color: vital.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vital.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.formattedValue,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: vital.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () async {
                      final confirmed =
                          await _showDeleteConfirmation(context, item);
                      if (confirmed == true && item.id != null) {
                        HapticFeedback.mediumImpact();
                        await repo.deleteReading(item.id!);
                        ref.invalidate(readingsListProvider);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                              : const Color(0xFFFCA5A5),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFDC2626),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '"${item.rawTranscript}"',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (item.note != null) ...[
              const SizedBox(height: 8),
              Text(
                item.note!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (reduceMotion) {
      return card;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 220 + (index * 40).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 10),
            child: child,
          ),
        );
      },
      child: card,
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    VitalReading item,
  ) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF450A0A).withValues(alpha: 0.6)
                    : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF991B1B)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Vital Log?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this recorded vital sign?',
              style: TextStyle(
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(item.type.icon, color: item.type.color, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    item.type.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.formattedValue,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: item.type.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

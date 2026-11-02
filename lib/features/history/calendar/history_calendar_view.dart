import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/vital_reading.dart';
import '../../record/record_controller.dart';
import 'calendar_day_tile.dart';
import 'day_vital_modal.dart';

/// Monthly calendar layout for History screen.
///
/// Supports:
/// - Swipe left/right between months with fluid PageView physics
/// - Chevron buttons for monthly navigation
/// - Locked UI & feedback for future dates
/// - Mini bullet info for up to 2 recent vitals with color-matched dots
/// - Tap to view all vitals in a detailed modal card
class HistoryCalendarView extends ConsumerStatefulWidget {
  final List<VitalReading> readings;

  const HistoryCalendarView({
    super.key,
    required this.readings,
  });

  @override
  ConsumerState<HistoryCalendarView> createState() =>
      _HistoryCalendarViewState();
}

class _HistoryCalendarViewState extends ConsumerState<HistoryCalendarView> {
  static final DateTime _baseMonth = DateTime(2020, 1, 1);
  static const int _totalMonths = 2400; // 200 years of months

  late int _currentPage;
  late PageController _pageController;
  late DateTime _currentVisibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentVisibleMonth = DateTime(now.year, now.month, 1);
    _currentPage = _pageIndexForMonth(_currentVisibleMonth);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageIndexForMonth(DateTime month) {
    return (month.year - _baseMonth.year) * 12 +
        (month.month - _baseMonth.month);
  }

  DateTime _monthForPageIndex(int index) {
    final totalMonths = index;
    final year = _baseMonth.year + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;
    return DateTime(year, month, 1);
  }

  void _goToPreviousMonth() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToNextMonth() {
    if (_currentPage < _totalMonths - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final targetPage = _pageIndexForMonth(currentMonth);
    if (targetPage != _currentPage) {
      HapticFeedback.mediumImpact();
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Map<DateTime, List<VitalReading>> _groupReadingsByDay(
      List<VitalReading> readings) {
    final map = <DateTime, List<VitalReading>>{};
    for (final r in readings) {
      final key = DateTime(
          r.recordedAt.year, r.recordedAt.month, r.recordedAt.day);
      map.putIfAbsent(key, () => []).add(r);
    }
    // Strictly sort readings for each day by recordedAt DESC (most recent first)
    for (final list in map.values) {
      list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    return map;
  }

  void _showLockedDateToast(BuildContext context, DateTime date) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // High contrast theme adaptation:
    // In Dark Mode: Crisp light surface with deep dark text & amber lock icon
    // In Light Mode: Deep slate surface with crisp white text & bright amber lock icon
    final toastBg =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final toastBorder =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final textColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final iconColor =
        isDark ? const Color(0xFFD97706) : const Color(0xFFFBBF24);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.16 : 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('MMMM d').format(date)} is in the future and locked',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cannot record or view vital signs ahead of time.',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF94A3B8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: toastBg,
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: toastBorder, width: 1.2),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth = _currentVisibleMonth.year == now.year &&
        _currentVisibleMonth.month == now.month;

    final groupedReadings = _groupReadingsByDay(widget.readings);

    return Column(
      children: [
        // Month Selector & Navigation Header
        Padding(
          padding:
              const EdgeInsets.only(left: 18, right: 18, top: 8, bottom: 10),
          child: Row(
            children: [
              // Month & Year title with fluid AnimatedSwitcher
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentVisibleMonth),
                    key: ValueKey(_currentVisibleMonth),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // "Today" quick jump button if browsing other months
              if (!isCurrentMonth)
                _PressableBounce(
                  onTap: _goToCurrentMonth,
                  pressedScale: 0.92,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D9488).withValues(alpha: 0.20)
                          : const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2DD4BF).withValues(alpha: 0.40)
                            : const Color(0xFF0D9488).withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              // Left chevron button
              _buildNavArrowButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous Month',
                isDark: isDark,
                onTap: _goToPreviousMonth,
              ),
              const SizedBox(width: 8),

              // Right chevron button
              _buildNavArrowButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next Month',
                isDark: isDark,
                onTap: _goToNextMonth,
              ),
            ],
          ),
        ),

        // Weekday Columns Header (Sun, Mon, Tue, Wed, Thu, Fri, Sat)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: const [
              'Sun',
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat'
            ].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Swipeable Monthly Calendar Grid
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalMonths,
            onPageChanged: (pageIndex) {
              setState(() {
                _currentPage = pageIndex;
                _currentVisibleMonth = _monthForPageIndex(pageIndex);
              });
            },
            itemBuilder: (context, pageIndex) {
              final month = _monthForPageIndex(pageIndex);
              return _buildMonthGrid(context, month, groupedReadings, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavArrowButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return _PressableBounce(
      onTap: onTap,
      pressedScale: 0.88,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime month,
    Map<DateTime, List<VitalReading>> groupedReadings,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // Sunday = 0, Monday = 1, ..., Saturday = 6
    final leadingDays = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final totalCells = leadingDays + daysInMonth;
    final trailingDays = (7 - (totalCells % 7)) % 7;
    final totalGridCells = totalCells + trailingDays;
    final totalWeeks = totalGridCells ~/ 7;

    final repo = ref.watch(vitalRepositoryProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalWeeks, (weekIndex) {
          return SizedBox(
            height: 92,
            child: Row(
              children: List.generate(7, (dayColIndex) {
                final cellIndex = (weekIndex * 7) + dayColIndex;
                final dayOffset = cellIndex - leadingDays + 1;
                final cellDate = DateTime(month.year, month.month, dayOffset);
                final isCellInCurrentMonth = (cellDate.month == month.month);

                final cellKey = DateTime(
                    cellDate.year, cellDate.month, cellDate.day);
                final isCellToday = (cellKey == today);
                final isCellFuture = cellKey.isAfter(today);

                final cellReadings = groupedReadings[cellKey] ?? [];

                return Expanded(
                  child: CalendarDayTile(
                    date: cellDate,
                    isCurrentMonth: isCellInCurrentMonth,
                    isToday: isCellToday,
                    isFuture: isCellFuture,
                    readings: cellReadings,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      DayVitalModal.show(
                        context,
                        date: cellDate,
                        readings: cellReadings,
                        ref: ref,
                        repo: repo,
                      );
                    },
                    onLockedTap: () {
                      _showLockedDateToast(context, cellDate);
                    },
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// A tactile interactive wrapper that scales down on press for instant physical feedback,
/// adhering to Emil Kowalski & Apple touch response guidelines.
class _PressableBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  const _PressableBounce({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.90,
  });

  @override
  State<_PressableBounce> createState() => _PressableBounceState();
}

class _PressableBounceState extends State<_PressableBounce> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (reduceMotion || !_isPressed) ? 1.0 : widget.pressedScale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

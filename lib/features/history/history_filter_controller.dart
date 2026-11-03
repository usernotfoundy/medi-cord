import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/vitals/vital_type.dart';
import '../../data/models/vital_reading.dart';

enum HistoryDatePreset {
  all('All Dates', Icons.calendar_today_rounded),
  today('Today', Icons.today_rounded),
  yesterday('Yesterday', Icons.history_rounded),
  past7Days('Past 7 Days', Icons.date_range_rounded),
  past30Days('Past 30 Days', Icons.calendar_month_rounded),
  custom('Specific Date', Icons.event_rounded);

  final String label;
  final IconData icon;
  const HistoryDatePreset(this.label, this.icon);
}

@immutable
class HistoryFilterState {
  final VitalType? selectedVital; // null = all vitals
  final HistoryDatePreset datePreset;
  final DateTime? customDate;

  const HistoryFilterState({
    this.selectedVital,
    this.datePreset = HistoryDatePreset.all,
    this.customDate,
  });

  bool get hasActiveFilter =>
      selectedVital != null || datePreset != HistoryDatePreset.all;

  int get activeFilterCount {
    int count = 0;
    if (selectedVital != null) count++;
    if (datePreset != HistoryDatePreset.all) count++;
    return count;
  }

  String get dateDisplayLabel {
    if (datePreset == HistoryDatePreset.custom && customDate != null) {
      return DateFormat('MMM d, yyyy').format(customDate!);
    }
    return datePreset.label;
  }

  HistoryFilterState copyWith({
    VitalType? Function()? selectedVital,
    HistoryDatePreset? datePreset,
    DateTime? Function()? customDate,
  }) {
    return HistoryFilterState(
      selectedVital:
          selectedVital != null ? selectedVital() : this.selectedVital,
      datePreset: datePreset ?? this.datePreset,
      customDate: customDate != null ? customDate() : this.customDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryFilterState &&
          runtimeType == other.runtimeType &&
          selectedVital == other.selectedVital &&
          datePreset == other.datePreset &&
          customDate == other.customDate;

  @override
  int get hashCode => Object.hash(selectedVital, datePreset, customDate);
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilterState>(
  HistoryFilterNotifier.new,
);

class HistoryFilterNotifier extends Notifier<HistoryFilterState> {
  @override
  HistoryFilterState build() => const HistoryFilterState();

  void selectVital(VitalType? vital) {
    state = state.copyWith(selectedVital: () => vital);
  }

  void toggleVital(VitalType vital) {
    if (state.selectedVital == vital) {
      state = state.copyWith(selectedVital: () => null);
    } else {
      state = state.copyWith(selectedVital: () => vital);
    }
  }

  void setDatePreset(HistoryDatePreset preset) {
    state = state.copyWith(
      datePreset: preset,
      customDate: () => null,
    );
  }

  void setCustomDate(DateTime date) {
    state = state.copyWith(
      datePreset: HistoryDatePreset.custom,
      customDate: () => date,
    );
  }

  void clearDateFilter() {
    state = state.copyWith(
      datePreset: HistoryDatePreset.all,
      customDate: () => null,
    );
  }

  void clearVital() {
    state = state.copyWith(selectedVital: () => null);
  }

  void applyFilter(HistoryFilterState newState) {
    state = newState;
  }

  void reset() {
    state = const HistoryFilterState();
  }
}

/// Helper function to filter a list of [VitalReading] items
List<VitalReading> filterHistoryReadings(
  List<VitalReading> readings,
  HistoryFilterState filter,
) {
  if (!filter.hasActiveFilter) {
    return readings;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final sevenDaysAgo = today.subtract(const Duration(days: 7));
  final thirtyDaysAgo = today.subtract(const Duration(days: 30));

  return readings.where((reading) {
    // 1. Vital Type filter
    if (filter.selectedVital != null && reading.type != filter.selectedVital) {
      return false;
    }

    // 2. Date filter
    final readingDate = DateTime(
      reading.recordedAt.year,
      reading.recordedAt.month,
      reading.recordedAt.day,
    );

    switch (filter.datePreset) {
      case HistoryDatePreset.all:
        return true;
      case HistoryDatePreset.today:
        return readingDate == today;
      case HistoryDatePreset.yesterday:
        return readingDate == yesterday;
      case HistoryDatePreset.past7Days:
        return !readingDate.isBefore(sevenDaysAgo) &&
            !readingDate.isAfter(today);
      case HistoryDatePreset.past30Days:
        return !readingDate.isBefore(thirtyDaysAgo) &&
            !readingDate.isAfter(today);
      case HistoryDatePreset.custom:
        if (filter.customDate == null) return true;
        final targetDate = DateTime(
          filter.customDate!.year,
          filter.customDate!.month,
          filter.customDate!.day,
        );
        return readingDate == targetDate;
    }
  }).toList();
}


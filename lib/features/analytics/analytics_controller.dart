import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vitals/vital_type.dart';
import '../record/record_controller.dart';
import 'models/analytics_models.dart';

class AnalyticsFilterState {
  final VitalType selectedVital;
  final TimeRangePreset timeRangePreset;
  final DateTime customStart;
  final DateTime customEnd;
  final bool showPulseOnBp;

  AnalyticsFilterState({
    this.selectedVital = VitalType.bloodPressure,
    this.timeRangePreset = TimeRangePreset.week,
    DateTime? customStart,
    DateTime? customEnd,
    this.showPulseOnBp = true,
  })  : customStart = customStart ?? DateTime.now().subtract(const Duration(days: 6)),
        customEnd = customEnd ?? DateTime.now();

  AnalyticsFilterState copyWith({
    VitalType? selectedVital,
    TimeRangePreset? timeRangePreset,
    DateTime? customStart,
    DateTime? customEnd,
    bool? showPulseOnBp,
  }) {
    return AnalyticsFilterState(
      selectedVital: selectedVital ?? this.selectedVital,
      timeRangePreset: timeRangePreset ?? this.timeRangePreset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      showPulseOnBp: showPulseOnBp ?? this.showPulseOnBp,
    );
  }
}

final analyticsFilterProvider =
    NotifierProvider<AnalyticsFilterNotifier, AnalyticsFilterState>(
  AnalyticsFilterNotifier.new,
);

class AnalyticsFilterNotifier extends Notifier<AnalyticsFilterState> {
  @override
  AnalyticsFilterState build() => AnalyticsFilterState();

  void setVitalType(VitalType vital) {
    state = state.copyWith(selectedVital: vital);
  }

  void setTimeRange(TimeRangePreset preset) {
    state = state.copyWith(timeRangePreset: preset);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      timeRangePreset: TimeRangePreset.custom,
      customStart: start,
      customEnd: end,
    );
  }

  void togglePulseOnBp() {
    state = state.copyWith(showPulseOnBp: !state.showPulseOnBp);
  }
}

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final filter = ref.watch(analyticsFilterProvider);
  final repo = ref.watch(vitalRepositoryProvider);

  // Re-run whenever readings list changes (e.g. after adding or deleting a log)
  ref.watch(readingsListProvider);

  final now = DateTime.now();
  late final DateTime start;
  late final DateTime end;

  if (filter.timeRangePreset == TimeRangePreset.custom) {
    start = DateTime(
      filter.customStart.year,
      filter.customStart.month,
      filter.customStart.day,
      0,
      0,
      0,
    );
    end = DateTime(
      filter.customEnd.year,
      filter.customEnd.month,
      filter.customEnd.day,
      23,
      59,
      59,
      999,
    );
  } else {
    start = filter.timeRangePreset.getStartDate(now);
    end = filter.timeRangePreset.getEndDate(now);
  }

  final readings = await repo.getReadingsForRange(
    type: filter.selectedVital,
    start: start,
    end: end,
  );

  return AnalyticsSummary.calculate(filter.selectedVital, readings);
});

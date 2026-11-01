import 'package:flutter/material.dart';
import '../../../core/vitals/vital_type.dart';
import '../../../data/models/vital_reading.dart';

enum TimeRangePreset {
  day('Day', 'Today', 1),
  week('7 Days', 'Past 7 Days', 7),
  month('30 Days', 'Past 30 Days', 30),
  quarter('90 Days', 'Past 3 Months', 90),
  custom('Custom', 'Custom Range', 0);

  final String label;
  final String title;
  final int days;

  const TimeRangePreset(this.label, this.title, this.days);

  DateTime getStartDate(DateTime reference) {
    if (this == TimeRangePreset.day) {
      return DateTime(reference.year, reference.month, reference.day);
    }
    return DateTime(reference.year, reference.month, reference.day)
        .subtract(Duration(days: days - 1));
  }

  DateTime getEndDate(DateTime reference) {
    return DateTime(reference.year, reference.month, reference.day, 23, 59, 59, 999);
  }
}

enum TimeOfDaySlot {
  am('AM / Morning', Icons.wb_sunny_rounded, Color(0xFFF59E0B)),
  midday('Midday', Icons.wb_twilight_rounded, Color(0xFFF97316)),
  pm('PM / Evening', Icons.nightlight_round, Color(0xFF6366F1));

  final String label;
  final IconData icon;
  final Color color;

  const TimeOfDaySlot(this.label, this.icon, this.color);

  static TimeOfDaySlot fromDateTime(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 4 && hour < 12) {
      return TimeOfDaySlot.am;
    } else if (hour >= 12 && hour < 17) {
      return TimeOfDaySlot.midday;
    } else {
      return TimeOfDaySlot.pm;
    }
  }
}

enum TargetZone {
  inTarget('In Target', Color(0xFF10B981)),
  elevated('Elevated', Color(0xFFF59E0B)),
  critical('Alert', Color(0xFFEF4444));

  final String label;
  final Color color;

  const TargetZone(this.label, this.color);

  static TargetZone evaluate(VitalReading reading) {
    switch (reading.type) {
      case VitalType.bloodPressure:
        final sys = reading.valuePrimary;
        final dia = reading.valueSecondary ?? 0;
        if (sys >= 140 || dia >= 90) return TargetZone.critical;
        if (sys >= 130 || dia >= 80) return TargetZone.elevated;
        if (sys >= 120 && sys < 130 && dia < 80) return TargetZone.elevated;
        return TargetZone.inTarget;

      case VitalType.glucose:
        final val = reading.valuePrimary;
        if (val < 70 || val > 180) return TargetZone.critical;
        if (val > 130) return TargetZone.elevated;
        return TargetZone.inTarget;

      case VitalType.heartRate:
        final val = reading.valuePrimary;
        if (val < 50 || val > 110) return TargetZone.critical;
        if (val < 60 || val > 100) return TargetZone.elevated;
        return TargetZone.inTarget;

      case VitalType.temperature:
        final val = reading.valuePrimary;
        if (val > 38.3 || val < 35.5) return TargetZone.critical;
        if (val > 37.5) return TargetZone.elevated;
        return TargetZone.inTarget;

      case VitalType.oxygenSaturation:
        final val = reading.valuePrimary;
        if (val < 92) return TargetZone.critical;
        if (val < 95) return TargetZone.elevated;
        return TargetZone.inTarget;

      case VitalType.respiratoryRate:
        final val = reading.valuePrimary;
        if (val < 10 || val > 24) return TargetZone.critical;
        if (val < 12 || val > 20) return TargetZone.elevated;
        return TargetZone.inTarget;

      case VitalType.weight:
        return TargetZone.inTarget;
    }
  }
}

class AnalyticsSummary {
  final VitalType vitalType;
  final List<VitalReading> readings;
  final VitalReading? latestReading;
  final int totalCount;
  final double? meanPrimary;
  final double? meanSecondary;
  final double? meanTertiary;
  final double? minPrimary;
  final double? maxPrimary;
  final double inTargetPercentage;
  final double? amMeanPrimary;
  final double? amMeanSecondary;
  final int amCount;
  final double? pmMeanPrimary;
  final double? pmMeanSecondary;
  final int pmCount;

  const AnalyticsSummary({
    required this.vitalType,
    required this.readings,
    this.latestReading,
    required this.totalCount,
    this.meanPrimary,
    this.meanSecondary,
    this.meanTertiary,
    this.minPrimary,
    this.maxPrimary,
    required this.inTargetPercentage,
    this.amMeanPrimary,
    this.amMeanSecondary,
    required this.amCount,
    this.pmMeanPrimary,
    this.pmMeanSecondary,
    required this.pmCount,
  });

  bool get isEmpty => totalCount == 0;

  static AnalyticsSummary calculate(VitalType vitalType, List<VitalReading> readings) {
    if (readings.isEmpty) {
      return AnalyticsSummary(
        vitalType: vitalType,
        readings: const [],
        totalCount: 0,
        inTargetPercentage: 0,
        amCount: 0,
        pmCount: 0,
      );
    }

    // Sort chronologically ascending for analytical calculations
    final sorted = List<VitalReading>.from(readings)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final latest = sorted.last;
    final count = sorted.length;

    double sumPrimary = 0;
    double sumSecondary = 0;
    int secondaryCount = 0;
    double sumTertiary = 0;
    int tertiaryCount = 0;

    double minP = sorted.first.valuePrimary;
    double maxP = sorted.first.valuePrimary;
    int inTargetCount = 0;

    double amSumPrimary = 0;
    double amSumSecondary = 0;
    int amSecondaryCount = 0;
    int amCount = 0;

    double pmSumPrimary = 0;
    double pmSumSecondary = 0;
    int pmSecondaryCount = 0;
    int pmCount = 0;

    for (final r in sorted) {
      final p = r.valuePrimary;
      sumPrimary += p;
      if (p < minP) minP = p;
      if (p > maxP) maxP = p;

      if (r.valueSecondary != null) {
        sumSecondary += r.valueSecondary!;
        secondaryCount++;
      }

      if (r.valueTertiary != null) {
        sumTertiary += r.valueTertiary!;
        tertiaryCount++;
      }

      if (TargetZone.evaluate(r) == TargetZone.inTarget) {
        inTargetCount++;
      }

      final slot = TimeOfDaySlot.fromDateTime(r.recordedAt);
      if (slot == TimeOfDaySlot.am) {
        amSumPrimary += p;
        amCount++;
        if (r.valueSecondary != null) {
          amSumSecondary += r.valueSecondary!;
          amSecondaryCount++;
        }
      } else if (slot == TimeOfDaySlot.pm) {
        pmSumPrimary += p;
        pmCount++;
        if (r.valueSecondary != null) {
          pmSumSecondary += r.valueSecondary!;
          pmSecondaryCount++;
        }
      }
    }

    return AnalyticsSummary(
      vitalType: vitalType,
      readings: sorted,
      latestReading: latest,
      totalCount: count,
      meanPrimary: sumPrimary / count,
      meanSecondary: secondaryCount > 0 ? sumSecondary / secondaryCount : null,
      meanTertiary: tertiaryCount > 0 ? sumTertiary / tertiaryCount : null,
      minPrimary: minP,
      maxPrimary: maxP,
      inTargetPercentage: (inTargetCount / count) * 100.0,
      amMeanPrimary: amCount > 0 ? amSumPrimary / amCount : null,
      amMeanSecondary: amSecondaryCount > 0 ? amSumSecondary / amSecondaryCount : null,
      amCount: amCount,
      pmMeanPrimary: pmCount > 0 ? pmSumPrimary / pmCount : null,
      pmMeanSecondary: pmSecondaryCount > 0 ? pmSumSecondary / pmSecondaryCount : null,
      pmCount: pmCount,
    );
  }
}


import 'package:flutter/material.dart';

enum VitalType {
  glucose(
    id: 'glucose',
    displayName: 'Blood Glucose',
    defaultUnit: 'mg/dL',
    triggers: [
      'glucose',
      'sugar',
      'blood sugar',
      'fasting blood sugar',
      'cbg',
      'rbs',
    ],
    minPlausible: 20,
    maxPlausible: 600,
    icon: Icons.water_drop_outlined,
    color: Color(0xFFE65100),
  ),
  bloodPressure(
    id: 'blood_pressure',
    displayName: 'Blood Pressure',
    defaultUnit: 'mmHg',
    triggers: [
      'blood pressure',
      'pressure',
      'bp',
      'sys',
      'dia',
    ],
    minPlausible: 50,
    maxPlausible: 260,
    minPlausibleSecondary: 30,
    maxPlausibleSecondary: 160,
    icon: Icons.favorite_outline,
    color: Color(0xFFC2185B),
  ),
  heartRate(
    id: 'heart_rate',
    displayName: 'Heart Rate',
    defaultUnit: 'bpm',
    triggers: [
      'heart rate',
      'pulse',
      'pulse rate',
      'heartbeat',
      'hr',
      'bpm',
    ],
    minPlausible: 30,
    maxPlausible: 240,
    icon: Icons.monitor_heart_outlined,
    color: Color(0xFFD32F2F),
  ),
  temperature(
    id: 'temperature',
    displayName: 'Body Temperature',
    defaultUnit: '°C',
    triggers: [
      'temperature',
      'temp',
      'body temp',
      'fever',
    ],
    minPlausible: 32.0,
    maxPlausible: 43.0,
    icon: Icons.thermostat_outlined,
    color: Color(0xFFF57C00),
  ),
  oxygenSaturation(
    id: 'oxygen_saturation',
    displayName: 'Oxygen Saturation',
    defaultUnit: '%',
    triggers: [
      'oxygen saturation',
      'oxygen',
      'spo2',
      'o2 sat',
      'pulse ox',
      'oximeter',
      'sat',
      'o2',
    ],
    minPlausible: 60,
    maxPlausible: 100,
    icon: Icons.air_outlined,
    color: Color(0xFF0288D1),
  ),
  respiratoryRate(
    id: 'respiratory_rate',
    displayName: 'Respiratory Rate',
    defaultUnit: '/min',
    triggers: [
      'respiratory rate',
      'respiration',
      'breathing rate',
      'breaths',
      'breathing',
      'rr',
    ],
    minPlausible: 6,
    maxPlausible: 60,
    icon: Icons.waves_outlined,
    color: Color(0xFF00897B),
  ),
  weight(
    id: 'weight',
    displayName: 'Weight',
    defaultUnit: 'kg',
    triggers: [
      'body weight',
      'weight',
      'wt',
      'weighs',
    ],
    minPlausible: 1.0,
    maxPlausible: 500.0,
    icon: Icons.scale_outlined,
    color: Color(0xFF5E35B1),
  );

  const VitalType({
    required this.id,
    required this.displayName,
    required this.defaultUnit,
    required this.triggers,
    required this.minPlausible,
    required this.maxPlausible,
    this.minPlausibleSecondary,
    this.maxPlausibleSecondary,
    required this.icon,
    required this.color,
  });

  final String id;
  final String displayName;
  final String defaultUnit;
  final List<String> triggers;
  final double minPlausible;
  final double maxPlausible;
  final double? minPlausibleSecondary;
  final double? maxPlausibleSecondary;
  final IconData icon;
  final Color color;

  static VitalType? fromId(String id) {
    for (final type in VitalType.values) {
      if (type.id == id) return type;
    }
    return null;
  }

  String formatValue(double primary, [double? secondary, double? tertiary]) {
    if (this == VitalType.bloodPressure && secondary != null) {
      final bp = '${primary.round()} / ${secondary.round()} $defaultUnit';
      if (tertiary != null) {
        return '$bp • Pulse ${tertiary.round()} bpm';
      }
      return bp;
    }
    if (this == VitalType.temperature || this == VitalType.weight) {
      final formatted = (primary % 1 == 0)
          ? primary.toInt().toString()
          : primary.toStringAsFixed(1);
      return '$formatted $defaultUnit';
    }
    return '${primary.round()} $defaultUnit';
  }

  String? validateRange(double primary, [double? secondary, double? tertiary]) {
    if (primary < minPlausible || primary > maxPlausible) {
      return 'Value $primary is outside the typical range ($minPlausible–$maxPlausible $defaultUnit)';
    }
    if (this == VitalType.bloodPressure && secondary != null) {
      if (secondary < (minPlausibleSecondary ?? 30) ||
          secondary > (maxPlausibleSecondary ?? 160)) {
        return 'Diastolic $secondary is outside typical range ($minPlausibleSecondary–$maxPlausibleSecondary $defaultUnit)';
      }
      if (primary <= secondary) {
        return 'Systolic pressure should typically be higher than diastolic';
      }
      if (tertiary != null && (tertiary < 30 || tertiary > 240)) {
        return 'Pulse ${tertiary.round()} bpm is outside typical range (30–240 bpm)';
      }
    }
    return null;
  }
}

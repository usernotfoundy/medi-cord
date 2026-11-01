import '../../core/vitals/vital_type.dart';

class VitalReading {
  final int? id;
  final VitalType type;
  final double valuePrimary;
  final double? valueSecondary;
  final double? valueTertiary;
  final String unit;
  final String rawTranscript;
  final DateTime recordedAt;
  final String? note;

  const VitalReading({
    this.id,
    required this.type,
    required this.valuePrimary,
    this.valueSecondary,
    this.valueTertiary,
    required this.unit,
    required this.rawTranscript,
    required this.recordedAt,
    this.note,
  });

  String get formattedValue =>
      type.formatValue(valuePrimary, valueSecondary, valueTertiary);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.id,
      'value_primary': valuePrimary,
      'value_secondary': valueSecondary,
      'value_tertiary': valueTertiary,
      'unit': unit,
      'raw_transcript': rawTranscript,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory VitalReading.fromMap(Map<String, dynamic> map) {
    final typeId = map['type'] as String;
    final type = VitalType.fromId(typeId) ?? VitalType.glucose;
    return VitalReading(
      id: map['id'] as int?,
      type: type,
      valuePrimary: (map['value_primary'] as num).toDouble(),
      valueSecondary: (map['value_secondary'] as num?)?.toDouble(),
      valueTertiary: (map['value_tertiary'] as num?)?.toDouble(),
      unit: map['unit'] as String? ?? type.defaultUnit,
      rawTranscript: map['raw_transcript'] as String? ?? '',
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recorded_at'] as int),
      note: map['note'] as String?,
    );
  }

  VitalReading copyWith({
    int? id,
    VitalType? type,
    double? valuePrimary,
    double? valueSecondary,
    double? valueTertiary,
    String? unit,
    String? rawTranscript,
    DateTime? recordedAt,
    String? note,
  }) {
    return VitalReading(
      id: id ?? this.id,
      type: type ?? this.type,
      valuePrimary: valuePrimary ?? this.valuePrimary,
      valueSecondary: valueSecondary ?? this.valueSecondary,
      valueTertiary: valueTertiary ?? this.valueTertiary,
      unit: unit ?? this.unit,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
    );
  }
}


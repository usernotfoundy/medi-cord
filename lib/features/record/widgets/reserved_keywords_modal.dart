import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/vitals/vital_type.dart';

class ReservedKeywordsModal extends StatelessWidget {
  final VitalType vital;

  const ReservedKeywordsModal({
    super.key,
    required this.vital,
  });

  static Future<void> show(BuildContext context, VitalType vital) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReservedKeywordsModal(vital: vital),
    );
  }

  List<String> get _examplePhrases {
    switch (vital) {
      case VitalType.glucose:
        return [
          'Glucose 120',
          'Sugar one twenty',
          'Blood sugar 95',
          'Fasting blood sugar 105',
        ];
      case VitalType.bloodPressure:
        return [
          'Blood pressure 120 over 80',
          'BP 135 74 93 (with pulse)',
          'Pressure 130 over 85',
          'BP 125 78',
        ];
      case VitalType.heartRate:
        return [
          'Heart rate 72',
          'Pulse 80',
          'Pulse rate sixty five',
          'BPM 75',
        ];
      case VitalType.temperature:
        return [
          'Temperature 37.2',
          'Temp thirty six point eight',
          'Body temp 36.5',
          'Fever 38.5',
        ];
      case VitalType.oxygenSaturation:
        return [
          'Oxygen 98',
          'Oxygen saturation 99',
          'SPO2 ninety seven',
          'O2 sat 98',
        ];
      case VitalType.respiratoryRate:
        return [
          'Respiratory rate 16',
          'Respiration 18',
          'Breaths 14',
          'Breathing rate 16',
        ];
      case VitalType.weight:
        return [
          'Weight 68.5',
          'Body weight seventy',
          'Weight 72 kg',
          'Weighs 65.4',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header with Vital Badge
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: vital.color.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    vital.icon,
                    color: vital.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vital.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard Unit: ${vital.defaultUnit}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Accepted Voice Triggers
            Text(
              'RESERVED VOICE KEYWORDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Speak any of these trigger words when holding the mic to automatically detect ${vital.displayName}:',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vital.triggers.map((trigger) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: vital.color.withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          vital.color.withValues(alpha: isDark ? 0.38 : 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 13,
                        color: vital.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '"$trigger"',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Section 2: Sample Spoken Phrases
            Text(
              'HOW TO SAY IT (EXAMPLES)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: _examplePhrases.map((phrase) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '"$phrase"',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 26),

            // "Got it" Button
            FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/text_size_button.dart';
import '../../core/theme/theme_toggle_switch.dart';
import '../../core/vitals/vital_type.dart';
import 'record_controller.dart';
import 'widgets/dynamic_island_pill.dart';
import 'widgets/mic_button.dart';
import 'widgets/review_card.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);
    final controller = ref.read(recordControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo_horizontal.png',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            'MediCord',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor?.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        actions: const [
          TextSizeButton(),
          ThemeToggleSwitch(),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reserved Voice Keywords Guide
                  _buildReservedWordsCard(theme, isDark),
                  const SizedBox(height: 20),

                  // Dynamic Main Area
                  if (state.status == RecordStatus.review &&
                      state.parsedReading != null) ...[
                    ReviewCard(
                      reading: state.parsedReading!,
                      isSaving: _isSaving,
                      onRetry: () => controller.retry(),
                      onReadingEdited: (updated) =>
                          controller.updateParsedReading(updated),
                      onSave: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSaving = true);
                        final success = await controller.saveReading();
                        setState(() => _isSaving = false);
                        if (mounted && success) {
                          HapticFeedback.mediumImpact();
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Vital sign recorded to database',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0D9488),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                  ] else if (state.status == RecordStatus.error) ...[
                    _buildErrorCard(context, state, controller, isDark),
                  ] else ...[
                    _buildRecordingArea(state, controller, theme, isDark),
                  ],

                  const SizedBox(height: 24),

                  // How to Record Guide Card (replaces test scenarios)
                  if (state.status == RecordStatus.idle) ...[
                    _buildHowToUseGuide(theme, isDark),
                  ],
                ],
              ),
            ),

            // Floating Dynamic Island Pill with Apple-style Fluid In & Out Physics
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: DynamicIslandPill(
                isListening: state.status == RecordStatus.listening ||
                    state.status == RecordStatus.processing,
                rawTranscript: state.rawTranscript,
                soundLevel: state.soundLevel,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservedWordsCard(ThemeData theme, bool isDark) {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                size: 20,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(width: 8),
              Text(
                'Reserved Voice Keywords',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hold the mic and say any trigger keyword followed by values (e.g., "Glucose 120" or "BP 120 over 80"):',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VitalType.values.map((v) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: v.color.withValues(alpha: isDark ? 0.14 : 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: v.color.withValues(alpha: isDark ? 0.35 : 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(v.icon, size: 14, color: v.color),
                    const SizedBox(width: 6),
                    Text(
                      '${v.displayName} (${v.defaultUnit})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingArea(
    RecordState state,
    RecordController controller,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: MicButton(
          isListening: state.status == RecordStatus.listening,
          isProcessing: state.status == RecordStatus.processing,
          soundLevel: state.soundLevel,
          onPressDown: () => controller.onMicPressDown(),
          onPressUp: () => controller.onMicPressUp(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    RecordState state,
    RecordController controller,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
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
              Icons.mic_off_rounded,
              color: Color(0xFFDC2626),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Recording Not Recognized',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 8),
          if (state.rawTranscript.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Heard: "${state.rawTranscript}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            state.errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.retry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 48),
              foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseGuide(ThemeData theme, bool isDark) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'How to Use MediCord',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideStep(
            number: '1',
            icon: Icons.touch_app_rounded,
            title: 'Press & Hold',
            description:
                'Press and hold the round microphone button with your finger.',
            color: const Color(0xFF0D9488),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildGuideStep(
            number: '2',
            icon: Icons.mic_rounded,
            title: 'Speak Vital & Reading',
            description:
                'Say the vital sign name and your numbers clearly (e.g. "Glucose 120", "BP 120 over 80", or "BP 135 74 93").',
            color: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildGuideStep(
            number: '3',
            icon: Icons.check_circle_outline_rounded,
            title: 'Release to Finalize',
            description:
                'Release the button when finished speaking. Review the recognized text, then tap Save to record it or Retry to try again.',
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, size: 16, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/parsing/vital_parser.dart';
import '../../../core/vitals/vital_type.dart';

class ReviewCard extends StatefulWidget {
  final ParsedReading reading;
  final VoidCallback onRetry;
  final VoidCallback onSave;
  final ValueChanged<ParsedReading>? onReadingEdited;
  final bool isSaving;

  const ReviewCard({
    super.key,
    required this.reading,
    required this.onRetry,
    required this.onSave,
    this.onReadingEdited,
    this.isSaving = false,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isRetryPressed = false;
  bool _isSavePressed = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    // Emil Kowalski & Apple rule: Never animate from scale(0); start from scale(0.95)
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Cubic(0.23, 1, 0.32, 1), // Strong ease-out
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    HapticFeedback.selectionClick();
    final primaryController = TextEditingController(
      text: widget.reading.vitalType == VitalType.temperature ||
              widget.reading.vitalType == VitalType.weight
          ? widget.reading.primaryValue.toString()
          : widget.reading.primaryValue.round().toString(),
    );
    final secondaryController = TextEditingController(
      text: widget.reading.secondaryValue?.round().toString() ?? '',
    );
    final tertiaryController = TextEditingController(
      text: widget.reading.tertiaryValue?.round().toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit ${widget.reading.vitalType.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: primaryController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: widget.reading.vitalType == VitalType.bloodPressure
                    ? 'Systolic (mmHg)'
                    : 'Value (${widget.reading.unit})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (widget.reading.vitalType == VitalType.bloodPressure) ...[
              const SizedBox(height: 14),
              TextField(
                controller: secondaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: tertiaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Pulse (bpm) — Optional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newPrimary = double.tryParse(primaryController.text);
              final newSecondary =
                  double.tryParse(secondaryController.text);
              final newTertiary =
                  double.tryParse(tertiaryController.text);
              if (newPrimary != null) {
                final warning = widget.reading.vitalType.validateRange(
                  newPrimary,
                  newSecondary,
                  newTertiary,
                );
                final updated = widget.reading.copyWith(
                  primaryValue: newPrimary,
                  secondaryValue: newSecondary,
                  tertiaryValue: newTertiary,
                  warningMessage: warning,
                );
                widget.onReadingEdited?.call(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vital = widget.reading.vitalType;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final content = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heard Transcript Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: isDark
                  ? Border.all(color: const Color(0xFF334155))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hearing_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                      children: [
                        TextSpan(
                          text: 'You spoke: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                        TextSpan(
                          text: '"${widget.reading.rawTranscript}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: vital.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Parsed Vital Card
          InkWell(
            onTap: _showEditDialog,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: vital.color.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: vital.color.withValues(alpha: isDark ? 0.35 : 0.22),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:
                          vital.color.withValues(alpha: isDark ? 0.22 : 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      vital.icon,
                      color: vital.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              vital.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : Colors.grey.shade400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (widget.reading.vitalType ==
                                VitalType.bloodPressure &&
                            widget.reading.secondaryValue != null) ...[
                          Text(
                            '${widget.reading.primaryValue.round()} / ${widget.reading.secondaryValue!.round()} ${widget.reading.unit}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: vital.color,
                              letterSpacing: -0.6,
                            ),
                          ),
                          if (widget.reading.tertiaryValue != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  size: 15,
                                  color: Color(0xFFD32F2F),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pulse: ${widget.reading.tertiaryValue!.round()} bpm',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          Text(
                            widget.reading.formattedValue,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: vital.color,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plausible Range Warning if any
          if (widget.reading.warningMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF451A03).withValues(alpha: 0.4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFB45309)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.reading.warningMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Retry and Save Buttons
          Row(
            children: [
              // Retry Button
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isRetryPressed = true),
                  onTapUp: (_) {
                    setState(() => _isRetryPressed = false);
                    HapticFeedback.lightImpact();
                    widget.onRetry();
                  },
                  onTapCancel: () => setState(() => _isRetryPressed = false),
                  child: AnimatedScale(
                    scale: _isRetryPressed ? 0.96 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    child: OutlinedButton.icon(
                      onPressed: widget.isSaving ? null : widget.onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Save Button
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isSavePressed = true),
                  onTapUp: (_) {
                    setState(() => _isSavePressed = false);
                    HapticFeedback.mediumImpact();
                    widget.onSave();
                  },
                  onTapCancel: () => setState(() => _isSavePressed = false),
                  child: AnimatedScale(
                    scale: _isSavePressed ? 0.96 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    child: FilledButton.icon(
                      onPressed: widget.isSaving ? null : widget.onSave,
                      icon: widget.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        widget.isSaving ? 'Saving...' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return content;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: content,
      ),
    );
  }
}

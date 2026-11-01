import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/vitals/vital_type.dart';
import '../../data/db/app_database.dart';
import '../../data/models/vital_reading.dart';
import '../record/record_controller.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ManualEntrySheet(),
    );
  }

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  VitalType _selectedVital = VitalType.bloodPressure;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _tertiaryController = TextEditingController();
  final _noteController = TextEditingController();

  String? _validationWarning;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _primaryController.addListener(_validateInputs);
    _secondaryController.addListener(_validateInputs);
    _tertiaryController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _tertiaryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    final pVal = double.tryParse(_primaryController.text.trim());
    final sVal = double.tryParse(_secondaryController.text.trim());
    final tVal = double.tryParse(_tertiaryController.text.trim());

    if (pVal == null) {
      if (_validationWarning != null) {
        setState(() => _validationWarning = null);
      }
      return;
    }

    final warning = _selectedVital.validateRange(pVal, sVal, tVal);
    if (warning != _validationWarning) {
      setState(() => _validationWarning = warning);
    }
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2DD4BF),
                    surface: Color(0xFF1E293B),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    surface: Colors.white,
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2DD4BF),
                    surface: Color(0xFF1E293B),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    surface: Colors.white,
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveEntry() async {
    final pText = _primaryController.text.trim();
    final pVal = double.tryParse(pText);

    if (pVal == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid numeric reading.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final double? sVal;
    if (_selectedVital == VitalType.bloodPressure) {
      final sText = _secondaryController.text.trim();
      sVal = double.tryParse(sText);
      if (sVal == null) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter diastolic blood pressure.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    } else {
      sVal = null;
    }

    final double? tVal = double.tryParse(_tertiaryController.text.trim());

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final note = _noteController.text.trim();

      final reading = VitalReading(
        type: _selectedVital,
        valuePrimary: pVal,
        valueSecondary: sVal,
        valueTertiary: tVal,
        unit: _selectedVital.defaultUnit,
        rawTranscript: 'Manual entry',
        recordedAt: finalDateTime,
        note: note.isNotEmpty ? note : null,
      );

      AppDatabase.ensureInitialized();
      final repo = ref.read(vitalRepositoryProvider);
      await repo.insertReading(reading);
      ref.invalidate(readingsListProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedVital.displayName} ($pText ${_selectedVital.defaultUnit}) saved successfully.',
            ),
            backgroundColor: const Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reading: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBp = _selectedVital == VitalType.bloodPressure;

    // Date formatting string
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateStr = isToday
        ? 'Today (${DateFormat('MMM d').format(_selectedDate)})'
        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate);

    final timeStr = _selectedTime.format(context);

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
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
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
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedVital.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedVital.icon,
                    color: _selectedVital.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Vital Entry',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Record past or missed readings',
                        style: TextStyle(
                          fontSize: 12.5,
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
            const SizedBox(height: 18),

            // Vital Type Selector
            Text(
              'SELECT VITAL SIGN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: VitalType.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final vital = VitalType.values[index];
                  final isSelected = vital == _selectedVital;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedVital = vital;
                        _primaryController.clear();
                        _secondaryController.clear();
                        _tertiaryController.clear();
                        _validationWarning = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? vital.color
                            : (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? vital.color
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            vital.icon,
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vital.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Value Input Fields
            Text(
              'READING VALUES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),

            if (isBp) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _primaryController,
                      label: 'Systolic',
                      unit: 'mmHg',
                      isDark: isDark,
                      isDecimal: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputField(
                      controller: _secondaryController,
                      label: 'Diastolic',
                      unit: 'mmHg',
                      isDark: isDark,
                      isDecimal: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputField(
                      controller: _tertiaryController,
                      label: 'Pulse (opt)',
                      unit: 'bpm',
                      isDark: isDark,
                      isDecimal: false,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildInputField(
                controller: _primaryController,
                label: _selectedVital.displayName,
                unit: _selectedVital.defaultUnit,
                isDark: isDark,
                isDecimal: _selectedVital == VitalType.temperature ||
                    _selectedVital == VitalType.weight,
              ),
            ],

            // Clinical validation warning
            if (_validationWarning != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationWarning!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFB45309),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Date & Time Setter Section
            Text(
              'RECORDING DATE & TIME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // Date Button
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Time Button
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Optional Note Field
            Text(
              'OPTIONAL NOTES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'e.g. Fasting, Post-medication, Felt dizzy',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D9488),
                    width: 1.8,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Save Reading Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveEntry,
              icon: _isSaving
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
                _isSaving ? 'Saving...' : 'Save Vital Reading',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required bool isDark,
    required bool isDecimal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0D9488),
                width: 1.8,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}


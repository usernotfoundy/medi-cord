import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'manual_entry_sheet.dart';

/// An accessible, high-contrast header button with both an icon and text label
/// making manual entry immediately visible and easy to spot for low-vision patients.
class ManualEntryHeaderButton extends StatelessWidget {
  const ManualEntryHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
    final bgColor = isDark
        ? const Color(0xFF0D9488).withValues(alpha: 0.20)
        : const Color(0xFF0D9488).withValues(alpha: 0.12);
    final borderColor = isDark
        ? const Color(0xFF2DD4BF).withValues(alpha: 0.45)
        : const Color(0xFF0D9488).withValues(alpha: 0.35);

    return Tooltip(
      message: 'Manual Entry',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Material(
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor, width: 1.2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                ManualEntrySheet.show(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Manual',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


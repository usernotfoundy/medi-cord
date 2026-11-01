import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/vitals/vital_type.dart';
import '../models/analytics_models.dart';

class ClinicalKpiGrid extends StatelessWidget {
  final AnalyticsSummary summary;
  final bool isDark;

  const ClinicalKpiGrid({
    super.key,
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    final vital = summary.vitalType;
    final isBp = vital == VitalType.bloodPressure;

    // Latest value formatting
    final latestVal = summary.latestReading?.formattedValue ?? '—';
    final latestTime = summary.latestReading != null
        ? DateFormat('MMM d • h:mm a').format(summary.latestReading!.recordedAt)
        : '';
    final latestTarget = summary.latestReading != null
        ? TargetZone.evaluate(summary.latestReading!)
        : TargetZone.inTarget;

    // Period Average formatting
    final String avgFormatted;
    if (isBp && summary.meanPrimary != null && summary.meanSecondary != null) {
      avgFormatted =
          '${summary.meanPrimary!.round()} / ${summary.meanSecondary!.round()} ${vital.defaultUnit}';
    } else if (summary.meanPrimary != null) {
      final p = summary.meanPrimary!;
      final str = (vital == VitalType.temperature || vital == VitalType.weight)
          ? p.toStringAsFixed(1)
          : p.round().toString();
      avgFormatted = '$str ${vital.defaultUnit}';
    } else {
      avgFormatted = '—';
    }

    // Range string
    final minStr = summary.minPrimary != null ? summary.minPrimary!.round().toString() : '—';
    final maxStr = summary.maxPrimary != null ? summary.maxPrimary!.round().toString() : '—';

    // Compliance color
    final compliance = summary.inTargetPercentage;
    final Color complianceColor = compliance >= 75
        ? const Color(0xFF10B981)
        : (compliance >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            children: [
              // Card 1: Latest Reading
              Expanded(
                child: _buildKpiCard(
                  title: 'LATEST READING',
                  value: latestVal,
                  valueColor: vital.color,
                  subtitle: latestTime,
                  badge: latestTarget.label,
                  badgeColor: latestTarget.color,
                ),
              ),
              const SizedBox(width: 10),

              // Card 2: Target Range Compliance
              Expanded(
                child: _buildKpiCard(
                  title: 'IN TARGET RANGE',
                  value: '${compliance.round()}%',
                  valueColor: complianceColor,
                  subtitle: '${summary.totalCount} total recordings',
                  badge: compliance >= 75
                      ? 'Optimal'
                      : (compliance >= 50 ? 'Moderate' : 'Action Needed'),
                  badgeColor: complianceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Card 3: Period Average & Range
              Expanded(
                child: _buildKpiCard(
                  title: 'PERIOD AVERAGE',
                  value: avgFormatted,
                  valueColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  subtitle: 'Range: $minStr – $maxStr',
                  badge: '${summary.totalCount} logs',
                  badgeColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 10),

              // Card 4: AM vs PM Split
              Expanded(
                child: _buildAmPmSplitCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmSplitCard() {
    final isBp = summary.vitalType == VitalType.bloodPressure;

    final String amStr;
    if (summary.amCount > 0) {
      if (isBp && summary.amMeanPrimary != null && summary.amMeanSecondary != null) {
        amStr = '${summary.amMeanPrimary!.round()}/${summary.amMeanSecondary!.round()}';
      } else if (summary.amMeanPrimary != null) {
        amStr = summary.amMeanPrimary!.round().toString();
      } else {
        amStr = '—';
      }
    } else {
      amStr = 'None';
    }

    final String pmStr;
    if (summary.pmCount > 0) {
      if (isBp && summary.pmMeanPrimary != null && summary.pmMeanSecondary != null) {
        pmStr = '${summary.pmMeanPrimary!.round()}/${summary.pmMeanSecondary!.round()}';
      } else if (summary.pmMeanPrimary != null) {
        pmStr = summary.pmMeanPrimary!.round().toString();
      } else {
        pmStr = '—';
      }
    } else {
      pmStr = 'None';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AM / PM SPLIT',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const Icon(
                Icons.compare_arrows_rounded,
                size: 14,
                color: Color(0xFF0D9488),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                size: 13,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                'AM: ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                amStr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.nightlight_round,
                size: 12,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(width: 4),
              Text(
                'PM: ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                pmStr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AM (${summary.amCount}) • PM (${summary.pmCount})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}


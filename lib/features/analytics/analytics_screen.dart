import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/text_size_button.dart';
import '../../core/theme/theme_toggle_switch.dart';
import 'analytics_controller.dart';
import 'widgets/clinical_kpi_grid.dart';
import 'widgets/clinical_trend_chart.dart';
import 'widgets/period_readings_list.dart';
import 'widgets/time_range_selector.dart';
import 'widgets/vital_type_selector.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Clinical Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor?.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            tooltip: 'Refresh Analytics',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(analyticsSummaryProvider);
            },
          ),
          const TextSizeButton(),
          const ThemeToggleSwitch(),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(analyticsSummaryProvider);
              await ref.read(analyticsSummaryProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const VitalTypeSelector(),
                  const SizedBox(height: 12),
                  const TimeRangeSelector(),
                  const SizedBox(height: 16),
                  if (summary.isEmpty) ...[
                    ClinicalTrendChart(summary: summary, isDark: isDark),
                  ] else ...[
                    ClinicalKpiGrid(summary: summary, isDark: isDark),
                    const SizedBox(height: 16),
                    ClinicalTrendChart(summary: summary, isDark: isDark),
                    const SizedBox(height: 16),
                    PeriodReadingsList(summary: summary, isDark: isDark),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
        ),
        error: (error, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load analytics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(analyticsSummaryProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


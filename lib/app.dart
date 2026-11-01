import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/text_size_provider.dart';
import 'features/record/record_screen.dart';
import 'features/history/history_screen.dart';
import 'features/analytics/analytics_screen.dart';

class MediCordApp extends ConsumerWidget {
  const MediCordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);

    return MaterialApp(
      title: 'Medi Cord',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale.scale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RecordScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            if (_currentIndex != idx) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = idx);
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.mic_none_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.mic_rounded,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
              ),
              label: 'Record',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.insights_outlined,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.insights_rounded,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
              ),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.history_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.history_rounded,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
              ),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}

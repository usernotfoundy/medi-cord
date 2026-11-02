import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';

enum AppTextScale {
  standard(1.0, 'Standard', '1.0x', 'Default reading size'),
  large(1.2, 'Large', '1.2x', 'Enhanced legibility (+20%)'),
  extraLarge(1.4, 'Extra Large', '1.4x', 'High visibility (+40%)'),
  huge(1.6, 'Maximum', '1.6x', 'Maximum accessibility (+60%)');

  final double scale;
  final String label;
  final String badge;
  final String description;

  const AppTextScale(this.scale, this.label, this.badge, this.description);
}

final textScaleProvider =
    NotifierProvider<TextScaleNotifier, AppTextScale>(TextScaleNotifier.new);

class TextScaleNotifier extends Notifier<AppTextScale> {
  @override
  AppTextScale build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.getTextScale();
  }

  void setScale(AppTextScale scale) {
    state = scale;
    ref.read(preferencesServiceProvider).saveTextScale(scale);
  }

  void cycleNext() {
    final values = AppTextScale.values;
    final nextIndex = (state.index + 1) % values.length;
    final nextScale = values[nextIndex];
    state = nextScale;
    ref.read(preferencesServiceProvider).saveTextScale(nextScale);
  }
}


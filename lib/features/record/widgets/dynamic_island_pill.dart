import 'package:flutter/material.dart';

class DynamicIslandPill extends StatefulWidget {
  final bool isListening;
  final String rawTranscript;
  final double soundLevel;
  final bool isDark;

  const DynamicIslandPill({
    super.key,
    required this.isListening,
    required this.rawTranscript,
    this.soundLevel = 0.0,
    required this.isDark,
  });

  @override
  State<DynamicIslandPill> createState() => _DynamicIslandPillState();
}

class _DynamicIslandPillState extends State<DynamicIslandPill>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );

    // Apple Dynamic Island spring-like ease-out overshoot on entry
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30,
      ),
    ]).animate(_morphController);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.9),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: const Cubic(0.175, 0.885, 0.32, 1.2), // Apple spring feel
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    // Continuous audio recording halo pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    if (widget.isListening) {
      _morphController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DynamicIslandPill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening && !oldWidget.isListening) {
      _morphController.forward();
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _morphController.reverse();
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        if (_morphController.isDismissed && !widget.isListening) {
          return const SizedBox.shrink();
        }

        final double scale = reduceMotion ? 1.0 : _scaleAnimation.value;
        final Offset slide = reduceMotion ? Offset.zero : _slideAnimation.value;
        final double opacity = _fadeAnimation.value.clamp(0.0, 1.0);

        return IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: FractionalTranslation(
              translation: slide,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: opacity,
                  child: _buildIslandCapsule(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIslandCapsule(BuildContext context) {
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(
        minWidth: 160,
        maxWidth: 420,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? const Color(0xFFEF4444).withValues(alpha: 0.45)
              : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
        boxShadow: [
          // Dynamic Island ambient red glow
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(
              alpha: isDark ? 0.35 : 0.18,
            ),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Island Mic / Pulse Indicator with Halo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseVal = _pulseController.value;
              return SizedBox(
                width: 22,
                height: 22,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 14 + (pulseVal * 8),
                      height: 14 + (pulseVal * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF4444).withValues(
                          alpha: (0.45 - (pulseVal * 0.35)).clamp(0.0, 0.45),
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Waveform Audio Bars (Reacting dynamically)
          _buildMiniWaveform(isDark),

          const SizedBox(width: 10),

          // Live Transcript or Listening Hint
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              child: Text(
                widget.rawTranscript.isEmpty
                    ? 'Listening... Speak now'
                    : widget.rawTranscript,
                key: ValueKey(widget.rawTranscript),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isDark
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniWaveform(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final val = _pulseController.value;
        final soundBoost = (widget.soundLevel * 0.4).clamp(0.0, 0.8);

        final h1 = (6.0 + (val * 8.0) + (soundBoost * 10)).clamp(4.0, 22.0);
        final h2 = (12.0 - (val * 6.0) + (soundBoost * 12)).clamp(4.0, 24.0);
        final h3 = (7.0 + ((1.0 - val) * 7.0) + (soundBoost * 8)).clamp(4.0, 20.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _waveBar(h1),
            const SizedBox(width: 2.5),
            _waveBar(h2),
            const SizedBox(width: 2.5),
            _waveBar(h3),
          ],
        );
      },
    );
  }

  Widget _waveBar(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 2.8,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}


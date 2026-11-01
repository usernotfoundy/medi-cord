import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final double soundLevel;
  final VoidCallback onPressDown;
  final VoidCallback onPressUp;

  const MicButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    this.soundLevel = 0.0,
    required this.onPressDown,
    required this.onPressUp,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.value = 0.0;
      _rippleController.stop();
      _rippleController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final Color activeColor = widget.isListening
        ? const Color(0xFFEF4444) // Apple-like vibrant red
        : widget.isProcessing
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFF0D9488); // Deep Medical Teal

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.mediumImpact();
            widget.onPressDown();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact();
            widget.onPressUp();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            HapticFeedback.selectionClick();
            widget.onPressUp();
          },
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Concentric Ripples when listening
                if (widget.isListening && !reduceMotion) ...[
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      final val = _rippleController.value;
                      final size = 96.0 + (val * 44.0);
                      final opacity = (1.0 - val).clamp(0.0, 0.45);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColor.withValues(alpha: opacity),
                            width: 2.5,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      final val = (_rippleController.value + 0.5) % 1.0;
                      final size = 96.0 + (val * 34.0);
                      final opacity = (1.0 - val).clamp(0.0, 0.35);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColor.withValues(alpha: opacity),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Main Core Button with Physical Spring Feel
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final soundBoost =
                        (widget.soundLevel * 0.04).clamp(0.0, 0.15);
                    final pulse = (widget.isListening && !reduceMotion)
                        ? 1.0 + (_pulseController.value * 0.08) + soundBoost
                        : 1.0;
                    final targetScale = _isPressed ? 0.94 : pulse;

                    return AnimatedScale(
                      scale: targetScale,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              activeColor,
                              activeColor.withValues(alpha: 0.88),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(
                                  alpha: widget.isListening ? 0.45 : 0.22),
                              blurRadius: widget.isListening ? 26 : 14,
                              spreadRadius: widget.isListening ? 4 : 0,
                              offset: const Offset(0, 6),
                            ),
                            // Top light reflection edge (Apple glass/material aesthetic)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 1,
                              spreadRadius: 0,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.isProcessing
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.8,
                                  ),
                                )
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                    scale: anim,
                                    child: child,
                                  ),
                                  child: Icon(
                                    widget.isListening
                                        ? Icons.mic_rounded
                                        : Icons.mic_none_rounded,
                                    key: ValueKey(widget.isListening),
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Text(
                widget.isListening
                    ? 'Listening... Release to finish'
                    : widget.isProcessing
                        ? 'Processing voice...'
                        : 'Press and hold to record',
                key: ValueKey(widget.isListening
                    ? 'listening'
                    : widget.isProcessing
                        ? 'processing'
                        : 'idle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.isListening
                      ? activeColor
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                  fontWeight:
                      widget.isListening ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

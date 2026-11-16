import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// True when the device asks for less motion (accessibility setting): animations then skip to the end.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades a child in while it rises a few pixels. Give list items an [index] so they appear one
/// after another. Plays once, when the widget first appears.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.dy = 14,
    this.duration = AppMotion.slow,
  });

  final Widget child;

  /// Position in a list: each step adds a short delay (capped, so long lists don't wait).
  final int index;

  /// Extra delay on top of the index stagger.
  final Duration? delay;
  final double dy;
  final Duration duration;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final wait = (widget.delay ?? Duration.zero) + Duration(milliseconds: 55 * widget.index.clamp(0, 8));
    final total = wait + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    // The wait is folded into the curve (an Interval) so no timers are needed.
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(wait.inMilliseconds / total.inMilliseconds, 1, curve: AppMotion.emphasized),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - _curve.value) * widget.dy), child: child),
      ),
    );
  }
}

/// Gives anything tappable a small press-down effect without taking over its gestures.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.97, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Counts a number up to [value] (e.g. revenue on the dashboard). [format] turns it into text.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.format, this.style, this.duration = AppMotion.slow});

  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text(format(value), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: AppMotion.emphasized,
      builder: (_, v, _) => Text(format(v), style: style),
    );
  }
}

/// Wraps skeleton shapes so a soft highlight sweeps across all of them together.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final glow = scheme.surfaceContainerHighest.withValues(alpha: 1);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final t = _controller.value;
          return LinearGradient(
            begin: Alignment(-1.6 + 3.2 * t, -0.3),
            end: Alignment(-0.6 + 3.2 * t, 0.3),
            colors: [base, glow, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

/// A grey rounded placeholder shape, used inside [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder for a list row (photo, two lines of text and a price), shown while loading.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 64, height: 64, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 14),
                SizedBox(height: 10),
                SkeletonBox(width: 100, height: 12),
                SizedBox(height: 10),
                SkeletonBox(width: 60, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades the page of an admin / customer tab in when it becomes the selected one.
/// Used as the `navigatorContainerBuilder` of the tab shells.
class BranchFader extends StatelessWidget {
  const BranchFader({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [for (var i = 0; i < children.length; i++) _FadeBranch(active: i == currentIndex, child: children[i])],
    );
  }
}

class _FadeBranch extends StatefulWidget {
  const _FadeBranch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_FadeBranch> createState() => _FadeBranchState();
}

class _FadeBranchState extends State<_FadeBranch> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.base,
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_FadeBranch old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      if (reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    } else if (!widget.active && old.active) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
    return Offstage(
      offstage: !widget.active,
      child: TickerMode(
        enabled: widget.active,
        child: FadeTransition(
          opacity: curve,
          child: AnimatedBuilder(
            animation: curve,
            child: widget.child,
            builder: (_, child) => Transform.translate(offset: Offset(0, (1 - curve.value) * 10), child: child),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';

/// Applies a 3D Rubik's cube face transform (horizontal shift, Y-axis hinge
/// rotation with perspective, and directional depth shading) while keeping
/// widget identity stable across frames.
class _RubikCubeFace extends StatelessWidget {
  final double offsetX;
  final Alignment alignment;
  final double angleY;
  final double shadeAlpha;
  final bool blockTouches;
  final Widget child;

  const _RubikCubeFace({
    required this.offsetX,
    required this.alignment,
    required this.angleY,
    required this.shadeAlpha,
    required this.blockTouches,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isIdentity = angleY == 0.0 && offsetX == 0.0 && shadeAlpha == 0.0;
    final isEdgeHidden = !isIdentity && angleY.abs() >= (math.pi / 2) - 0.015;
    final safeAngle = angleY.clamp(-(math.pi / 2) + 0.02, (math.pi / 2) - 0.02);
    final matrix = Matrix4.identity();
    if (!isIdentity && safeAngle != 0) {
      matrix
        ..setEntry(3, 2, 0.0014)
        ..rotateY(safeAngle);
    }

    return Visibility(
      visible: !isEdgeHidden,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: IgnorePointer(
        ignoring: blockTouches,
        child: Transform.translate(
          offset: isIdentity ? Offset.zero : Offset(offsetX, 0),
          child: Transform(
            alignment: alignment,
            transform: matrix,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: shadeAlpha > 0
                          ? Colors.black.withValues(alpha: shadeAlpha)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Switches between persistent tab screens with a 3D Rubik's cube rotation
/// while preserving each tab's state (scroll offsets, forms, controllers).
class RubikCubeTabView extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  final Duration duration;

  const RubikCubeTabView({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  State<RubikCubeTabView> createState() => _RubikCubeTabViewState();
}

class _RubikCubeTabViewState extends State<RubikCubeTabView>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  int? _previousIndex;
  bool? _isForward;

  int get _prevIdx => _previousIndex ?? widget.currentIndex;
  bool get _forward => _isForward ?? true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _isForward = true;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _previousIndex = widget.currentIndex;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant RubikCubeTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller?.duration = widget.duration;
    }
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _isForward = widget.currentIndex > oldWidget.currentIndex;
      _controller?.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return IndexedStack(
        index: widget.currentIndex,
        children: widget.children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final rawT = controller.value;
              final isAnimating =
                  controller.isAnimating && _prevIdx != widget.currentIndex;
              final t = Curves.easeInOutCubic.transform(rawT);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Visibility(
                      visible: isAnimating,
                      child: const ColoredBox(color: AppColors.deepNavy),
                    ),
                  ),
                  for (var i = 0; i < widget.children.length; i++)
                    _buildTabChild(
                      index: i,
                      width: width,
                      t: t,
                      isAnimating: isAnimating,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabChild({
    required int index,
    required double width,
    required double t,
    required bool isAnimating,
  }) {
    final isCurrent = index == widget.currentIndex;
    final isOutgoing = isAnimating && index == _prevIdx;
    final isVisible = isCurrent || isOutgoing;

    var offsetX = 0.0;
    var alignment = Alignment.centerLeft;
    var angleY = 0.0;
    var shadeAlpha = 0.0;

    if (isAnimating && isVisible) {
      const maxAngle = math.pi / 2;
      if (_forward) {
        if (isOutgoing) {
          offsetX = -width * t;
          alignment = Alignment.centerRight;
          angleY = maxAngle * t;
          shadeAlpha = 0.24 * t;
        } else {
          offsetX = width * (1.0 - t);
          alignment = Alignment.centerLeft;
          angleY = -maxAngle * (1.0 - t);
          shadeAlpha = 0.24 * (1.0 - t);
        }
      } else {
        if (isOutgoing) {
          offsetX = width * t;
          alignment = Alignment.centerLeft;
          angleY = -maxAngle * t;
          shadeAlpha = 0.24 * t;
        } else {
          offsetX = -width * (1.0 - t);
          alignment = Alignment.centerRight;
          angleY = maxAngle * (1.0 - t);
          shadeAlpha = 0.24 * (1.0 - t);
        }
      }
    }

    return Offstage(
      offstage: !isVisible,
      child: TickerMode(
        enabled: isVisible,
        child: _RubikCubeFace(
          offsetX: offsetX,
          alignment: alignment,
          angleY: angleY,
          shadeAlpha: shadeAlpha,
          blockTouches: isAnimating,
          child: widget.children[index],
        ),
      ),
    );
  }
}

/// Global [PageTransitionsBuilder] rotating pushed and popped [PageRoute]s
/// around their shared vertical seam like adjacent faces of a Rubik's cube.
class RubikCubePageTransitionsBuilder extends PageTransitionsBuilder {
  const RubikCubePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return child;
        }
        const maxAngle = math.pi / 2;

        return AnimatedBuilder(
          animation: Listenable.merge([animation, secondaryAnimation]),
          child: child,
          builder: (context, animatedChild) {
            final isExitingForward = secondaryAnimation.value > 0.0;
            final isEntering = animation.value < 1.0;
            final isAnimating = isExitingForward || isEntering;
            if (!isAnimating) {
              return animatedChild!;
            }

            var offsetX = 0.0;
            var alignment = Alignment.centerLeft;
            var angleY = 0.0;
            var shadeAlpha = 0.0;

            if (isExitingForward) {
              final s =
                  Curves.easeInOutCubic.transform(secondaryAnimation.value);
              offsetX = -width * s;
              alignment = Alignment.centerRight;
              angleY = maxAngle * s;
              shadeAlpha = 0.22 * s;
            } else if (isEntering) {
              final t = Curves.easeInOutCubic.transform(animation.value);
              offsetX = width * (1.0 - t);
              alignment = Alignment.centerLeft;
              angleY = -maxAngle * (1.0 - t);
              shadeAlpha = 0.22 * (1.0 - t);
            }

            return ClipRect(
              clipBehavior: Clip.hardEdge,
              child: _RubikCubeFace(
                offsetX: offsetX,
                alignment: alignment,
                angleY: angleY,
                shadeAlpha: shadeAlpha,
                blockTouches: isAnimating,
                child: animatedChild!,
              ),
            );
          },
        );
      },
    );
  }
}

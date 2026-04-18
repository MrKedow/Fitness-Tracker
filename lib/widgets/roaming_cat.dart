import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RoamingCat extends StatefulWidget {
  final double maxWidth;
  final double maxHeight;
  final String githubUrl;
  final double catSize;

  const RoamingCat({
    super.key,
    required this.maxWidth,
    required this.maxHeight,
    required this.githubUrl,
    this.catSize = 50.0,
  });

  @override
  State<RoamingCat> createState() => _RoamingCatState();
}

class _RoamingCatState extends State<RoamingCat> with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  Timer? _moveTimer;
  bool _isHovering = false;
  bool _isMoving = true;
  double _scrollWidth = 0.0;
  bool _isFacingRight = true;

  static const double _stepMax = 120.0;
  static const Duration _minInterval = Duration(seconds: 1);
  static const Duration _maxInterval = Duration(seconds: 3);
  static const double _minRightMargin = 60.0;

  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    final maxX = (widget.maxWidth - widget.catSize).clamp(0.0, double.infinity);
    final maxY = (widget.maxHeight - widget.catSize).clamp(0.0, double.infinity);
    _position = Offset(
      _randomDouble(0, maxX),
      _randomDouble(0, maxY),
    );
    _startRoaming();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _calculateTextWidth();
  }

  void _startRoaming() {
    _moveTimer?.cancel();
    if (_isMoving) _scheduleNextMove();
  }

  void _scheduleNextMove() {
    final interval = _minInterval +
        Duration(milliseconds: _randomInt(0, _maxInterval.inMilliseconds - _minInterval.inMilliseconds));
    _moveTimer = Timer(interval, _moveRandomly);
  }

  void _moveRandomly() {
    if (!mounted || !_isMoving) return;
    final dx = _position.dx + _randomStep();
    final dy = _position.dy + _randomStep();
    final maxX = (widget.maxWidth - widget.catSize).clamp(0.0, double.infinity);
    final maxY = (widget.maxHeight - widget.catSize).clamp(0.0, double.infinity);
    final newDx = dx.clamp(0.0, maxX);
    final newDy = dy.clamp(0.0, maxY);

    final deltaX = newDx - _position.dx;
    if (deltaX != 0) {
      _isFacingRight = deltaX > 0;
    }

    setState(() {
      _position = Offset(newDx, newDy);
    });
    _scheduleNextMove();
  }

  double _randomStep() => _randomDouble(-_stepMax, _stepMax);
  
  double _randomDouble(double min, double max) {
    if (max - min <= 0.0) return min;
    final random = Random();
    return min + random.nextDouble() * (max - min);
  }
  
  int _randomInt(int min, int max) {
    if (max - min <= 0) return min;
    final random = Random();
    return min + random.nextInt(max - min);
  }

  void _setHovering(bool hovering) {
    if (_isHovering == hovering) return;
    setState(() {
      _isHovering = hovering;
      _isMoving = !hovering;
      if (hovering) {
        _scrollController.forward();
        _startRoaming();
      } else {
        _scrollController.reverse();
        _startRoaming();
      }
    });
  }

  void _calculateTextWidth() {
    const textStyle = TextStyle(fontSize: 12);
    final textPainter = TextPainter(
      text: TextSpan(text: widget.githubUrl, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _scrollWidth = textPainter.width + 24 + 16;
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateScrollLeft(double animatedWidth) {
    final catLeft = _position.dx;
    final catRight = _position.dx + widget.catSize;
    double left = catLeft;
    final maxRight = widget.maxWidth - _minRightMargin;
    final scrollRight = left + animatedWidth;
    if (scrollRight > maxRight) {
      left = catRight - animatedWidth;
      if (left < 0) left = 0;
    }
    if (left < 0) left = 0;
    if (left + animatedWidth > maxRight) left = maxRight - animatedWidth;
    if (left < 0) left = 0;
    return left;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.maxWidth,
      height: widget.maxHeight,
      child: MouseRegion(
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final animatedWidth = _scrollWidth * _scrollController.value;
                if (animatedWidth <= 0) return const SizedBox.shrink();
                final scrollLeft = _calculateScrollLeft(animatedWidth);
                return Positioned(
                  left: scrollLeft,
                  top: 0,
                  bottom: 0,
                  width: animatedWidth,
                  child: ClipRect(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF5E6).withValues(alpha: 0.98),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(2, 2)),
                        ],
                        border: Border.all(color: Colors.brown.shade400, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade800,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async => await launchUrl(Uri.parse(widget.githubUrl)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Center(
                                  child: Text(
                                    widget.githubUrl,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade800,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(_isFacingRight ? 1.0 : -1.0, 1.0, 1.0),
                child: SizedBox(
                  width: widget.catSize,
                  height: widget.catSize,
                  child: Image.asset(
                    'assets/吉祥物奔奔猫.gif',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text('🐱', style: TextStyle(fontSize: 30)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DraggableCat extends StatefulWidget {
  final double catSize;
  final String githubUrl;
  final Size parentSize; // 父容器尺寸，用于边界限制

  const DraggableCat({
    super.key,
    required this.catSize,
    required this.githubUrl,
    required this.parentSize,
  });

  @override
  State<DraggableCat> createState() => _DraggableCatState();
}

class _DraggableCatState extends State<DraggableCat>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isHovering = false;
  double _scrollWidth = 0.0;
  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _calculateTextWidth();
    // 初始位置右下角
    _position = Offset(
      widget.parentSize.width - widget.catSize - 20,
      widget.parentSize.height - widget.catSize - 20,
    );
  }

  @override
  void didUpdateWidget(DraggableCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果父容器尺寸变化，重新调整位置确保在边界内
    if (widget.parentSize != oldWidget.parentSize) {
      _updatePosition(_position);
    }
  }

  void _calculateTextWidth() {
    const textStyle = TextStyle(fontSize: 12);
    final textPainter = TextPainter(
      text: TextSpan(text: widget.githubUrl, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _scrollWidth = textPainter.width + 24 + 16 + 20;
  }

  void _setHovering(bool hovering) {
    if (_isHovering == hovering) return;
    setState(() {
      _isHovering = hovering;
      if (hovering) {
        _scrollController.forward();
      } else {
        _scrollController.reverse();
      }
    });
  }

  void _updatePosition(Offset newPosition) {
    final width = widget.parentSize.width;
    final height = widget.parentSize.height;
    double newX = newPosition.dx.clamp(0.0, width - widget.catSize);
    double newY = newPosition.dy.clamp(0.0, height - widget.catSize);
    if (_position.dx != newX || _position.dy != newY) {
      setState(() {
        _position = Offset(newX, newY);
      });
    }
  }

  double _calculateScrollLeft() {
    double catLeft = _position.dx;
    double catRight = _position.dx + widget.catSize;
    double left = catLeft;
    double maxRight = widget.parentSize.width - 10;
    double scrollRight = left + _scrollWidth;
    if (scrollRight > maxRight) {
      left = catRight - _scrollWidth;
      if (left < 0) left = 0;
    }
    if (left < 0) left = 0;
    if (left + _scrollWidth > maxRight) left = maxRight - _scrollWidth;
    if (left < 0) left = 0;
    return left;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: GestureDetector(
          onPanUpdate: (details) {
            final newPosition = _position + details.delta;
            _updatePosition(newPosition);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: widget.catSize,
                height: widget.catSize,
                child: Image.asset(
                  'assets/吉祥物奔奔猫.gif',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('🐱', style: TextStyle(fontSize: 50)),
                ),
              ),
              if (_isHovering)
                Positioned(
                  left: _calculateScrollLeft() - _position.dx,
                  top: -10,
                  child: AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      final animatedWidth = _scrollWidth * _scrollController.value;
                      if (animatedWidth <= 0) return const SizedBox.shrink();
                      return Container(
                        width: animatedWidth,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF5E6).withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(2, 2),
                            ),
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
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
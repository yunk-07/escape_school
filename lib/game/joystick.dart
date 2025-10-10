import 'package:flutter/material.dart';
import 'dart:math';

class JoystickController extends StatefulWidget {
  final Function(double dx, double dy, double intensity) onMove;
  final Function() onStop;
  final double size;
  final Color baseColor;
  final Color knobColor;

  const JoystickController({
    Key? key,
    required this.onMove,
    required this.onStop,
    this.size = 120.0,
    this.baseColor = const Color(0x88FFFFFF),
    this.knobColor = const Color(0xFFFFFFFF),
  }) : super(key: key);

  @override
  _JoystickControllerState createState() => _JoystickControllerState();
}

class _JoystickControllerState extends State<JoystickController> {
  double _knobX = 0.0;
  double _knobY = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: JoystickPainter(
            knobX: _knobX,
            knobY: _knobY,
            baseColor: widget.baseColor,
            knobColor: widget.knobColor,
            size: widget.size,
          ),
          size: Size(widget.size, widget.size),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = widget.size / 2;
    final maxRadius = center * 0.8; // 80% of radius for movement area
    
    // Calculate relative position from center
    final dx = details.localPosition.dx - center;
    final dy = details.localPosition.dy - center;
    
    // Calculate distance from center
    final distance = sqrt(dx * dx + dy * dy);
    
    if (distance <= maxRadius) {
      // Within bounds, use actual position
      _knobX = dx;
      _knobY = dy;
    } else {
      // Outside bounds, clamp to edge
      final angle = atan2(dy, dx);
      _knobX = cos(angle) * maxRadius;
      _knobY = sin(angle) * maxRadius;
    }
    
    // Calculate movement intensity (0.0 to 1.0)
    final intensity = min(distance / maxRadius, 1.0);
    
    // Normalize direction (-1.0 to 1.0)
    final normalizedX = _knobX / maxRadius;
    final normalizedY = _knobY / maxRadius;
    
    setState(() {});
    
    // Call movement callback
    widget.onMove(normalizedX, normalizedY, intensity);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _knobX = 0.0;
      _knobY = 0.0;
      _isDragging = false;
    });
    
    widget.onStop();
  }
}

class JoystickPainter extends CustomPainter {
  final double knobX;
  final double knobY;
  final Color baseColor;
  final Color knobColor;
  final double size;

  JoystickPainter({
    required this.knobX,
    required this.knobY,
    required this.baseColor,
    required this.knobColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;
    final knobRadius = baseRadius * 0.3;
    
    // Draw base circle
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, baseRadius, basePaint);
    
    // Draw base border
    final borderPaint = Paint()
      ..color = knobColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, baseRadius, borderPaint);
    
    // Draw movement area indicator
    final movementAreaPaint = Paint()
      ..color = knobColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, baseRadius * 0.8, movementAreaPaint);
    
    // Draw knob
    final knobCenter = Offset(
      center.dx + knobX,
      center.dy + knobY,
    );
    
    final knobPaint = Paint()
      ..color = knobColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);
    
    // Draw knob border
    final knobBorderPaint = Paint()
      ..color = knobColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(knobCenter, knobRadius, knobBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
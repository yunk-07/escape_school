import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui; // 关键区域：用于径向渐变与阴影绘制（提升立体感）

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
    // 关键区域：整体半透明处理（使用 baseColor 的透明度作为统一 alpha）
    // 为摇杆所有绘制内容加一层统一透明度，避免逐个元素修改。
    final Rect layerBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final double layerOpacity = baseColor.opacity; // 复用传入的 baseColor 的透明度
    canvas.saveLayer(layerBounds, Paint()..color = Colors.white.withOpacity(layerOpacity));

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;
    final knobRadius = baseRadius * 0.3;
    
    // 关键区域：底座立体感（收敛强度）- 更轻的径向渐变 + 低强度阴影
    final basePath = Path()..addOval(Rect.fromCircle(center: center, radius: baseRadius));
    canvas.drawShadow(basePath, Colors.black.withOpacity(0.25), 6.0, true);

    // 底座径向渐变（白灰色层次）
    final baseGradient = ui.Gradient.radial(
      center,
      baseRadius,
      [
        Colors.grey.shade100,
        Colors.grey.shade300,
        Colors.grey.shade400,
      ],
      [0.0, 0.7, 1.0],
    );
    final basePaint = Paint()
      ..shader = baseGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius, basePaint);

    // 底座外圈高光与暗部（模拟光照方向：左上高光，右下暗部）
    final ringRect = Rect.fromCircle(center: center, radius: baseRadius * 0.96);
    final ringHighlight = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final ringShadow = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    // 高光弧：顶部左侧（更短更细）
    canvas.drawArc(ringRect, pi * 0.75, pi * 0.4, false, ringHighlight);
    // 暗部弧：底部右侧（更短更细）
    canvas.drawArc(ringRect, pi * 1.65, pi * 0.35, false, ringShadow);

    // 移动区域指示圈（浅白灰）
    final movementAreaPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, baseRadius * 0.8, movementAreaPaint);
    
    // Draw knob
    final knobCenter = Offset(
      center.dx + knobX,
      center.dy + knobY,
    );
    
    // 关键区域：摇杆头立体感（收敛） - 更低对比的渐变 + 轻阴影
    final knobPath = Path()..addOval(Rect.fromCircle(center: knobCenter, radius: knobRadius));
    canvas.drawShadow(knobPath, Colors.black.withOpacity(0.25), 4.0, true);

    // 摇杆头径向渐变（白灰层次）
    final knobGradient = ui.Gradient.radial(
      knobCenter,
      knobRadius,
      [
        Colors.grey.shade200,
        Colors.grey.shade300,
        Colors.grey.shade500,
      ],
      [0.0, 0.6, 1.0],
    );
    final knobPaint = Paint()
      ..shader = knobGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);

    // 摇杆头边缘微高光与暗部（方向与底座一致）
    final knobRingRect = Rect.fromCircle(center: knobCenter, radius: knobRadius * 0.98);
    final knobRingHighlight = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final knobRingShadow = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(knobRingRect, pi * 0.75, pi * 0.4, false, knobRingHighlight);
    canvas.drawArc(knobRingRect, pi * 1.65, pi * 0.35, false, knobRingShadow);

    // 摇杆头高光点（左上角的镜面反射效果）
    final highlightCenter = Offset(
      knobCenter.dx - knobRadius * 0.35,
      knobCenter.dy - knobRadius * 0.35,
    );
    final highlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        highlightCenter,
        knobRadius * 0.2,
        [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.0)],
        [0.0, 1.0],
      );
    canvas.drawCircle(highlightCenter, knobRadius * 0.14, highlightPaint);

    // 结束半透明合成层
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
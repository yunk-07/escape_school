import 'package:flutter/material.dart';
import 'dart:math';

class ShakingDialog extends StatefulWidget {
  final Widget child;
  final bool shouldShake;
  final int shakeCount;

  const ShakingDialog({
    super.key,
    required this.child,
    required this.shouldShake,
    required this.shakeCount,
  });

  @override
  State<ShakingDialog> createState() => _ShakingDialogState();
}

class _ShakingDialogState extends State<ShakingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        // 关键修改：确保所有数值都是double类型
        final intensity = pow(widget.shakeCount, 1.5).toDouble();
        final baseOffset = _random.nextDouble() * 20 - 10;

        final offsetX = widget.shouldShake ? baseOffset * intensity : 0.0;
        final offsetY = widget.shouldShake ? baseOffset * intensity : 0.0;

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: widget.child,
        );
      },
    );
  }
}

class FloatingTextBackground extends StatefulWidget {
  final Widget child;

  const FloatingTextBackground({super.key, required this.child});

  @override
  State<FloatingTextBackground> createState() => _FloatingTextBackgroundState();
}

class _FloatingTextBackgroundState extends State<FloatingTextBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FloatingText> _floatingTexts = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _generateFloatingTexts();
  }

  void _generateFloatingTexts() {
    final random = Random();
    const texts = ["逃", "离", "学", "校", "抓", "回", "来", "！"];
    for (int i = 0; i < 20; i++) {
      _floatingTexts.add(FloatingText(
        text: texts[random.nextInt(texts.length)],
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 0.7,
        angle: random.nextDouble() * 2 * pi,
        size: 16 + random.nextDouble() * 20,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand, // 全屏显示
        children: [
          // 纯黑背景
          Container(color: Colors.black),
          // 漂浮文字
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              _updateTextPositions();
              return Stack(
                children: _floatingTexts.map((text) => _buildTextWidget(text)).toList(),
              );
            },
          ),
          // 弹窗内容
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextWidget(FloatingText text) {
    return Positioned(
      left: text.x * MediaQuery.of(context).size.width,
      top: text.y * MediaQuery.of(context).size.height,
      child: Transform.rotate(
        angle: text.angle,
        child: Text(
          text.text,
          style: TextStyle(
            color: Colors.red.withOpacity(0.7),
            fontSize: text.size,
            fontFamily: 'MicC',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _updateTextPositions() {
    for (var text in _floatingTexts) {
      text.x += cos(text.angle) * 0.002 * text.speed;
      text.y += sin(text.angle) * 0.002 * text.speed;
      // 边界反弹
      if (text.x < 0 || text.x > 0.95) text.angle = pi - text.angle;
      if (text.y < 0 || text.y > 0.95) text.angle = -text.angle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class FloatingText {
  String text;
  double x, y;
  double speed;
  double angle;
  double size;

  FloatingText({
    required this.text,
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
    required this.size,
  });
}


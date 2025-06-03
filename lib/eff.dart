import 'package:flutter/material.dart';
import 'dart:math' as math; // 导入math库并指定别名

class ParticleEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  final Size containerSize;
  final Color particleColor;
  final double minSize;
  final double maxSize;
  final double blurIntensity;
  final int particleCount;

  const ParticleEffect({
    super.key,
    required this.position,
    required this.onComplete,
    required this.containerSize,
    this.particleColor = Colors.amber,
    this.minSize = 4.0,
    this.maxSize = 10.0,
    this.blurIntensity = 0.5,
    this.particleCount = 25,
  });

  @override
  _ParticleEffectState createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    })
      ..addListener(_updateParticles);

    _initParticles();
    _controller.forward();
  }

  void _initParticles() {
    final complementaryColor = HSLColor.fromColor(widget.particleColor)
        .withHue((HSLColor.fromColor(widget.particleColor).hue + 180) % 360)
        .toColor();

    particles = List.generate(widget.particleCount, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 0.5 + _random.nextDouble() * 1.5;
      final sizeVariation = widget.minSize +
          _random.nextDouble() * (widget.maxSize - widget.minSize);

      return Particle(
        position: widget.position,
        velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
        color: _random.nextDouble() > 0.7
            ? complementaryColor
            : widget.particleColor.withOpacity(0.7 + _random.nextDouble() * 0.3),
        size: sizeVariation,
        life: 0.4 + _random.nextDouble() * 0.8,
      );
    });
  }

  void _updateParticles() {
    setState(() {
      particles.removeWhere((particle) => particle.age >= particle.life);
      for (var particle in particles) {
        particle.position += particle.velocity * 5;
        particle.age += _controller.lastElapsedDuration!.inMilliseconds / 1000;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final blurRadius = widget.blurIntensity * 10;

    return SizedBox(
      width: widget.containerSize.width,
      height: widget.containerSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: particles.map((particle) {
          final progress = particle.age / particle.life;
          // 修复1: 使用math.pow()函数代替progress.pow()
          final opacity = (1 - math.pow(progress, 1.5)).toDouble().clamp(0.0, 1.0);

          return Positioned(
            left: particle.position.dx - particle.size / 2,
            top: particle.position.dy - particle.size / 2,
            child: Opacity(
              // 修复2: 确保传递的是double类型
              opacity: opacity,
              child: Transform.scale(
                scale: 1 + progress * 3,
                child: Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    color: particle.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: particle.color.withOpacity(opacity * 0.7),
                        blurRadius: blurRadius,
                        spreadRadius: blurRadius / 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;
  double age = 0;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  });
}
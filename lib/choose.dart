
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'data/manData.dart';
import 'eff.dart';
import 'game/board.dart';

class ChooseCharacterPage extends StatefulWidget {
  const ChooseCharacterPage({super.key});

  @override
  State<ChooseCharacterPage> createState() => _ChooseCharacterPageState();
}

class _ChooseCharacterPageState extends State<ChooseCharacterPage> {

  @override
  Widget build(BuildContext context) {
    GlobalState.enableAllCards();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/background_1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),


          Center(
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: manData.length,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 60),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TiltCard(character: manData[index]),
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class GlobalState {
  static bool _cardsDisabled = false;

  static bool get cardsDisabled => _cardsDisabled;

  static void disableAllCards() {
    _cardsDisabled = true;
  }

  static void enableAllCards() {
    _cardsDisabled = false;
  }
}

class TiltCard extends StatefulWidget {
  final Map<String, dynamic> character;

  const TiltCard({super.key, required this.character});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  // late AnimationController _floatController;
  // late Animation<Offset> _floatAnimation;
  Alignment _dragAlignment = Alignment.center;
  bool _isPressed = false;
  bool _isHovering = false;
  bool _isAnimating = false; // 新增动画状态标志
  Offset? _tapPosition;

  final SpringDescription _spring = SpringDescription(
    mass: 10,
    stiffness: 1000,
    damping: 0.5,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _dragAlignment = _animation.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Matrix4 _getTransform(Alignment alignment) {
    final x = alignment.x;
    final y = alignment.y;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(y * 0.1)
      ..rotateY(-x * 0.2);
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isAnimating) {
      setState(() {
        _isPressed = true;
        _tapPosition = details.localPosition;
      });
    }
  }

  // 保留原有的_onPanDown方法
  void _onPanDown(DragDownDetails details) {
    if (!_isAnimating) {
      setState(() {
        _isPressed = true;
        _tapPosition = details.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isAnimating) { // 只在非动画状态下响应
      setState(() {
        _tapPosition = details.localPosition;
        final x = (_tapPosition!.dx - 125) / 125;
        final y = (_tapPosition!.dy - 200) / 200;
        _dragAlignment = Alignment(
            x.clamp(-1.0, 1.0),
            y.clamp(-1.0, 1.0)
        );
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isAnimating) { // 只在非动画状态下响应
      setState(() => _isPressed = false);
      _animateBackToCenter();
    }
  }

  void _handleTap() {
    if (GlobalState.cardsDisabled) return;

    GlobalState.disableAllCards(); // 禁用所有卡片

    setState(() {
      _isAnimating = true;
      _isPressed = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  void _onParticleComplete() {
    if (mounted) {
      setState(() => _isAnimating = false); // 动画结束
      _navigateToMap();
    }
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardPage(character: widget.character),
      ),
    );
  }

  void _animateBackToCenter() {
    _animation = _controller.drive(
      AlignmentTween(begin: _dragAlignment, end: Alignment.center),
    );
    final simulation = SpringSimulation(
        _spring, _dragAlignment.x, 0, _dragAlignment.y);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = Size(200, 350);

    return AbsorbPointer(
      absorbing: GlobalState.cardsDisabled && !_isAnimating,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MouseRegion(
            onEnter: (_) => !_isAnimating ? setState(() => _isHovering = true) : null,
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTapDown: _onTapDown,  // 修复2: 使用正确的处理方法
              onTap: _handleTap,
              onPanDown: _onPanDown,  // 保留原有的pan处理方法
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: () => setState(() => _isPressed = false),
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : _isHovering ? 1.03 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Transform(
                  transform: _getTransform(_dragAlignment),
                  alignment: FractionalOffset.center,
                  child: Container(
                    width: cardSize.width,
                    height: cardSize.height,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _isHovering ? Colors.orange : Colors.red,
                          width: _isHovering ? 3 : 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isHovering ? 0.6 : 0.4),
                          blurRadius: _isHovering ? 30 : 20,
                          spreadRadius: _isHovering ? 10 : 5,
                          offset: Offset(
                              _dragAlignment.x * (_isHovering ? 15 : 10),
                              _dragAlignment.y * (_isHovering ? 15 : 10)),
                        )],
                    ),
                    child:Column(
                      children: [
                        // 顶部图片区域
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                widget.character['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        // 底部信息区域
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 角色名称
                                Text(
                                  widget.character['name'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'MicC',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // 角色描述
                                Text(
                                  widget.character['description'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'MicC',
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const Spacer(),

                                // 属性信息
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatItem('金币', widget.character['gold']),
                                    _buildStatItem('生命', widget.character['hp']),
                                    _buildStatItem('精神', widget.character['san']),
                                    _buildStatItem('攻击', widget.character['att']),
                                    _buildStatItem('饱食', widget.character['food']),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isAnimating && _tapPosition != null)
            Positioned(
              left: 0,
              top: 0,
              width: cardSize.width,
              height: cardSize.height,
              child: ParticleEffect(
                position: _tapPosition!,
                onComplete: _onParticleComplete,
                containerSize: cardSize,
                particleColor: Colors.white,
                minSize: 1.0,
                maxSize: 3.0,
                blurIntensity: 1,
                particleCount: 10,
              )
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'MicC',
            color: Colors.white70,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'MicC',
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

}
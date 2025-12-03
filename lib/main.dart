import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'choose.dart';
import 'package:escape_from_school/game/music.dart';
import 'eff02.dart';
import 'package:escape_from_school/game/catalog_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MusicManager().initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _buttonController;
  late AnimationController _backgroundController;

  // 独立按钮状态
  bool _isStartButtonHovered = false;
  bool _isStartButtonPressed = false;
  bool _isCatalogButtonHovered = false;
  bool _isCatalogButtonPressed = false;

  // 独立按钮动画控制器
  late AnimationController _startButtonHoverController;
  late AnimationController _startButtonPressController;
  late AnimationController _catalogButtonHoverController;
  late AnimationController _catalogButtonPressController;

  final List<Animation<Offset>> _letterSlideAnimations = [];
  final List<Animation<double>> _letterFadeAnimations = [];
  final List<Animation<double>> _letterScaleAnimations = [];

  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _buttonSlideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;

  // 独立按钮动画
  late Animation<double> _startButtonHoverAnimation;
  late Animation<double> _startButtonPressAnimation;
  late Animation<double> _catalogButtonHoverAnimation;
  late Animation<double> _catalogButtonPressAnimation;

  final String title = "逃离学校";

  @override
  void initState() {
    super.initState();

    // 主动画控制器 - 控制标题动画
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 按钮动画控制器
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 背景动画控制器
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 独立按钮动画控制器
    _startButtonHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startButtonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _catalogButtonHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _catalogButtonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // 背景淡入动画
    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // 为每个字母创建多重动画效果
    for (int i = 0; i < title.length; i++) {
      final startTime = i * 0.08; // 更短的间隔，更流畅
      final endTime = (startTime + 0.4).clamp(0.0, 1.0);

      // 滑动动画 - 从不同角度进入
      final slideAnimation = Tween<Offset>(
        begin: Offset(
          (i % 2 == 0 ? -1.5 : 1.5) + (i * 0.1), // 交替从左右进入
          -0.8 - (i * 0.1), // 从上方不同高度进入
        ),
        end: const Offset(0, 0),
      ).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeOutBack),
        ),
      );
      _letterSlideAnimations.add(slideAnimation);

      // 淡入动画
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeInOut),
        ),
      );
      _letterFadeAnimations.add(fadeAnimation);

      // 缩放动画 - 添加弹性效果
      final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.elasticOut),
        ),
      );
      _letterScaleAnimations.add(scaleAnimation);
    }

    // 按钮动画
    _buttonSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // 开始按钮独立动画
    _startButtonHoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _startButtonHoverController,
        curve: Curves.easeInOut,
      ),
    );

    _startButtonPressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _startButtonPressController,
        curve: Curves.easeInOut,
      ),
    );

    // 图鉴按钮独立动画
    _catalogButtonHoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _catalogButtonHoverController,
        curve: Curves.easeInOut,
      ),
    );

    _catalogButtonPressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _catalogButtonPressController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // 启动背景动画
    _backgroundController.forward();

    // 延迟启动主动画
    await Future.delayed(const Duration(milliseconds: 300));
    _mainController.forward();

    // 在标题动画进行到一半时启动按钮动画
    await Future.delayed(const Duration(milliseconds: 1200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    _startButtonHoverController.dispose();
    _startButtonPressController.dispose();
    _catalogButtonHoverController.dispose();
    _catalogButtonPressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景层
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background_1.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: FloatingTextBackground(child: Container()),
          ),

          // 渐变遮罩层，增强可读性
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 主要内容
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: isLandscape ? 800 : double.infinity,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.1,
                            vertical: 40,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: screenSize.height * 0.05),

                              // 标题动画
                              AnimatedBuilder(
                                animation: _mainController,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(title.length, (
                                        index,
                                      ) {
                                        return SlideTransition(
                                          position:
                                              _letterSlideAnimations[index],
                                          child: FadeTransition(
                                            opacity:
                                                _letterFadeAnimations[index],
                                            child: ScaleTransition(
                                              scale:
                                                  _letterScaleAnimations[index],
                                              child: Text(
                                                title[index],
                                                style: TextStyle(
                                                  fontSize:
                                                      isLandscape ? 70 : 80,
                                                  color: Colors.red,
                                                  shadows: const [
                                                    Shadow(
                                                      blurRadius: 15,
                                                      color: Colors.black,
                                                      offset: Offset(3, 3),
                                                    ),
                                                    Shadow(
                                                      blurRadius: 30,
                                                      color: Colors.red,
                                                      offset: Offset(0, 0),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: screenSize.height * 0.03),
                              SizedBox(height: screenSize.height * 0.05),

                              // 开始按钮
                              AnimatedBuilder(
                                animation: _buttonController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      _buttonSlideAnimation.value,
                                    ),
                                    child: Transform.scale(
                                      scale: _buttonScaleAnimation.value,
                                      // Impeller 修复：避免使用 Opacity 包裹（按钮包含渐变与阴影），
                                      // 采用叠加遮罩实现淡入，规避继承透明度传播导致的报错。
                                      child: Stack(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _buildStartButton(isLandscape),
                                              const SizedBox(width: 16),
                                              _buildCatalogButton(isLandscape),
                                            ],
                                          ),
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  // 与按钮圆角保持一致，避免遮罩外溢
                                                  // 关键区域：开始页面圆角统一为 5（遮罩层）
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha:
                                                            1.0 -
                                                            _buttonFadeAnimation
                                                                .value,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(bool isLandscape) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isStartButtonHovered = true);
        _startButtonHoverController.forward();
      },
      onExit: (_) {
        setState(() => _isStartButtonHovered = false);
        _startButtonHoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isStartButtonPressed = true);
          _startButtonPressController.forward();
        },
        onTapUp: (_) {
          setState(() => _isStartButtonPressed = false);
          _startButtonPressController.reverse();
        },
        onTapCancel: () {
          setState(() => _isStartButtonPressed = false);
          _startButtonPressController.reverse();
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChooseCharacterPage(),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _startButtonHoverController,
            _startButtonPressController,
          ]),
          builder: (context, child) {
            final hoverValue = _startButtonHoverAnimation.value;
            final pressValue = _startButtonPressAnimation.value;
            final combinedValue = hoverValue + pressValue * 0.3;

            return Container(
              width: isLandscape ? 200 : 240,
              height: isLandscape ? 60 : 70,
              transform:
                  Matrix4.identity()
                    ..scale(1.0 + hoverValue * 0.05 - pressValue * 0.03)
                    ..translate(0.0, hoverValue * -2.0 - pressValue * 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFFFF4444),
                      const Color(0xFFFF5555),
                      hoverValue,
                    )!,
                    Color.lerp(
                      const Color(0xFFCC0000),
                      const Color(0xFFDD0000),
                      hoverValue,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.6 + hoverValue * 0.2,
                    ),
                    offset: Offset(0, 8 + hoverValue * 4),
                    blurRadius: 20 + hoverValue * 5,
                    spreadRadius: 2 + hoverValue * 1,
                  ),
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4 + hoverValue * 0.2),
                    offset: const Offset(0, 0),
                    blurRadius: 15 + hoverValue * 5,
                    spreadRadius: 1 + hoverValue * 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 按钮顶部高光效果
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(
                              alpha: 0.3 + hoverValue * 0.1,
                            ),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),

                  // 悬停时的光晕效果
                  if (hoverValue > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1 * hoverValue),
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.05 * hoverValue),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 点击波纹效果
                  if (pressValue > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.5 + pressValue * 0.5,
                            colors: [
                              Colors.white.withValues(alpha: 0.3 * pressValue),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 按钮文字
                  Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize:
                            isLandscape
                                ? 28 + hoverValue * 2
                                : 32 + hoverValue * 2,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8 + hoverValue * 2,
                            color: Colors.black,
                            offset: const Offset(2, 2),
                          ),
                          if (hoverValue > 0)
                            Shadow(
                              blurRadius: 15 * hoverValue,
                              color: Colors.red,
                              offset: const Offset(0, 0),
                            ),
                        ],
                      ),
                      child: Transform.translate(
                        offset: Offset(0, pressValue * 1.0),
                        child: const Text('开始游戏'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCatalogButton(bool isLandscape) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isCatalogButtonHovered = true);
        _catalogButtonHoverController.forward();
      },
      onExit: (_) {
        setState(() => _isCatalogButtonHovered = false);
        _catalogButtonHoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isCatalogButtonPressed = true);
          _catalogButtonPressController.forward();
        },
        onTapUp: (_) {
          setState(() => _isCatalogButtonPressed = false);
          _catalogButtonPressController.reverse();
        },
        onTapCancel: () {
          setState(() => _isCatalogButtonPressed = false);
          _catalogButtonPressController.reverse();
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CatalogPage()),
          );
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _catalogButtonHoverController,
            _catalogButtonPressController,
          ]),
          builder: (context, child) {
            final hoverValue = _catalogButtonHoverAnimation.value;
            final pressValue = _catalogButtonPressAnimation.value;

            return Container(
              width: isLandscape ? 200 : 240,
              height: isLandscape ? 60 : 70,
              transform:
                  Matrix4.identity()
                    ..scale(1.0 + hoverValue * 0.05 - pressValue * 0.03)
                    ..translate(0.0, hoverValue * -2.0 - pressValue * 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF4499FF),
                      const Color(0xFF55AAFF),
                      hoverValue,
                    )!,
                    Color.lerp(
                      const Color(0xFF0044CC),
                      const Color(0xFF0055DD),
                      hoverValue,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.6 + hoverValue * 0.2,
                    ),
                    offset: Offset(0, 8 + hoverValue * 4),
                    blurRadius: 20 + hoverValue * 5,
                    spreadRadius: 2 + hoverValue * 1,
                  ),
                  BoxShadow(
                    color: Colors.blue.withValues(
                      alpha: 0.4 + hoverValue * 0.2,
                    ),
                    offset: const Offset(0, 0),
                    blurRadius: 15 + hoverValue * 5,
                    spreadRadius: 1 + hoverValue * 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 按钮顶部高光效果
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(
                              alpha: 0.3 + hoverValue * 0.1,
                            ),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),

                  // 悬停时的光晕效果
                  if (hoverValue > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1 * hoverValue),
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.05 * hoverValue),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 点击波纹效果
                  if (pressValue > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.5 + pressValue * 0.5,
                            colors: [
                              Colors.white.withValues(alpha: 0.3 * pressValue),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 按钮文字
                  Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize:
                            isLandscape
                                ? 28 + hoverValue * 2
                                : 32 + hoverValue * 2,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8 + hoverValue * 2,
                            color: Colors.black,
                            offset: const Offset(2, 2),
                          ),
                          if (hoverValue > 0)
                            Shadow(
                              blurRadius: 15 * hoverValue,
                              color: Colors.blue,
                              offset: const Offset(0, 0),
                            ),
                        ],
                      ),
                      child: Transform.translate(
                        offset: Offset(0, pressValue * 1.0),
                        child: const Text('图鉴'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

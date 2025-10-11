import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'choose.dart';
import 'eff02.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<Offset>> _letterAnimations = [];
  final String title = "逃离学校";
  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 为每个字母创建不同的动画
    for (int i = 0; i < title.length; i++) {
      final animation = Tween<Offset>(
        begin: Offset(i * 0.1 - 0.5, -1.0), // 从上方不同位置开始
        end: const Offset(0, 0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.05, 1.0, curve: Curves.elasticOut), // 交错动画时间
        ),
      );
      _letterAnimations.add(animation);
    }

    _controller.forward().then((_) {
      setState(() {
        _showButton = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
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
                                animation: _controller,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(title.length, (index) {
                                        return SlideTransition(
                                          position: _letterAnimations[index],
                                          child: Text(
                                            title[index],
                                            style: TextStyle(
                                              fontSize: isLandscape ? 70 : 80,
                                              fontFamily: 'MicC',
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
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                              
                              SizedBox(height: screenSize.height * 0.03),
                              SizedBox(height: screenSize.height * 0.05),

                              // 开始按钮
                              if (_showButton)
                                _buildStartButton(isLandscape),
                              
                              
                            
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChooseCharacterPage()),
        );
      },
      child: Container(
        width: isLandscape ? 200 : 240,
        height: isLandscape ? 60 : 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF4444),
              Color(0xFFCC0000),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              offset: const Offset(0, 8),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              offset: const Offset(0, 0),
              blurRadius: 15,
              spreadRadius: 1,
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
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
              ),
            ),
            
            // 按钮文字
            Center(
              child: Text(
                '开始做人',
                style: TextStyle(
                  fontSize: isLandscape ? 28 : 32,
                  fontFamily: 'MicC',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        duration: 300.ms,
        curve: Curves.elasticOut,
      ).fadeIn(duration: 300.ms),
    );
  }
}
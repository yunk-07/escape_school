import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'choose.dart';
import 'eff02.dart';

void main() {
  runApp(const MyApp());
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background_1.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: FloatingTextBackground(child: Container(),),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(title.length, (index) {
                        return SlideTransition(
                          position: _letterAnimations[index],
                          child: Text(
                            title[index],
                            style: const TextStyle(
                              fontSize: 80,
                              fontFamily: 'MicC',
                              color: Colors.red,
                              shadows: [
                              Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(2, 2),)
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 40),
                if (_showButton)
                  GestureDetector(
                    onTap: () {
                      // 按钮点击事件
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  ChooseCharacterPage()),
                      );
                    },
                    child: Container(
                      width: 220,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 10),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.red,
                            offset: Offset(0, 0),
                            blurRadius: 0,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 按钮顶部高光效果
                          Positioned(
                            top: 0,
                            child: Container(
                              width: 220,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          // 按钮文字
                          const Center(
                            child: Text(
                              '开始做人',
                              style: TextStyle(
                                fontSize: 32,
                                fontFamily: 'MicC',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                Shadow(
                                blurRadius: 5,
                                color: Colors.black,
                                offset: Offset(2, 2),)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(
                      begin: Offset(1, 1),
                        end: Offset(0.9, 0.9),
                      duration: 100.ms
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
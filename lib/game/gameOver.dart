// game_over.dart
import 'package:flutter/material.dart';

class GameOverPage extends StatelessWidget {
  final String deathReason;
  final String characterImage;

  const GameOverPage({
    Key? key,
    required this.deathReason,
    required this.characterImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // 隐藏标题栏
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background_1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 角色头像
              Image.asset(
                characterImage,
                width: 100,
                height: 100,
              ),
              SizedBox(height: 10),
              // 死亡提示
              Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mic',
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // 死亡原因
              Text(
                '$deathReason',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.red,
                  fontFamily: 'MicC',
                  shadows: [
                    Shadow(
                      blurRadius: 5,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // 重开按钮
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  '重新做人',
                  style: TextStyle(fontSize: 20, color: Colors.white,
                  fontFamily: 'MicC'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
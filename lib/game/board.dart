import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mapData.dart';
import 'gameOver.dart';
import 'package:escape_from_school/data/props.dart';
import '../eff02.dart';

class BoardPage extends StatefulWidget {
  final Map<String, dynamic> character;

  const BoardPage({Key? key, required this.character}) : super(key: key);

  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late Map<String, dynamic> character;
  int playerX = 10;
  int playerY = 10;
  String explorationResult = "";
  List<List<String>> map = MapData.testMap;

  List<Point> chestPositions = [];
  List<Item> playerInventory = [];

  // 添加背包状态
  bool _showInventory = false;

  final int horizontalTiles = 13; // 横向显示7格
  final int verticalTiles = 6;   // 纵向显示7格
  int viewRadiusX = 3; // 水平视野半径 (horizontalTiles ~/ 2)
  int viewRadiusY = 3; // 垂直视野半径 (verticalTiles ~/ 2)

// 获取所有可行走的格子位置
  List<Point> _getWalkablePositions() {
    List<Point> walkable = [];
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        final terrain = map[y][x];
        if (terrain != 'wall' && terrain != 'water') {
          walkable.add(Point(x, y));
        }
      }
    }
    return walkable;
  }

  @override
  void initState() {
    super.initState();
    character = Map<String, dynamic>.from(widget.character);
    _loadCharacterData().then((_) {
      // 加载数据后设置随机出生点
      _setRandomSpawnPoint();
      // 初始化宝箱
      _initChests();
    });
  }

  // 初始化宝箱
  void _initChests() {
    final rand = Random();
    chestPositions.clear();

    // 获取所有可行走位置并排除玩家位置
    final walkable = _getWalkablePositions()
        .where((p) => !(p.x == playerX && p.y == playerY))
        .toList();

    // 随机选择10个位置
    for (int i = 0; i < min(100, walkable.length); i++) {
      final index = rand.nextInt(walkable.length);
      chestPositions.add(walkable.removeAt(index));
    }
  }

  void _setRandomSpawnPoint() {
    final rand = Random();
    int attempts = 0;
    const maxAttempts = 100;

    while (attempts < maxAttempts) {
      final x = rand.nextInt(map[0].length);
      final y = rand.nextInt(map.length);

      if (_isWalkable(x, y)) {
        setState(() {
          playerX = x;
          playerY = y;
        });
        return;
      }
      attempts++;
    }

    // 如果随机尝试失败，使用备用方案
    _setFallbackSpawnPoint();
  }

  void _setFallbackSpawnPoint() {
    // 备用方案：找到第一个可行走的点
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        if (_isWalkable(x, y)) {
          setState(() {
            playerX = x;
            playerY = y;
          });
          return;
        }
      }
    }

    // 实在找不到，使用默认值
    setState(() {
      playerX = 1;
      playerY = 1;
    });
  }

  bool _isWalkable(int x, int y) {
    // 检查边界
    if (x < 0 || x >= map[0].length || y < 0 || y >= map.length) {
      return false;
    }

    // 检查地形
    final terrain = map[y][x];
    return terrain != 'wall' && terrain != 'water';
  }

  final terrainImages = {
    'wall': 'images/map/wall.png',
    'grass': 'images/map/grass.png',
    'woods': 'images/map/woods.png',
    'water': 'images/map/water.png',
    'path': 'images/map/path.png',
    'building': 'images/map/building.png',
  };

  // 加载角色数据
  Future<void> _loadCharacterData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('saved_character');
    if (savedData != null) {
      setState(() {
        character = Map<String, dynamic>.from(jsonDecode(savedData));
      });
    }
  }

  // // 删除数据
  // static Future<void> clearCharacterData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(_characterKey);
  // }

  // 保存角色数据
  // Future<void> _saveCharacterData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('saved_character', jsonEncode(character));
  // }
  // 在_BoardPageState类中添加死亡检查方法
  void _checkDeath() {
    bool isDead = character['hp'] <= 0 ||
        character['food'] <= 0 ||
        character['san'] <= 0 ||
        character['gold'] <= -100;

    if (isDead) {
      String deathReason = '';
      if (character['hp'] <= 0) deathReason = '你在学校死了（要吃处分的）';
      else if (character['food'] <= 0) deathReason = '你在学校饿死了（肯定是吃外卖吃死的）';
      else if (character['san'] <= 0) deathReason = '你神智不清迷失了';
      else if (character['gold'] <= -100) deathReason = '你负债累累';

      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameOverPage(
              deathReason: deathReason,
              characterImage: character['image'],
            ),
          ),
        );
      });
    }
  }

  // 获取当前可见的5x5区域
  List<List<String>> get visibleMap {
    List<List<String>> visible = [];

    for (int y = playerY - viewRadiusY; y <= playerY + viewRadiusY; y++) {
      List<String> row = [];
      for (int x = playerX - viewRadiusX; x <= playerX + viewRadiusX; x++) {
        if (x >= 0 && x < map[0].length && y >= 0 && y < map.length) {
          row.add(map[y][x]);
        } else {
          row.add('wall');
        }
      }
      visible.add(row);
    }
    return visible;
  }

  void _movePlayer(int dx, int dy) {
    final newX = playerX + dx;
    final newY = playerY + dy;
    _checkDeath();

    if (newX >= 0 && newX < map[0].length && newY >= 0 && newY < map.length) {
      final terrain = map[newY][newX];
      if (terrain != 'wall' && terrain != 'water') {
        setState(() {
          playerX = newX;
          playerY = newY;
          // 移动消耗食物
          // character['food'] = (character['food'] - 1).clamp(0, 100);
          _applyTerrainMovementEffect();
          // _saveCharacterData();
        });
      }
    }
  }

  final Map<String, Map<String, dynamic>> _terrainEffects = {
    'grass': {
      'explore': [
        {'text': '在草丛中发现了一些草药！生命值+5', 'hp': 5},
        {'text': '发现了一些野果！饱食度+3', 'food': 3},
        {'text': '什么也没发现...', 'hp': 0},
      ],
      'move': {'food': -1, 'san': 0},
    },
    'path': {
      'explore': [
        {'text': '在路上捡到了金币！金币+10', 'gold': 10},
        {'text': '遇到商人交易获得金币！金币+15', 'gold': 15},
        {'text': '被路过的旅人帮助，精神值+5', 'san': 5},
      ],
      'move': {'food': -0.5, 'san': 0},
    },
    'woods': {
      'explore': [
        {'text': '在树林中采集了蘑菇！饱食度+5', 'food': 5},
        {'text': '被野生动物惊吓，精神值-3', 'san': -3},
        {'text': '发现了一个隐藏的宝箱！金币+20', 'gold': 20},
      ],
      'move': {'food': -2, 'san': -1},
    },
    'building': {
      'explore': [
        {'text': '在建筑内找到了补给！生命值+10，饱食度+5', 'hp': 10, 'food': 5},
        {'text': '发现了一个宝箱！金币+30', 'gold': 30},
        {'text': '在书架上发现了一本有趣的书，精神值+8', 'san': 8},
      ],
      'move': {'food': -1, 'san': 1},
    },
    'water': {
      'explore': {'text': '在水中无法进行探索'},
      'move': {'text': '无法进入水中'},
    },
    'wall': {
      'explore': {'text': '墙壁无法探索'},
      'move': {'text': '无法穿过墙壁'},
    },
  };

  // 地形移动效果判定（60%几率触发）
  void _applyTerrainMovementEffect() {
    if (Random().nextDouble() > 0.6) return; // 40%几率不触发任何效果

    final currentTerrain = map[playerY][playerX];
    final rand = Random();

    switch (currentTerrain) {
      case 'woods':
      // 树林中60%几率消耗更多食物（1-3点）
        if (rand.nextDouble() < 0.6) {
          final cost = 1 + rand.nextInt(2); // 随机消耗1-3点

          setState(() {
            character['food'] = (character['food'] - cost).clamp(0, 100);

          });
        }
        if(rand.nextDouble() <0.3){
          final hcost = rand.nextInt(2);
          setState(() {
            character['hp'] = (character['hp'] - hcost).clamp(0,100);
          });
        }
        break;

      case 'path':
      // 道路上60%几率恢复少量饱食度（0-1点）
        if (rand.nextDouble() < 0.5) {
          setState(() {
            character['food'] = (character['food'] - 1).clamp(0, 100);
          });
        }
        if(rand.nextDouble() <0.3){
          final gain = rand.nextInt(3); // 随机恢复0-1点
          setState(() {
            character['san'] = (character['san'] + gain).clamp(0, 100);
          });
        }
        break;

      case 'building':
      // 建筑内60%几率影响精神值（50%几率恢复或减少1-2点）
        if (rand.nextDouble() < 0.6) {
          final change = rand.nextBool()
              ? 1 + rand.nextInt(2)  // 恢复1-2点
              : -1 - rand.nextInt(2); // 减少1-2点
          setState(() {
            character['san'] = (character['san'] + change).clamp(0, 100);
          });
        }
        if (rand.nextDouble() < 0.6) {
          setState(() {
            character['food'] = (character['food'] - 1).clamp(0, 100);
          });
        }
        break;

      default:
      // 其他地形60%几率正常消耗1点食物
        if (rand.nextDouble() < 0.6) {
          setState(() {
            character['food'] = (character['food'] - 1).clamp(0, 100);
          });
        }
    }

    _checkDeath();
  }

  void _explore() {
    final currentTerrain = map[playerY][playerX];
    final effect = _terrainEffects[currentTerrain]?['explore'];
    character['food'] = (character['food'] - 2).clamp(0, 100);

    if (effect is List) {
      // 随机选择探索结果
      final resultData = effect[Random().nextInt(effect.length)];
      _applyEffect(resultData);
    } else if (effect is Map) {
      // 固定结果（如水、墙）
      setState(() {
        explorationResult = effect['text'] ?? '无法探索';
      });
    }
  }

  void _applyEffect(Map<String, dynamic> effect) {
    setState(() {
      explorationResult = effect['text'] ?? '什么也没发现';
      character['gold'] += effect['gold']?.toInt() ?? 0;
      character['hp'] = (character['hp'] + (effect['hp']?.toInt() ?? 0)).clamp(0, 100);
      character['san'] = (character['san'] + (effect['san']?.toInt() ?? 0)).clamp(0, 100);
      character['food'] = (character['food'] + (effect['food']?.toInt() ?? 0)).clamp(0, 100);
      _checkDeath();
    });
  }

  // 打开宝箱逻辑
  void _openChest(int x, int y) {
    // 检查玩家是否在宝箱相邻位置
    final distance = max((x - playerX).abs(), (y - playerY).abs());
    if (distance > 1) {
      setState(() {
        explorationResult = '距离太远，无法打开宝箱';
      });
      return;
    }

    final rand = Random();
    final item = allItems[rand.nextInt(allItems.length)];

    setState(() {
      // 移除宝箱
      chestPositions.removeWhere((p) => p.x == x && p.y == y);
      // 添加新宝箱
      _addRandomChest();
      // 显示获得物品
      explorationResult = '获得: ${item.name}';
      // 添加到背包
      playerInventory.add(item);
    });
  }

// 随机添加一个新宝箱
  void _addRandomChest() {
    final walkable = _getWalkablePositions()
        .where((p) => !chestPositions.any((cp) => cp.x == p.x && cp.y == p.y))
        .where((p) => !(p.x == playerX && p.y == playerY))
        .toList();

    if (walkable.isNotEmpty) {
      chestPositions.add(walkable[Random().nextInt(walkable.length)]);
    }
  }

  void _showItemDetail(Item item, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(item.name, style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(item.image, width: 60, height: 60,fit: BoxFit.fill,),
            SizedBox(height: 16),
            Text(item.description, style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _useItem(item, index);
              Navigator.pop(context);
            },
            child: Text('使用', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              setState(() => playerInventory.removeAt(index));
              Navigator.pop(context);
            },
            child: Text('丢弃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _useItem(Item item, int index) {
    setState(() {
      playerInventory.removeAt(index);
      item.effects.forEach((key, value) {
        switch (key) {
          case 'hp':
            character['hp'] = (character['hp'] + value).clamp(0, 100);
            break;
          case 'gold':
            character['gold'] += value;
            break;
          case 'food':
            character['food'] = (character['food'] + value).clamp(0, 100);
            break;
          case 'san':
            character['san'] = (character['san'] + value).clamp(0, 100);
            break;
          case 'att':
            character['att'] = (character['att'] + value).clamp(0, 100);
            break;
        }
      });
      explorationResult = '使用了: ${item.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        bool _shouldShake = false;
        int _shakeCount = 0;
        double _shakeIntensity = 0;
        late AnimationController _shakeController;  // 需要在StatefulWidget中声明

        final shouldPop = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, _, __) {
            // 初始化动画控制器
            _shakeController = AnimationController(
              vsync: Navigator.of(context),
              duration: const Duration(milliseconds: 50),
            )..repeat();

            return FloatingTextBackground(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // 计算当前抖动偏移量
                      final intensity = pow(_shakeCount, 1.5).toDouble();
                      final offsetX = _shouldShake
                          ? (Random().nextDouble() * 2 - 1) * intensity
                          : 0.0;
                      final offsetY = _shouldShake
                          ? (Random().nextDouble() * 2 - 1) * intensity
                          : 0.0;

                      return Transform.translate(
                        offset: Offset(offsetX, offsetY),
                        child: AlertDialog(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.red, width: 2.0),
                          ),
                          title: const Text(
                            '退出可不算逃离学校',
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'MicC',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          content: Text(
                            _shakeCount == 0
                                ? '就算你走了我们也会把你抓回来的'
                                : '你这样是要吃处分的',
                            style: const TextStyle(
                              color: Colors.red,
                              fontFamily: 'MicC',
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () {
                                _shakeController.dispose();
                                Navigator.pop(context, false);
                              },
                              child: const Text(
                                '取消',
                                style: TextStyle(fontFamily: 'MicC'),
                              ),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _shakeCount++;
                                  _shakeIntensity = 5 + _shakeCount * 5;
                                  _shouldShake = true;
                                });

                                if (_shakeCount >= 3) {
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    _shakeController.dispose();
                                    Navigator.pop(context, true);
                                  });
                                }
                              },
                              child: const Text(
                                '确定',
                                style: TextStyle(fontFamily: 'MicC'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );

// 确保控制器被释放
        if (!(shouldPop ?? false)) {
          _shakeController.dispose();
        }
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background_1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: -10,
                child: Container(
                  width: 70 * horizontalTiles.toDouble(), // 每个格子70宽
                  height: 70 * verticalTiles.toDouble(),   // 每个格子70高
                  decoration: BoxDecoration(
                    // border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: horizontalTiles, // 使用配置的横向数量
                    ),
                    itemCount: horizontalTiles * verticalTiles,
                    itemBuilder: (context, index) {
                      final x = index % horizontalTiles;
                      final y = index ~/ horizontalTiles;
                      final mapX = playerX - viewRadiusX + x;
                      final mapY = playerY - viewRadiusY + y;

                      // 检查是否在地图范围内
                      final terrain = (mapX >= 0 && mapX < map[0].length && mapY >= 0 && mapY < map.length)
                          ? map[mapY][mapX]
                          : 'grass';

                      final isPlayerHere = mapX == playerX && mapY == playerY;
                      final isChest = chestPositions.any((p) => p.x == mapX && p.y == mapY);

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withOpacity(0.2)),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 地形背景
                            Image.asset(
                              terrainImages[terrain]!,
                              fit: BoxFit.fill,
                            ),

                            // 宝箱显示
                            if (isChest)
                              Positioned(
                                bottom: 0,
                                left: 20,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _openChest(mapX, mapY),
                                    child: Image.asset(
                                      'images/map/chest.png',
                                      width: 30,
                                      height: 30,
                                    ),
                                  ),
                                ),
                              ),

                            // 玩家显示
                            if (isPlayerHere)
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Image.asset(
                                    character['image'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                top: 20,
                left: 20,
                child: Opacity(
                  opacity: 0.85,
                  child: Container(
                    width: 200,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        _buildStatBar('生命值', character['hp'], Colors.red),
                        _buildStatBar('饱食', character['food'], Colors.orange),
                        _buildStatBar('精神', character['san'], Colors.blue),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatValue('att', character['att'], Colors.deepOrange),
                            _buildStatValue('gold', character['gold'], Colors.amber),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 30,
                top: 50,
                child: Opacity(
                  opacity: 0.7,
                  child: Container(
                    width: 220,
                    height: 100,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child:
                    Text(
                      explorationResult,
                      style: TextStyle(fontSize: 12, height: 1.4,fontFamily: 'MicC',color: Colors.red),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 30,
                left: 30,
                child: Column(
                  children: [
                    _buildMovementButton(Icons.arrow_upward, () => _movePlayer(0, -1)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMovementButton(Icons.arrow_back, () => _movePlayer(-1, 0)),
                        SizedBox(width: 66),
                        _buildMovementButton(Icons.arrow_forward, () => _movePlayer(1, 0)),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildMovementButton(Icons.arrow_downward, () => _movePlayer(0, 1)),
                  ],
                ),
              ),

              Positioned(
                bottom: 50,
                right: 80,
                child: ElevatedButton(
                  onPressed: _explore,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      child:Image(image: AssetImage('images/get.png'),fit: BoxFit.cover,width: 30,height: 30,)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              // 背包按钮
              Positioned(
                top: 50,
                left: 240,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showInventory = true),
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      child: Image(image: AssetImage('images/bag.png'),fit: BoxFit.cover,width: 20,height: 25,)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // 背包界面
              if (_showInventory)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showInventory = false),
                    child: Container(
                      color: Colors.black54,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {}, // 阻止事件冒泡
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              border: Border.all(color: Colors.white),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('背包',
                                    style: TextStyle(fontSize: 24, color: Colors.white)),
                                Divider(color: Colors.white),
                                Expanded(
                                  child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: playerInventory.length,
                                    itemBuilder: (context, index) {
                                      final item = playerInventory[index];
                                      return GestureDetector(
                                        onTap: () => _showItemDetail(item, index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                item.image,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.fill,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                item.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    final isMax = value >= 100;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: Stack(
              children: [
                Container(
                  width: 200 * (value / 100),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withOpacity(0.7),
                    boxShadow: isMax
                        ? [
                      BoxShadow(
                        color: color,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$label: $value',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  金币
  Widget _buildStatValue(String path, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(image: AssetImage('images/${path}.png'), fit: BoxFit.cover, width: 10, height: 10),
          SizedBox(width: 3),
          Text('$value', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // 移动按钮
  Widget _buildMovementButton(IconData icon, VoidCallback onPressed) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white.withOpacity(0.7),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withOpacity(0.1)),
          ),
          child: Icon(icon, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}
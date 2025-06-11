import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mapData.dart';
import '../data/shop.dart';
import 'gameOver.dart';
import 'package:escape_from_school/data/props.dart';
import '../eff02.dart';
import '../data/mapEff.dart'; // 地形效果数据

class BoardPage extends StatefulWidget {
  final Map<String, dynamic> character;

  const BoardPage({Key? key, required this.character}) : super(key: key);

  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  // 角色数据
  late Map<String, dynamic> character;

  // 玩家位置
  int playerX = 10;
  int playerY = 10;

  // 探索结果文本
  String explorationResult = "";

  // 地图数据
  List<List<String>> map = MapData.testMap;

  // 宝箱位置列表
  List<Point<int>> chestPositions = [];

  // 玩家背包
  List<Item> playerInventory = [];

  // 背包显示状态
  bool _showInventory = false;

  // 添加角色朝向状态 (true=右, false=左)
  bool _facingRight = true;

  Shop? schoolShop;
  bool showShop = false; // 是否显示商店界面
  Point? shopPosition; // 商店位置

  Timer? _shopRefreshTimer; // 添加定时器变量

  // 移动冷却相关变量
  late Timer _moveCooldownTimer;
  bool _canMove = true;
  double _moveCooldown = 1.0; // 基础冷却时间(秒)
  double _currentCooldown = 0.0; // 当前剩余冷却时间

  // 视野范围配置
  final int horizontalTiles = 13; // 横向显示格子数
  final int verticalTiles = 6;    // 纵向显示格子数
  final int viewRadiusX = 3;      // 水平视野半径
  final int viewRadiusY = 3;      // 垂直视野半径

  // 地形图片映射
  static const terrainImages = {
    'wall': 'images/map/wall.png',
    'grass': 'images/map/grass.png',
    'woods': 'images/map/woods.png',
    'water': 'images/map/water.png',
    'path': 'images/map/path.png',
    'building': 'images/map/building.png',
  };

  // 随机数生成器实例
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    character = Map<String, dynamic>.from(widget.character);
    _loadCharacterData().then((_) {
      _setRandomSpawnPoint(); // 设置随机出生点
      _initChests();         // 初始化宝箱
      _initShop(); // 初始化商店
      _startShopRefreshTimer(); // 启动定时器
    });
  }

  @override
  void dispose() {
    _shopRefreshTimer?.cancel(); // 组件销毁时取消定时器
    _moveCooldownTimer.cancel(); // 确保计时器被取消
    super.dispose();
  }

  void _startShopRefreshTimer() {
    // 取消现有定时器（如果有）
    _shopRefreshTimer?.cancel();

    // 设置随机刷新间隔（90秒±30秒）
    final random = Random();
    final seconds = 90 + random.nextInt(61) - 30; // 60-120秒之间
    final duration = Duration(seconds: seconds);

    print('商店将在${duration.inSeconds}秒后刷新');

    _shopRefreshTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          schoolShop?.refreshItems();
        });
        // 刷新后重新启动定时器
        _startShopRefreshTimer();
      }
    });
  }

  // 初始化商店位置（固定或随机）
// 初始化商店
  void _initShop() {

    // 在找到位置后同样初始化为空列表并立即刷新
    schoolShop = Shop(
      position: Point(4,4),
      items: [],
      lastPriceChange: DateTime.now(),
    );
    setState(() {
      schoolShop!.refreshItems();
    });
  }

// 价格浮动计算 (±20%)
  int _calculatePrice(int basePrice) {
    final random = Random();
    final variation = (basePrice * 0.2).round();
    return basePrice + random.nextInt(variation * 2) - variation;
  }

// 尝试打开商店
  void _tryOpenShop(int x, int y) {
    if (schoolShop == null) return;
    // 检查是否是商店位置
    if (schoolShop?.position.x != x || schoolShop?.position.y != y) return;

    // 距离检查
    final dx = (x - playerX).abs();
    final dy = (y - playerY).abs();
    if (dx > 1 || dy > 1) {
      setState(() => explorationResult = '需要靠近商店才能交易');
      return;
    }

    setState(() {
      schoolShop?.fluctuatePrices();
      showShop = true;
    });
  }

  // 获取所有可行走的格子位置
  List<Point<int>> _getWalkablePositions() {
    final walkable = <Point<int>>[];
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        if (_isWalkable(x, y)) {
          walkable.add(Point(x, y));
        }
      }
    }
    return walkable;
  }

  // 初始化宝箱位置
  void _initChests() {
    chestPositions.clear();
    final walkable = _getWalkablePositions()
        .where((p) => !(p.x == playerX && p.y == playerY))
        .toList();

    // 随机选择位置，最多100个宝箱
    for (int i = 0; i < min(100, walkable.length); i++) {
      chestPositions.add(walkable.removeAt(_rand.nextInt(walkable.length)));
    }
  }

  // 设置随机出生点
  void _setRandomSpawnPoint() {
    const maxAttempts = 100;
    final walkable = _getWalkablePositions();

    if (walkable.isNotEmpty) {
      final spawn = walkable[_rand.nextInt(walkable.length)];
      setState(() {
        playerX = spawn.x;
        playerY = spawn.y;
      });
      return;
    }

    // 备用方案
    _setFallbackSpawnPoint();
  }

  // 备用出生点设置
  void _setFallbackSpawnPoint() {
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

    // 默认出生点
    setState(() {
      playerX = 1;
      playerY = 1;
    });
  }

  // 检查位置是否可行走
  bool _isWalkable(int x, int y) {
    if (x < 0 || x >= map[0].length || y < 0 || y >= map.length) {
      return false;
    }
    final terrain = map[y][x];
    return terrain != 'wall' && terrain != 'water';
  }

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

  // 死亡检查
  void _checkDeath() {

    final isDead = character['hp'] <= 0 ||
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

  // 获取当前可见区域地图
  List<List<String>> get visibleMap {
    final visible = <List<String>>[];
    final centerX = horizontalTiles ~/ 2;
    final centerY = verticalTiles ~/ 2;

    for (int y = 0; y < verticalTiles; y++) {
      final row = <String>[];
      for (int x = 0; x < horizontalTiles; x++) {
        final mapX = playerX - centerX + x;
        final mapY = playerY - centerY + y;

        if (mapX >= 0 && mapX < map[0].length && mapY >= 0 && mapY < map.length) {
          row.add(map[mapY][mapX]);
        } else {
          row.add('grass'); // 边界外显示草地
        }
      }
      visible.add(row);
    }
    return visible;
  }

  // 移动玩家
  void _movePlayer(int dx, int dy) {
    // 检查是否可以移动
    if (!_canMove) {
      return;
    }

    // 当ATT为负时，有几率无法移动
    if (character['att'] < 0 && Random().nextDouble() < 0.2) {
      setState(() {
        explorationResult = "今天吃的东西肯定有问题。。。";
        _startMoveCooldown(); // 仍然触发冷却
      });
      return;
    }
    if (character['att'] < -3 && Random().nextDouble() < 0.4) {
      setState(() {
        explorationResult = "我要倒下了。。。";
        _startMoveCooldown(); // 仍然触发冷却
      });
      return;
    }
    if (character['att'] < -6 && Random().nextDouble() < 0.6) {
      setState(() {
        explorationResult = "救救我。。。";
        _startMoveCooldown(); // 仍然触发冷却
      });
      return;
    }
    if (character['att'] < -9 && Random().nextDouble() < 0.8) {
      setState(() {
        explorationResult = "让我离开这个学校。。。";
        _startMoveCooldown(); // 仍然触发冷却
      });
      return;
    }


    // 仅处理左右移动 (dy=0)
    if (dy == 0 && dx != 0) {
      setState(() {
        _facingRight = dx > 0;
      });
    }

    final newX = playerX + dx;
    final newY = playerY + dy;
    _checkDeath();

    if (newX >= 0 && newX < map[0].length && newY >= 0 && newY < map.length) {
      final terrain = map[newY][newX];
      if (terrain != 'wall' && terrain != 'water') {
        setState(() {
          playerX = newX;
          playerY = newY;
          _applyTerrainMovementEffect();
          _startMoveCooldown(); // 开始移动冷却
        });
      }
    }
  }

// 计算冷却时间 - 支持负值ATT
  double _calculateCooldown() {
    // 基础冷却1秒，att每增加1点减少0.02秒
    // att为负时，冷却时间增加，无上限限制
    double cooldown = 1.0 - (character['att'] * 0.02);

    // 最低不低于0.2秒，但允许无上限增加
    return cooldown.clamp(0.2, double.infinity);
  }

  // 开始移动冷却
  void _startMoveCooldown() {
    setState(() {
      _canMove = false;
      _currentCooldown = _calculateCooldown();

      // 当ATT为负时，有几率移动失败
      if (character['att'] < 0 && Random().nextDouble() < 0.3) {
        _currentCooldown *= 1.5; // 增加50%冷却时间
      }
    });

    _moveCooldownTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentCooldown -= 0.1;
        if (_currentCooldown <= 0) {
          _currentCooldown = 0;
          _canMove = true;
          timer.cancel();
        }
      });
    });
  }

  // 应用地形移动效果
  void _applyTerrainMovementEffect() {
    if (_rand.nextDouble() > 0.6) return; // 40%几率不触发效果

    final currentTerrain = map[playerY][playerX];

    switch (currentTerrain) {
      case 'woods':
      // 树林中60%几率消耗更多食物
        if (_rand.nextDouble() < 0.6) {
          final cost = 1 + _rand.nextInt(2);
          character['food'] = (character['food'] - cost).clamp(0, 100);
        }
        if (_rand.nextDouble() < 0.3) {
          final hcost = _rand.nextInt(2);
          character['hp'] = (character['hp'] - hcost).clamp(0, 100);
        }
        break;

      case 'path':
      // 道路上50%几率消耗食物
        if (_rand.nextDouble() < 0.5) {
          character['food'] = (character['food'] - 1).clamp(0, 100);
        }
        if (_rand.nextDouble() < 0.3) {
          final gain = _rand.nextInt(3);
          character['san'] = (character['san'] + gain).clamp(0, 100);
        }
        break;

      case 'building':
      // 建筑内60%几率影响精神值
        if (_rand.nextDouble() < 0.6) {
          final change = _rand.nextBool()
              ? 1 + _rand.nextInt(2)
              : -1 - _rand.nextInt(2);
          character['san'] = (character['san'] + change).clamp(0, 100);
        }
        if (_rand.nextDouble() < 0.6) {
          character['food'] = (character['food'] - 1).clamp(0, 100);
        }
        break;

      default:
      // 其他地形60%几率消耗食物
        if (_rand.nextDouble() < 0.6) {
          character['food'] = (character['food'] - 1).clamp(0, 100);
        }
    }

    _checkDeath();
  }

  // 探索当前格子
  void _explore() {
    character['food'] = (character['food'] - 2).clamp(0, 100);
    final currentTerrain = map[playerY][playerX];
    final effect = MapEff.terrainEffects[currentTerrain]?['explore'];

    if (effect is List) {
      // 随机选择探索结果
      _applyEffect(effect[_rand.nextInt(effect.length)]);
    } else if (effect is Map) {
      setState(() {
        explorationResult = effect['text'] ?? '无法探索';
      });
    }
  }

  // 应用效果到角色
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

  // 打开宝箱
  void _openChest(int x, int y) {
    final distance = max((x - playerX).abs(), (y - playerY).abs());
    if (distance > 1) {
      setState(() => explorationResult = '距离太远，无法打开宝箱');
      return;
    }

    final item = allItems[_rand.nextInt(allItems.length)];

    setState(() {
      chestPositions.removeWhere((p) => p.x == x && p.y == y);
      _addRandomChest();
      explorationResult = '获得: ${item.name}';
      playerInventory.add(item);
    });
  }

  // 随机添加新宝箱
  void _addRandomChest() {
    final walkable = _getWalkablePositions()
        .where((p) => !chestPositions.any((cp) => cp.x == p.x && cp.y == p.y))
        .where((p) => !(p.x == playerX && p.y == playerY))
        .toList();

    if (walkable.isNotEmpty) {
      chestPositions.add(walkable[_rand.nextInt(walkable.length)]);
    }
  }

  // 显示物品详情对话框
  void _showItemDetail(Item item, int indexInSortedList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5)
        ),
        backgroundColor: Color(0xFF282828),
        title: Text(item.name, style: TextStyle(color: Colors.white),textAlign: TextAlign.center,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(item.image, width: 60, height: 60, fit: BoxFit.fill),
            SizedBox(height: 16),
            Text(item.description, style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final actualIndex = playerInventory.indexWhere((invItem) => invItem == item);
              if (actualIndex != -1) {
                setState(() => playerInventory.removeAt(actualIndex));
              }
              Navigator.pop(context);
            },
            child: Text('丢弃', style: TextStyle(color: Colors.red)),
          ),

          TextButton(
            onPressed: () {
              _useItem(item, indexInSortedList);
              Navigator.pop(context);
            },
            child: Text('使用', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // 使用物品
  void _useItem(Item item, int indexInSortedList) {
    // 找到物品在原始列表中的实际索引
    final actualIndex = playerInventory.indexWhere((invItem) => invItem == item);

    if (actualIndex == -1) return; // 没找到物品

    setState(() {
      // 从原始列表中移除物品
      playerInventory.removeAt(actualIndex);

      // 应用物品效果
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
          // 移除clamp限制，允许ATT变为负值
            character['att'] = character['att'] + value;
            // 更新移动冷却时间
            if (!_canMove) {
              _currentCooldown = _calculateCooldown();
            }
            break;
        }
      });

      explorationResult = '使用了: ${item.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _showExitConfirmation(context),
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
              // 地图渲染
              _buildMapView(),

              // 角色状态面板
              _buildStatusPanel(),

              // 探索结果提示
              _buildExplorationResult(),

              // 移动控制按钮
              _buildMovementControls(),

              // 探索按钮
              _buildExploreButton(),

              // 背包按钮
              _buildInventoryButton(),

              // 背包界面
              if (_showInventory) _buildInventoryView(),

              if(showShop && schoolShop != null) _buildShopPanel(),
            ],
          ),
        ),
      ),
    );
  }

  // 显示退出确认对话框
  Future<bool> _showExitConfirmation(BuildContext context) async {
    bool _shouldShake = false;
    int _shakeCount = 0;
    late AnimationController _shakeController;

    final shouldPop = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
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
                  final intensity = pow(_shakeCount, 1.5).toDouble();
                  final offsetX = _shouldShake
                      ? (_rand.nextDouble() * 2 - 1) * intensity
                      : 0.0;
                  final offsetY = _shouldShake
                      ? (_rand.nextDouble() * 2 - 1) * intensity
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

    return shouldPop ?? false;
  }

  // 在 _BoardPageState 类中修改 _buildInventoryView 方法
  Widget _buildInventoryView() {
    final sortedInventory = List<Item>.from(playerInventory)
      ..sort((a, b) {
        final typeComparison = (a.type ?? '').compareTo(b.type ?? '');
        if (typeComparison != 0) return typeComparison;
        return a.name.compareTo(b.name);
      });

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showInventory = false),
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width / 3,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 背包标题 - 添加立体效果
                    Container(
                      child: Text(
                        '背 包',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 物品网格 - 添加排序功能
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: sortedInventory.length,
                        // 按物品类型排序
                        itemBuilder: (context, index) {
                          final item = sortedInventory[index];
                          return _buildInventoryItem(item, index);
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
    );
  }

// 新增方法：构建单个物品格子
  Widget _buildInventoryItem(Item item, int indexInSortedList) {
    return GestureDetector(
      onTap: () => _showItemDetail(item, indexInSortedList),
      child: MouseRegion(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Color(0xFF282828),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: _getItemBorderColor(item.type),
                blurRadius: 6,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 物品图标 - 添加悬浮放大效果
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(1.0),
                child: Image.asset(
                  item.image,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 8),
              // 物品名称
              Text(
                item.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

// 根据物品类型获取边框颜色
  Color _getItemBorderColor(String type) {
    switch (type) {
      case 'weapon':
        return Colors.red;
      case 'food':
        return Colors.green;
      case 'potion':
        return Colors.blue;
      case 'material':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // 构建地图视图
  Widget _buildMapView() {
    return Positioned(
      left: 0,
      top: -10,
      child: Container(
        width: 70 * horizontalTiles.toDouble(),
        height: 70 * verticalTiles.toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: horizontalTiles,
              ),
              itemCount: horizontalTiles * verticalTiles,
              itemBuilder: (context, index) {
                final x = index % horizontalTiles;
                final y = index ~/ horizontalTiles;
                final visibleRow = visibleMap[y];
                final terrain = visibleRow[x];

                final centerX = horizontalTiles ~/ 2;
                final centerY = verticalTiles ~/ 2;
                final mapX = playerX - centerX + x;
                final mapY = playerY - centerY + y;

                final isPlayerHere = x == centerX && y == centerY;
                final isChest = chestPositions.any((p) => p.x == mapX && p.y == mapY);

                final isShop = schoolShop != null &&
                    mapX == schoolShop!.position.x &&
                    mapY == schoolShop!.position.y;

                // 计算与玩家的欧几里得距离（圆形视野）
                // final distance = sqrt(pow(x - centerX, 2) + pow(y - centerY, 2));
                // final maxRadius = min(viewRadiusX, viewRadiusY).toDouble();
                //
                // // 计算透明度 - 使用平滑过渡
                // double opacity;
                // if (distance <= maxRadius - 1) {
                // opacity = 1.0; // 完全可见区域
                // } else if (distance <= maxRadius) {
                // opacity = 0.7; // 边缘半透明
                // } else {
                // opacity = 0.3; // 视野外低透明度
                // }

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

                      // 圆形暗边效果 - 使用径向渐变
                      // if (opacity < 1.0)
                      //   Container(
                      //     decoration: BoxDecoration(
                      //       gradient: RadialGradient(
                      //         center: Alignment(0, 0),
                      //         radius: 1.0,
                      //         colors: [
                      //           Colors.transparent,
                      //           Colors.black.withOpacity(1.0 - opacity),
                      //         ],
                      //         stops: [
                      //           0.7,
                      //           1.0,
                      //         ],
                      //       ),
                      //     ),
                      //   ),

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

                      // 商店显示
                      if (isShop)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => schoolShop != null ? _tryOpenShop(mapX, mapY) : null,
                            child: Image.asset(
                              'images/map/shop.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain, // 修改为contain确保完整显示
                            ),
                          ),
                        ),

                      // 玩家显示
                      if (isPlayerHere)
                        Center(
                          child: Transform(
                            transform: Matrix4.identity()
                              ..scale(_facingRight ? 1.0 : -1.0, 1.0),
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                character['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            // 圆形暗边遮罩层
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 商店页面组件
  Widget _buildShopPanel() {
    if (schoolShop == null || !showShop) return SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => showShop = false),
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止事件冒泡
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    // 顶部标题栏
                    Stack(
                      children: [
                        // 居中标题
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '学校小卖部',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.red,
                                  fontFamily: 'MicC',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _getTotalItemCount(),
                        itemBuilder: (context, index) {
                          final itemInfo = _getItemByIndex(index);
                          final item = itemInfo['item'];
                          final isMainItem = itemInfo['isMainItem'];

                          return GestureDetector(
                            onTap: () => _showPurchaseDialog(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isMainItem ? Colors.white : Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // 价格只在主商品上显示
                                  if (isMainItem) Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${item.currentPrice}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Image.asset('images/gold.png', width: 12, height: 12,fit: BoxFit.fill,),
                                      ],
                                    ),
                                  ),

                                  // 图片显示 - 副本商品添加半透明效果
                                  Center(
                                    child: Opacity(
                                      opacity: isMainItem ? 1.0 : 0.6,
                                      child: Image.asset(
                                        item.item.image,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  // 名称只在主商品上显示
                                  if (isMainItem) Positioned(
                                    bottom: 8,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      item.item.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
    );
  }

  String _formatTimeRemaining(DateTime refreshTime) {
    final remaining = refreshTime.difference(DateTime.now());
    if (remaining.isNegative) return '即将刷新';
    return '${remaining.inMinutes}分${remaining.inSeconds.remainder(60)}秒';
  }

// 计算总商品数量（考虑库存）
  int _getTotalItemCount() {
    if (schoolShop == null) return 0;
    return schoolShop!.items.fold(0, (sum, item) => sum + item.stock);
  }

// 根据索引获取对应的商品信息
  Map<String, dynamic> _getItemByIndex(int index) {
    int currentIndex = 0;
    for (var item in schoolShop!.items) {
      if (index < currentIndex + item.stock) {
        return {
          'item': item,
          'isMainItem': (index == currentIndex), // 第一个是该商品的主显示
        };
      }
      currentIndex += item.stock;
    }
    return {'item': schoolShop!.items.last, 'isMainItem': true};
  }

  // 购买确认对话框
  void _showPurchaseDialog(ShopItem shopItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5)
        ),
        backgroundColor: Color(0xFF282828),
        content: Column(
          mainAxisSize: MainAxisSize.min,  // 对话框内容高度根据内容自动调整
          crossAxisAlignment: CrossAxisAlignment.stretch,  // 横向拉伸填满可用空间
          children: [
            // 顶部行布局：左侧物品名称 + 右侧价格和金币图标
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,  // 左右两端对齐
              children: [
                // 左侧物品名称
                Text(
                    shopItem.item.name,
                    style: TextStyle(fontSize: 18, color: Colors.white)
                ),
                // 右侧价格和金币图标
                Row(
                  children: [
                    Text(
                      '${shopItem.currentPrice}',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 4),  // 价格和金币图标之间的间距
                    Image.asset('images/gold.png', width: 16, height: 16),  // 金币图标
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),  // 名称行和物品图片之间的间距
            // 中间物品图片（居中显示）
            Center(
              child: Image.asset(shopItem.item.image, width: 60, height: 60),
            ),
          ],
        ),
        // 底部按钮区域
        actions: [
          Container(
            width: double.infinity,
            child: Row(
              children: [
                // 取消按钮（左侧，使用Expanded平均分配空间）
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消'),
                  ),
                ),
                // 购买按钮（右侧，使用Expanded平均分配空间）
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _buyItem(shopItem);
                    },
                    child: Text(
                      '购买',
                      style: TextStyle(
                        // 根据金币是否足够和库存决定按钮颜色
                        color: character['gold'] >= shopItem.currentPrice && shopItem.stock > 0
                            ? Colors.green  // 可购买状态为绿色
                            : Colors.grey,  // 不可购买状态为灰色
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

// 购买商品
  void _buyItem(ShopItem shopItem) {
    if (character['gold'] < shopItem.currentPrice || shopItem.stock <= 0) return;

    setState(() {
      character['gold'] -= shopItem.currentPrice;
      shopItem.stock--;
      playerInventory.add(shopItem.item);
      explorationResult = '购买了: ${shopItem.item.name}';
    });
  }

  // 构建状态面板
  Widget _buildStatusPanel() {
    return Positioned(
      top: 30,
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
    );
  }

  // 构建探索结果提示
  Widget _buildExplorationResult() {
    return Positioned(
      right: 30,
      top: 30,
      child: Opacity(
        opacity: 0.7,
        child: Container(
          width: 220,
          height: 100,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
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
          child: Text(
            explorationResult,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
                // fontFamily: 'MicC',
                color: Colors.white
            ),
          ),
        ),
      ),
    );
  }

  // 构建移动控制按钮
  Widget _buildMovementControls() {
    return Positioned(
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
    );
  }

  // 构建探索按钮
  Widget _buildExploreButton() {
    return Positioned(
      bottom: 50,
      right: 80,
      child: ElevatedButton(
        onPressed: _explore,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Image(
            image: AssetImage('images/get.png'),
            fit: BoxFit.cover,
            width: 30,
            height: 30,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // 构建背包按钮
  Widget _buildInventoryButton() {
    return Positioned(
      top: 40,
      left: 240,
      child: ElevatedButton(
        onPressed: () => setState(() => _showInventory = true),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Image(
            image: AssetImage('images/bag.png'),
            fit: BoxFit.cover,
            width: 20,
            height: 25,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // 构建状态条
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

  // 构建状态数值显示
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
          Image(
              image: AssetImage('images/${path}.png'),
              fit: BoxFit.cover,
              width: 10,
              height: 10
          ),
          SizedBox(width: 3),
          Text('$value', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDebugButton() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            schoolShop?.refreshItems();
          });
        },
        child: Text('手动刷新商店'),
      ),
    );
  }

  // 构建移动按钮
  Widget _buildMovementButton(IconData icon, VoidCallback onPressed) {
    final isCoolingDown = !_canMove;
    final isImpaired = character['att'] < 0;

    return Material(
      borderRadius: BorderRadius.circular(10),
      color: isCoolingDown
          ? Colors.grey.withOpacity(0.5)
          : isImpaired
          ? Colors.red.withOpacity(0.3)
          : Colors.white.withOpacity(0.7),
      elevation: isImpaired ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isCoolingDown ? null : onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isImpaired
                  ? Colors.red.withOpacity(0.5)
                  : isCoolingDown
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Icon(
              icon,
              size: 32,
              color: isImpaired
                  ? Colors.red.withOpacity(0.7)
                  : isCoolingDown
                  ? Colors.grey
                  : Colors.white
          ),
        ),
      ),
    );
  }
}
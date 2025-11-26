import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'data/manData.dart';
import 'data/props.dart';
import 'eff.dart';
import 'eff02.dart';
import 'game/optimized_board.dart';

class ChooseCharacterPage extends StatefulWidget {
  const ChooseCharacterPage({super.key});

  @override
  State<ChooseCharacterPage> createState() => _ChooseCharacterPageState();
}

class _ChooseCharacterPageState extends State<ChooseCharacterPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.5, // 控制一页显示多少个卡片，0.6表示一页显示1.6个卡片
      initialPage: _currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onCardTap(int index) {
    if (index == _currentIndex) {
      // 点击当前选中的卡片，开始游戏
      _navigateToMap(manData[index]);
    } else {
      // 点击其他卡片，滚动到该卡片
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToMap(Map<String, dynamic> character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OptimizedBoardPage(
              characterStats: {
                'id': character['name'],
                'name': character['name'],
                'hp': (character['hp'] as num).toDouble(),
                'maxHp': (character['hp'] as num).toDouble(),
                'san': (character['san'] as num).toDouble().clamp(0, 250),
                'maxSan': 250.0,
                'moveSpeed': character['moveSpeed'],
                'gold': (character['gold'] as num).toDouble(),
                'food': (character['food'] as num).toDouble(),
                'maxFood':
                    ((character['maxFood'] ?? character['food']) as num)
                        .toDouble(),
                'baseDamage':
                    ((character['baseDamage'] ?? 0.0) as num).toDouble(),
                'baseCritChance':
                    ((character['baseCritChance'] ?? 0.0) as num).toDouble(),
                'initialItems': character['initialItems'],
                'image': character['image'],
              },
              characterImage: character['image'],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    GlobalState.enableAllCards();
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景层
          Positioned.fill(
            child: Container(
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
          ),

          // 渐变遮罩层 - 增强视觉效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.6),
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 蓝色调遮罩层 - 增强UI一致性
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A5F).withOpacity(0.1),
                    Color(0xFF0F1F3D).withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),

          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部标题栏 - 参考图鉴页面设计
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(0, 0, 0, 0.8),
                        Color.fromRGBO(0, 0, 0, 0.4),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Color.fromRGBO(255, 255, 255, 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 返回按钮 - 美化样式
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromRGBO(255, 255, 255, 0.2),
                                Color.fromRGBO(0, 0, 0, 0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Color.fromRGBO(255, 255, 255, 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Color.fromRGBO(255, 255, 255, 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Color(0xFF4A90E2).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Text(
                            '选择角色',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  blurRadius: 15,
                                  color: Colors.black.withOpacity(0.8),
                                  offset: const Offset(0, 3),
                                ),
                                Shadow(
                                  blurRadius: 10,
                                  color: Color(0xFF4A90E2).withOpacity(0.6),
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // 右侧占位空间（保持对称）
                      Container(width: 40, height: 40),
                    ],
                  ),
                ),

                // 角色卡片轮播区域
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: isLandscape ? 320 : 350,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: manData.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (_pageController
                                  .position
                                  .hasContentDimensions) {
                                value = (_pageController.page! - index);
                                value = (1 - (value.abs() * 0.5)).clamp(
                                  0.0,
                                  1.0,
                                );
                              }

                              // 中间卡片特写效果
                              final double scale = 0.8 + (value * 0.2); // 缩放效果
                              final double opacity =
                                  0.5 + (value * 0.5); // 透明度效果

                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: TiltCard(
                                      character: manData[index],
                                      isCompact: isLandscape,
                                      isSelected: index == _currentIndex,
                                      onTap: () => _onCardTap(index),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 底部提示区域
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isLandscape ? 15 : 25,
                  ),
                  child: Column(
                    children: [
                      // 装饰线
                      Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 提示文字
                      Text(
                        '滑动查看角色，点击中间卡片开始游戏',
                        style: TextStyle(
                          fontSize: isLandscape ? 12 : 14,
                          color: Colors.white.withOpacity(0.7),
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
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
  final bool isCompact;
  final bool isSelected;
  final VoidCallback? onTap;

  const TiltCard({
    super.key,
    required this.character,
    this.isCompact = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final cardSize = widget.isCompact ? Size(180, 320) : Size(200, 350);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovering ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: cardSize.width,
            height: cardSize.height,
            decoration: BoxDecoration(
              color:
                  widget.isSelected
                      ? Color(0xFF1E3A5F).withOpacity(0.95) // 深蓝色背景
                      : Color(0xFF0F1F3D).withOpacity(0.95), // 深蓝色背景
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color:
                    widget.isSelected
                        ? const Color(0xFF4A90E2) // 蓝色 - 选中状态
                        : _isHovering
                        ? const Color(0xFF4A5568) // 灰色 - 悬停状态
                        : const Color(0xFF4A5568), // 灰色 - 普通状态
                width: widget.isSelected ? 3 : (_isHovering ? 2 : 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovering ? 0.9 : 0.7),
                  blurRadius: _isHovering ? 40 : 30,
                  spreadRadius: _isHovering ? 15 : 10,
                  offset: const Offset(0, 8),
                ),
                if (widget.isSelected) // 只有选中状态才有蓝色发光效果
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.4), // 蓝色
                    blurRadius: 25,
                    spreadRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                BoxShadow(
                  color: Colors.white.withOpacity(_isHovering ? 0.1 : 0.05),
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                // 顶部图片区域
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2D3748).withOpacity(0.9),
                            Color(0xFF1A202C).withOpacity(0.95),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      Color(0xFF4A5568).withOpacity(0.3),
                                      Color(0xFF2D3748).withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Image.asset(
                                  widget.character['image'],
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 30,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.transparent,
                                      ],
                                    ),
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

                // 底部信息区域
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 角色名称
                        Text(
                          widget.character['name'],
                          style: TextStyle(
                            fontSize: widget.isCompact ? 18 : 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // 角色描述
                        Expanded(
                          child: Text(
                            widget.character['description'] ?? '',
                            style: TextStyle(
                              fontSize: widget.isCompact ? 10 : 12,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 属性网格
                        _buildStatsGrid(),

                        const SizedBox(height: 6),

                        // 初始携带物品
                        _buildInitialItems(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = widget.character;
    final statKeys = ['hp', 'san', 'moveSpeed', 'gold', 'food'];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.spaceBetween,
      children:
          statKeys.map((key) {
            return _buildStatItem(key, stats[key]);
          }).toList(),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    final config = _getAttributeConfig(label);
    final numValue =
        (value is num)
            ? value.toDouble()
            : double.tryParse(value.toString()) ?? 0.0;
    final progress = (numValue / config['maxValue']).clamp(0.0, 1.0);

    // 将英文标签转换为中文
    String getChineseLabel(String label) {
      switch (label) {
        case 'hp':
          return '生命';
        case 'san':
          return '理智';
        case 'moveSpeed':
          return '速度';
        case 'gold':
          return '金币';
        case 'food':
          return '食物';
        default:
          return label;
      }
    }

    final chineseLabel = getChineseLabel(label);

    return Container(
      width: widget.isCompact ? 45 : 55,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chineseLabel,
            style: TextStyle(
              fontSize: widget.isCompact ? 8 : 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: widget.isCompact ? 14 : 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withOpacity(0.3),
              border: Border.all(
                color: config['color'].withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        config['color'].withOpacity(0.7),
                        config['color'].withOpacity(0.4),
                      ],
                    ),
                  ),
                  width: progress * (widget.isCompact ? 45 : 55),
                ),
                Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: widget.isCompact ? 8 : 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Map<String, dynamic> _getAttributeConfig(String label) {
    switch (label) {
      case 'hp':
        return {'color': Colors.red, 'maxValue': 200.0};
      case 'san':
        return {'color': Colors.blue, 'maxValue': 250.0};
      case 'moveSpeed':
        return {'color': Colors.green, 'maxValue': 10.0};
      case 'gold':
        return {'color': Colors.yellow, 'maxValue': 1000.0};
      case 'food':
        return {'color': Colors.orange, 'maxValue': 200.0};
      default:
        return {'color': Colors.grey, 'maxValue': 100.0};
    }
  }

  Widget _buildCompactStatItem(String label, dynamic value, Color color) {
    final numValue =
        (value is num)
            ? value.toDouble()
            : double.tryParse(value.toString()) ?? 0.0;
    final maxValue = _getMaxValueForAttribute(label);
    // 所有属性都限制在100%以内，防止进度条爆表
    final progress = (numValue / maxValue).clamp(0.0, 1.0);

    // 关键区域：金币缩写显示（>=1000 显示为 K；>=1000000 显示为 M；>=1000000000 显示为 B）
    // 说明：仅影响选择角色页面的“金币”文本展示，不改动数值或进度条计算逻辑。
    String _formatGoldAbbr(double v) {
      final iv = v.floor();
      if (iv >= 1000000000) return '${iv ~/ 1000000000}B';
      if (iv >= 1000000) return '${iv ~/ 1000000}M';
      if (iv >= 1000) return '${iv ~/ 1000}K';
      return iv.toString();
    }

    final String displayValue =
        label == '金币' ? _formatGoldAbbr(numValue) : value.toString();

    return Container(
      height: 42,
      decoration: BoxDecoration(
        // 关键区域：选择页面圆角统一为 5（紧凑属性卡外层）
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.grey[900]!.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 进度条背景
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[800]!.withOpacity(0.9),
                  Colors.grey[900]!.withOpacity(0.95),
                ],
              ),
            ),
          ),

          // 进度条填充
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.9),
                      color,
                      color.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 标签和数值 - 增大字体，提高可读性
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 属性标签
                Text(
                  label,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12 : 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),

                // 数值
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12 : 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxValueForAttribute(String label) {
    switch (label) {
      case '金币':
        return 100.0;
      case '生命':
        return 100.0;
      case '精神':
        return 250.0;
      case '速度':
        return 200.0;
      case '饱食':
        return 30.0;
      default:
        return 100.0;
    }
  }

  // 构建初始携带物品显示
  Widget _buildInitialItems() {
    // 获取角色初始物品列表
    final initialItems =
        widget.character['initialItems'] as List<String>? ?? [];

    if (initialItems.isEmpty) {
      return const SizedBox.shrink(); // 如果没有初始物品，不显示任何内容
    }

    // 获取所有物品数据
    final allItems = _getAllItems();

    // 根据初始物品ID获取对应的物品对象
    final items =
        initialItems.map((itemId) {
          return allItems.firstWhere(
            (item) => item.id == itemId,
            orElse:
                () => Item(
                  id: itemId,
                  name: '未知物品',
                  image: 'images/items/1.png',
                  description: '物品信息缺失',
                  type: 'item',
                ),
          );
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '初始携带物品',
          style: TextStyle(
            fontSize: widget.isCompact ? 10 : 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),

        // 物品水平滚动列表
        Container(
          height: widget.isCompact ? 50 : 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: widget.isCompact ? 45 : 55,
                margin: const EdgeInsets.only(right: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 物品图片
                    Container(
                      width: widget.isCompact ? 35 : 40,
                      height: widget.isCompact ? 35 : 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade800,
                              child: Icon(
                                Icons.question_mark,
                                color: Colors.white,
                                size: widget.isCompact ? 16 : 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // 物品名称（简化显示）
                    Text(
                      item.name.length > 4
                          ? '${item.name.substring(0, 4)}...'
                          : item.name,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 7 : 8,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 获取所有物品数据（简化实现）
  List<Item> _getAllItems() {
    // 这里应该从实际的物品数据源获取，暂时返回一些示例物品
    return [
      Item(
        id: 'hanbao',
        name: '美去人通便汉堡',
        image: 'images/items/hanbao.png',
        description: '钻研肠胃科主任为何把最灵的药藏在这里',
        type: 'item',
      ),
      Item(
        id: 'm-three-armor_fangdan',
        name: '三级防弹衣',
        image: 'images/items/m-three-fangdan.png',
        description: '高级防弹装备',
        type: 'equipment',
      ),
      Item(
        id: 'wine',
        name: '酒',
        image: 'images/items/wine.png',
        description: '恢复精神',
        type: 'item',
      ),
      Item(
        id: 'speed_gloves',
        name: '速度手套',
        image: 'images/items/speedGloves.png',
        description: '增加移动速度',
        type: 'equipment',
      ),
      Item(
        id: 'g-eteen-gun',
        name: 'G-eteen枪',
        image: 'images/items/g-eteen-gun.png',
        description: '强力武器',
        type: 'equipment',
      ),
      Item(
        id: 'm-one-gun',
        name: 'M-one枪',
        image: 'images/items/m-one-gun.png',
        description: '标准武器',
        type: 'equipment',
      ),
      Item(
        id: 'bow',
        name: '弓',
        image: 'images/items/bow.png',
        description: '远程武器',
        type: 'equipment',
      ),
      Item(
        id: 'g-eteen-ultra-gun',
        name: 'G-eteen超强枪',
        image: 'images/items/g-eteen-gun.png',
        description: '超强力武器',
        type: 'equipment',
      ),
    ];
  }
}

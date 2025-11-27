import 'package:flutter/material.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/game/catalog_detail_page.dart';
import 'package:escape_from_school/game/fan_carousel.dart';
import 'package:escape_from_school/utils/level_color_manager.dart';

/// 图鉴页面：展示 props.dart 中所有物品，支持按等级与类型筛选，并详细显示物品数据
///
/// 主要功能和使用方法：
/// 1. 搜索功能：顶部搜索框支持按物品名称或描述筛选，输入内容时会自动重置选中索引
/// 2. 类型筛选：左侧扇形轮盘提供「全部」、「物品」、「装备」三种筛选选项
/// 3. 等级筛选：右侧扇形轮盘提供 1-7 级物品筛选选项
/// 4. 卡片轮播：中间区域使用扇形轮播展示筛选后的物品卡片
///
/// 内部键说明：
/// - searchQuery: 搜索框内容
/// - _currentIndex: 当前选中的物品索引
/// - _selectedType: 选中的物品类型筛选条件
/// - _selectedLevel: 选中的物品等级筛选条件
/// - searchQuery：当前搜索框的输入内容
/// - _currentIndex：当前高亮显示的卡片索引，用于同步轮播页面位置
/// - filteredItems：根据筛选条件过滤后的物品列表

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  int? _selectedLevel; // null 表示全部
  String? _selectedType; // null 表示全部
  String searchQuery = '';
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Item> items = allItems;
    final List<Item> filtered =
        items.where((it) {
          final bool levelMatch =
              _selectedLevel == null ? true : (it.level == _selectedLevel);
          final String typeCat = _canonicalType(it.type);
          final bool typeMatch =
              _selectedType == null ? true : (typeCat == _selectedType);
          final String q = searchQuery.trim();
          final bool searchMatch =
              q.isEmpty
                  ? true
                  : (it.name.contains(q) || it.description.contains(q));
          return levelMatch && typeMatch && searchMatch;
        }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/background_1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.35),
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.55),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 主布局
          Column(
            children: [
              // 顶部：搜索筛选和返回按钮
              _buildTopBar(),

              // 中间：左右扇形轮盘筛选
              Expanded(
                child: Row(
                  children: [
                    // 左边：一级筛选类型扇形轮盘
                    SizedBox(
                      width: 80, // 缩小宽度
                      child: _buildTypeFanFilter(),
                    ),

                    // 中间：卡片轮播展示区域
                    Expanded(flex: 1, child: _buildCardCarousel(filtered)),

                    // 右边：二级筛选等级扇形轮盘
                    SizedBox(
                      width: 80, // 缩小宽度
                      child: _buildLevelFanFilter(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 顶部栏：搜索筛选和返回按钮
  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(0, 0, 0, 0.8), Color.fromRGBO(0, 0, 0, 0.4)],
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
          const SizedBox(width: 12),
          // 搜索框 - 美化样式
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2D3748), const Color(0xFF1A202C)],
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Color.fromRGBO(255, 255, 255, 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: TextField(
                onChanged:
                    (v) => setState(() {
                      searchQuery = v;
                      _currentIndex = 0; // 切换筛选时重置选中索引
                    }),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '搜索物品名称或描述...',
                  hintStyle: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white70,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 左边：一级筛选类型扇形轮盘
  Widget _buildTypeFanFilter() {
    final List<String> typeOptions = ['全部', '物品', '装备'];
    return FanFilter(
      options: typeOptions,
      selectedIndex:
          _selectedType == null ? 0 : (typeOptions.indexOf(_selectedType!)),
      onOptionSelected: (index) {
        setState(() {
          _selectedType = index == 0 ? null : typeOptions[index];
          _currentIndex = 0; // 切换筛选时重置选中索引
        });
      },
      isLeftSide: true, // 左侧轮盘
    );
  }

  // 右边：二级筛选等级扇形轮盘
  Widget _buildLevelFanFilter() {
    final List<String> levelOptions = ['全部', '1', '2', '3', '4', '5', '6', '7'];
    return FanFilter(
      options: levelOptions,
      selectedIndex:
          _selectedLevel == null
              ? 0
              : (levelOptions.indexOf(_selectedLevel!.toString())),
      onOptionSelected: (index) {
        setState(() {
          _selectedLevel = index == 0 ? null : int.parse(levelOptions[index]);
          _currentIndex = 0; // 切换筛选时重置选中索引
        });
      },
      isLeftSide: false, // 右侧轮盘
    );
  }

  // 中间：卡片轮播展示区域
  Widget _buildCardCarousel(List<Item> filteredItems) {
    return Expanded(
      flex: 3,
      child: FanCarousel(
        initialPage: _currentIndex,
        items:
            filteredItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CatalogDetailPage(
                            selectedItem: item,
                            allItems: allItems,
                          ),
                    ),
                  );
                },
                child: _buildItemCard(
                  item,
                  isHighlighted: index == _currentIndex,
                ),
              );
            }).toList(),
        onItemChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildItemCard(Item item, {bool isHighlighted = false}) {
    final levelColor = _getItemLevelColor(item.level);
    final typeCat = _canonicalType(item.type);
    final Map<String, int> eff = item.effects;
    final Map<String, dynamic> wp = item.weaponParams ?? const {};
    final String atkTypeStr = (wp['attackType'] ?? '').toString();
    final bool isRanged = atkTypeStr == 'ranged' || atkTypeStr == '远程';
    final int intervalMs = ((wp['fireIntervalMs'] ?? 0) as num).toInt();
    final int roundsPerSecond = intervalMs > 0 ? (1000 / intervalMs).ceil() : 0;
    final bool isWeapon =
        item.type == 'equipment' &&
        item.weaponParams != null &&
        item.weaponParams!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isHighlighted ? 280 : 240,
      height: isHighlighted ? 380 : 340,
      decoration: BoxDecoration(
        // 根据等级颜色的渐变背景
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isHighlighted
                  ? [
                    // 融合等级颜色的深色渐变
                    Color.fromRGBO(
                      (levelColor.r.toInt() * 0.3 + 45).toInt(),
                      (levelColor.g.toInt() * 0.3 + 55).toInt(),
                      (levelColor.b.toInt() * 0.3 + 72).toInt(),
                      0.95,
                    ),
                    const Color.fromRGBO(26, 32, 44, 0.95),
                  ]
                  : [
                    // 融合等级颜色的深色渐变
                    Color.fromRGBO(
                      (levelColor.r.toInt() * 0.2 + 26).toInt(),
                      (levelColor.g.toInt() * 0.2 + 32).toInt(),
                      (levelColor.b.toInt() * 0.2 + 44).toInt(),
                      0.8,
                    ),
                    const Color.fromRGBO(13, 17, 23, 0.8),
                  ],
        ),
        borderRadius: BorderRadius.circular(6),
        // 立体边框效果
        border: Border.all(
          color:
              isHighlighted
                  ? Color.fromRGBO(
                    levelColor.r.toInt(),
                    levelColor.g.toInt(),
                    levelColor.b.toInt(),
                    0.8,
                  )
                  : Color.fromRGBO(158, 158, 158, 0.4),
          width: isHighlighted ? 2.5 : 1.5,
        ),
        // 增强的阴影效果
        boxShadow: [
          if (isHighlighted)
            BoxShadow(
              color: Color.fromRGBO(
                levelColor.r.toInt(),
                levelColor.g.toInt(),
                levelColor.b.toInt(),
                0.6,
              ),
              blurRadius: 20,
              spreadRadius: 3,
              offset: const Offset(0, 5),
            ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.9),
            blurRadius: 15,
            spreadRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 顶部高光效果
          if (isHighlighted)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(
                        levelColor.r.toInt(),
                        levelColor.g.toInt(),
                        levelColor.b.toInt(),
                        0.3,
                      ),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 物品图标和基本信息
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Color.fromRGBO(
                            levelColor.r.toInt(),
                            levelColor.g.toInt(),
                            levelColor.b.toInt(),
                            1.0,
                          ),
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child:
                            item.image.isNotEmpty
                                ? Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (c, e, s) => Icon(
                                        Icons.inventory_2,
                                        color: levelColor,
                                        size: 24,
                                      ),
                                )
                                : Icon(
                                  Icons.inventory_2,
                                  color: levelColor,
                                  size: 24,
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: levelColor,
                              fontSize: isHighlighted ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 3,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '等级: ${item.level} · 类型: ${_canonicalType(item.type)}${item.equipmentSlot != null ? ' · 槽位: ${_getSlotChineseName(item.equipmentSlot!)}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color.fromRGBO(0, 255, 255, 0.9),
                              fontSize: isHighlighted ? 12 : 11,
                            ),
                          ),
                          if (item.usageTime > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '使用时间: ${(item.usageTime / 1000).toStringAsFixed(1)}秒',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.amberAccent.withOpacity(0.9),
                                fontSize: isHighlighted ? 11 : 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 物品描述
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: isHighlighted ? 13 : 12,
                    ),
                  ),

                const SizedBox(height: 12),

                // 物品效果详情
                Expanded(
                  child:
                      isWeapon
                          ? Row(
                            children: [
                              Expanded(
                                child: _buildLeftDetails(
                                  eff,
                                  wp,
                                  isRanged,
                                  roundsPerSecond,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRightDetails(eff, wp, isRanged),
                              ),
                            ],
                          )
                          : eff.isNotEmpty
                          ? _buildEffectsOnly(eff)
                          : Center(
                            child: Text(
                              '无特殊效果',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: isHighlighted ? 14 : 12,
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

  Widget _buildLeftDetails(
    Map<String, int> eff,
    Map<String, dynamic> wp,
    bool isRanged,
    int rps,
  ) {
    final double distance = ((wp['distance'] ?? 0) as num).toDouble();
    final double rangeVal = ((wp['range'] ?? 0) as num).toDouble();
    final double dmgAmp = ((wp['damageAmplify'] ?? 1.0) as num).toDouble();
    final double critDmg = ((wp['critDamage'] ?? 1.5) as num).toDouble();
    final double critChance =
        ((wp['critChanceBonus'] ?? 0.0) as num).toDouble();
    final List<Map<String, String>> left = [
      {'k': '攻击类型', 'v': isRanged ? '远程' : '近战'},
      {'k': '距离', 'v': '${distance.toStringAsFixed(1)} 米'},
      {
        'k': isRanged ? '子弹速度' : '弧度',
        'v':
            isRanged
                ? '${rangeVal.toStringAsFixed(1)} 米/秒'
                : rangeVal.toStringAsFixed(1),
      },
      if (isRanged && rps > 0) {'k': '射速', 'v': '$rps 发/秒'},
      {'k': '增幅伤害', 'v': '${dmgAmp.toStringAsFixed(2)} 倍'},
      {'k': '暴击伤害', 'v': '${critDmg.toStringAsFixed(2)} 倍'},
      {'k': '暴击几率加成', 'v': '${(critChance * 100).toStringAsFixed(0)}%'},
    ];
    return _pairsColumn(left);
  }

  Widget _buildRightDetails(
    Map<String, int> eff,
    Map<String, dynamic> wp,
    bool isRanged,
  ) {
    final int magazineSize = ((wp['magazineSize'] ?? 0) as num).toInt();
    final int ammoTotal = ((wp['ammoTotal'] ?? 0) as num).toInt();
    final String fireMode = (wp['fireMode'] ?? '').toString();
    final int reloadMs = ((wp['reloadMs'] ?? 0) as num).toInt();
    final bool wall = (wp['penetrateWalls'] ?? false) == true;
    final bool ghost = (wp['penetrateGhosts'] ?? false) == true;
    final List<Map<String, String>> right = [
      if (fireMode.isNotEmpty)
        {'k': '开火模式', 'v': fireMode == 'fullauto' ? '全自动' : '半自动'},
      if (reloadMs > 0) {'k': '换弹时间', 'v': '${reloadMs}ms'},
      if (isRanged && magazineSize > 0) {'k': '弹夹容量', 'v': '$magazineSize'},
      if (isRanged && ammoTotal > 0) {'k': '备用弹药', 'v': '$ammoTotal'},
      {'k': '穿墙', 'v': wall ? '是' : '否'},
      {'k': '穿鬼', 'v': ghost ? '是' : '否'},
    ];
    // 附加 effects（展示核心效果）
    eff.forEach((k, v) {
      right.add({'k': _effectName(k), 'v': v.toString()});
    });
    return _pairsColumn(right);
  }

  Widget _pairsColumn(List<Map<String, String>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      Text(
                        '${e['k']}:',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          e['v'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildEffectsOnly(Map<String, int> eff) {
    final List<Map<String, String>> effects = [];
    eff.forEach((k, v) {
      effects.add({'k': _effectName(k), 'v': v.toString()});
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '效果:',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        ...effects.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text(
                  '${e['k']}:',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    e['v'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _canonicalType(String t) {
    final s = t.toLowerCase();
    if (s == 'item' || t == '物品') return '物品';
    return '装备';
  }

  String _getSlotChineseName(String slot) {
    switch (slot) {
      case 'weapon':
        return '武器';
      case 'armor':
        return '护甲';
      case 'head':
        return '头部';
      case 'bag':
        return '背部';
      case 'pants':
        return '裤子';
      case 'shoes':
        return '鞋子';
      default:
        return slot;
    }
  }

  Color _getItemLevelColor(int level) {
    return LevelColorManager.getItemLevelColor(level);
  }

  String _effectName(String key) {
    switch (key) {
      case 'hp':
        return '生命值';
      case 'maxHp':
        return '最大生命值';
      case 'food':
        return '饱食度';
      case 'maxFood':
        return '最大饱食度';
      case 'san':
        return '理智值';
      case 'moveSpeed':
        return '移动速度';
      case 'gold':
        return '资产';
      case 'oxygenBonus':
        return '肺活量';
      case 'inventoryBonus':
        return '背包容量';
      case 'punish':
        return '处分';
      case 'armorValue':
        return '耐久';
      case 'baseDamage':
        return '基础伤害';
      default:
        return key;
    }
  }
}

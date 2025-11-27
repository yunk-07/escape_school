// game/catalog_compare_page.dart
// 作用：图鉴对比页面，展示两个选中物品的详细数据用于横向对比

import 'package:flutter/material.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/utils/level_color_manager.dart';

class CatalogComparePage extends StatelessWidget {
  final Item a;
  final Item b;

  const CatalogComparePage({super.key, required this.a, required this.b});

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromRGBO(0, 0, 0, 0.8),
            const Color.fromRGBO(0, 0, 0, 0.4),
          ],
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color.fromRGBO(255, 255, 255, 0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 16,
            top: 12,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(255, 255, 255, 0.2),
                      const Color.fromRGBO(255, 255, 255, 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.4),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                      blurRadius: 4,
                      offset: Offset(0, 2),
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
          ),
          // 标题
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromRGBO(255, 255, 255, 0.1),
                    const Color.fromRGBO(255, 255, 255, 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.3),
                  width: 1.0,
                ),
              ),
              child: Text(
                '物品对比',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 主布局
          Column(
            children: [
              // 顶部：自定义标题栏
              _buildTopBar(context),

              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: _itemPanel(a)),
                      const SizedBox(width: 12),
                      Expanded(child: _itemPanel(b)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemPanel(Item item) {
    final levelColor = _getItemLevelColor(item.level);
    final Map<String, dynamic> wp = item.weaponParams ?? const {};
    final Map<String, int> eff = item.effects;
    final String atkTypeStr = (wp['attackType'] ?? '').toString();
    final bool isRanged = atkTypeStr == 'ranged' || atkTypeStr == '远程';
    final int intervalMs = ((wp['fireIntervalMs'] ?? 0) as num).toInt();
    final int roundsPerSecond = intervalMs > 0 ? (1000 / intervalMs).ceil() : 0;

    // 判断是否为武器：type为'equipment'且weaponParams不为空
    final bool isWeapon = item.type == 'equipment' && wp.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(
              (levelColor.r.toInt() * 0.2 + 26).toInt(),
              (levelColor.g.toInt() * 0.2 + 32).toInt(),
              (levelColor.b.toInt() * 0.2 + 44).toInt(),
              0.8,
            ),
            const Color.fromRGBO(13, 17, 23, 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: levelColor.withOpacity(1.0), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              levelColor.r.toInt(),
              levelColor.g.toInt(),
              levelColor.b.toInt(),
              0.4,
            ),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.8),
            blurRadius: 12,
            spreadRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: levelColor.withOpacity(1.0),
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '等级: ${item.level} · 类型: ${_canonicalType(item.type)}${item.equipmentSlot != null ? ' · 槽位: ${_getSlotChineseName(item.equipmentSlot!)}' : ''}',
                        style: TextStyle(
                          color: Colors.cyanAccent.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  isWeapon
                      ? Row(
                        children: [
                          Expanded(
                            child: _leftDetails(wp, isRanged, roundsPerSecond),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _rightDetails(eff, wp, isRanged)),
                        ],
                      )
                      : _buildItemEffects(eff, item == a),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftDetails(Map<String, dynamic> wp, bool isRanged, int rps) {
    final double distance = ((wp['distance'] ?? 0) as num).toDouble();
    final double rangeVal = ((wp['range'] ?? 0) as num).toDouble();
    final double dmgAmp = ((wp['damageAmplify'] ?? 1.0) as num).toDouble();
    final double critDmg = ((wp['critDamage'] ?? 1.5) as num).toDouble();
    final double critChance =
        ((wp['critChanceBonus'] ?? 0.0) as num).toDouble();
    final entries = <Map<String, String>>[
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
    return _pairs(entries, isLeftPanel: true);
  }

  Widget _rightDetails(
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
    final entries = <Map<String, String>>[
      if (fireMode.isNotEmpty)
        {'k': '开火模式', 'v': fireMode == 'fullauto' ? '全自动' : '半自动'},
      if (reloadMs > 0) {'k': '换弹时间', 'v': '${reloadMs}ms'},
      if (isRanged && magazineSize > 0) {'k': '弹夹容量', 'v': '$magazineSize'},
      if (isRanged && ammoTotal > 0) {'k': '备用弹药', 'v': '$ammoTotal'},
      {'k': '穿墙', 'v': wall ? '是' : '否'},
      {'k': '穿鬼', 'v': ghost ? '是' : '否'},
    ];
    eff.forEach(
      (k, v) => entries.add({'k': _effectName(k), 'v': v.toString()}),
    );
    return _pairs(entries, isLeftPanel: false);
  }

  Widget _pairs(List<Map<String, String>> entries, {bool isLeftPanel = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${e['k']}:',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 智能对比标注 - 现在双方都会显示对比状态
                      _buildComparisonValue(e['k']!, e['v']!, isLeftPanel),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  // 构建带对比标注的值显示
  Widget _buildComparisonValue(String key, String value, bool isLeftPanel) {
    // 获取对方物品的对应值
    final otherValue = _getOtherValue(key, isLeftPanel);

    // 判断对比状态
    final bool hasOtherValue = otherValue.isNotEmpty;
    final bool isDifferent = value != otherValue;
    final bool isUnique = !hasOtherValue;

    // 特殊属性处理：越小越好或特定值更好
    final bool isSpecialCaseBetter = _isSpecialCaseBetter(
      key,
      value,
      otherValue,
    );
    final bool isSpecialCaseWorse = _isSpecialCaseWorse(key, value, otherValue);

    // 对于数值型属性，进行精确对比
    final bool isHigher =
        hasOtherValue &&
        !_isSmallerBetter(key) &&
        _isNumericValueHigher(value, otherValue);
    final bool isLower =
        hasOtherValue &&
        !_isSmallerBetter(key) &&
        _isNumericValueLower(value, otherValue);

    // 对于布尔型属性（是/否），"是"比"否"更好
    final bool isBooleanBetter =
        hasOtherValue && (value == '是' && otherValue == '否');
    final bool isBooleanWorse =
        hasOtherValue && (value == '否' && otherValue == '是');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color:
                isUnique
                    ? Colors.yellow.withOpacity(0.3)
                    : isDifferent
                    ? (isHigher || isBooleanBetter || isSpecialCaseBetter
                        ? Colors.green.withOpacity(0.3)
                        : isLower || isBooleanWorse || isSpecialCaseWorse
                        ? Colors.red.withOpacity(0.3)
                        : Colors.transparent)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color:
                  isUnique
                      ? Colors.yellowAccent
                      : isDifferent
                      ? (isHigher || isBooleanBetter || isSpecialCaseBetter
                          ? Colors.greenAccent
                          : isLower || isBooleanWorse || isSpecialCaseWorse
                          ? Colors.redAccent
                          : Colors.transparent)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color:
                  isUnique
                      ? Colors.yellowAccent
                      : isDifferent
                      ? (isHigher || isBooleanBetter || isSpecialCaseBetter
                          ? Colors.greenAccent
                          : isLower || isBooleanWorse || isSpecialCaseWorse
                          ? Colors.redAccent
                          : Colors.white)
                      : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // 获取对方物品的对应值
  String _getOtherValue(String key, bool isLeftPanel) {
    final otherItem = isLeftPanel ? b : a;
    final otherWp = otherItem.weaponParams ?? const {};
    final otherEff = otherItem.effects;

    String otherValue = '';

    // 根据key查找对应的值
    switch (key) {
      case '攻击类型':
        final otherAtkTypeStr = (otherWp['attackType'] ?? '').toString();
        final otherIsRanged =
            otherAtkTypeStr == 'ranged' || otherAtkTypeStr == '远程';
        otherValue = otherIsRanged ? '远程' : '近战';
        break;
      case '距离':
        final otherDistance = ((otherWp['distance'] ?? 0) as num).toDouble();
        otherValue = '${otherDistance.toStringAsFixed(1)} 米';
        break;
      case '子弹速度':
      case '弧度':
        final otherRangeVal = ((otherWp['range'] ?? 0) as num).toDouble();
        final otherAtkTypeStr = (otherWp['attackType'] ?? '').toString();
        final otherIsRanged =
            otherAtkTypeStr == 'ranged' || otherAtkTypeStr == '远程';
        otherValue =
            otherIsRanged
                ? '${otherRangeVal.toStringAsFixed(1)} 米/秒'
                : otherRangeVal.toStringAsFixed(1);
        break;
      case '射速':
        final otherIntervalMs =
            ((otherWp['fireIntervalMs'] ?? 0) as num).toInt();
        final otherRps =
            otherIntervalMs > 0 ? (1000 / otherIntervalMs).ceil() : 0;
        otherValue = '$otherRps 发/秒';
        break;
      case '增幅伤害':
        final otherDmgAmp =
            ((otherWp['damageAmplify'] ?? 1.0) as num).toDouble();
        otherValue = '${otherDmgAmp.toStringAsFixed(2)} 倍';
        break;
      case '暴击伤害':
        final otherCritDmg = ((otherWp['critDamage'] ?? 1.5) as num).toDouble();
        otherValue = '${otherCritDmg.toStringAsFixed(2)} 倍';
        break;
      case '暴击几率加成':
        final otherCritChance =
            ((otherWp['critChanceBonus'] ?? 0.0) as num).toDouble();
        otherValue = '${(otherCritChance * 100).toStringAsFixed(0)}%';
        break;
      case '开火模式':
        final otherFireMode = (otherWp['fireMode'] ?? '').toString();
        otherValue = otherFireMode == 'fullauto' ? '全自动' : '半自动';
        break;
      case '换弹时间':
        final otherReloadMs = ((otherWp['reloadMs'] ?? 0) as num).toInt();
        otherValue = otherReloadMs > 0 ? '${otherReloadMs}秒' : '';
        break;
      case '弹夹容量':
        final otherMagazineSize =
            ((otherWp['magazineSize'] ?? 0) as num).toInt();
        otherValue = otherMagazineSize > 0 ? '$otherMagazineSize' : '';
        break;
      case '备用弹药':
        final otherAmmoTotal = ((otherWp['ammoTotal'] ?? 0) as num).toInt();
        otherValue = otherAmmoTotal > 0 ? '$otherAmmoTotal' : '';
        break;
      case '穿墙':
        final otherWall = (otherWp['penetrateWalls'] ?? false) == true;
        otherValue = otherWall ? '是' : '否';
        break;
      case '穿鬼':
        final otherGhost = (otherWp['penetrateGhosts'] ?? false) == true;
        otherValue = otherGhost ? '是' : '否';
        break;
      case '使用时间':
        // 处理使用时间对比
        if (otherItem.usageTime > 0) {
          otherValue = '${(otherItem.usageTime / 1000).toStringAsFixed(1)}秒';
        }
        break;
      default:
        // 处理效果属性
        final effectKey = _getEffectKeyFromName(key);
        if (effectKey.isNotEmpty) {
          otherValue = otherEff[effectKey]?.toString() ?? '';
        }
        break;
    }

    return otherValue;
  }

  // 判断数值是否更高（仅对数值型属性）
  bool _isNumericValueHigher(String value1, String value2) {
    try {
      final num1 = _extractNumericValue(value1);
      final num2 = _extractNumericValue(value2);
      return num1 > num2;
    } catch (e) {
      return false;
    }
  }

  // 判断数值是否更低（仅对数值型属性）
  bool _isNumericValueLower(String value1, String value2) {
    try {
      final num1 = _extractNumericValue(value1);
      final num2 = _extractNumericValue(value2);
      return num1 < num2;
    } catch (e) {
      return false;
    }
  }

  // 从字符串中提取数值（处理带单位的数值）
  double _extractNumericValue(String value) {
    // 移除中文单位并提取数字
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // 判断是否为越小越好的属性
  bool _isSmallerBetter(String key) {
    return key == '使用时间' || key == '换弹时间' || key == '处分';
  }

  // 判断特殊属性是否更好
  bool _isSpecialCaseBetter(String key, String value, String otherValue) {
    // 对于越小越好的属性，数值越小越好
    if (_isSmallerBetter(key)) {
      try {
        final num1 = _extractNumericValue(value);
        final num2 = _extractNumericValue(otherValue);
        return num1 < num2;
      } catch (e) {
        return false;
      }
    }

    // 特定值的对比
    switch (key) {
      case '攻击类型':
        return value == '远程' && otherValue == '近战';
      case '开火模式':
        return value == '全自动' && otherValue == '半自动';
      case '穿墙':
        return value == '是' && otherValue == '否';
      case '穿鬼':
        return value == '是' && otherValue == '否';
      default:
        return false;
    }
  }

  // 判断特殊属性是否更差
  bool _isSpecialCaseWorse(String key, String value, String otherValue) {
    // 对于越小越好的属性，数值越大越差
    if (_isSmallerBetter(key)) {
      try {
        final num1 = _extractNumericValue(value);
        final num2 = _extractNumericValue(otherValue);
        return num1 > num2;
      } catch (e) {
        return false;
      }
    }

    // 特定值的对比
    switch (key) {
      case '攻击类型':
        return value == '近战' && otherValue == '远程';
      case '开火模式':
        return value == '半自动' && otherValue == '全自动';
      case '穿墙':
        return value == '否' && otherValue == '是';
      case '穿鬼':
        return value == '否' && otherValue == '是';
      default:
        return false;
    }
  }

  // 从显示名称获取效果键名
  String _getEffectKeyFromName(String displayName) {
    switch (displayName) {
      case '生命值':
        return 'hp';
      case '最大生命值':
        return 'maxHp';
      case '饱食度':
        return 'food';
      case '最大饱食度':
        return 'maxFood';
      case '理智值':
        return 'san';
      case '移动速度':
        return 'moveSpeed';
      case '资产':
        return 'gold';
      case '肺活量':
        return 'oxygenBonus';
      case '背包容量':
        return 'inventoryBonus';
      case '处分':
        return 'punish';
      case '耐久':
        return 'armorValue';
      case '基础伤害':
        return 'baseDamage';
      default:
        return '';
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

  // 构建物品效果显示（带对比标注）
  Widget _buildItemEffects(Map<String, int> eff, bool isLeftPanel) {
    // 创建效果列表，包含物品效果和使用时间
    final List<Map<String, String>> entries = [];

    // 添加物品效果
    eff.forEach(
      (k, v) => entries.add({'k': _effectName(k), 'v': v.toString()}),
    );

    // 添加使用时间（如果大于0）
    final currentItem = isLeftPanel ? a : b;
    if (currentItem.usageTime > 0) {
      entries.add({
        'k': '使用时间',
        'v': '${(currentItem.usageTime / 1000).toStringAsFixed(1)}秒',
      });
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          '物品详情',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return _pairs(entries, isLeftPanel: isLeftPanel);
  }
}

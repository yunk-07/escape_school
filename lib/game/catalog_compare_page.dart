// game/catalog_compare_page.dart
// 作用：图鉴对比页面，展示两个选中物品的详细数据用于横向对比

import 'package:flutter/material.dart';
import 'package:escape_from_school/data/props.dart';

class CatalogComparePage extends StatelessWidget {
  final Item a;
  final Item b;

  const CatalogComparePage({super.key, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品对比'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _itemPanel(a)),
                const SizedBox(width: 12),
                Expanded(child: _itemPanel(b)),
              ],
            ),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.35),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: levelColor.withOpacity(0.55), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 6)),
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
                    border: Border.all(color: levelColor.withOpacity(0.85), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: item.image.isNotEmpty
                        ? Image.asset(
                            item.image,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: levelColor, size: 24),
                          )
                        : Icon(Icons.inventory_2, color: levelColor, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: levelColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (item.description.isNotEmpty)
                        Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _leftDetails(wp, isRanged, roundsPerSecond)),
                  const SizedBox(width: 8),
                  Expanded(child: _rightDetails(eff, wp, isRanged)),
                ],
              ),
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
    final double critChance = ((wp['critChanceBonus'] ?? 0.0) as num).toDouble();
    final entries = <Map<String, String>>[
      {'k': '攻击类型', 'v': isRanged ? '远程' : '近战'},
      {'k': '距离', 'v': '${distance.toStringAsFixed(1)} 格'},
      {'k': isRanged ? '子弹速度' : '弧度', 'v': isRanged ? '${rangeVal.toStringAsFixed(1)} 格/秒' : rangeVal.toStringAsFixed(1)},
      if (isRanged && rps > 0) {'k': '射速', 'v': '$rps 发/秒'},
      {'k': '增幅伤害', 'v': '${dmgAmp.toStringAsFixed(2)} 倍'},
      {'k': '暴击伤害', 'v': '${critDmg.toStringAsFixed(2)} 倍'},
      {'k': '暴击几率加成', 'v': '${(critChance * 100).toStringAsFixed(0)}%'},
    ];
    return _pairs(entries, isLeftPanel: true);
  }

  Widget _rightDetails(Map<String, int> eff, Map<String, dynamic> wp, bool isRanged) {
    final int magazineSize = ((wp['magazineSize'] ?? 0) as num).toInt();
    final int ammoTotal = ((wp['ammoTotal'] ?? 0) as num).toInt();
    final String fireMode = (wp['fireMode'] ?? '').toString();
    final int reloadMs = ((wp['reloadMs'] ?? 0) as num).toInt();
    final bool wall = (wp['penetrateWalls'] ?? false) == true;
    final bool ghost = (wp['penetrateGhosts'] ?? false) == true;
    final entries = <Map<String, String>>[
      if (fireMode.isNotEmpty) {'k': '开火模式', 'v': fireMode},
      if (reloadMs > 0) {'k': '换弹时间', 'v': '${reloadMs}ms'},
      if (isRanged && magazineSize > 0) {'k': '弹夹容量', 'v': '$magazineSize'},
      if (isRanged && ammoTotal > 0) {'k': '备用弹药', 'v': '$ammoTotal'},
      {'k': '穿墙', 'v': wall ? '是' : '否'},
      {'k': '穿鬼', 'v': ghost ? '是' : '否'},
    ];
    eff.forEach((k, v) => entries.add({'k': _effectName(k), 'v': v.toString()}));
    return _pairs(entries, isLeftPanel: false);
  }

  Widget _pairs(List<Map<String, String>> entries, {bool isLeftPanel = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e['k']}:', style: TextStyle(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(e['v'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(
                        color: _isDifferentValue(e['k']!, e['v']!, isLeftPanel) ? Colors.yellowAccent : Colors.white,
                        fontSize: 12, 
                        fontWeight: FontWeight.w700,
                        backgroundColor: _isDifferentValue(e['k']!, e['v']!, isLeftPanel) ? Colors.red.withOpacity(0.3) : Colors.transparent,
                      )),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // 检查是否为不同值
  bool _isDifferentValue(String key, String value, bool isLeftPanel) {
    // 获取另一个物品的对应值
    final otherItem = isLeftPanel ? b : a;
    final otherWp = otherItem.weaponParams ?? const {};
    final otherEff = otherItem.effects;
    
    String otherValue = '';
    
    // 根据key查找对应的值
    switch (key) {
      case '攻击类型':
        final otherAtkTypeStr = (otherWp['attackType'] ?? '').toString();
        final otherIsRanged = otherAtkTypeStr == 'ranged' || otherAtkTypeStr == '远程';
        otherValue = otherIsRanged ? '远程' : '近战';
        break;
      case '距离':
        final otherDistance = ((otherWp['distance'] ?? 0) as num).toDouble();
        otherValue = '${otherDistance.toStringAsFixed(1)} 格';
        break;
      case '子弹速度':
      case '弧度':
        final otherRangeVal = ((otherWp['range'] ?? 0) as num).toDouble();
        final otherAtkTypeStr = (otherWp['attackType'] ?? '').toString();
        final otherIsRanged = otherAtkTypeStr == 'ranged' || otherAtkTypeStr == '远程';
        otherValue = otherIsRanged ? '${otherRangeVal.toStringAsFixed(1)} 格/秒' : otherRangeVal.toStringAsFixed(1);
        break;
      case '射速':
        final otherIntervalMs = ((otherWp['fireIntervalMs'] ?? 0) as num).toInt();
        final otherRps = otherIntervalMs > 0 ? (1000 / otherIntervalMs).ceil() : 0;
        otherValue = '$otherRps 发/秒';
        break;
      case '增幅伤害':
        final otherDmgAmp = ((otherWp['damageAmplify'] ?? 1.0) as num).toDouble();
        otherValue = '${otherDmgAmp.toStringAsFixed(2)} 倍';
        break;
      case '暴击伤害':
        final otherCritDmg = ((otherWp['critDamage'] ?? 1.5) as num).toDouble();
        otherValue = '${otherCritDmg.toStringAsFixed(2)} 倍';
        break;
      case '暴击几率加成':
        final otherCritChance = ((otherWp['critChanceBonus'] ?? 0.0) as num).toDouble();
        otherValue = '${(otherCritChance * 100).toStringAsFixed(0)}%';
        break;
      case '开火模式':
        otherValue = (otherWp['fireMode'] ?? '').toString();
        break;
      case '换弹时间':
        final otherReloadMs = ((otherWp['reloadMs'] ?? 0) as num).toInt();
        otherValue = otherReloadMs > 0 ? '${otherReloadMs}ms' : '';
        break;
      case '弹夹容量':
        final otherMagazineSize = ((otherWp['magazineSize'] ?? 0) as num).toInt();
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
      default:
        // 处理效果属性
        final effectKey = _getEffectKeyFromName(key);
        if (effectKey.isNotEmpty) {
          otherValue = otherEff[effectKey]?.toString() ?? '';
        }
        break;
    }
    
    return value != otherValue;
  }
  
  // 从显示名称获取效果键名
  String _getEffectKeyFromName(String displayName) {
    switch (displayName) {
      case '生命值': return 'hp';
      case '最大生命值': return 'maxHp';
      case '饱食度': return 'food';
      case '最大饱食度': return 'maxFood';
      case '理智值': return 'san';
      case '移动速度': return 'moveSpeed';
      case '资产': return 'gold';
      case '肺活量': return 'oxygenBonus';
      case '背包容量': return 'inventoryBonus';
      case '处分': return 'punish';
      case '耐久': return 'armorValue';
      case '基础伤害': return 'baseDamage';
      default: return '';
    }
  }

  Color _getItemLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.white;
      case 2:
        return Colors.greenAccent;
      case 3:
        return Colors.blueAccent;
      case 4:
        return Colors.purpleAccent;
      case 5:
        return Colors.amberAccent;
      case 6:
        return Colors.redAccent;
      case 7:
        return Colors.cyanAccent;
      default:
        return Colors.white;
    }
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
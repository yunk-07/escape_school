// game/catalog_page.dart
// 图鉴页面：展示 props.dart 中所有物品，支持按等级与类型筛选，并详细显示物品数据

import 'package:flutter/material.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/game/catalog_compare_page.dart';
import 'package:escape_from_school/game/catalog_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  int? selectedLevel; // null 表示全部
  String selectedType = '全部'; // '全部' | '物品' | '装备'
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<Item> items = allItems;
    final List<Item> filtered = items.where((it) {
      final bool levelMatch = selectedLevel == null ? true : (it.level == selectedLevel);
      final String typeCat = _canonicalType(it.type);
      final bool typeMatch = selectedType == '全部' ? true : (typeCat == selectedType);
      final String q = searchQuery.trim();
      final bool searchMatch = q.isEmpty ? true : (it.name.contains(q) || it.description.contains(q));
      return levelMatch && typeMatch && searchMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('图鉴'),
        backgroundColor: Colors.black,
        elevation: 8,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.95),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
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
          Column(
            children: [
              _buildLevelFilter(),
              _buildTypeFilter(),
              _buildSearchBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final scale = Tween<double>(begin: 0.28, end: 1.0).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: scale, child: child),
                      );
                    },
                    child: LayoutBuilder(
                      key: ValueKey('${selectedLevel ?? '全部'}_${selectedType}'),
                      builder: (context, constraints) {
                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2 / 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildItemCard(item);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    final levels = [1, 2, 3, 4, 5, 6, 7];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('全部', selectedLevel == null, () {
              setState(() => selectedLevel = null);
            }),
            const SizedBox(width: 8),
            ...levels.map((lv) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip('$lv', selectedLevel == lv, () {
                    setState(() => selectedLevel = lv);
                  }),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    final types = ['全部', '物品', '装备'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: types
              .map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(t, selectedType == t, () {
                      setState(() => selectedType = t);
                    }),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.2)],
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '搜索名称或描述',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.black.withOpacity(0.25),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [Colors.blueAccent.withOpacity(0.6), Colors.black.withOpacity(0.4)]
                : [Colors.grey.withOpacity(0.35), Colors.black.withOpacity(0.25)],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(selected ? 0.4 : 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.45 : 0.3),
              blurRadius: selected ? 8 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final levelColor = _getItemLevelColor(item.level);
    final typeCat = _canonicalType(item.type);
    final Map<String, int> eff = item.effects;
    final Map<String, dynamic> wp = item.weaponParams ?? const {};
    final String atkTypeStr = (wp['attackType'] ?? '').toString();
    final bool isRanged = atkTypeStr == 'ranged' || atkTypeStr == '远程';
    final int intervalMs = ((wp['fireIntervalMs'] ?? 0) as num).toInt();
    final int roundsPerSecond = intervalMs > 0 ? (1000 / intervalMs).ceil() : 0;
    final bool isWeapon = item.type == 'equipment' && item.weaponParams != null && item.weaponParams!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CatalogDetailPage(selectedItem: item, allItems: allItems),
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
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
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.28),
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: levelColor.withOpacity(0.85), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: item.image.isNotEmpty
                              ? Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: levelColor, size: 16),
                                )
                              : Icon(Icons.inventory_2, color: levelColor, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: levelColor, fontSize: 12, fontWeight: FontWeight.bold, shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
                              ]),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '等级: ${item.level} · 类型: $typeCat${item.equipmentSlot != null ? ' · 槽位: ${item.equipmentSlot}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.cyanAccent.withOpacity(0.85), fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 10),
                    ),
                  const SizedBox(height: 6),
                  if (isWeapon)
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildLeftDetails(eff, wp, isRanged, roundsPerSecond)),
                          const SizedBox(width: 4),
                          Expanded(child: _buildRightDetails(eff, wp, isRanged)),
                        ],
                      ),
                    )
                  else if (eff.isNotEmpty)
                    Expanded(
                      child: _buildEffectsOnly(eff),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildLeftDetails(Map<String, int> eff, Map<String, dynamic> wp, bool isRanged, int rps) {
    final double distance = ((wp['distance'] ?? 0) as num).toDouble();
    final double rangeVal = ((wp['range'] ?? 0) as num).toDouble();
    final double dmgAmp = ((wp['damageAmplify'] ?? 1.0) as num).toDouble();
    final double critDmg = ((wp['critDamage'] ?? 1.5) as num).toDouble();
    final double critChance = ((wp['critChanceBonus'] ?? 0.0) as num).toDouble();
    final List<Map<String, String>> left = [
      {'k': '攻击类型', 'v': isRanged ? '远程' : '近战'},
      {'k': '距离', 'v': '${distance.toStringAsFixed(1)} 格'},
      {'k': isRanged ? '子弹速度' : '弧度', 'v': isRanged ? '${rangeVal.toStringAsFixed(1)} 格/秒' : rangeVal.toStringAsFixed(1)},
      if (isRanged && rps > 0) {'k': '射速', 'v': '$rps 发/秒'},
      {'k': '增幅伤害', 'v': '${dmgAmp.toStringAsFixed(2)} 倍'},
      {'k': '暴击伤害', 'v': '${critDmg.toStringAsFixed(2)} 倍'},
      {'k': '暴击几率加成', 'v': '${(critChance * 100).toStringAsFixed(0)}%'},
    ];
    return _pairsColumn(left);
  }

  Widget _buildRightDetails(Map<String, int> eff, Map<String, dynamic> wp, bool isRanged) {
    final int magazineSize = ((wp['magazineSize'] ?? 0) as num).toInt();
    final int ammoTotal = ((wp['ammoTotal'] ?? 0) as num).toInt();
    final String fireMode = (wp['fireMode'] ?? '').toString();
    final int reloadMs = ((wp['reloadMs'] ?? 0) as num).toInt();
    final bool wall = (wp['penetrateWalls'] ?? false) == true;
    final bool ghost = (wp['penetrateGhosts'] ?? false) == true;
    final List<Map<String, String>> right = [
      if (fireMode.isNotEmpty) {'k': '开火模式', 'v': fireMode},
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
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Text('${e['k']}:', style: TextStyle(color: Colors.grey.shade300, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        e['v'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ))
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
        Text('效果:', style: TextStyle(color: Colors.grey.shade300, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        ...effects.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Text('${e['k']}:', style: TextStyle(color: Colors.grey.shade300, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  e['v'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }



  String _canonicalType(String t) {
    final s = t.toLowerCase();
    if (s == 'item' || t == '物品') return '物品';
    return '装备';
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
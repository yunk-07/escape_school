import 'package:flutter/material.dart';
import '../data/props.dart';
import 'catalog_compare_page.dart';

class CatalogDetailPage extends StatefulWidget {
  final Item selectedItem;
  final List<Item> allItems;

  const CatalogDetailPage({
    Key? key,
    required this.selectedItem,
    required this.allItems,
  }) : super(key: key);

  @override
  State<CatalogDetailPage> createState() => _CatalogDetailPageState();
}

class _CatalogDetailPageState extends State<CatalogDetailPage> {
  Item? _compareItem;
  String _filterType = '全部';
  String _filterLevel = '全部';

  @override
  Widget build(BuildContext context) {
    final Item item = widget.selectedItem;
    final Map<String, dynamic> wp = item.weaponParams ?? const {};
    final Map<String, int> eff = item.effects;
    final String atkTypeStr = (wp['attackType'] ?? '').toString();
    final bool isRanged = atkTypeStr == 'ranged' || atkTypeStr == '远程';
    final int intervalMs = ((wp['fireIntervalMs'] ?? 0) as num).toInt();
    final int rps = intervalMs > 0 ? (1000 / intervalMs).ceil() : 0;
    final bool isWeapon = item.type == 'equipment' && item.weaponParams != null && item.weaponParams!.isNotEmpty;

    // 筛选物品列表
    final filteredItems = widget.allItems.where((otherItem) {
      if (_filterType != '全部' && otherItem.type != _filterType.toLowerCase()) {
        return false;
      }
      if (_filterLevel != '全部') {
        final levelRange = _filterLevel.split('-');
        if (levelRange.length == 2) {
          final minLevel = int.tryParse(levelRange[0]) ?? 1;
          final maxLevel = int.tryParse(levelRange[1]) ?? 7;
          if (otherItem.level < minLevel || otherItem.level > maxLevel) {
            return false;
          }
        }
      }
      return otherItem.id != item.id;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('物品详情 - ${item.name}', style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          // 左侧：物品详情
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getItemLevelColor(item.level), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 物品头部信息
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getItemLevelColor(item.level), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.image.isNotEmpty
                              ? Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: _getItemLevelColor(item.level), size: 32),
                                )
                              : Icon(Icons.inventory_2, color: _getItemLevelColor(item.level), size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                color: _getItemLevelColor(item.level),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '等级: ${item.level} · 类型: ${_canonicalType(item.type)}${item.equipmentSlot != null ? ' · 槽位: ${item.equipmentSlot}' : ''}',
                              style: TextStyle(color: Colors.cyanAccent.withOpacity(0.9), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 物品描述
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // 可滚动的内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 物品数据详情
                          if (isWeapon)
                            Row(
                              children: [
                                Expanded(child: _buildLeftDetails(eff, wp, isRanged, rps)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildRightDetails(eff, wp, isRanged)),
                              ],
                            )
                          else if (eff.isNotEmpty)
                            _buildEffectsOnly(eff),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // 对比按钮 - 固定在底部，确保不会溢出
                  if (_compareItem != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatalogComparePage(a: item, b: _compareItem!),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('开始对比', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 右侧：其他物品列表和筛选
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 筛选区域
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('类型:', style: TextStyle(color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _filterType,
                              dropdownColor: Colors.grey.shade800,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              onChanged: (value) {
                                setState(() => _filterType = value!);
                              },
                              items: ['全部', '物品', '装备'].map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                            ),
                            const Spacer(),
                            const Text('等级:', style: TextStyle(color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _filterLevel,
                              dropdownColor: Colors.grey.shade800,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              onChanged: (value) {
                                setState(() => _filterLevel = value!);
                              },
                              items: ['全部', '1-3', '4-7'].map((level) {
                                return DropdownMenuItem<String>(
                                  value: level,
                                  child: Text(level, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 物品列表
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                '没有符合条件的物品',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final otherItem = filteredItems[index];
                                final isSelected = _compareItem?.id == otherItem.id;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? Colors.blueAccent : Colors.grey.shade700,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _getItemLevelColor(otherItem.level), width: 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: otherItem.image.isNotEmpty
                                            ? Image.asset(
                                                otherItem.image,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => Icon(Icons.inventory_2, color: _getItemLevelColor(otherItem.level), size: 16),
                                              )
                                            : Icon(Icons.inventory_2, color: _getItemLevelColor(otherItem.level), size: 16),
                                      ),
                                    ),
                                    title: Text(
                                      otherItem.name,
                                      style: TextStyle(
                                        color: _getItemLevelColor(otherItem.level),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '等级 ${otherItem.level} · ${_canonicalType(otherItem.type)}',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check, color: Colors.blueAccent, size: 16)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _compareItem = isSelected ? null : otherItem;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e['k']}:', style: TextStyle(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e['v'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
        Text('效果:', style: TextStyle(color: Colors.grey.shade300, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...effects.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text('${e['k']}:', style: TextStyle(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e['v'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
import 'package:flutter/material.dart';
import '../data/props.dart';
import 'catalog_compare_page.dart';
import '../utils/level_color_manager.dart';

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
  String _filterType = '物品'; // 默认选中中间的筛选条件
  String _filterLevel = '4'; // 默认选中中间的筛选条件

  @override
  void initState() {
    super.initState();
  }

  // 顶部栏：自定义标题栏
  Widget _buildTopBar(String itemName) {
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
          // 标题
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
              child: Center(
                child: Text(
                  '物品详情 - $itemName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
    final Item item = widget.selectedItem;
    final Map<String, dynamic> wp = item.weaponParams ?? const {};
    final Map<String, int> eff = item.effects;
    final String atkTypeStr = (wp['attackType'] ?? '').toString();
    final bool isRanged = atkTypeStr == 'ranged' || atkTypeStr == '远程';
    final int intervalMs = ((wp['fireIntervalMs'] ?? 0) as num).toInt();
    final int rps = intervalMs > 0 ? (1000 / intervalMs).ceil() : 0;
    final bool isWeapon =
        item.type == 'equipment' &&
        item.weaponParams != null &&
        item.weaponParams!.isNotEmpty;

    // 筛选物品列表
    final filteredItems =
        widget.allItems.where((otherItem) {
          if (_filterType != '全部') {
            // 将中文筛选值映射回英文类型值
            final String expectedType =
                _filterType == '物品' ? 'item' : 'equipment';
            if (otherItem.type != expectedType) {
              return false;
            }
          }
          if (_filterLevel != '全部') {
            final selectedLevel = int.tryParse(_filterLevel) ?? 1;
            if (otherItem.level != selectedLevel) {
              return false;
            }
          }
          return otherItem.id != item.id;
        }).toList();

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
              // 顶部：自定义标题栏
              _buildTopBar(item.name),

              // 内容区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧：物品详情
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromRGBO(
                                (_getItemLevelColor(item.level).r.toInt() *
                                            0.2 +
                                        26)
                                    .toInt(),
                                (_getItemLevelColor(item.level).g.toInt() *
                                            0.2 +
                                        32)
                                    .toInt(),
                                (_getItemLevelColor(item.level).b.toInt() *
                                            0.2 +
                                        44)
                                    .toInt(),
                                0.8,
                              ),
                              const Color.fromRGBO(13, 17, 23, 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _getItemLevelColor(
                              item.level,
                            ).withOpacity(1.0),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(
                                _getItemLevelColor(item.level).r.toInt(),
                                _getItemLevelColor(item.level).g.toInt(),
                                _getItemLevelColor(item.level).b.toInt(),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 物品头部信息
                            Row(
                              children: [
                                // 物品图片
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: _getItemLevelColor(item.level),
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
                                                    color: _getItemLevelColor(
                                                      item.level,
                                                    ),
                                                    size: 32,
                                                  ),
                                            )
                                            : Icon(
                                              Icons.inventory_2,
                                              color: _getItemLevelColor(
                                                item.level,
                                              ),
                                              size: 32,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          color: _getItemLevelColor(item.level),
                                          fontSize: 20,
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
                                      const SizedBox(height: 4),
                                      Text(
                                        '等级: ${item.level} · 类型: ${_canonicalType(item.type)}${item.equipmentSlot != null ? ' · 槽位: ${_getSlotChineseName(item.equipmentSlot!)}' : ''}',
                                        style: TextStyle(
                                          color: Colors.cyanAccent.withOpacity(
                                            0.9,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (item.usageTime > 0 &&
                                          item.type == "item")
                                        Text(
                                          '使用时间: ${(item.usageTime / 1000).toStringAsFixed(1)}秒',
                                          style: TextStyle(
                                            color: Colors.amberAccent
                                                .withOpacity(0.9),
                                            fontSize: 12,
                                          ),
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
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
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
                                          Expanded(
                                            child: _buildLeftDetails(
                                              eff,
                                              wp,
                                              isRanged,
                                              rps,
                                              item,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildRightDetails(
                                              eff,
                                              wp,
                                              isRanged,
                                              item,
                                            ),
                                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CatalogComparePage(
                                              a: item,
                                              b: _compareItem!,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: const Text(
                                    '开始对比',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 右侧：其他物品列表和筛选
                    Expanded(
                      flex: 3, // 增大右边区域占比
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            // 筛选区域 - 自适应滑动卡片设计
                            Container(
                              height: 100, // 优化高度以适应内容
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 类型筛选 - 水平滑动卡片
                                  Container(
                                    height: 50,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: ['全部', '物品', '装备'].length,
                                      itemBuilder: (context, index) {
                                        final type = ['全部', '物品', '装备'][index];
                                        final isSelected = _filterType == type;

                                        return GestureDetector(
                                          onTap:
                                              () => setState(() {
                                                _filterType = type;
                                              }),
                                          child: AnimatedContainer(
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOutBack,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 80,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  isSelected
                                                      ? LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end:
                                                            Alignment
                                                                .bottomRight,
                                                        colors: [
                                                          Colors.amber
                                                              .withOpacity(0.9),
                                                          Colors.orange
                                                              .withOpacity(0.7),
                                                        ],
                                                      )
                                                      : LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end:
                                                            Alignment
                                                                .bottomRight,
                                                        colors: [
                                                          Colors.grey.shade600
                                                              .withOpacity(0.5),
                                                          Colors.grey.shade500
                                                              .withOpacity(0.4),
                                                        ],
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? Colors.amber
                                                        : Colors.white
                                                            .withOpacity(0.3),
                                                width: isSelected ? 2 : 1,
                                              ),
                                              boxShadow:
                                                  isSelected
                                                      ? [
                                                        BoxShadow(
                                                          color: Colors.amber
                                                              .withOpacity(0.6),
                                                          blurRadius: 12,
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                      : [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  type,
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.white
                                                                .withOpacity(
                                                                  0.9,
                                                                ),
                                                    fontSize: 12,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.w600,
                                                    shadows:
                                                        isSelected
                                                            ? [
                                                              Shadow(
                                                                blurRadius: 4,
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.5,
                                                                    ),
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      1,
                                                                    ),
                                                              ),
                                                            ]
                                                            : [],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // 等级筛选 - 水平滑动轮盘
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: PageView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        controller: PageController(
                                          viewportFraction: 0.25,
                                        ),
                                        itemCount:
                                            [
                                              '全部',
                                              '1',
                                              '2',
                                              '3',
                                              '4',
                                              '5',
                                              '6',
                                              '7',
                                            ].length,
                                        onPageChanged: (index) {
                                          setState(() {
                                            _filterLevel =
                                                [
                                                  '全部',
                                                  '1',
                                                  '2',
                                                  '3',
                                                  '4',
                                                  '5',
                                                  '6',
                                                  '7',
                                                ][index];
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          final level =
                                              [
                                                '全部',
                                                '1',
                                                '2',
                                                '3',
                                                '4',
                                                '5',
                                                '6',
                                                '7',
                                              ][index];
                                          final isSelected =
                                              _filterLevel == level;

                                          return GestureDetector(
                                            onTap:
                                                () => setState(() {
                                                  _filterLevel = level;
                                                }),
                                            child: AnimatedContainer(
                                              duration: Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeOutBack,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              constraints: BoxConstraints(
                                                minWidth: 60,
                                                minHeight: 40,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient:
                                                    isSelected
                                                        ? LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end:
                                                              Alignment
                                                                  .bottomRight,
                                                          colors: [
                                                            Colors.cyanAccent
                                                                .withOpacity(
                                                                  0.9,
                                                                ),
                                                            Colors.blueAccent
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ],
                                                        )
                                                        : LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end:
                                                              Alignment
                                                                  .bottomRight,
                                                          colors: [
                                                            Colors.grey.shade600
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                            Colors.grey.shade500
                                                                .withOpacity(
                                                                  0.4,
                                                                ),
                                                          ],
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? Colors.cyanAccent
                                                          : Colors.white
                                                              .withOpacity(0.3),
                                                  width: isSelected ? 2 : 1,
                                                ),
                                                boxShadow:
                                                    isSelected
                                                        ? [
                                                          BoxShadow(
                                                            color: Colors
                                                                .cyanAccent
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                            blurRadius: 12,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  3,
                                                                ),
                                                            spreadRadius: 1,
                                                          ),
                                                        ]
                                                        : [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  1,
                                                                ),
                                                          ),
                                                        ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  AnimatedDefaultTextStyle(
                                                    duration: Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : Colors.white
                                                                  .withOpacity(
                                                                    0.9,
                                                                  ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                      shadows:
                                                          isSelected
                                                              ? [
                                                                Shadow(
                                                                  blurRadius: 4,
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.5,
                                                                      ),
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        1,
                                                                      ),
                                                                ),
                                                              ]
                                                              : [],
                                                    ),
                                                    child: Text(level),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 物品列表
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child:
                                    filteredItems.isEmpty
                                        ? Center(
                                          child: Text(
                                            '没有符合条件的物品',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                        : ListView.builder(
                                          itemCount: filteredItems.length,
                                          itemBuilder: (context, index) {
                                            final otherItem =
                                                filteredItems[index];
                                            final isSelected =
                                                _compareItem?.id ==
                                                otherItem.id;
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? Colors.blueAccent
                                                            .withOpacity(0.3)
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? Colors.blueAccent
                                                          : Colors
                                                              .grey
                                                              .shade700,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    border: Border.all(
                                                      color: _getItemLevelColor(
                                                        otherItem.level,
                                                      ),
                                                      width: 2.5,
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    child:
                                                        otherItem
                                                                .image
                                                                .isNotEmpty
                                                            ? Image.asset(
                                                              otherItem.image,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                              errorBuilder:
                                                                  (
                                                                    c,
                                                                    e,
                                                                    s,
                                                                  ) => Icon(
                                                                    Icons
                                                                        .inventory_2,
                                                                    color: _getItemLevelColor(
                                                                      otherItem
                                                                          .level,
                                                                    ),
                                                                    size: 16,
                                                                  ),
                                                            )
                                                            : Icon(
                                                              Icons.inventory_2,
                                                              color:
                                                                  _getItemLevelColor(
                                                                    otherItem
                                                                        .level,
                                                                  ),
                                                              size: 16,
                                                            ),
                                                  ),
                                                ),
                                                title: Text(
                                                  otherItem.name,
                                                  style: TextStyle(
                                                    color: _getItemLevelColor(
                                                      otherItem.level,
                                                    ),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '等级 ${otherItem.level} · ${_canonicalType(otherItem.type)}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                trailing:
                                                    isSelected
                                                        ? const Icon(
                                                          Icons.check,
                                                          color:
                                                              Colors.blueAccent,
                                                          size: 16,
                                                        )
                                                        : null,
                                                onTap: () {
                                                  setState(() {
                                                    _compareItem =
                                                        isSelected
                                                            ? null
                                                            : otherItem;
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
              ),
            ],
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
    Item item,
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
      if (item.usageTime > 0 && item.type == "item")
        {'k': '使用时间', 'v': '${(item.usageTime / 1000).toStringAsFixed(1)}秒'},
    ];
    return _pairsColumn(left);
  }

  Widget _buildRightDetails(
    Map<String, int> eff,
    Map<String, dynamic> wp,
    bool isRanged,
    Item item,
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
      if (item.usageTime > 0 && item.type == "item")
        {'k': '使用时间', 'v': '${(item.usageTime / 1000).toStringAsFixed(1)}秒'},
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
                      Expanded(
                        child: Text(
                          e['v'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...effects
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
                    Expanded(
                      child: Text(
                        e['v'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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

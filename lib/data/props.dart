// data/props.dart
// 物品数据配置文件：定义物品基础信息、使用效果与装备加成
//
// =============================================================================
// 主要功能概述
// =============================================================================
// 本文件定义了游戏中所有物品的完整数据模型，包括：
// 1. 基础物品系统 - Item类管理所有物品的基础属性
// 2. 装备系统 - 武器、防具、饰品等装备管理
// 3. 消耗品系统 - 食物、药水等消耗类物品
// 4. 种植系统 - 可种植的种子和植物管理
// 5. 商店系统 - 物品商店价格和可购买性
//
// =============================================================================
// Item类核心字段说明
// =============================================================================
//
// 基础字段：
// - id: 物品唯一标识符（英文命名，程序内部使用）
// - name: 物品显示名称（中文，用户界面显示）
// - image: 物品图片路径
// - description: 物品描述文本
// - effects: 使用效果Map，键值对形式 {效果名: 数值}
// - type: 物品类型（'item'物品/'equipment'装备）
// - count: 物品数量（用于堆叠物品）
// - level: 物品等级（1-7，影响稀有度和显示颜色）
// - basePrice: 基础价格（商店买卖价格）
// - availableInShop: 是否在商店出售
// - usageTime: 使用时间（毫秒，影响使用动画时长）
//
// 装备专属字段：
// - equipmentSlot: 装备槽位类型
//   * 'weapon': 武器槽（近战/远程武器）
//   * 'armor': 护甲槽（增加生命值防御）
//   * 'head': 头部槽（帽子头饰）
//   * 'bag': 背包槽（增加背包容量）
//   * 'pants': 裤子槽（增加生命值）
//   * 'shoes': 鞋子槽（增加移动速度）
// - weaponParams: 武器参数Map
//   * 'attackType': 攻击类型（'melee'近战/'ranged'远程）
//   * 'distance': 攻击距离（格数）
//   * 'damageAmplify': 伤害倍率
//   * 'critChanceBonus': 暴击几率加成
//   * 'magazineSize': 弹夹容量（>0表示使用弹药系统）
//   * 'reloadMs': 换弹时间（毫秒）
//   * 'fireIntervalMs': 开火间隔（毫秒）
//   * 'penetrateWalls': 是否可穿透墙体
//   * 'bulletSize': 子弹大小倍数
//   * 'trailEffect': 拖尾效果强度（1-100）
//
// 种植系统专属字段：
// - plantable: 是否可种植（true/false）
// - plantParams: 种植参数Map，包含以下键值：
//   * 'growthTimeMs': 生长时间（毫秒）
//   * 'harvestItemId': 收获物ID（成熟后获得的物品）
//   * 'harvestCount': 收获数量（收获时获得的数量）
//   * 'stages': 生长阶段数（通常为3：种子→发芽→成熟）
//   * 'stageImages': 各阶段图片路径列表
//   * 'requiresWater': 是否需要浇水（true/false）
//   * 'waterIntervalMs': 浇水间隔（毫秒，超过此时间未浇水则生长停止）
// - plantableTileTypes: 可种植的瓦片类型列表
//   * ['grass']: 仅可在草地上种植
//   * ['grass', 'farmland']: 可在草地和农田种植
//   * ['any']: 任何可见瓦片都可种植
//
// =============================================================================
// effects字段支持的键值说明
// =============================================================================
//
// 生命值相关：
// - 'hp': 当前生命值（按maxHp夹取，不能超过上限）
// - 'maxHp': 生命值上限（至少为1，降低时会夹取hp）
//
// 饱食度相关：
// - 'food': 当前饱食度（按maxFood夹取）
// - 'maxFood': 饱食度上限（至少为1，降低时会夹取food）
//
// 精神值相关：
// - 'san': 精神值（0-250范围夹取）
//
// 移动相关：
// - 'moveSpeed': 移动速度（无上限，最小值为1）
//
// 经济系统：
// - 'gold': 金币数量（可为负数）
//
// 背包系统：
// - 'inventoryBonus': 背包容量增益（仅在equipEffects中生效）
//
// 氧气系统：
// - 'oxygenBonus': 氧气上限增益（已在状态机中处理）
//
// =============================================================================
// 种植系统物品示例
// =============================================================================
//
// 1. 玉米种子 (id: 'corn')
//    plantable: true
//    plantParams: {
//      'growthTimeMs': 30000,      // 30秒生长时间
//      'harvestItemId': 'corn',    // 收获玉米
//      'harvestCount': 2,          // 收获2个玉米
//      'stages': 3,                // 3个生长阶段
//      'stageImages': [            // 各阶段图片
//        'images/items/corn_seed.png',   // 种子阶段
//        'images/items/corn_sprout.png', // 发芽阶段
//        'images/items/corn.png',        // 成熟阶段
//      ],
//      'requiresWater': true,      // 需要浇水
//      'waterIntervalMs': 15000,   // 15秒浇水间隔
//    }
//    plantableTileTypes: ['grass'] // 仅可在草地种植
//
// 2. 胡萝卜种子 (id: 'carrot')
//    plantable: true
//    plantParams: {
//      'growthTimeMs': 25000,      // 25秒生长时间
//      'harvestItemId': 'carrot',  // 收获胡萝卜
//      'harvestCount': 3,          // 收获3个胡萝卜
//      'stages': 3,                // 3个生长阶段
//      'stageImages': [            // 各阶段图片
//        'images/items/carrot_seed.png',   // 种子阶段
//        'images/items/carrot_sprout.png', // 发芽阶段
//        'images/items/carrot_max.png',    // 成熟阶段
//      ],
//      'requiresWater': true,      // 需要浇水
//      'waterIntervalMs': 12000,   // 12秒浇水间隔
//    }
//    plantableTileTypes: ['grass'] // 仅可在草地种植
//
// =============================================================================
// 物品等级颜色对应
// =============================================================================
// 1级（无色）- 普通物品
// 2级（绿色）- 优秀物品
// 3级（蓝色）- 稀有物品
// 4级（紫色）- 史诗物品
// 5级（橙色）- 传说物品
// 6级（红色）- 神器物品
// 7级（彩色）- 至尊物品
//
// =============================================================================
// 使用方法
// =============================================================================
//
// 1. 在代码中引用物品：
//    final cornSeed = allItems.firstWhere((item) => item.id == 'corn');
//
// 2. 检查物品是否可种植：
//    if (item.plantable) {
//      // 处理可种植物品
//      final params = item.plantParams;
//      final growthTime = params['growthTimeMs'];
//      final requiresWater = params['requiresWater'];
//    }
//
// 3. 应用物品效果：
//    final effects = item.effects;
//    if (effects.containsKey('hp')) {
//      player.hp = (player.hp + effects['hp']).clamp(0, player.maxHp);
//    }
//
// 4. 检查装备槽位：
//    if (item.equipmentSlot == 'weapon') {
//      // 装备到武器槽
//    }
//
// =============================================================================
// 重要注意事项
// =============================================================================
// - 物品ID必须唯一且为英文，用于程序内部识别
// - 物品名称为中文，用于用户界面显示
// - plantParams中的图片路径必须存在，否则会显示空白
// - 生长时间过短可能导致植物瞬间成熟，影响游戏平衡
// - 浇水间隔设置过短会增加游戏难度，过长会降低挑战性
// - 所有数值效果在应用时都会进行合理性检查和夹取
// - 装备效果仅在装备后生效，消耗品效果仅在使用时生效
// - 武器参数中的数值会影响战斗系统的具体表现
//
// =============================================================================

// 关键区域：类型与槽位映射
// - 类型字段支持：'item'、'equipment'；兼容旧中文 '物品'、'装备' 及 '武器/甲/头/背包/裤子/鞋'
// - 槽位对应：weapon / armor / head / bag / pants / shoes
//   说明：不再支持历史槽位 'hand'
// 关键区域：效果与加成的区别
// - effects：消耗类使用效果（仅在点击"使用"时生效）
// - equipEffects：装备类佩戴加成（仅在"装备"后生效）
//   注意：inventoryBonus 与 armorValue 仅在 equipEffects 中生效
// 关键区域：护甲耐久说明
// - 护甲最大耐久由 equipEffects["armorValue"] 提供
// - 当前耐久使用 Item.count 记录；显示为 count/armorValue
// - 护甲抗伤机制：先削弱 50% 伤害，再按等级比例分配到护甲与玩家
// 关键区域：effects 支持的键
// - hp：修改生命值（按当前 maxHp 夹取）
// - maxHp：修改生命值上限（至少为 1；若降低会夹取 hp）
// - food：修改饱食度（按当前 maxFood 夹取）
// - maxFood：修改饱食度上限（至少为 1；若降低会夹取 food）
// - san：修改精神值（按 0..250 夹取）
// - moveSpeed：修改移动速度（不设上限，最小 1）
// - gold：修改金币
// - oxygenBonus：修改氧气上限（已在状态机中处理）
// - inventoryBonus：背包容量增益（仅 equipEffects 生效，effects 中忽略）
class Item {
  final String id;
  final String name;
  final String image;
  final String description;
  final Map<String, int> effects; // {hp: 10, gold: 5, maxHp: 20, maxFood: -10}
  final String type; // 新增：物品类型（严格为“物品”或“装备”）
  final int count; // 新增：物品数量
  final bool availableInShop; // 新增：是否在商店出售
  final int basePrice; // 新增：基础价格
  final int usageTime; // 新增：使用时间（毫秒）
  final int level; // 新增：物品等级（1-7）
  // 关键区域：装备专属字段
  final String? equipmentSlot; // 装备部位：weapon/armor/head/bag/pants/shoes
  // 关键区域：每件武器的独立弹药状态（与护甲耐久类似按件保存）
  final int? clipAmmo; // 当前弹夹内弹药
  final int? ammoReserve; // 当前备用弹药（不含弹夹）
  // 关键区域：武器模板参数（从物品读取并应用到攻击效果）
  // 键说明（全部使用英文）：
  // - attackType        攻击类型：'melee' 或 'ranged'
  // - effectColor       颜色效果：int ARGB（例如 0xFFFFA000）
  // - distance          攻击距离/子弹飞行距离（格）
  // - range             近战弧度；远程子弹速度（格/秒）
  // - damageAmplify     伤害增幅倍数
  // - critDamage        暴击伤害倍数
  // - critChanceBonus   暴击几率加成（0.0~1.0）
  // - fireMode          远程开火模式：'semiAuto' 或 'fullAuto'（亦支持小写 'semiauto'/'fullauto'）
  //                      行为说明：
  //                      1）滑动仅瞄准，不开火
  //                      2）长按进入自动开火（仅 fullAuto）
  //                      3）长按后滑动，持续按滑动方向连发
  // - penetrateWalls    是否可穿透墙体/建筑：true/false（默认 false）
  // - penetrateGhosts   是否可穿透鬼（命中后继续前进）：true/false（默认 false）
  // - reloadMs          换弹时间（毫秒），弹夹为 0 且有备用弹药时自动换弹
  // - fireIntervalMs    单发间隔（毫秒），用于节流单点与长按连发；详情页射速 = ceil(1000/fireIntervalMs) 发/秒
  // - magazineSize      弹夹容量（>0 表示使用弹药系统）
  // - ammoTotal         备用弹药总量（不含弹夹）
  // - bulletSize        子弹大小倍数：默认 1.0（1倍大小），大于1时放大（如2表示2倍）
  //                      远程武器：修改子弹视觉效果大小
  //                      近战武器：修改武器的攻击范围大小
  // - trailEffect       尾迹效果强度：1-100，控制子弹拖尾的长度和强度
  //                      数值越大，拖尾越长越明显；默认0（无拖尾）
  final Map<String, dynamic>? weaponParams;
  // final Map<String, int>? equipEffects; // 装备效果加成（佩戴生效）

  // 关键区域：种植系统相关字段
  final bool plantable; // 是否可种植
  final Map<String, dynamic>? plantParams; // 种植参数
  // 键说明（全部使用英文）：
  // - growthTimeMs      生长时间（毫秒）
  // - harvestItemId     收获物ID
  // - harvestCount      收获数量
  // - stages            生长阶段数
  // - stageImages       各阶段图片路径列表
  // - requiresWater     是否需要浇水（true/false）
  // - waterIntervalMs   浇水间隔时间（毫秒）
  final List<String>? plantableTileTypes; // 可种植的格子类型列表（支持多种格子）

  Item({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    this.effects = const {},
    this.type = 'item',
    this.count = 1,
    this.availableInShop = false, // 默认不在商店出售
    this.basePrice = 0,
    this.usageTime = 2000, // 默认使用时间2秒
    this.level = 1, // 默认等级1（无色）
    this.equipmentSlot,
    this.clipAmmo,
    this.ammoReserve,
    this.weaponParams,
    // this.equipEffects,
    this.plantable = false, // 默认不可种植
    this.plantParams,
    this.plantableTileTypes, // 可种植的格子类型列表
  });

  /// 复制并更新物品属性
  Item copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    Map<String, int>? effects,
    String? type,
    int? count,
    bool? availableInShop,
    int? basePrice,
    int? usageTime,
    int? level,
    String? equipmentSlot,
    int? clipAmmo,
    int? ammoReserve,
    Map<String, dynamic>? weaponParams,
    bool? plantable,
    Map<String, dynamic>? plantParams,
    List<String>? plantableTileTypes,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      effects: effects ?? this.effects,
      type: type ?? this.type,
      count: count ?? this.count,
      availableInShop: availableInShop ?? this.availableInShop,
      basePrice: basePrice ?? this.basePrice,
      usageTime: usageTime ?? this.usageTime,
      level: level ?? this.level,
      equipmentSlot: equipmentSlot ?? this.equipmentSlot,
      clipAmmo: clipAmmo ?? this.clipAmmo,
      ammoReserve: ammoReserve ?? this.ammoReserve,
      weaponParams: weaponParams ?? this.weaponParams,
      plantable: plantable ?? this.plantable,
      plantParams: plantParams ?? this.plantParams,
      plantableTileTypes: plantableTileTypes ?? this.plantableTileTypes,
    );
  }
}

final List<Item> allItems = [
  Item(
    id: 'hanbao',
    name: '美去人通便汉堡',
    image: 'images/items/hanbao.png',
    description: '钻研肠胃科主任为何把最灵的药藏在这里',
    effects: {'hp': -2, 'food': 20},
    type: 'item',
    availableInShop: false,
    basePrice: 16,
    usageTime: 3000, // 汉堡需要3秒食用
    level: 3, // 紫色等级
  ),
  Item(
    id: 'fish01',
    name: '半生不熟鱼',
    image: 'images/items/fish01.png',
    description: '苦心钻研匠心制造还没煮熟的鱼',
    effects: {'hp': -5, 'food': 10, 'san': -5, 'moveSpeed': -5}, // 移动速度减少5
    type: 'item',
    availableInShop: true,
    basePrice: 8,
    usageTime: 2500, // 半生不熟鱼需要2.5秒食用
    level: 2, // 绿色等级
  ),
  Item(
    id: 'fish02',
    name: '熟鱼',
    image: 'images/items/fish02.png',
    description: '30年阳寿换来一条煮熟的鱼',
    effects: {'hp': -5, 'food': 50, 'san': 20},
    type: 'item',
    availableInShop: true,
    basePrice: 12,
    usageTime: 2000, // 熟鱼需要2秒食用
    level: 3, // 蓝色等级
  ),
  Item(
    id: 'fish03',
    name: '尘封已久的鱼',
    image: 'images/items/fish03.png',
    description: '这样吃了没事吧？反正举报也没用管他的',
    effects: {'hp': -10, 'food': 5, 'san': -15, 'moveSpeed': -5}, // 移动速度减少5
    type: 'item',
    availableInShop: true,
    basePrice: 8,
    usageTime: 1500, // 尘封鱼很难吃，快速吞下只需1.5秒
    level: 1, // 无色等级
  ),
  Item(
    id: 'book01',
    name: '学生守则',
    image: 'images/items/book.png',
    description: '三百多页？不管了看一下吧说不定有好处',
    effects: {'san': -25, 'moveSpeed': 10}, // 移动速度增加10
    type: 'item',
    availableInShop: true,
    basePrice: 0,
    usageTime: 5000, // 阅读书籍需要5秒
    level: 1,
  ),
  Item(
    id: 'shit',
    name: '不可名之物',
    image: 'images/items/shit.png',
    description: '或许我们真的可以尝试一下',
    effects: {'san': -30, 'hp': -10, 'food': 20},
    level: 3,
    availableInShop: false,
    usageTime: 5000,
  ),

  Item(
    id: 'energy_bar',
    name: '能量棒',
    image: 'images/items/oxbang.png',
    description: '高能量营养棒，能够快速恢复体力和精神状态',
    effects: {'san': 10, 'oxygenBonus': 1, 'food': 10, 'hp': 5},
    type: 'item',
    level: 4,
    availableInShop: true,
    basePrice: 20,
    usageTime: 6000, // 6秒使用时间
  ),
  Item(
    id: 'energy_bar2',
    name: '能量棒',
    image: 'images/items/hpbang.png',
    description: '高能量营养棒，能够快速恢复体力和精神状态',
    effects: {'san': 10, 'hp': 20, 'food': 10, 'maxHp': 1},
    type: 'item',
    level: 4,
    availableInShop: true,
    basePrice: 20,
    usageTime: 6000, // 6秒使用时间
  ),
  Item(
    id: 'energy_bar3',
    name: '能量棒',
    image: 'images/items/fobang.png',
    description: '高能量营养棒，能够快速恢复体力和精神状态',
    effects: {'san': 10, 'hp': 2, 'food': 40},
    type: 'item',
    level: 4,
    availableInShop: true,
    basePrice: 20,
    usageTime: 6000, // 6秒使用时间
  ),
  Item(
    id: 'corn',
    name: '玉米',
    image: 'images/items/corn.png',
    description: '应该煮了？',
    effects: {'san': 10, 'food': 20, 'hp': 1},
    type: 'item',
    level: 3,
    availableInShop: true,
    basePrice: 10,
    usageTime: 6000, // 6秒使用时间
    plantable: true,
    plantParams: {
      'growthTimeMs': 560000, // 生长时间
      'harvestItemId': 'corn',
      'harvestCount': 2,
      'stages': 3,
      'stageImages': [
        'images/items/corn_seed.png',
        'images/items/corn_sprout.png',
        'images/items/corn_max.png',
      ],
      'requiresWater': true,
      'waterIntervalMs': 15000, // 15秒需要浇水一次
    },
    plantableTileTypes: ['grass'], // 可在草地和农田种植
  ),
  Item(
    id: 'bread',
    name: '面包',
    image: 'images/items/bread.png',
    description: '还好不是十万马克',
    effects: {'san': 1, 'food': 40, 'hp': 1},
    type: 'item',
    level: 4,
    availableInShop: true,
    basePrice: 20,
    usageTime: 6000, // 6秒使用时间
  ),
  Item(
    id: 'bread2',
    name: '面包',
    image: 'images/items/bread.png',
    description: '还真是十万马克',
    effects: {'san': 100, 'food': 100, 'hp': 20},
    type: 'item',
    level: 5,
    availableInShop: true,
    basePrice: 100,
    usageTime: 1000, // 1秒使用时间
  ),
  Item(
    id: 'carrot',
    name: '胡萝卜',
    image: 'images/items/carrot.png',
    description: '我吃吃吃',
    effects: {'san': 20, 'food': 5},
    type: 'item',
    level: 3,
    availableInShop: true,
    basePrice: 9,
    usageTime: 3000, // 3秒使用时间
    plantable: true,
    plantParams: {
      'growthTimeMs': 250000, // 25秒生长时间
      'harvestItemId': 'carrot',
      'harvestCount': 3,
      'stages': 3,
      'stageImages': [
        'images/items/carrot_seed.png',
        'images/items/carrot_sprout.png',
        'images/items/carrot_max.png',
      ],
      'requiresWater': true,
      'waterIntervalMs': 12000, // 12秒需要浇水一次
    },
    plantableTileTypes: ['grass'], // 可在草地种植
  ),
  Item(
    id: 'allbang',
    name: '奇怪的粉末',
    image: 'images/items/allbang.png',
    description: '吃了会有什么效果？',
    effects: {
      'san': 40,
      'food': 1,
      'maxHp': -1,
      'moveSpeed': -1,
      'oxygenBonus': -1,
    },
    type: 'item',
    level: 4,
    availableInShop: false,
    basePrice: 1,
    usageTime: 500, // 0.5秒使用时间
  ),
  // 关键区域：以下为最小装备示例，用于验证装备系统
  Item(
    id: 'weapon_wooden_sword',
    name: '木质短剑',
    image: 'images/items/mzdj.png',
    description: '朴素的木剑，略微提升机动性',
    effects: const {},
    type: 'equipment',
    equipmentSlot: 'weapon',
    level: 2,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'melee',
      'effectColor': 0xFFFFA000,
      'distance': 1,
      'range': 1.2,
      'damageAmplify': 1.2,
      'critDamage': 1.5,
      'critChanceBonus': 0.05,
    },
  ),
  Item(
    id: 'armor_school_uniform',
    name: '校服',
    image: 'images/items/xiaofu.png',
    description: '普通校服，增加最大生命值',
    effects: const {'maxHp': 10},
    type: 'equipment',
    equipmentSlot: 'armor',
    level: 2,
    availableInShop: true,
    basePrice: 80,
  ),
  Item(
    id: 'head_hat',
    name: '帽子',
    image: 'images/items/hat.png',
    description: '普通帽子，更加专注',
    effects: const {'san': 5},
    type: 'equipment',
    equipmentSlot: 'head',
    level: 2,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'niuzai_hat',
    name: '牛仔帽',
    image: 'images/items/niuzai.png',
    description: '无所畏惧',
    effects: const {'maxHp': -40, 'moveSpeed': 70, 'san': 20},
    type: 'equipment',
    equipmentSlot: 'head',
    level: 4,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'speed_gloves',
    name: '动力手套',
    image: 'images/items/speedGloves.png',
    description: '禁忌的九号之力',
    effects: const {'moveSpeed': 40, 'punish': 1},
    type: 'equipment',
    equipmentSlot: 'weapon', // 关键区域：对应武器槽
    level: 4,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'melee',
      'effectColor': 0xFF00E5FF,
      'distance': 1,
      'range': 0.9,
      'damageAmplify': 0.5,
      'critDamage': 1.3,
      'critChanceBonus': 0.10,
    },
  ),
  Item(
    id: 'pants_school_uniform',
    name: '校裤',
    image: 'images/items/xiaoku.png',
    description: '普通校裤，增加最大生命值',
    effects: const {'maxHp': 10},
    type: 'equipment',
    equipmentSlot: 'pants',
    level: 2,
    availableInShop: true,
    basePrice: 80,
  ),
  // 关键区域：金币道具，使用后增加1金币
  Item(
    id: 'gold',
    name: '金币',
    image: 'images/items/gold.png',
    description: '使用后增加1金币',
    effects: const {'gold': 1},
    type: 'item',
    level: 1,
    availableInShop: false,
    usageTime: 0,
  ),
  Item(
    id: 'bag',
    name: '背包',
    image: 'images/items/bag.png',
    description: '普通背包',
    effects: const {'inventoryBonus': 2},
    type: 'equipment',
    equipmentSlot: 'bag',
    level: 1,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'goldbar',
    name: '金条',
    image: 'images/items/goldbar.png',
    description: '校长裤兜掉出来的',
    effects: const {'gold': 333},
    type: 'item',
    level: 6,
    availableInShop: false,
    usageTime: 0,
  ),
  // 关键区域：新增护甲物品（防弹衣），装备到 armor 槽位，提供护甲耐久
  Item(
    id: 'm-three-armor_fangdan',
    name: 'M3轻型',
    image: 'images/items/m-three-fangdan.png',
    description: '可格挡大量伤害，耐久耗尽后失去格挡能力',
    effects: const {'armorValue': 40, 'moveSpeed': -5},
    type: 'equipment',
    equipmentSlot: 'armor',
    count: 40,
    level: 6,
    availableInShop: true,
    basePrice: 200,
  ),
  Item(
    id: 'm-one-armor_fangdan',
    name: 'M1轻型',
    image: 'images/items/m-one-fangdan.png',
    description: '可格挡大量伤害，耐久耗尽后失去格挡能力',
    effects: const {'armorValue': 40, 'moveSpeed': -1},
    type: 'equipment',
    equipmentSlot: 'armor',
    count: 40,
    level: 2,
    availableInShop: true,
    basePrice: 60,
  ),
  Item(
    id: 'divingmask',
    name: '潜水面罩',
    image: 'images/items/divingmask.png',
    description: '水里或许有什么东西',
    effects: const {'oxygenBonus': 20},
    type: 'equipment',
    equipmentSlot: 'head',
    count: 1,
    level: 3,
  ),
  Item(
    id: 'wine',
    name: '啤酒',
    image: 'images/items/wine.png',
    description: '你会吃处分的',
    effects: const {
      'moveSpeed': -10,
      'maxHp': 4,
      'san': 20,
      'punish': 2,
      'baseDamage': 2,
    },
    type: 'item',
    level: 3,
    usageTime: 2000,
  ),
  Item(
    id: 'm-two-bag',
    name: 'M2背包',
    image: 'images/items/m-two-bag.png',
    description: '普通背包',
    type: 'equipment',
    // 关键区域：背包装备到 bag 槽位，装备效果为增加2格背包容量
    equipmentSlot: 'bag',
    effects: const {'inventoryBonus': 8, 'moveSpeed': -5},
    level: 3,
    availableInShop: true,
    basePrice: 80,
  ),
  Item(
    id: 'g-one-gun',
    name: 'G1手枪',
    image: 'images/items/g-one-gun.png',
    description: '普通手枪',
    type: 'equipment',
    equipmentSlot: 'weapon',
    effects: const {'moveSpeed': 2},
    level: 3,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'semiauto',
      'penetrateWalls': false,
      'penetrateGhosts': false,
      'reloadMs': 1000,
      'fireIntervalMs': 320,
      'effectColor': 0xFFFFF59D,
      'distance': 6,
      'range': 12,
      'damageAmplify': 1.2,
      'critDamage': 1.5,
      'critChanceBonus': 0.15,
      'magazineSize': 4,
      'ammoTotal': 20,
    },
  ),
  Item(
    id: 'm-one-gun',
    name: 'M1手枪',
    image: 'images/items/m-one-gun.png',
    description: '全自动激发',
    type: 'equipment',
    equipmentSlot: 'weapon',
    effects: const {'moveSpeed': 2},
    level: 3,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'fullauto',
      'penetrateWalls': false,
      'penetrateGhosts': false,
      'reloadMs': 1500,
      'effectColor': 0xFFFFF59D,
      'distance': 5,
      'range': 12,
      'damageAmplify': 1.2,
      'critDamage': 1.5,
      'critChanceBonus': 0.19,
      'magazineSize': 7,
      'ammoTotal': 35,
      'trailEffect': 50, // 中等尾迹效果
    },
  ),
  Item(
    id: 'g-eteen-gun',
    name: 'G18',
    image: 'images/items/g-eteen-gun.png',
    description: '全自动激发',
    type: 'equipment',
    equipmentSlot: 'weapon',
    effects: const {'moveSpeed': 2},
    level: 5,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'fullauto',
      'penetrateWalls': false,
      'penetrateGhosts': false,
      'reloadMs': 1000,
      'fireIntervalMs': 20,
      'effectColor': 0xFFFFF59D,
      'distance': 6,
      'range': 12,
      'damageAmplify': 0.6,
      'critDamage': 1.1,
      'critChanceBonus': 0.01,
      'magazineSize': 33,
      'ammoTotal': 132,
    },
  ),
  Item(
    id: 'g-eteen-ultra-gun',
    name: 'G18-ultra',
    image: 'images/items/g-eteen-ultra-gun.png',
    description: '',
    type: 'equipment',
    equipmentSlot: 'weapon',
    effects: const {'moveSpeed': 8},
    level: 6,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'fullauto',
      'penetrateWalls': false,
      'penetrateGhosts': false,
      'reloadMs': 800,
      'fireIntervalMs': 10,
      'effectColor': 0xFFFFF59D,
      'distance': 7,
      'range': 12,
      'damageAmplify': 1.0,
      'critDamage': 1.1,
      'critChanceBonus': 0.09,
      'magazineSize': 18,
      'ammoTotal': 72,
    },
  ),
  Item(
    id: 'bow',
    name: '弓',
    image: 'images/items/bow.png',
    description: '穿透世界',
    type: 'equipment',
    equipmentSlot: 'weapon',
    effects: const {'moveSpeed': 9},
    level: 3,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'semiauto',
      'penetrateWalls': true,
      'penetrateGhosts': true,
      'reloadMs': 1000,
      'fireIntervalMs': 500,
      'effectColor': 0xFFFFF59D,
      'distance': 6,
      'range': 20,
      'damageAmplify': 1.2,
      'critDamage': 1.9,
      'critChanceBonus': 0.33,
      'magazineSize': 1,
      'ammoTotal': 20,
      'trailEffect': 80, // 强尾迹效果
    },
  ),
  Item(
    id: 'kungfu-tea',
    name: '功夫茶',
    image: 'images/items/kungfu-tea.png',
    description: '静心养气 PS:确保你有充足的时间恢复元气',
    type: 'item',
    level: 5,
    usageTime: 8000,
    effects: const {
      'oxygenBonus': 6,
      'moveSpeed': 6,
      'san': 66,
      'maxFood': 6,
      'maxHp': 6,
    },
    availableInShop: true,
    basePrice: 66,
  ),
  Item(
    id: 'Tactical-Manual',
    name: '战术手册',
    image: 'images/items/Tactical-Manual.png',
    description: '学习更多校园格斗技巧',
    type: 'item',
    effects: const {
      'oxygenBonus': 2,
      'hp': -5,
      'san': 15,
      'moveSpeed': 2,
      'baseDamage': 2,
    },
    level: 4,
    availableInShop: true,
    basePrice: 80,
    usageTime: 3000,
  ),
  Item(
    id: 'hypervent_kit',
    name: '过度呼吸训练包',
    image: 'images/items/hypervent_kit.png',
    description: '训练过度呼吸，提高氧气值',
    type: 'item',
    effects: const {'oxygenBonus': 4, 'hp': -5, 'san': 15},
    level: 4,
    availableInShop: false,
    usageTime: 7000,
  ),
  Item(
    id: 'niki',
    name: 'Niki跑鞋',
    image: 'images/items/niki.png',
    description: '',
    type: 'equipment',
    equipmentSlot: 'shoes',
    effects: const {'moveSpeed': 8},
    level: 3,
    availableInShop: true,
    basePrice: 120,
  ),
  Item(
    id: 'calming_tablet',
    name: '镇定片',
    image: 'images/items/calming_tablet.png',
    description: '怎么学校什么都有',
    type: 'item',
    effects: const {'san': 25, 'moveSpeed': -2, 'baseDamage': -1, 'maxHp': -1},
    level: 3,
    availableInShop: true,
    basePrice: 20,
    usageTime: 2200,
  ),
  Item(
    id: 'discipline_report',
    name: '检讨书',
    image: 'images/items/discipline_report.png',
    description: '笑都笑不出来',
    type: 'item',
    effects: const {'punish': -1, 'san': -5},
    level: 4,
    usageTime: 5000,
  ),
  Item(
    id: 'broken_gold',
    name: '破碎的金币',
    image: 'images/items/broken_gold.png',
    description: '校长办公室的线索？',
    type: 'item',
    effects: const {'gold': 33},
    level: 5,
  ),
  Item(
    id: 'battle_charm',
    name: '战斗绷带',
    image: 'images/items/battle_charm.png',
    description: '',
    type: 'item',
    effects: const {'baseDamage': 1, 'san': -5, 'maxHp': -1},
    level: 2,
    usageTime: 2000,
  ),
  Item(
    id: 'canned_food',
    name: '罐头',
    image: 'images/items/canned.png',
    description: '',
    type: 'item',
    effects: const {'food': 25, 'san': -5},
    level: 3,
    availableInShop: true,
    basePrice: 17,
    usageTime: 2500,
  ),
  Item(
    id: 'water',
    name: '水',
    image: 'images/items/water.png',
    description: '',
    type: 'item',
    effects: const {'food': 6, 'san': 2},
    level: 2,
    availableInShop: true,
    basePrice: 4,
    usageTime: 2100,
  ),
  Item(
    id: 'apple',
    name: '苹果',
    image: 'images/items/apple.png',
    description: '',
    type: 'item',
    effects: const {'food': 8, 'hp': 5},
    level: 2,
    availableInShop: true,
    basePrice: 8,
    usageTime: 2800,
  ),
  Item(
    id: 'shoes',
    name: '布鞋',
    image: 'images/items/shoes.png',
    description: '轻便鞋子，略微提升移动速度',
    effects: const {'moveSpeed': 5},
    type: 'equipment',
    equipmentSlot: 'shoes',
    level: 1,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'cook_gun',
    name: '厨师的枪',
    image: 'images/items/cook_gun.png',
    description: '我们在厨师身上发现了这个',
    type: 'equipment',
    equipmentSlot: 'weapon',
    effects: const {'moveSpeed': -50, 'san': 40},
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'fullauto',
      'penetrateWalls': false,
      'penetrateGhosts': true,
      'reloadMs': 11111,
      'fireIntervalMs': 90,
      'effectColor': 0xF8F8FFFF,
      'distance': 4,
      'range': 4,
      'damageAmplify': 0.8,
      'critDamage': 1.1,
      'critChanceBonus': 2.0,
      'magazineSize': 70,
      'ammoTotal': 700,
      'bulletSize': 1.2,
      'trailEffect': 50, // 中等尾迹效果
    },
    level: 7,
    availableInShop: false,
  ),
  Item(
    id: 'magazine-d',
    name: 'D1弹夹',
    image: 'images/items/magazine-d.png',
    description: '为武器补充弹药',
    type: 'item',
    effects: const {'ammo': 20},
    level: 3,
    availableInShop: false,
    usageTime: 3000,
  ),
  Item(
    id: 'magazine-m',
    name: 'M1弹夹',
    image: 'images/items/magazine-m.png',
    description: '为武器补充弹药',
    type: 'item',
    effects: const {'ammo': 30},
    level: 4,
    availableInShop: false,
    usageTime: 2500,
  ),
  Item(
    id: 'raw_meat',
    name: '生肉',
    image: 'images/items/raw_meat.png',
    description: '未经处理的肉类，最好烹饪后再吃。',
    type: 'item',
    effects: const {'food': 10, 'san': -4, 'hp': -3},
    usageTime: 2500,
    level: 2,
    availableInShop: false,
    basePrice: 8,
  ),
  Item(
    id: 'revolver',
    name: '左轮手枪',
    image: 'images/items/revolver.png',
    description: '可靠但装弹缓慢，暴击伤害极高。',
    type: 'equipment',
    equipmentSlot: 'weapon',
    level: 4,
    availableInShop: false,
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'semiauto',
      'bulletSize': 1.2,
      'trailEffect': 50, // 中等尾迹效果
      'penetrateWalls': false,
      'penetrateGhosts': false,
      'reloadMs': 2000,
      'fireIntervalMs': 500,
      'effectColor': 0xFFE0E0E0,
      'distance': 6,
      'range': 12,
      'damageAmplify': 1.35,
      'critDamage': 2.2,
      'critChanceBonus': 0.15,
      'magazineSize': 6,
      'ammoTotal': 30,
    },
  ),
  Item(
    id: 'cheese',
    name: '奶酪',
    image: 'images/items/cheese.png',
    description: '香浓的奶酪，能让心情变好。',
    type: 'item',
    effects: const {'food': 30, 'san': 6},
    usageTime: 3000,
    level: 3,
    availableInShop: true,
    basePrice: 18,
  ),
  Item(
    id: 'first_aid_kit',
    name: '急救包',
    image: 'images/items/first_aid_kit.png',
    description: '专业急救用品，能显著提升生存能力。',
    type: 'item',
    effects: const {'hp': 35, 'san': 10},
    usageTime: 5000,
    level: 4,
    availableInShop: true,
    basePrice: 55,
  ),
  Item(
    id: 'chocolate',
    name: '巧克力',
    image: 'images/items/chocolate.png',
    description: '甜蜜能驱散疲惫，非常受欢迎。',
    type: 'item',
    effects: const {'food': 8, 'san': 22},
    usageTime: 2000,
    level: 3,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'bone',
    name: '骨头',
    image: 'images/items/bone.png',
    description: '普通。',
    type: 'item',
    effects: const {},
    usageTime: 0,
    level: 1,
    availableInShop: false,
  ),
  Item(
    id: 'steak',
    name: '牛排',
    image: 'images/items/steak.png',
    description: '香气四溢的熟牛排，大幅恢复状态。',
    type: 'item',
    effects: const {'food': 45, 'hp': 10, 'san': 6},
    usageTime: 4500,
    level: 4,
    availableInShop: true,
    basePrice: 35,
  ),
  Item(
    id: 'obsidian_revolver',
    name: '黑曜左轮',
    image: 'images/items/obsidian_revolver.png',
    description: '以黑曜石抛光的高精度左轮，枪口火光如闪电般夺目。',
    type: 'equipment',
    equipmentSlot: 'weapon',
    level: 6,
    availableInShop: false, // 更稀有，可掉落
    weaponParams: const {
      'attackType': 'ranged',
      'fireMode': 'semiauto',
      'bulletSize': 1.4,
      'trailEffect': 70, // 中等尾迹效果
      'penetrateWalls': false,
      'penetrateGhosts': false,
      'reloadMs': 2400, // 比普通左轮更慢
      'fireIntervalMs': 480,
      'effectColor': 0xFFFFF0E0,
      'distance': 7,
      'range': 15,
      'damageAmplify': 1.75, // 超高伤害倍率
      'critDamage': 2.8, // 史诗级暴击倍率
      'critChanceBonus': 0.22, // 高暴击率
      'magazineSize': 6,
      'ammoTotal': 36,
    },
  ),
];

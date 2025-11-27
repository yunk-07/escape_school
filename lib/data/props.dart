// data/props.dart
// 物品数据配置文件：定义物品基础信息、使用效果与装备加成
// 关键区域：类型与槽位映射
// - 类型字段支持：'item'、'equipment'；兼容旧中文 '物品'、'装备' 及 '武器/甲/头/背包/裤子/鞋'
// - 槽位对应：weapon / armor / head / bag / pants / shoes
//   说明：不再支持历史槽位 'hand'
// 关键区域：效果与加成的区别
// - effects：消耗类使用效果（仅在点击“使用”时生效）
// - equipEffects：装备类佩戴加成（仅在“装备”后生效）
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
  final Map<String, dynamic>? weaponParams;
  // final Map<String, int>? equipEffects; // 装备效果加成（佩戴生效）

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
  });
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
    equipmentSlot: 'footwear',
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
      'range': 2,
      'damageAmplify': 0.8,
      'critDamage': 1.1,
      'critChanceBonus': 2.0,
      'magazineSize': 70,
      'ammoTotal': 700,
      'bulletSize': 1.2,
    },
    level: 7,
    availableInShop: false,
  ),
];

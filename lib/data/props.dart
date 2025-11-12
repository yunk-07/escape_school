// data/props.dart
// 物品数据配置文件 - 包含物品的基本信息、效果和使用时间
// 关键区域：统一物品类型为“物品/装备”，并为装备提供部位与加成
// 关键区域：装备栏类别与 equipmentSlot 对应关系（备注在此）：
// - 武器 -> equipmentSlot: 'weapon'
// - 护甲 -> equipmentSlot: 'armor'
// - 头部 -> equipmentSlot: 'head'
// - 背包 -> equipmentSlot: 'bag'  
// - 裤子 -> equipmentSlot: 'pants'
// - 鞋子 -> equipmentSlot: 'shoes'
// 关键区域：effects 支持可变上限修改
// 支持的效果键：
// - hp:        修改生命值（按当前 maxHp 夹取）
// - maxHp:     修改生命值上限（至少为 1；若降低会夹取 hp）
// - food:      修改饱食度（按当前 maxFood 夹取）
// - maxFood:   修改饱食度上限（至少为 1；若降低会夹取 food）
// - san:       修改精神值（按 0..250 夹取）
// - moveSpeed: 修改移动速度（不设上限，最小 1）
// - gold:      修改金币
// - oxygenBonus: 修改氧气上限（已在状态机中处理）
class Item {
  final String id;
  final String name;
  final String image;
  final String description;
  final Map<String, int> effects; // {hp: 10, gold: 5, maxHp: 20, maxFood: -10}
  final String type; // 新增：物品类型（严格为“物品”或“装备”）
  final int count;   // 新增：物品数量
  final bool availableInShop; // 新增：是否在商店出售
  final int basePrice;       // 新增：基础价格
  final int usageTime;       // 新增：使用时间（毫秒）
  final int level;           // 新增：物品等级（1-7）
  // 关键区域：装备专属字段
  final String? equipmentSlot; // 装备部位：weapon/armor/head/bag/pants/shoes
  final Map<String, int>? equipEffects; // 装备效果加成（佩戴生效）

  Item({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.effects,
    this.type = '物品', // 默认类型为“物品”
    this.count = 1,
    this.availableInShop = false, // 默认不在商店出售
    this.basePrice = 0,
    this.usageTime = 2000, // 默认使用时间2秒
    this.level = 1, // 默认等级1（无色）
    this.equipmentSlot,
    this.equipEffects,
  });
}

final List<Item> allItems = [
  Item(
    id: 'hanbao',
    name: '美去人通便汉堡',
    image: 'images/items/hanbao.png',
    description: '钻研肠胃科主任为何把最灵的药藏在这里',
    effects: {'hp': -2,'food': 20},
    type: '物品',
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
    effects: {'hp': -5,'food':10,'san':-5,'moveSpeed':-5}, // 移动速度减少5
    type: '物品',
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
    effects: {'hp': -5,'food':50,'san':20},
    type: '物品',
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
    effects: {'hp': -10,'food':5,'san':-15,'moveSpeed':-5}, // 移动速度减少5
    type: '物品',
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
      effects: {'san':-25,'moveSpeed': 10}, // 移动速度增加10
      type: '物品',
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
    effects: {'san':-30,'hp':-10,'food':20,},
    level: 3,
    availableInShop: false,
    usageTime: 5000
    ),

  Item(
    id: 'energy_bar',
    name: '能量棒',
    image: 'images/items/oxbang.png',
    description: '高能量营养棒，能够快速恢复体力和精神状态',
    effects: {'san': 10, 'oxygenBonus': 1, 'food': 10, 'hp': 5},
    type: '物品',
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
    effects: {'san': 10, 'hp': 20, 'food': 10,'maxHp':1},
    type: '物品',
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
    type: '物品',
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
    type: '物品',
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
    type: '物品',
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
    type: '物品',
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
    effects: {'san': 20, 'food': 5,},
    type: '物品',
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
    effects: {'san': 40, 'food': 1,'maxHp':-1,'moveSpeed':-1,'oxygenBonus':-1},
    type: '物品',
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
    type: '装备',
    equipmentSlot: 'weapon',
    equipEffects: const {'moveSpeed': 3},
    level: 2,
    availableInShop: false,
  ),
  Item(
    id: 'armor_school_uniform',
    name: '校服',
    image: 'images/items/xiaofu.png',
    description: '普通校服，增加最大生命值',
    effects: const {},
    type: '装备',
    equipmentSlot: 'armor',
    equipEffects: const {'maxHp': 10},
    level: 2,
    availableInShop: true,
    basePrice: 80,
  ),
  Item(
    id: 'head_hat',
    name: '帽子',
    image: 'images/items/hat.png',
    description: '普通帽子，更加专注',
    effects: const {},
    type: '装备',
    equipmentSlot: 'head',
    equipEffects: const {'san': 5},
    level: 2,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'niuzai_hat',
    name: '牛仔帽',
    image: 'images/items/niuzai.png',
    description: '无所畏惧',
    effects: const {'maxHp': -40,'moveSpeed': 70,'san': 20},
    type: '装备',
    equipmentSlot: 'head',
    equipEffects: const {'maxHp': -40,'moveSpeed': 70,'san': 20},
    level: 4,
    availableInShop: true,
    basePrice: 20,
  ),
  Item(
    id: 'hand_gloves',
    name: '手套', 
    image: 'images/items/hand_gloves.png',
    description: '保暖手套，略增氧气上限',
    effects: const {},
    type: '武器', // 关键区域：手套归类为“武器”
    equipmentSlot: 'weapon', // 关键区域：对应武器槽
    equipEffects: const {'oxygenBonus': 1},
    level: 2,
    availableInShop: false,
  ),
  Item(
    id: 'pants_school_uniform',
    name: '校裤',
    image: 'images/items/xiaoku.png',
    description: '普通校裤，增加最大生命值',
    effects: const {'maxHp': 10},
    type: '装备',
    equipmentSlot: 'pants',
    equipEffects: const {'maxHp': 10},
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
    type: '物品',
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
    type: '背包', // 关键区域：背包归类为“背包”
    // 关键区域：背包装备到 bag 槽位，装备效果为增加2格背包容量
    equipmentSlot: 'bag',
    equipEffects: const {'inventoryBonus': 2},
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
    type: '物品',
    level: 6,
    availableInShop: false,
    usageTime: 0,
  ),
];
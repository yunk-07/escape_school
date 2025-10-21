/**
 * 角色配置文件
 * 
 * 此文件定义了游戏中所有角色的配置数据，包括：
 * - 基础属性（生命值、理智值、攻击力等）
 * - 显示属性（贴图路径、大小比例）
 * - 移动属性（速度、碰撞检测范围）
 * - 经济属性（初始金币、食物）
 * 
 * 方便后期添加新角色和调整角色平衡性
 */

/// 角色配置类
class CharacterConfig {
  // 基础信息
  final String id;              // 角色唯一标识
  final String name;            // 角色名称
  final String description;     // 角色描述
  final String imagePath;       // 角色贴图路径
  
  // 基础属性
  final int maxHp;              // 最大生命值
  final int maxSan;             // 最大理智值
  final int attack;             // 攻击力
  final int initialGold;        // 初始金币
  final int initialFood;        // 初始食物
  
  // 显示属性
  final double sizeScale;       // 相对于瓦片大小的缩放比例（默认0.6）
  final double spriteOffsetX;   // 贴图X轴偏移（用于居中调整）
  final double spriteOffsetY;   // 贴图Y轴偏移（用于居中调整）
  
  // 移动属性
  final double moveSpeed;       // 移动速度（像素/秒）
  final double collisionScale;  // 碰撞检测范围相对于显示大小的比例
  
  // 特殊属性
  final Map<String, dynamic> specialAbilities; // 特殊能力
  final List<String> startingItems;            // 初始物品

  const CharacterConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.maxHp,
    required this.maxSan,
    required this.attack,
    required this.initialGold,
    required this.initialFood,
    this.sizeScale = 0.6,
    this.spriteOffsetX = 0.0,
    this.spriteOffsetY = 0.0,
    this.moveSpeed = 100.0,
    this.collisionScale = 0.8,
    this.specialAbilities = const {},
    this.startingItems = const [],
  });

  /// 从Map创建角色配置（用于JSON序列化）
  factory CharacterConfig.fromMap(Map<String, dynamic> map) {
    return CharacterConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      maxHp: map['maxHp'] ?? 100,
      maxSan: map['maxSan'] ?? 100,
      attack: map['attack'] ?? 5,
      initialGold: map['initialGold'] ?? 0,
      initialFood: map['initialFood'] ?? 10,
      sizeScale: map['sizeScale']?.toDouble() ?? 0.6,
      spriteOffsetX: map['spriteOffsetX']?.toDouble() ?? 0.0,
      spriteOffsetY: map['spriteOffsetY']?.toDouble() ?? 0.0,
      moveSpeed: map['moveSpeed']?.toDouble() ?? 100.0,
      collisionScale: map['collisionScale']?.toDouble() ?? 0.8,
      specialAbilities: Map<String, dynamic>.from(map['specialAbilities'] ?? {}),
      startingItems: List<String>.from(map['startingItems'] ?? []),
    );
  }

  /// 转换为Map（用于JSON序列化）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'maxHp': maxHp,
      'maxSan': maxSan,
      'attack': attack,
      'initialGold': initialGold,
      'initialFood': initialFood,
      'sizeScale': sizeScale,
      'spriteOffsetX': spriteOffsetX,
      'spriteOffsetY': spriteOffsetY,
      'moveSpeed': moveSpeed,
      'collisionScale': collisionScale,
      'specialAbilities': specialAbilities,
      'startingItems': startingItems,
    };
  }
}

/// 预定义的角色配置
class CharacterConfigs {
  static const List<CharacterConfig> allCharacters = [
    // 厨师角色
    CharacterConfig(
      id: 'cook',
      name: '厨师',
      description: '猜猜今天吃什么？',
      imagePath: 'images/man/cook.png',
      maxHp: 80,
      maxSan: 50,
      attack: 10,
      initialGold: 66,
      initialFood: 50,
      sizeScale: 0.6,
      moveSpeed: 90.0,  // 稍慢，但攻击力高
      collisionScale: 0.8,
      specialAbilities: {
        'cooking': true,        // 可以烹饪
        'foodBonus': 1.5,      // 食物效果加成
      },
      startingItems: ['knife'], // 初始携带刀具
    ),
    
    // 困倦者角色
    CharacterConfig(
      id: 'sleepy',
      name: '已经困了',
      description: '睡觉何尝不是战斗的方式？',
      imagePath: 'images/man/sleep.png',
      maxHp: 100,
      maxSan: 80,
      attack: 5,
      initialGold: 10,
      initialFood: 20,
      sizeScale: 0.6,
      moveSpeed: 70.0,  // 移动较慢
      collisionScale: 0.8,
      specialAbilities: {
        'sleepRecover': true,   // 睡眠恢复能力
        'sanityBonus': 1.2,    // 理智恢复加成
      },
      startingItems: ['pillow'], // 初始携带枕头
    ),
    

  ];

  /// 根据ID获取角色配置
  static CharacterConfig? getCharacterById(String id) {
    try {
      return allCharacters.firstWhere((config) => config.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取所有角色ID列表
  static List<String> getAllCharacterIds() {
    return allCharacters.map((config) => config.id).toList();
  }

  /// 获取所有角色名称列表
  static List<String> getAllCharacterNames() {
    return allCharacters.map((config) => config.name).toList();
  }
}
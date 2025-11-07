
/**
 * 角色数据配置文件
 * 
 * 此文件定义了游戏中角色的基础数据，包括：
 * - 基础属性（生命值、理智值、移动速度等）
 * - 经济属性（初始金币、食物）
 * - 显示属性（名称、描述、贴图路径）
 * 
 * moveSpeed字段表示角色的移动速度（像素/秒）
 * 
 * 关键区域：支持最大值配置
 * 可选字段：
 * - maxHp    最大生命值（未设置则默认等于 hp）
 * - maxSan   最大精神值（未设置则默认等于 san）
 * - maxFood  最大饱食度（未设置则默认等于 food）
 */

final List<Map<String, dynamic>> manData = const [
  {
    'name': '厨师',
    'image': 'images/man/cook.png',
    'gold': 66,
    'hp': 80,
    'maxHp': 80,      // 最大生命值（可调整）
    'san': 50,
    'maxSan': 50,     // 最大精神值（可调整）
    'description': '猜猜今天吃什么？',
    'moveSpeed': 90.0,  // 移动速度：90像素/秒
    'food': 10,
    'maxFood': 90,    // 最大饱食度（可调整）
    'maxOxygen': 10.0,  // 最大氧气值
  },
  {
    'name': '已经困了',
    'image': 'images/man/sleep.png',
    'gold': 10,
    'hp': 100,
    'maxHp': 100,
    'san': 80,
    'maxSan': 80,
    'description': '睡觉何尝不是战斗的方式？',
    'moveSpeed': 70.0,  // 移动速度：70像素/秒
    'food': 80,
    'maxFood': 100,
    'maxOxygen': 10.0,  // 最大氧气值
  },
  {
    'name': '速度之王',
    'image': 'images/man/sleep.png',
    'gold': 10,
    'hp': 100,
    'maxHp': 100,
    'san': 80,
    'maxSan': 80,
    'description': '睡觉何尝不是战斗的方式？',
    'moveSpeed': 200.0,  // 移动速度：200像素/秒
    'food': 20,
    'maxFood': 20,
    'maxOxygen': 10.0,  // 最大氧气值
  },

{
    'name': '开发者',
    'image': 'images/man/sleep.png',
    'gold': 1000,
    'hp': 1000,
    'maxHp': 1000,
    'san': 1000,
    'maxSan': 1000,
    'description': '睡觉何尝不是战斗的方式？',
    'moveSpeed': 200.0,  // 移动速度：200像素/秒
    'food': 200,
    'maxFood': 200,
    'maxOxygen': 15.0,  // 最大氧气值（开发者有更多氧气）
  },
];
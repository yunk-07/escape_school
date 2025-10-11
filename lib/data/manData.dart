
/**
 * 角色数据配置文件
 * 
 * 此文件定义了游戏中角色的基础数据，包括：
 * - 基础属性（生命值、理智值、移动速度等）
 * - 经济属性（初始金币、食物）
 * - 显示属性（名称、描述、贴图路径）
 * 
 * moveSpeed字段表示角色的移动速度（像素/秒）
 */

final List<Map<String, dynamic>> manData = const [
  {
    'name': '厨师',
    'image': 'images/man/cook.png',
    'gold': 66,
    'hp': 80,
    'san': 50,
    'description': '猜猜今天吃什么？',
    'moveSpeed': 90.0,  // 移动速度：90像素/秒
    'food': 10,
  },
  {
    'name': '已经困了',
    'image': 'images/man/sleep.png',
    'gold': 10,
    'hp': 100,
    'san': 80,
    'description': '睡觉何尝不是战斗的方式？',
    'moveSpeed': 70.0,  // 移动速度：70像素/秒
    'food': 20,
  },
  {
    'name': '速度之王',
    'image': 'images/man/sleep.png',
    'gold': 10,
    'hp': 100,
    'san': 80,
    'description': '睡觉何尝不是战斗的方式？',
    'moveSpeed': 200.0,  // 移动速度：70像素/秒
    'food': 20,
  },

];
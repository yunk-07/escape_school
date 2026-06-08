/*
 * 植物详情页按钮功能实现说明
 * 
 * ==============================
 * 使用方法 (Usage Instructions)
 * ==============================
 * 
 * 本文件实现了植物详情页的所有操作按钮，包括浇水、采摘和挖除功能。
 * 
 * 文件路径: lib/game/plant_page.dart
 * 
 * 主要方法:
 * 
 * 1. 浇水功能 (_waterPlant)
 *    - 消耗资源: 6饱食度 + 1精神值
 *    - 效果: 植物生长速度+10%
 *    - 使用条件: 植物需要浇水(needsWater=true)
 *    - 按钮状态: 需要时显示蓝色"浇水", 不需要时显示灰色"已浇水"
 * 
 * 2. 采摘功能 (_harvestPlant)
 *    - 消耗资源: 无
 *    - 效果: 获得对应物品 (玉米2个, 胡萝卜3个), 10%几率获得额外随机物品
 *    - 使用条件: 植物完全成熟(isHarvestable=true)
 *    - 按钮状态: 成熟时显示橙色"采摘", 未成熟时显示灰色"未成熟"
 * 
 * 3. 挖除功能 (_removePlant)
 *    - 消耗资源: 1饱食度
 *    - 效果: 移除植物(不获得任何物品)
 *    - 使用条件: 任何植物
 *    - 按钮状态: 始终显示红色"挖除"
 * 
 * ==============================
 * 内部键说明 (Internal Keys)
 * ==============================
 * 
 * 植物对象键 (Plant Object Keys):
 * - 'id': 植物唯一标识符
 * - 'growthProgress': 生长进度 (0.0-1.0+)
 * - 'currentStage': 当前阶段 (seed/sprout/growing/mature/withered)
 * - 'needsWater': 是否需要浇水 (boolean)
 * - 'isHarvestable': 是否可采摘 (boolean)
 * - 'lastWateredTime': 最后浇水时间 (DateTime)
 * - 'plantedTime': 种植时间 (DateTime)
 * 
 * 游戏状态键 (Game State Keys):
 * - 'food': 饱食度资源
 * - 'san': 精神值资源
 * - 'health': 生命值
 * - 'water': 水资源
 * - 'energy': 体力值
 * 
 * 物品类型键 (Item Type Keys):
 * - 'corn': 玉米
 * - 'carrot': 胡萝卜
 * - 'corn_seed': 玉米种子
 * - 'carrot_seed': 胡萝卜种子
 * 
 * 按钮状态键 (Button State Keys):
 * - 'backgroundColor': 按钮背景色 (Colors.blue[500], Colors.orange[500], Colors.red[500], Colors.grey[500])
 * - 'label': 按钮文字 ('浇水', '已浇水', '采摘', '未成熟', '挖除')
 * - 'enabled': 按钮是否可点击 (boolean)
 * 
 * ==============================
 * 事件处理流程 (Event Flow)
 * ==============================
 * 
 * 1. 用户点击按钮
 *    ↓
 * 2. 触发对应方法 (_waterPlant/_harvestPlant/_removePlant)
 *    ↓
 * 3. 检查资源条件 (food >= 6, san >= 1, 等)
 *    ↓
 * 4. 更新游戏状态 (消耗资源)
 *    ↓
 * 5. 调用种植系统方法 (waterPlantWithBonus/harvestPlant/removePlant)
 *    ↓
 * 6. 显示操作结果提示 (SnackBar)
 *    ↓
 * 7. 关闭详情页 (Navigator.pop)
 * 
 * ==============================
 * 资源消耗详情 (Resource Cost)
 * ==============================
 * 
 * 浇水: 6饱食度 + 1精神值 = 7点总资源
 * 采摘: 0资源消耗
 * 挖除: 1饱食度
 * 
 * 收获奖励:
 * - 玉米: 基础2个 + 10%几率获得随机物品
 * - 胡萝卜: 基础3个 + 10%几率获得随机物品
 * 
 * ==============================
 * 状态管理 (State Management)
 * ==============================
 * 
 * 使用Riverpod进行状态管理:
 * - gameStateProvider: 游戏整体状态
 * - optimizedGameStateProvider: 优化后的游戏状态
 * - plantingSystemProvider: 种植系统状态
 * 
 * 状态更新流程:
 * 1. 读取当前状态
 * 2. 创建新状态副本
 * 3. 修改对应字段
 * 4. 更新状态提供者
 * 
 * ==============================
 * 错误处理 (Error Handling)
 * ==============================
 * 
 * 所有方法都包含完整的错误处理:
 * - 资源不足检查
 * - 植物存在性验证
 * - 异常捕获和显示
 * - 失败时资源恢复
 * 
 * 错误信息会通过SnackBar显示给用户。
 */
// game/inventory_page.dart
// 背包页面组件 - 保持原布局，显示角色信息和背包物品，支持物品图片和确认框

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker, TickerProviderStateMixin;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_from_school/game/optimized_game_state.dart';
import 'package:escape_from_school/game/time.dart'; // 关键区域：引入游戏时间格式化工具，用于显示当前游戏时间
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/game/music.dart';
import 'package:escape_from_school/game/ui_theme.dart'
    as ui_theme; // 关键区域：引入统一UI主题用于属性进度条渐变
import 'package:escape_from_school/utils/level_color_manager.dart';

/// 背包页面组件 - 原布局风格
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with TickerProviderStateMixin {
  // 拖拽状态管理
  bool _isDragging = false;
  // 关键区域：心电图相位控制（与外部样式一致，通过 Ticker 驱动）
  Ticker? _ecgTicker;
  double _ecgPhase = 0.0;

  @override
  void initState() {
    super.initState();
    // 关键区域：启动 Ticker，以 60fps 左右更新相位，从而驱动心电图动画
    _ecgTicker = createTicker((elapsed) {
      setState(() {
        _ecgPhase = elapsed.inMilliseconds / 1000.0; // 将毫秒换算为秒级相位
      });
    });
    _ecgTicker!.start();
  }

  @override
  void dispose() {
    // 关键区域：释放 Ticker，防止资源泄漏
    _ecgTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(optimizedGameStateProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.95),
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.blue.shade400.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 15,
                spreadRadius: 3,
                offset: const Offset(0, 5),
              ),
              // 关键区域：增加柔光外阴影，提升整体厚重感
              BoxShadow(
                color: Colors.blue.shade200.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          // 关键区域：增加前景高光渐变，模拟上左高光与下右微光，增强立体感
          foregroundDecoration: BoxDecoration(
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.transparent,
                Colors.white.withOpacity(0.03),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Column(
            children: [
              // 标题栏
              _buildHeader(context, ref),
              // 主要内容区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧：角色信息面板
                    Expanded(
                      flex: 2,
                      child: _buildCharacterInfoPanel(gameState),
                    ),
                    // 分隔线
                    Container(
                      width: 1,
                      color: Colors.blue.shade400.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    // 右侧：背包物品区域
                    Expanded(
                      flex: 3,
                      child: _buildInventoryPanel(gameState, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade700],
        ),
        // 关键区域：标题栏上侧圆角统一为5
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // 关键区域：标题栏前景高光，增强整体质感
      foregroundDecoration: BoxDecoration(
        // 关键区域：标题栏上侧圆角统一为5
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.transparent,
            Colors.white.withOpacity(0.03),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Row(
        children: [
          // 左侧：健康模块 (对应下方角色信息面板 flex: 2)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade700.withOpacity(0.28),
                    Colors.green.shade800.withOpacity(0.32),
                  ],
                ),
                // 关键区域：统一圆角为5
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.green.shade300, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '健康',
                    style: TextStyle(
                      color: Colors.green.shade100,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 分隔线 (对应下方的分隔线)
          Container(
            width: 1,
            height: 20,
            color: Colors.blue.shade400.withOpacity(0.3),
          ),

          // 右侧：背包模块和退出按钮 (对应下方背包物品区域 flex: 3)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // 背包标题
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      // 关键区域：背包标题去除黄色，采用青蓝胶囊标签风格
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.cyan.shade700.withOpacity(0.28),
                          Colors.cyan.shade800.withOpacity(0.32),
                        ],
                      ),
                      // 关键区域：统一圆角为5
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Colors.cyanAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '背包',
                          style: TextStyle(
                            color: Colors.cyanAccent.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 退出按钮
                Container(
                  decoration: BoxDecoration(
                    // 关键区域：退出按钮美化为胶囊风格，微霓虹边与柔光
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red.shade600, Colors.red.shade700],
                    ),
                    // 关键区域：调整退出按钮圆角为更小值
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.55),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      // 关键区域：统一圆角为5
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        final notifier = ref.read(
                          optimizedGameStateProvider.notifier,
                        );
                        notifier.toggleInventory();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              '退出',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建角色信息面板
  Widget _buildCharacterInfoPanel(OptimizedGameState gameState) {
    final stats = gameState.characterStats;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 只显示角色属性，移除头像和名字
            _buildCharacterStats(stats),
          ],
        ),
      ),
    );
  }

  /// 构建角色属性统计
  Widget _buildCharacterStats(Map<String, dynamic> stats) {
    // 计算最近鬼距离并映射为接近度因子（0-1）
    final gameState = ref.watch(optimizedGameStateProvider);
    final playerGrid = gameState.playerPosition.toPoint();
    double minGhostDistance = double.infinity;
    for (final ghost in gameState.ghostManager.ghosts) {
      if (ghost.position != null && !ghost.isInvisible) {
        final gp = ghost.position!.toPoint();
        final dx = (playerGrid.x - gp.x).toDouble();
        final dy = (playerGrid.y - gp.y).toDouble();
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < minGhostDistance) minGhostDistance = d;
      }
    }
    const double dangerRange = 25.0; // 在25格内开始显著影响心跳
    final double proximityFactor =
        minGhostDistance.isFinite
            ? ((dangerRange - minGhostDistance) / dangerRange).clamp(0.0, 1.0)
            : 0.0;
    // 背包打开时也根据接近度触发/更新心跳音效
    MusicManager().updateHeartbeat(proximityFactor);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        // 关键区域：统一圆角为5
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 属性详情标题和心电图
          // 关键区域：将“属性详情”替换为当前游戏时间，并统一心电图样式为外部风格
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 关键区域：美化游戏时间显示为胶囊标签（图标 + 渐变 + 边框）
              // 关键区域：固定时间标签宽度，避免文本变长时挤压右侧心电图
              Container(
                width: 120, // 固定宽度，大小始终不变
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // 关键区域：统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueGrey.shade900.withOpacity(0.55),
                      Colors.blueGrey.shade800.withOpacity(0.55),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.cyanAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    // 关键区域：限制时间文本不换行，超出以省略号处理，保证尺寸不变
                    Expanded(
                      child: Text(
                        GameTime.formatGameTime(
                          DateTime.now()
                              .difference(gameState.gameStartTime)
                              .inMilliseconds,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧：统一外部心电图样式（科技感网格 + ECG 标签）
              _buildInventoryECG(stats, gameState, proximityFactor),
            ],
          ),
          const SizedBox(height: 8), // 关键区域：缩小整体间距
          // 关键区域：生命值进度条
          _buildStatWithBar(
            '生命值',
            ((stats['hp'] ?? 0) as num).toDouble(),
            ((stats['maxHp'] ?? 0) as num).toDouble(),
            Icons.favorite,
            Colors.red,
          ),

          // 关键区域：理智值进度条
          _buildStatWithBar(
            '理智值',
            ((stats['san'] ?? 0) as num).toDouble(),
            ((stats['maxSan'] ?? 250) as num).toDouble(),
            Icons.psychology,
            Colors.blue,
          ),

          // 关键区域：饱食度进度条（使用动态 maxFood 上限）
          _buildStatWithBar(
            '饱食度',
            ((stats['food'] ?? 0) as num).toDouble(),
            ((stats['maxFood'] ?? 100) as num).toDouble(),
            Icons.restaurant,
            Colors.green,
          ),

          // 关键区域：肺活量（氧气值）进度条
          _buildOxygenStatRow(),

          // 金币 - 显示小数点后两位
          _buildStatRow(
            '金币',
            '${_formatToTwoDigits(stats['gold'])}',
            Icons.monetization_on,
            Colors.yellow,
          ),

          // 关键区域：移动速度显示（原始速度删除线灰色 + 当前被削弱速度）
          _buildMoveSpeedRow(stats),

          // 战斗属性：伤害/暴击几率/暴击伤害（按当前武器增幅计算）
          Builder(
            builder: (context) {
              final gameState2 = ref.watch(optimizedGameStateProvider);
              final double baseDamage =
                  ((gameState2.characterStats['baseDamage'] ?? 0) as num)
                      .toDouble();
              final double amp =
                  (gameState2.weaponDamageAmplify ?? 1.0).toDouble();
              final double effDamage = baseDamage * amp;

              final double baseCritChance =
                  ((gameState2.characterStats['baseCritChance'] ?? 0.0) as num)
                      .toDouble();
              final double critBonus =
                  (gameState2.weaponCritChanceBonus ?? 0.0).toDouble();
              final double effCritChance = (baseCritChance + critBonus).clamp(
                0.0,
                1.0,
              );

              final double effCritDamage =
                  (gameState2.weaponCritDamage ?? 1.5).toDouble();

              return Column(
                children: [
                  _buildStatRow(
                    '伤害',
                    _formatCombatValue(effDamage),
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  _buildStatRow(
                    '暴击几率',
                    '${(effCritChance * 100).toStringAsFixed(0)}%',
                    Icons.bolt,
                    Colors.amber,
                  ),
                  _buildStatRow(
                    '暴击伤害',
                    '${_formatCombatValue(effCritDamage)} 倍',
                    Icons.auto_awesome,
                    Colors.purpleAccent,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 关键区域：通用属性行（带进度条）
  /// 美化策略：
  /// - 顶部为图标+标签+数值，底部为统一主题的渐变进度条
  /// - 使用 UITheme.progressBackground / progressFill 渐变，风格与全局一致
  Widget _buildStatWithBar(
    String label,
    double current,
    double max,
    IconData icon,
    Color color,
  ) {
    final double safeMax = max <= 0 ? 1.0 : max;
    final double ratio = (current / safeMax).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 关键区域：缩小垂直间距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16), // 关键区域：缩小图标
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14, // 关键区域：缩小标签文字
                  ),
                ),
              ),
              Text(
                '${_formatToTwoDigits(current)}/${_formatToTwoDigits(max)}',
                style: TextStyle(
                  color: color,
                  fontSize: 14, // 关键区域：缩小数值文字
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 关键区域：统一主题进度条
          ClipRRect(
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 6, // 关键区域：缩小进度条厚度
              decoration: BoxDecoration(
                gradient: ui_theme.UITheme.progressBackground(),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: ui_theme.UITheme.progressFill(color),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个属性行
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 关键区域：缩小垂直间距
      child: Row(
        children: [
          Icon(icon, color: color, size: 16), // 关键区域：缩小图标
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14, // 关键区域：缩小标签文字
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14, // 关键区域：缩小数值文字
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 关键区域：构建“移动速度”专用行（展示原始与当前）
  Widget _buildMoveSpeedRow(Map<String, dynamic> stats) {
    final gameState = ref.watch(optimizedGameStateProvider);
    // 基础速度（角色面板中的原值）
    final double baseSpeed = ((stats['moveSpeed'] ?? 100) as num).toDouble();
    // 水中降低10%
    final bool isUnderwater = gameState.oxygenSystem?.isUnderwater == true;
    double currentSpeed = isUnderwater ? baseSpeed * 0.9 : baseSpeed;
    // 饱食度低于50%线性降低到50%
    final double food = ((stats['food'] ?? 0) as num).toDouble();
    // 关键区域：饱食度上限改为动态 maxFood
    final double maxFood = ((stats['maxFood'] ?? 100) as num).toDouble();
    final double foodPct = (food / maxFood).clamp(0.0, 1.0);
    if (foodPct < 0.5) {
      final double hungerSpeedMultiplier = 0.5 + foodPct; // 0.5~1.0
      currentSpeed *= hungerSpeedMultiplier;
    }

    // 关键区域：进度条比例计算
    final double safeBase = baseSpeed <= 0 ? 1.0 : baseSpeed;
    final double brightRatio = (currentSpeed / safeBase).clamp(0.0, 1.0);
    final double grayRatio = (1.0 - brightRatio).clamp(0.0, 1.0);
    const int totalFlex = 100;
    final int brightFlex = (brightRatio * totalFlex).round();
    final int grayFlex = totalFlex - brightFlex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 关键区域：缩小垂直间距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_run, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '移动速度',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              // 原始速度（删除线灰色） + 当前速度（高亮）
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatToTwoDigits(baseSpeed),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12, // 关键区域：缩小基础速度文字
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatToTwoDigits(currentSpeed),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14, // 关键区域：缩小当前速度文字
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 关键区域：移动速度双段进度条（亮色=削弱后速度，灰色=被削弱部分）
          ClipRRect(
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: ui_theme.UITheme.progressBackground(),
              ),
              child: Row(
                children: [
                  if (brightFlex > 0)
                    Expanded(
                      flex: brightFlex,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ui_theme.UITheme.progressFill(
                            Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  if (grayFlex > 0)
                    Expanded(
                      flex: grayFlex,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ui_theme.UITheme.progressFill(Colors.grey),
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

  /// 构建氧气值（肺活量）属性行
  Widget _buildOxygenStatRow() {
    return Consumer(
      builder: (context, WidgetRef ref, child) {
        final gameState = ref.watch(optimizedGameStateProvider);
        final maxOxygen = gameState.actualMaxOxygen;
        // 关键区域：根据需求调整为仅显示上限，不再显示当前值或进度条
        // 说明：用户要求“肺活量仅显示上限”，因此这里改为使用纯文本行展示最大肺活量。
        return _buildStatRow(
          '肺活量',
          _formatToTwoDigits(maxOxygen),
          Icons.air,
          Colors.cyan,
        );
      },
    );
  }

  /// 关键区域：背包页心电图，统一外部样式（科技感网格与ECG标签），避免循环依赖，复刻绘制器
  Widget _buildInventoryECG(
    Map<String, dynamic> stats,
    OptimizedGameState gameState,
    double proximityFactor,
  ) {
    // 参数计算与外部一致
    final double currentSan = (stats['san'] ?? 0).toDouble().clamp(0, 250);
    final double hp = (stats['hp'] ?? 0).toDouble();
    final double maxHp = (stats['maxHp'] ?? 100).toDouble();
    final double hpRatio = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    final double o2Ratio =
        (gameState.actualMaxOxygen > 0)
            ? (gameState.currentOxygen / gameState.actualMaxOxygen).clamp(
              0.0,
              1.0,
            )
            : 1.0;
    final double moveSpeed = ((stats['moveSpeed'] ?? 1.0) as num).toDouble();
    final double moveFactor = ((moveSpeed - 1.0) / 2.0).clamp(0.0, 1.0);
    final double castingFactor =
        gameState.currentCastingSkillId != null ? 1.0 : 0.0;
    final double damagePulse =
        (gameState.shouldShowDamageEffect == true)
            ? (gameState.lastDamageAmount.clamp(0.0, 50.0) / 50.0).clamp(
              0.2,
              1.0,
            )
            : 0.0;
    final bool isInWater = gameState.isInWater;

    return Container(
      width: 120, // 关键区域：缩小心电图宽度
      height: 54, // 关键区域：缩小心电图高度
      decoration: BoxDecoration(
        // 关键区域：统一圆角为5
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.88),
            Colors.grey.shade900.withOpacity(0.92),
          ],
        ),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 0),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: InventorySanityECGPainter(
                phase: _ecgPhase,
                san: currentSan,
                hpRatio: hpRatio,
                oxygenRatio: o2Ratio,
                moveFactor: moveFactor,
                castingFactor: castingFactor,
                damagePulse: damagePulse,
                isInWater: isInWater,
                proximityFactor: proximityFactor,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 8,
            child: Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: Colors.cyanAccent,
                  size: 12,
                ), // 关键区域：缩小标签图标
                const SizedBox(width: 4),
                Text(
                  'ECG',
                  style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.8),
                    fontSize: 10, // 关键区域：缩小标签文字
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建背包物品面板
  Widget _buildInventoryPanel(OptimizedGameState gameState, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 关键区域：调整布局 —— 将装备栏置于顶部，背包网格置于底部且可滑动
          _buildEquipmentSlots(gameState, ref),

          const SizedBox(height: 12),

          // 背包物品网格（卡片容器包裹，增强立体与层次）
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                // 关键区域：统一圆角为5
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueGrey.shade900.withOpacity(0.85),
                    Colors.black.withOpacity(0.80),
                  ],
                ),
                boxShadow: const [
                  // 关键区域：下方加深阴影，上方微亮，形成厚度感
                  BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              // 关键区域：取消大黄框（移除琥珀色边框），保留高光与阴影增强立体感
              // 关键区域：前景高光网格，增强质感
              foregroundDecoration: BoxDecoration(
                // 关键区域：统一圆角为5
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                    Colors.white.withOpacity(0.02),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildInventoryGrid(gameState, ref),
              ),
            ),
          ),

          // 垃圾桶拖拽区域 - 只在拖拽时显示
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isDragging ? 60 : 0,
            child:
                _isDragging ? _buildTrashCanArea(ref) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 关键区域：装备槽横向正方形布局（weapon/armor/head/bag/pants/shoes）
  Widget _buildEquipmentSlots(OptimizedGameState gameState, WidgetRef ref) {
    final slotsOrder = const [
      'weapon',
      'armor',
      'head',
      'bag',
      'pants',
      'shoes',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children:
          slotsOrder.map((slot) {
            final equipped = gameState.equipmentSlots[slot];
            final bool hasEquipped = equipped != null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: DragTarget<Item>(
                // 关键区域：按英文类型与槽位映射接受拖拽（equipment + equipmentSlot）
                onWillAcceptWithDetails: (details) {
                  final item = details.data;
                  if (item == null) return false;
                  final matchesByType =
                      (item.type == 'equipment' && item.equipmentSlot == slot);
                  return matchesByType;
                },
                onAccept: (item) {
                  ref
                      .read(optimizedGameStateProvider.notifier)
                      .equipItemToSlot(item, slot);
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  return GestureDetector(
                    onTap: () {
                      if (equipped != null) {
                        ref
                            .read(optimizedGameStateProvider.notifier)
                            .unequipItemFromSlot(slot);
                      }
                    },
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          // 关键区域：统一圆角为5
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            // 关键区域：装备状态高亮边框，融合全局风格
                            // 装备栏按 level 着色：悬停用琥珀，高亮用等级色
                            color:
                                isHovering
                                    ? Colors.amberAccent.withOpacity(0.85)
                                    : (hasEquipped
                                        ? _getItemLevelColor(
                                          equipped!.level,
                                        ).withOpacity(0.85)
                                        : Colors.grey.shade500.withOpacity(
                                          0.6,
                                        )),
                            width: 1.2,
                          ),
                          // 关键区域：背景渐变采用 UITheme，风格统一
                          gradient: ui_theme.UITheme.progressBackground(),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        // 关键区域：前景高光与装备状态微光，应作为 Container 的 foregroundDecoration
                        foregroundDecoration: BoxDecoration(
                          // 关键区域：统一圆角为5
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              // 关键区域：装备栏前景微光按 level 着色
                              (hasEquipped
                                      ? _getItemLevelColor(equipped!.level)
                                      : Colors.white)
                                  .withOpacity(hasEquipped ? 0.12 : 0.06),
                              Colors.transparent,
                              Colors.white.withOpacity(0.04),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                          // 关键区域：加入凹陷下去的内阴影效果（模拟内凹）
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.10),
                              blurRadius: 4,
                              spreadRadius: -2,
                              offset: const Offset(-2, -2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 6,
                              spreadRadius: -2,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            // 关键区域：统一圆角为5
                            borderRadius: BorderRadius.circular(5),
                            child: Stack(
                              children: [
                                // 关键区域：装备底层内容（图片或文字）
                                Positioned.fill(
                                  child:
                                      equipped == null
                                          ? Center(
                                            child: Text(
                                              _slotShortText(slot),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey.shade300,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                          : (equipped.image.isNotEmpty
                                              ? Image.asset(
                                                equipped.image,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (c, e, s) => Center(
                                                      child: Text(
                                                        _slotShortText(slot),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color:
                                                              _getItemLevelColor(
                                                                equipped!.level,
                                                              ),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                              : Center(
                                                child: Text(
                                                  _slotShortText(slot),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: _getItemLevelColor(
                                                      equipped!.level,
                                                    ),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )),
                                ),
                                // 关键区域：装备栏右下角显示耐久（仅对具备格挡的装备）
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Builder(
                                    builder: (context) {
                                      if (equipped == null)
                                        return const SizedBox.shrink();
                                      final int maxDur =
                                          equipped.effects?['armorValue'] ?? 0;
                                      final bool show =
                                          (equipped.type == 'equipment') &&
                                          maxDur > 0;
                                      if (!show) return const SizedBox.shrink();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          border: Border.all(
                                            color: _getItemLevelColor(
                                              equipped.level,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          '${equipped.count}/${maxDur}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
    );
  }

  IconData _slotIcon(String slot) {
    switch (slot) {
      case 'weapon':
        return Icons.security;
      case 'armor':
        return Icons.checkroom;
      case 'head':
        return Icons.masks;
      case 'bag':
        return Icons.pan_tool_alt;
      case 'pants':
        return Icons.roller_shades;
      case 'shoes':
        return Icons.hiking;
      default:
        return Icons.inventory_2;
    }
  }

  // 关键区域：槽位短标签（用于占位与贴图回退文字）
  String _slotShortText(String slot) {
    switch (slot) {
      case 'weapon':
        return '武器';
      case 'armor':
        return '护甲';
      case 'head':
        return '头部';
      case 'bag':
        return '背包';
      case 'pants':
        return '裤子';
      case 'shoes':
        return '鞋子';
      default:
        return '装备';
    }
  }

  String _slotLabel(String slot) {
    switch (slot) {
      case 'weapon':
        return '武器槽（拖拽装备到此）';
      case 'armor':
        return '护甲槽（拖拽装备到此）';
      case 'head':
        return '头部槽（拖拽装备到此）';
      case 'bag':
        return '背包槽（拖拽装备到此）';
      case 'pants':
        return '裤子槽（拖拽装备到此）';
      case 'shoes':
        return '鞋子槽（拖拽装备到此）';
      default:
        return '装备槽';
    }
  }

  /// 构建空背包提示
  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade700.withOpacity(0.3),
              // 关键区域：统一圆角为5
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.grey.shade500.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '背包是空的',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去探索世界寻找物品吧！',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 构建背包物品网格
  Widget _buildInventoryGrid(OptimizedGameState gameState, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10, // 10列布局
        crossAxisSpacing: 4, // 统一边距
        mainAxisSpacing: 4, // 统一边距
        childAspectRatio: 1.0, // 正方形比例
      ),
      itemCount: gameState.inventoryCapacity, // 固定显示背包容量数量的格子
      itemBuilder: (context, index) {
        // 如果索引小于实际物品数量，显示物品；否则显示空格子
        if (index < gameState.playerInventory.length) {
          final item = gameState.playerInventory[index];
          return _buildInventoryItem(item, ref, context);
        } else {
          return _buildEmptySlot(index, ref);
        }
      },
    );
  }

  /// 构建背包物品
  Widget _buildInventoryItem(Item item, WidgetRef ref, BuildContext context) {
    return DragTarget<Item>(
      onAccept: (Item draggedItem) {
        // 交换物品位置
        final notifier = ref.read(optimizedGameStateProvider.notifier);
        final inventory = ref.read(optimizedGameStateProvider).playerInventory;
        final fromIndex = inventory.indexWhere((i) => i.id == draggedItem.id);
        final toIndex = inventory.indexWhere((i) => i.id == item.id);
        if (fromIndex != -1 && toIndex != -1 && fromIndex != toIndex) {
          notifier.moveItemInInventory(fromIndex, toIndex);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return Container(
          decoration:
              isHovering
                  ? BoxDecoration(
                    // 关键区域：统一圆角为5
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      // 关键区域：移除黄色高亮，改为按物品等级着色的微霓虹边
                      color: _getItemLevelColor(item.level).withOpacity(0.85),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getItemLevelColor(item.level).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  )
                  : null,
          child: LongPressDraggable<Item>(
            data: item,
            onDragStarted: () {
              setState(() {
                _isDragging = true;
              });
            },
            onDragEnd: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            onDraggableCanceled: (velocity, offset) {
              setState(() {
                _isDragging = false;
              });
            },
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 40, // 缩小拖拽反馈尺寸适应10列布局
                height: 40,
                decoration: BoxDecoration(
                  // 关键区域：拖拽反馈渐变与阴影，提升立体质感
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getItemLevelColor(item.level).withOpacity(0.35),
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                  // 关键区域：统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _getItemLevelColor(item.level).withOpacity(0.9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getItemLevelColor(item.level).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    // 关键区域：顶部微光，模拟高光边缘
                    BoxShadow(
                      color: Colors.white.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                // 关键区域：前景高光叠加，增强质感
                foregroundDecoration: BoxDecoration(
                  // 关键区域：统一圆角为5
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.09),
                      Colors.transparent,
                      Colors.white.withOpacity(0.03),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // 物品图片 - 占据整个容器
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child:
                            item.image.isNotEmpty
                                ? Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      _getItemTypeIcon(item.type),
                                      color: Colors.white,
                                      size: 12, // 缩小图标尺寸适应10列布局
                                    );
                                  },
                                )
                                : Icon(
                                  _getItemTypeIcon(item.type),
                                  color: Colors.white,
                                  size: 12, // 缩小图标尺寸适应10列布局
                                ),
                      ),
                    ),

                    // 物品名称 - 左上角重叠显示
                    Positioned(
                      top: 1,
                      left: 1,
                      right: 8, // 为可能的数量显示留出空间
                      child: Text(
                        (item.type == 'item' && item.count > 1)
                            ? '${item.name} x ${item.count}'
                            : item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6, // 缩小文字尺寸适应10列布局
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: Offset(0.3, 0.3),
                              blurRadius: 0.5,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 关键区域：右下角显示耐久（仅对具备格挡的装备）
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Builder(
                        builder: (context) {
                          final int maxDur = item.effects?['armorValue'] ?? 0;
                          final bool show =
                              (item.type == 'equipment') && maxDur > 0;
                          if (!show) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${item.count}/${maxDur}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                // 关键区域：统一圆角为5
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(Icons.drag_indicator, color: Colors.grey, size: 24),
              ),
            ),
            child: GestureDetector(
              onTap: () => _showUseItemDialog(context, item, item.count, ref),
              // 关键区域：双击行为 —— 双击物品则使用，双击装备则装备
              // 说明：通过 _slotForItem 判断是否为装备；非装备视为可使用物品
              onDoubleTap: () {
                final slot = _slotForItem(item);
                if (slot != null) {
                  // 双击装备：直接装备到对应槽位
                  ref
                      .read(optimizedGameStateProvider.notifier)
                      .equipItemToSlot(item, slot);
                } else {
                  // 双击物品：直接使用
                  _useItem(item, ref);
                }
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      // 关键区域：统一物品格子视觉风格，使用柔和渐变与阴影
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getItemLevelColor(item.level).withOpacity(0.28),
                          Colors.black.withOpacity(0.18),
                        ],
                      ),
                      // 关键区域：统一圆角为5
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _getItemLevelColor(item.level).withOpacity(0.85),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getItemLevelColor(
                            item.level,
                          ).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        // 关键区域：顶部内阴影，增强凹凸层次
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    // 关键区域：前景高光叠加
                    foregroundDecoration: BoxDecoration(
                      // 关键区域：统一圆角为5
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                          Colors.white.withOpacity(0.03),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 物品图片 - 占据整个容器
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child:
                                item.image.isNotEmpty
                                    ? Image.asset(
                                      item.image,
                                      fit: BoxFit.contain,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          _getItemTypeIcon(item.type),
                                          color: Colors.white,
                                          size: 20,
                                        );
                                      },
                                    )
                                    : Icon(
                                      _getItemTypeIcon(item.type),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                          ),
                        ),

                        // 物品名称 - 左上角重叠显示
                        Positioned(
                          top: 2,
                          left: 2,
                          right: 20, // 为右上角数量显示留出空间
                          child: Text(
                            item.count > 1
                                ? '${item.name} x ${item.count}'
                                : item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  offset: Offset(0.5, 0.5),
                                  blurRadius: 1.0,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 数量显示 - 右上角
                  if (item.type == 'item' && item.count > 1)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          // 关键区域：统一圆角为5
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _getItemLevelColor(item.level),
                            width: 0.5,
                          ),
                          boxShadow: [
                            // 关键区域：数量徽标增加微光阴影，与等级色系保持一致
                            BoxShadow(
                              color: _getItemLevelColor(
                                item.level,
                              ).withOpacity(0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${item.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // 关键区域：右下角显示耐久（仅对具备格挡的装备）
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Builder(
                      builder: (context) {
                        final int maxDur = item.effects?['armorValue'] ?? 0;
                        final bool show =
                            (item.type == 'equipment') && maxDur > 0;
                        if (!show) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _getItemLevelColor(item.level),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${item.count}/${maxDur}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建空的背包格子
  Widget _buildEmptySlot(int index, WidgetRef ref) {
    return DragTarget<Item>(
      onAccept: (Item item) {
        // 移动物品到这个空位置
        final notifier = ref.read(optimizedGameStateProvider.notifier);
        final inventory = ref.read(optimizedGameStateProvider).playerInventory;
        final fromIndex = inventory.indexWhere((i) => i.id == item.id);
        if (fromIndex != -1) {
          notifier.moveItemInInventory(fromIndex, index);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            // 关键区域：空格子采用柔和渐变与微光边框，提升整体一致性
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isHovering ? Colors.blue : Colors.grey).withOpacity(0.18),
                Colors.black.withOpacity(0.12),
              ],
            ),
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: (isHovering ? Colors.blue : Colors.grey).withOpacity(0.5),
              width: isHovering ? 1.5 : 1,
            ),
            boxShadow:
                isHovering
                    ? [
                      // 关键区域：悬停时增加柔光阴影，突出层次
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          // 关键区域：前景高光叠加，非悬停时更柔和
          foregroundDecoration: BoxDecoration(
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(isHovering ? 0.10 : 0.06),
                Colors.transparent,
                Colors.white.withOpacity(isHovering ? 0.04 : 0.02),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }

  /// 显示使用物品确认对话框
  void _showUseItemDialog(
    BuildContext context,
    Item item,
    int quantity,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // 关键区域：统一弹窗配色与圆角，强化质感与层次
          backgroundColor: Colors.blueGrey.shade900.withOpacity(0.92),
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          // 关键区域：全体缩小 —— 标题/内容/按钮区内边距整体减小
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          clipBehavior: Clip.antiAlias,
          // 关键区域：物品详情页弹窗圆角统一为5
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            // 关键区域：详情页按等级颜色区分 —— 弹窗边框使用等级颜色
            side: BorderSide(
              color: _getItemLevelColor(item.level).withOpacity(0.45),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              // 物品图片
              Container(
                // 关键区域：全体缩小 —— 缩略图尺寸
                width: 32,
                height: 32,
                // 物品缩略图容器采用渐变与边框阴影，提升视觉质感
                // 关键区域：物品缩略图容器圆角统一为5
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      // 关键区域：详情页按等级颜色区分 —— 缩略图背景使用等级颜色
                      _getItemLevelColor(item.level).withOpacity(0.25),
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                  // 关键区域：缩略图边框使用等级颜色
                  border: Border.all(
                    color: _getItemLevelColor(item.level).withOpacity(0.45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      // 关键区域：缩略图阴影使用等级颜色
                      color: _getItemLevelColor(item.level).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                // 关键区域：缩略图高光前景圆角统一为5
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                      Colors.white.withOpacity(0.04),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child:
                    item.image.isNotEmpty
                        ? Image.asset(
                          item.image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getItemTypeIcon(item.type),
                              // 关键区域：缩略图回退图标使用等级颜色
                              color: _getItemLevelColor(item.level),
                              // 关键区域：全体缩小 —— 回退图标尺寸
                              size: 20,
                            );
                          },
                        )
                        : Icon(
                          _getItemTypeIcon(item.type),
                          // 关键区域：缩略图回退图标使用等级颜色
                          color: _getItemLevelColor(item.level),
                          // 关键区域：全体缩小 —— 回退图标尺寸
                          size: 20,
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        // 关键区域：标题使用等级颜色以体现区分
                        color: _getItemLevelColor(item.level),
                        // 关键区域：全体缩小 —— 标题文字尺寸
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final bool isEquip = _slotForItem(item) != null;
                        if (!isEquip) {
                          return Text(
                            '数量: $quantity',
                            style: TextStyle(
                              color: Colors.cyanAccent.withOpacity(0.75),
                              fontSize: 11,
                            ),
                          );
                        }
                        final Map<String, dynamic> params =
                            item.weaponParams ?? const {};
                        final String typeStr =
                            (params['attackType'] ?? params['近战/远程'] ?? '')
                                .toString();
                        final bool isRanged =
                            (typeStr == 'ranged' || typeStr == '远程');
                        final int magazineParam =
                            ((params['magazineSize'] ?? 0) as num).toInt();
                        if (isRanged && magazineParam > 0) {
                          final gs = ref.watch(optimizedGameStateProvider);
                          final Item? eqWeapon = gs.equipmentSlots['weapon'];
                          final bool isEquippedWeapon =
                              (eqWeapon?.id == item.id);
                          final int clip =
                              isEquippedWeapon
                                  ? gs.weaponClipAmmo
                                  : (item.clipAmmo ?? magazineParam);
                          return Text(
                            '弹夹: $clip',
                            style: TextStyle(
                              color: Colors.cyanAccent.withOpacity(0.75),
                              fontSize: 11,
                            ),
                          );
                        }
                        final int max = item.effects?['armorValue'] ?? 0;
                        if (max > 0) {
                          return Text(
                            '耐久: ${item.count}/$max',
                            style: TextStyle(
                              color: Colors.cyanAccent.withOpacity(0.75),
                              fontSize: 11,
                            ),
                          );
                        }
                        return Text(
                          '耐久: ${item.count}',
                          style: TextStyle(
                            color: Colors.cyanAccent.withOpacity(0.75),
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 关键区域：标题与内容之间的微分隔线
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  // 关键区域：分隔线使用等级颜色，保持不抢眼的弱透明度
                  color: _getItemLevelColor(item.level).withOpacity(0.14),
                ),
                // 物品描述
                Container(
                  // 关键区域：全体缩小 —— 描述块内边距减小
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // 关键区域：描述块圆角统一为5
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      // 关键区域：全体缩小 —— 描述文字尺寸
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if ((item.weaponParams ?? const {}).isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final Map<String, dynamic> params =
                          item.weaponParams ?? const {};
                      final String typeStr =
                          (params['attackType'] ?? params['近战/远程'] ?? '')
                              .toString();
                      final bool isRanged =
                          (typeStr == 'ranged' || typeStr == '远程');
                      final double distance =
                          ((params['distance'] ?? params['距离'] ?? 0) as num)
                              .toDouble();
                      final double rangeVal =
                          ((params['range'] ?? params['范围'] ?? 0) as num)
                              .toDouble();
                      final double dmgAmp =
                          ((params['damageAmplify'] ?? params['增幅伤害'] ?? 1.0)
                                  as num)
                              .toDouble();
                      final double critDmg =
                          ((params['critDamage'] ?? params['暴击伤害'] ?? 1.5)
                                  as num)
                              .toDouble();
                      final double critChance =
                          ((params['critChanceBonus'] ??
                                      params['暴击几率加成'] ??
                                      0.0)
                                  as num)
                              .toDouble();
                      final int fireIntervalParam =
                          ((params['fireIntervalMs'] ?? 0) as num).toInt();
                      final gs = ref.watch(optimizedGameStateProvider);
                      final Item? eqWeapon = gs.equipmentSlots['weapon'];
                      final bool isEquippedWeapon = (eqWeapon?.id == item.id);
                      final int intervalMs = () {
                        if (fireIntervalParam > 0) return fireIntervalParam;
                        if (isEquippedWeapon && gs.weaponFireIntervalMs > 0)
                          return gs.weaponFireIntervalMs;
                        return 150;
                      }();
                      final int roundsPerSecond = (1000 / intervalMs).ceil();
                      final List<Map<String, String>> entries = [
                        {'k': '攻击类型', 'v': isRanged ? '远程' : '近战'},
                        {'k': '距离', 'v': '${distance} 格'},
                        {
                          'k': isRanged ? '子弹速度' : '弧度',
                          'v': isRanged ? '${rangeVal} 格/秒' : '$rangeVal',
                        },
                        if (isRanged)
                          {'k': '射速', 'v': '${roundsPerSecond} 发/秒'},
                        {'k': '增幅伤害', 'v': '${dmgAmp} 倍'},
                        {'k': '暴击伤害', 'v': '${critDmg} 倍'},
                        {
                          'k': '暴击几率加成',
                          'v': '${(critChance * 100).toStringAsFixed(0)}%',
                        },
                        // 添加备用弹夹数量显示
                        if (isRanged)
                          {
                            'k': '备用弹夹',
                            'v':
                                isEquippedWeapon
                                    ? '${gs.weaponTotalAmmo - gs.weaponClipAmmo} 发'
                                    : '${(params['ammoTotal'] ?? 0) - (params['clipAmmo'] ?? 0)} 发',
                          },
                      ];
                      final int half = (entries.length + 1) ~/ 2;
                      final List<Map<String, String>> left = entries.sublist(
                        0,
                        half,
                      );
                      final List<Map<String, String>> right = entries.sublist(
                        half,
                      );

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.03),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    left
                                        .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: _getItemLevelColor(
                                                        item.level,
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    right
                                        .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: _getItemLevelColor(
                                                        item.level,
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if ((item.type == 'equipment') &&
                    ((item.effects?['armorValue'] ?? 0) > 0)) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final int level = item.level;
                        final Map<int, double> ratios = const {
                          1: 0.20,
                          2: 0.40,
                          3: 0.50,
                          4: 0.60,
                          5: 0.70,
                          6: 0.90,
                        };
                        final double armorShare = ratios[level] ?? 0.0;
                        final int percent = (armorShare * 100).round();
                        final int maxDur = item.effects?['armorValue'] ?? 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: _getItemLevelColor(item.level),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '护甲免疫伤害：$percent%',
                                  style: TextStyle(
                                    color: _getItemLevelColor(item.level),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 关键区域：详情页改为显示 effects（避免与 effects 重复维护）
                if ((item.effects ?? const {}).isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 160,
                    ), // 效果过多时滚动，大小保持不变
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            (item.effects ?? const {}).entries.map((effect) {
                              final effectName = _getEffectName(effect.key);
                              final effectValue = effect.value;
                              final bool isPunish = effect.key == 'punish';
                              final bool isPositive =
                                  isPunish
                                      ? (effectValue < 0)
                                      : (effectValue > 0);
                              final Color displayColor =
                                  isPositive ? Colors.green : Colors.red;

                              return Container(
                                // 关键区域：全体缩小 —— 效果条内边距与间距减小
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 5,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: displayColor.withOpacity(0.35),
                                    width: 1,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      displayColor.withOpacity(0.10),
                                      Colors.black.withOpacity(0.10),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getEffectIcon(effect.key),
                                      color: displayColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isPunish
                                          ? '$effectName: ${_punishText(effectValue)}'
                                          : '$effectName: ${isPositive ? '+' : ''}$effectValue',
                                      style: TextStyle(
                                        color: displayColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // 关键区域：按钮样式统一为圆角与边框，保持一致风格
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade300,
                // 关键区域：全体缩小 —— 按钮内边距减小
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                // 关键区域：按钮圆角统一为5
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: Colors.grey.shade600.withOpacity(0.5),
                  ),
                ),
              ),
              child: const Text('取消'),
            ),
            // 关键区域：互换“装备”与“丢弃”按钮位置 —— 先丢弃后装备（仅影响装备类详情页视觉顺序）
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _dropItem(item, ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade600,
                // 关键区域：全体缩小 —— 按钮内边距减小
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                // 关键区域：按钮圆角统一为5
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.55)),
                ),
              ),
              child: const Text('丢弃'),
            ),
            // 关键区域：装备按钮（支持中文类型与旧“装备+equipmentSlot”）
            if (_slotForItem(item) != null)
              TextButton(
                onPressed: () {
                  final slot = _slotForItem(item)!;
                  Navigator.of(context).pop();
                  ref
                      .read(optimizedGameStateProvider.notifier)
                      .equipItemToSlot(item, slot);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.indigo.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  // 关键区域：按钮圆角统一为5
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      color: Colors.indigoAccent.withOpacity(0.55),
                    ),
                  ),
                ),
                child: const Text('装备'),
              ),
            // 关键区域：装备类隐藏“使用”按钮，仅非装备类显示
            if (_slotForItem(item) == null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _useItem(item, ref);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _getItemTypeColor(item.type),
                  // 关键区域：全体缩小 —— 按钮内边距减小
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  // 关键区域：按钮圆角统一为5
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      color: _getItemTypeColor(item.type).withOpacity(0.55),
                    ),
                  ),
                ),
                child: const Text('使用'),
              ),
          ],
        );
      },
    );
  }

  /// 使用物品
  void _useItem(Item item, WidgetRef ref) {
    final notifier = ref.read(optimizedGameStateProvider.notifier);
    notifier.useItem(item);
  }

  /// 丢弃物品
  void _dropItem(Item item, WidgetRef ref) {
    final notifier = ref.read(optimizedGameStateProvider.notifier);
    notifier.dropItemFromInventory(item);
  }

  // 关键区域：根据英文类型返回装备槽位（equipment -> equipmentSlot）
  String? _slotForItem(Item item) {
    if (item.type == 'equipment') {
      return item.equipmentSlot;
    }
    return null;
  }

  /// 构建垃圾桶拖拽区域
  Widget _buildTrashCanArea(WidgetRef ref) {
    return DragTarget<Item>(
      onAccept: (Item item) {
        // 拖拽物品到垃圾桶时丢弃物品
        _dropItem(item, ref);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60,
          decoration: BoxDecoration(
            color:
                isHovering
                    ? Colors.red.shade600.withOpacity(0.8)
                    : Colors.grey.shade800.withOpacity(0.6),
            // 关键区域：统一圆角为5
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isHovering ? Colors.red.shade400 : Colors.grey.shade600,
              width: 2,
            ),
            boxShadow:
                isHovering
                    ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: isHovering ? Colors.white : Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isHovering ? '松开以丢弃物品' : '拖拽物品到此处丢弃',
                style: TextStyle(
                  color: isHovering ? Colors.white : Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 获取物品等级颜色（使用统一等级颜色管理）
  Color _getItemLevelColor(int level) {
    return LevelColorManager.getItemLevelColor(level);
  }

  /// 获取物品类型颜色
  Color _getItemTypeColor(String type) {
    switch (type) {
      case 'equipment':
        return Colors.indigo; // 装备统一为靛蓝
      case 'item':
        return Colors.amber; // 通用物品统一为琥珀
      case 'potion':
        return Colors.green;
      case 'food':
        return Colors.orange;
      case 'tool':
        return Colors.blue;
      case 'weapon':
        return Colors.red;
      case 'book':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// 获取物品类型图标
  IconData _getItemTypeIcon(String type) {
    switch (type) {
      case 'equipment':
        return Icons.security; // 统一用盾牌表示装备
      case 'item':
        return Icons.inventory_2; // 通用物品
      case 'potion':
        return Icons.local_pharmacy;
      case 'food':
        return Icons.restaurant;
      case 'tool':
        return Icons.build;
      case 'weapon':
        return Icons.security;
      case 'book':
        return Icons.menu_book;
      default:
        return Icons.inventory_2;
    }
  }

  /// 获取效果名称
  String _getEffectName(String effectKey) {
    switch (effectKey) {
      case 'hp':
        return '生命值';
      // 关键区域：弹窗效果名称映射——将 maxHp 显示为“最大生命值”
      case 'maxHp':
        return '最大生命值';
      case 'baseDamage':
        return '基础伤害';
      case 'maxSan':
        return '最大理智值';
      case 'maxFood':
        return '最大饱食度';
      case 'san':
        return '理智值';
      case 'food':
        return '饱食度';
      case 'moveSpeed':
        return '移动速度';
      case 'gold':
        return '资产';
      case 'oxygenBonus':
        return '肺活量';
      case 'punish':
        return '处分';
      case 'armorValue':
        return '耐久';
      case 'ammo':
        return '子弹';
      default:
        return effectKey;
    }
  }

  /// 获取效果图标
  IconData _getEffectIcon(String effectKey) {
    switch (effectKey) {
      case 'hp':
        return Icons.favorite;
      case 'san':
        return Icons.psychology;
      case 'food':
        return Icons.restaurant;
      case 'moveSpeed':
        return Icons.directions_run;
      case 'gold':
        return Icons.monetization_on;
      case 'oxygenBonus':
        return Icons.air;
      case 'punish':
        return Icons.assignment;
      default:
        return Icons.help;
    }
  }

  String _punishText(dynamic value) {
    int v;
    if (value is num) {
      v = value.toInt();
    } else {
      return value?.toString() ?? '';
    }
    if (v == 1) return '警告';
    if (v == 2) return '记过';
    if (v == 3) return '通报批评';
    if (v == 4) return '处分';
    if (v == 5) return '留校察看';
    if (v >= 6 && v <= 10) return '面临退学';
    return v.toString();
  }

  /// 格式化数值为小数点后两位显示
  String _formatToTwoDigits(dynamic value) {
    if (value == null) return '0.00';

    double doubleValue;
    if (value is double) {
      doubleValue = value;
    } else if (value is int) {
      doubleValue = value.toDouble();
    } else {
      doubleValue = 0.0;
    }

    // 显示小数点后两位
    return doubleValue.toStringAsFixed(2);
  }

  String _formatCombatValue(dynamic value) {
    if (value == null) return '0';
    double v;
    if (value is double) {
      v = value;
    } else if (value is int) {
      v = value.toDouble();
    } else {
      v = 0.0;
    }
    if (v.isFinite && v.roundToDouble() == v) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(2);
  }

  /// 计算健康百分比（基于生命值和理智值）
  double _calculateHealthPercentage(Map<String, dynamic> stats) {
    final hp = stats['hp'] ?? 0.0;
    final maxHp = stats['maxHp'] ?? 100.0;
    final san = stats['san'] ?? 0.0;
    final maxSan = stats['maxSan'] ?? 100.0;

    // 综合生命值和理智值计算健康百分比
    final hpPercentage = maxHp > 0 ? hp / maxHp : 0.0;
    final sanPercentage = maxSan > 0 ? san / maxSan : 0.0;

    // 取两者的平均值作为整体健康状况
    return ((hpPercentage + sanPercentage) / 2).clamp(0.0, 1.0);
  }

  /// 计算压力水平（基于饱食度和氧气值）
  double _calculateStressLevel(Map<String, dynamic> stats) {
    final food = stats['food'] ?? 100.0;
    final oxygen = stats['oxygen'] ?? 100.0;
    final maxOxygen = stats['maxOxygen'] ?? 100.0;

    // 饱食度越低，压力越大
    final foodStress = food < 50 ? (50 - food) / 50 : 0.0;

    // 氧气值越低，压力越大
    final oxygenPercentage = maxOxygen > 0 ? oxygen / maxOxygen : 1.0;
    final oxygenStress =
        oxygenPercentage < 0.5 ? (0.5 - oxygenPercentage) / 0.5 : 0.0;

    // 取较高的压力值
    return math.max(foodStress, oxygenStress).clamp(0.0, 1.0);
  }
}

/// 动态心电图组件
class ECGWidget extends StatefulWidget {
  final double width;
  final double height;
  final double healthPercentage; // 健康百分比 (0.0 - 1.0)
  final double stressLevel; // 压力水平 (0.0 - 1.0)
  final double proximityFactor; // 鬼接近度 (0.0 - 1.0)

  const ECGWidget({
    Key? key,
    this.width = 120,
    this.height = 60,
    required this.healthPercentage,
    required this.stressLevel,
    this.proximityFactor = 0.0,
  }) : super(key: key);

  @override
  State<ECGWidget> createState() => _ECGWidgetState();
}

class _ECGWidgetState extends State<ECGWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<double> _ecgPoints = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateECGPoints();

    // 根据健康状态调整动画速度
    final duration = _getAnimationDuration();
    _animationController = AnimationController(duration: duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.addListener(() {
      setState(() {
        _currentIndex = (_animation.value * (_ecgPoints.length - 1)).round();
      });
    });

    _animationController.repeat();
  }

  @override
  void didUpdateWidget(ECGWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.healthPercentage != widget.healthPercentage ||
        oldWidget.stressLevel != widget.stressLevel ||
        oldWidget.proximityFactor != widget.proximityFactor) {
      _generateECGPoints();

      // 更新动画速度
      final newDuration = _getAnimationDuration();
      if (_animationController.duration != newDuration) {
        _animationController.duration = newDuration;
      }
    }
  }

  Duration _getAnimationDuration() {
    // 新模式：心率主要由鬼接近度驱动（越近越快）
    const int baseSpeed = 2000; // ms，远离鬼时的速度
    const int minSpeed = 800; // ms，鬼靠近时的最快速度
    final double p = widget.proximityFactor.clamp(0.0, 1.0);
    final int speed = (baseSpeed - (baseSpeed - minSpeed) * p).round();
    return Duration(milliseconds: speed);
  }

  void _generateECGPoints() {
    _ecgPoints.clear();
    final pointCount = 50;

    for (int i = 0; i < pointCount; i++) {
      double point = 0.5; // 基线

      // 生成心电图波形
      if (i % 15 == 5) {
        // P波
        point += 0.1 * widget.healthPercentage;
      } else if (i % 15 == 8) {
        // Q波
        point -= 0.05 * widget.healthPercentage;
      } else if (i % 15 == 9) {
        // R波（主峰）
        point += 0.4 * widget.healthPercentage;
      } else if (i % 15 == 10) {
        // S波
        point -= 0.1 * widget.healthPercentage;
      } else if (i % 15 == 12) {
        // T波
        point += 0.15 * widget.healthPercentage;
      }

      // 新模式抖动：以鬼接近度为主，压力为辅
      final double jitterBase = widget.proximityFactor * 0.15;
      final double jitterStress = widget.stressLevel * 0.05;
      final noise =
          (math.Random().nextDouble() - 0.5) * (jitterBase + jitterStress);
      point += noise;

      // 确保点在合理范围内
      point = point.clamp(0.0, 1.0);
      _ecgPoints.add(point);
    }
  }

  Color _getECGColor() {
    // 新模式：颜色主要由鬼接近度决定（越近越偏红）
    final p = widget.proximityFactor.clamp(0.0, 1.0);
    if (p < 0.33) return Colors.green;
    if (p < 0.66) return Colors.yellow;
    if (p < 0.85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        // 关键区域：统一圆角为5
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _getECGColor().withOpacity(0.5), width: 1),
      ),
      child: CustomPaint(
        painter: ECGPainter(
          points: _ecgPoints,
          currentIndex: _currentIndex,
          color: _getECGColor(),
        ),
        size: Size(widget.width, widget.height),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// 心电图绘制器
class ECGPainter extends CustomPainter {
  final List<double> points;
  final int currentIndex;
  final Color color;

  ECGPainter({
    required this.points,
    required this.currentIndex,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final fadePaint =
        Paint()
          ..color = color.withOpacity(0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final path = Path();
    final fadePath = Path();

    // 绘制心电图线条
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fadePath.moveTo(x, y);
      } else {
        if (i <= currentIndex) {
          path.lineTo(x, y);
        } else {
          fadePath.lineTo(x, y);
        }
      }
    }

    // 绘制已经过的部分（亮色）
    canvas.drawPath(path, paint);

    // 绘制未到达的部分（暗色）
    canvas.drawPath(fadePath, fadePaint);

    // 绘制当前位置的脉冲点
    if (currentIndex < points.length) {
      final currentX = (currentIndex / (points.length - 1)) * size.width;
      final currentY = size.height - (points[currentIndex] * size.height);

      final pulsePaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), 3.0, pulsePaint);
    }

    // 绘制网格线
    final gridPaint =
        Paint()
          ..color = color.withOpacity(0.1)
          ..strokeWidth = 0.5;

    // 水平网格线
    for (int i = 1; i < 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 垂直网格线
    for (int i = 1; i < 6; i++) {
      final x = (i / 6) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// 新文件段落说明：顶层心电图绘制器（背包页用）
// 作用：统一背包内心电图样式与外部 SanityECGPainter 一致，避免循环导入。
class InventorySanityECGPainter extends CustomPainter {
  final double phase;
  final double san; // 0-250
  final double hpRatio; // 0-1
  final double oxygenRatio; // 0-1
  final double moveFactor; // 0-1
  final double castingFactor; // 0-1
  final double damagePulse; // 0-1
  final bool isInWater;
  final double proximityFactor; // 0-1

  InventorySanityECGPainter({
    required this.phase,
    required this.san,
    required this.hpRatio,
    required this.oxygenRatio,
    required this.moveFactor,
    required this.castingFactor,
    required this.damagePulse,
    required this.isInWater,
    required this.proximityFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint =
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 科技感网格线
    final gridPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.18)
          ..strokeWidth = 0.7;
    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 中心轴线
    final axisPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.35)
          ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );

    // 归一化
    final sanityRatio = (san / 250.0).clamp(0.0, 1.0);
    final double hpR = hpRatio.clamp(0.0, 1.0);
    final double o2R = oxygenRatio.clamp(0.0, 1.0);
    final double dmgP = damagePulse.clamp(0.0, 1.0);

    // 心率
    double hrBpm = 60 + 90 * proximityFactor + 10 * dmgP + (isInWater ? 5 : 0);
    hrBpm = hrBpm.clamp(50, 165);

    // 振幅
    final double baseAmp = 6.0 + (1.0 - sanityRatio) * 4.0 + (1.0 - o2R) * 2.0;

    // 尖峰参数
    final double spikeInterval = 42.0 * (60.0 / hrBpm);
    final double spikeWidth = 8.0;
    final double spikeHeight = baseAmp * (2.0 + (1.0 - hpR) * 0.6 + dmgP * 0.8);

    // 颜色
    final double stress = proximityFactor;
    final Color calmColor = Colors.greenAccent;
    final Color techColor = Colors.cyanAccent;
    final Color alertColor = Colors.orangeAccent;
    final Color dangerColor = Colors.redAccent;
    final Color waveColor =
        (stress < 0.33)
            ? Color.lerp(calmColor, techColor, 0.6)!
            : (stress < 0.66)
            ? Color.lerp(techColor, alertColor, (stress - 0.33) / 0.33)!
            : Color.lerp(alertColor, dangerColor, (stress - 0.66) / 0.34)!;

    final wavePaint =
        Paint()
          ..color = waveColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final path = Path();
    final double mid = size.height / 2;

    double x = 0.0;
    double y = mid;
    path.moveTo(x, y);

    while (x <= size.width) {
      final jitter = proximityFactor * 0.8;
      final noise =
          math.sin((x * 0.12) + phase * 1.7) * baseAmp * 0.15 * jitter;
      final smoothY =
          mid +
          math.sin((x / size.width) * math.pi * 2 + phase) * baseAmp * 0.6 +
          noise;

      final double offsetPhase = (phase * 30) % spikeInterval;
      final double distToSpike = ((x + offsetPhase) % spikeInterval);
      if (distToSpike < 1.0) {
        path.lineTo(x + spikeWidth * 0.2, mid - spikeHeight);
        path.lineTo(x + spikeWidth * 0.6, mid + spikeHeight * 0.6);
        path.lineTo(x + spikeWidth, smoothY);
        x += spikeWidth;
        y = smoothY;
      } else {
        final double nextX = x + 2.0;
        final double nextY = smoothY;
        path.lineTo(nextX, nextY);
        x = nextX;
        y = nextY;
      }
    }

    // 光晕
    final glow1 =
        Paint()
          ..color = waveColor.withOpacity(0.25)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke;
    final glow2 =
        Paint()
          ..color = waveColor.withOpacity(0.12)
          ..strokeWidth = 10.0
          ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glow2);
    canvas.drawPath(path, glow1);
    canvas.drawPath(path, wavePaint);

    // 扫描线
    final double phaseNorm = (phase % (math.pi * 2)) / (math.pi * 2);
    final double scanX = phaseNorm * size.width;
    final scanPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.15)
          ..strokeWidth = 2.0;
    canvas.drawLine(Offset(scanX, 0), Offset(scanX, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant InventorySanityECGPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.san != san ||
        oldDelegate.hpRatio != hpRatio ||
        oldDelegate.oxygenRatio != oxygenRatio ||
        oldDelegate.moveFactor != moveFactor ||
        oldDelegate.castingFactor != castingFactor ||
        oldDelegate.damagePulse != damagePulse ||
        oldDelegate.isInWater != isInWater ||
        oldDelegate.proximityFactor != proximityFactor;
  }
}

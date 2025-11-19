// game/optimized_game_state.dart
// 性能优化的游戏状态管理器

import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui' as ui; // 关键区域：用于模板中的颜色参数
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escape_from_school/data/mapData.dart';
import 'package:escape_from_school/data/props.dart';
import 'package:escape_from_school/data/shop.dart';
import 'package:escape_from_school/data/manData.dart';
import 'package:escape_from_school/data/skill_data.dart';
import 'package:escape_from_school/game/vision.dart';
import 'package:escape_from_school/game/enhanced_vision.dart';
import 'package:escape_from_school/game/ghost.dart';
import 'package:escape_from_school/game/smooth_vision.dart';
import 'package:escape_from_school/game/item_spawner.dart';
import 'package:escape_from_school/game/oxygen_system.dart';
import 'package:escape_from_school/game/oxygen_recovery_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:escape_from_school/game/zones.dart';

/// 游戏页面类型枚举
enum GamePage {
  game,      // 主游戏页面
  inventory, // 背包页面
  shop,      // 商店页面
  character, // 角色信息页面
}

/// 播报消息类型枚举
enum BroadcastMessageType {
  damage,     // 伤害消息
  heal,       // 治疗消息
  item,       // 物品相关消息
  system,     // 系统消息
}

/// 播报消息类
@immutable
class BroadcastMessage {
  final String text;
  final BroadcastMessageType type;
  final DateTime timestamp;
  final Duration displayDuration;

  const BroadcastMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.displayDuration = const Duration(seconds: 3),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > displayDuration;
}

/// 优化的玩家位置类
@immutable
class OptimizedPlayerPosition {
  final double x;
  final double y;
  final bool facingRight;

  const OptimizedPlayerPosition({
    required this.x,
    required this.y,
    this.facingRight = true,
  });

  OptimizedPlayerPosition copyWith({
    double? x,
    double? y,
    bool? facingRight,
  }) {
    return OptimizedPlayerPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      facingRight: facingRight ?? this.facingRight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizedPlayerPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          facingRight == other.facingRight;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ facingRight.hashCode;
  
  /// 转换为Point<int>，用于地图坐标
  Point<int> toPoint() {
    return Point<int>(x.round(), y.round());
  }
}

/// 优化的移动状态类
@immutable
class OptimizedMovementState {
  final double velocityX;
  final double velocityY;
  final double joystickX;
  final double joystickY;
  final double joystickIntensity;
  final bool isMoving;

  const OptimizedMovementState({
    this.velocityX = 0.0,
    this.velocityY = 0.0,
    this.joystickX = 0.0,
    this.joystickY = 0.0,
    this.joystickIntensity = 0.0,
    this.isMoving = false,
  });

  OptimizedMovementState copyWith({
    double? velocityX,
    double? velocityY,
    double? joystickX,
    double? joystickY,
    double? joystickIntensity,
    bool? isMoving,
  }) {
    return OptimizedMovementState(
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      joystickX: joystickX ?? this.joystickX,
      joystickY: joystickY ?? this.joystickY,
      joystickIntensity: joystickIntensity ?? this.joystickIntensity,
      isMoving: isMoving ?? this.isMoving,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizedMovementState &&
          runtimeType == other.runtimeType &&
          velocityX == other.velocityX &&
          velocityY == other.velocityY &&
          joystickX == other.joystickX &&
          joystickY == other.joystickY &&
          joystickIntensity == other.joystickIntensity &&
          isMoving == other.isMoving;

  @override
  int get hashCode =>
      velocityX.hashCode ^
      velocityY.hashCode ^
      joystickX.hashCode ^
      joystickY.hashCode ^
      joystickIntensity.hashCode ^
      isMoving.hashCode;
}

/// 优化的游戏状态类
@immutable
class OptimizedGameState {
  final Map<String, dynamic> characterStats; // 当前角色状态（HP、理智值等）
  // 注意：characterStats是不可变的，但其内部的Map内容可能会被修改
  final OptimizedPlayerPosition playerPosition;
  final OptimizedMovementState movementState;
  final double? weaponJoystickX;
  final double? weaponJoystickY;
  final double? weaponJoystickIntensity;
  final bool isWeaponAiming;
  final double lastWeaponAimX;
  final double lastWeaponAimY;
  final DateTime? weaponAttackStartTime;
  final AttackTemplate meleeAttackTemplate;  // 关键区域：近战模板
  final AttackTemplate rangedAttackTemplate; // 关键区域：远程模板
  final AttackMode selectedAttackMode;       // 关键区域：当前选中的攻击模式
  // 关键区域：武器伤害参数（来源于物品 weaponParams）
  final double? weaponDamageAmplify;          // 伤害增幅倍数
  final double? weaponCritDamage;             // 暴击伤害倍数
  final double? weaponCritChanceBonus;        // 暴击几率加成
  final int weaponMagazineSize;               
  final int weaponClipAmmo;                   
  final int weaponTotalAmmo;                  
  final List<Projectile> projectiles;         
  final bool isReloading;
  final double reloadProgress;
  final DateTime? reloadStartTime;
  final int reloadDurationMs;
  // 关键区域：换弹起始弹药（用于匀速补全计算）
  final int reloadStartClipAmmo;
  final int reloadStartReserveAmmo;
  final List<List<String>> map;
  final List<Point<int>> chestPositions;
  final List<Point<int>> safePositions; // 关键区域：保险箱位置列表（仅在建筑物内刷新）
  // 关键区域：固定刷新宝箱的位置（开局在玩家脚底生成的宝箱）
  final Point<int>? fixedChestPosition;
  final List<Item> playerInventory;
  // 关键区域：装备槽状态，严格四个部位（垂直展示）
  final Map<String, Item?> equipmentSlots; // {weapon, armor, head, bag}
  final int inventoryCapacity;                    // 背包容量
  final int maxInventoryCapacity;                 // 最大背包容量（用于扩容）
  final Map<Point<int>, List<Item>> groundItems;  // 地面物品，按位置存储
  final Set<Point<int>> visibleTiles;
  final List<List<bool>> visibleMap;
  final bool showInventory;
  final bool showCharacterInfo;
  final bool showShop;
  // 关键区域：炼金机显示状态与位置
  final bool showAlchemy; // 是否显示炼金界面
  final Point<int>? alchemyStation; // 炼金机在地图中的位置
  final Shop? schoolShop;
  final GhostManager ghostManager;
  final bool isGameOver;
  final String deathReason;
  final GamePage currentPage;
  
  // 脱离卡死相关状态
  final bool isNoClipMode;              // 是否处于无视地形模式
  final DateTime? noClipEndTime;        // 无视地形模式结束时间
  final DateTime? unstuckCooldownEnd;   // 脱离卡死冷却结束时间
  final bool isWaitingForMovement;      // 是否正在等待玩家移动以开始冷却
  final DateTime? unstuckActivatedTime; // 脱离卡死激活时间
  
  // 游戏开始无碰撞模式相关状态
  final bool isInitialNoClipMode;       // 是否处于游戏开始的初始无碰撞模式
  final bool hasUsedJoystick;           // 是否已经使用过摇杆
  
  // 移动距离计算相关状态
  final OptimizedPlayerPosition? lastPosition;  // 上一次位置，用于计算移动距离
  final double accumulatedDistance;             // 累积移动距离
  
  // 生命值变化检测相关状态
  final double? lastHp;                         // 上一次的生命值，用于检测变化
  final bool shouldShowDamageEffect;            // 是否应该显示伤害效果
  final double lastDamageAmount;                // 最后一次的伤害量
  
  // 平滑视野动画相关状态
  final int lastAnimationFrame;                 // 最后一次动画帧标识，用于触发重绘
  
  // 播报消息相关状态
  final List<BroadcastMessage> broadcastMessages; // 播报消息列表
  final String? currentZoneName;
  final DateTime? zoneNameVisibleUntil;
  
  // 技能系统相关状态
  final List<Skill> characterSkills;              // 角色拥有的技能列表
  final Map<String, SkillState> skillStates;      // 技能状态映射
  final String? currentCastingSkillId;            // 当前正在施法的技能ID
  final double castingProgress;                   // 施法进度 (0.0 - 1.0)
  
  // 物品使用相关状态
  final bool isUsingItem;                         // 是否正在使用物品
  final Item? currentUsingItem;                   // 当前正在使用的物品
  final double itemUsageProgress;                 // 物品使用进度 (0.0 - 1.0)
  final DateTime? itemUsageStartTime;             // 物品使用开始时间
  
  // 宝箱探索相关状态
  final bool isExploringChest;                    // 是否正在探索宝箱
  final Point<int>? currentExploringChest;        // 当前正在探索的宝箱位置
  final double chestExplorationProgress;          // 宝箱探索进度 (0.0 - 1.0)
  final DateTime? chestExplorationStartTime;      // 宝箱探索开始时间
  // 宝箱搜索页面相关状态
  final bool isChestSearchOpen;                   // 是否打开宝箱搜索页面
  final List<Item> chestPendingItems;             // 尚未揭示的宝箱物品（搜索队列）
  final List<Item> chestVisibleItems;             // 已揭示、当前显示在宝箱中的物品
  
  // 游戏时间相关状态
  final DateTime gameStartTime;                   // 游戏开始时间
  final DateTime? gameEndTime;                    // 游戏结束时间
  
  // 死亡时数据快照
  final Map<String, dynamic>? deathTimeStats;     // 死亡时的角色状态快照
  final List<Item>? deathTimeInventory;           // 死亡时的背包物品快照
  
  // 氧气系统相关状态
  final OxygenSystem? oxygenSystem;               // 氧气系统实例
  final bool isInWater;                           // 是否在水中
  final double currentOxygen;                     // 当前氧气值
  final double maxOxygen;                         // 基础最大氧气值
  final double oxygenBonus;                       // 氧气增强值（通过道具获得）
  final OxygenRecoveryManager? oxygenRecoveryManager; // 氧气恢复管理器

  // 炼金特效相关状态
  // 关键区域：控制炼金抽奖特效的显示与数据（候选与结果）
  final bool showAlchemyEffect;            // 是否显示炼金抽奖特效覆盖层
  final List<Item> alchemyCandidates;      // 可能合成出的候选物品列表（同等级）
  final Item? alchemyResultItem;           // 抽奖最终结果物品（点击后放入背包）
  // 关键区域：炼金动画用的等级概率权重（键为等级，值为权重）
  final Map<int, int> alchemyLevelWeights;



  const OptimizedGameState({
    required this.characterStats,
    required this.playerPosition,  
    required this.movementState,
    this.weaponJoystickX = 0.0,
    this.weaponJoystickY = 0.0,
    this.weaponJoystickIntensity = 0.0,
    this.isWeaponAiming = false,
    this.lastWeaponAimX = 1.0,
    this.lastWeaponAimY = 0.0,
    this.weaponAttackStartTime,
    this.meleeAttackTemplate = const AttackTemplate(
      color: ui.Color(0xFFFFA000), // 橙色近战效果
      distance: 1.2,               // 约1.2格半径
      range: 1.2,                  // 弧形扫过角宽（弧度）
    ),
    this.rangedAttackTemplate = const AttackTemplate(
      color: ui.Color(0xFF00E5FF), // 青色远程子弹
      distance: 4.0,               // 子弹飞行距离（格）
      range: 12.0,                 // 子弹速度（格/秒）
    ),
    this.selectedAttackMode = AttackMode.melee,
    this.weaponDamageAmplify = 1.0,
    this.weaponCritDamage = 1.5,
    this.weaponCritChanceBonus = 0.0,
    this.weaponMagazineSize = 0,
    this.weaponClipAmmo = 0,
    this.weaponTotalAmmo = 0,
    this.projectiles = const [],
    this.isReloading = false,
    this.reloadProgress = 0.0,
    this.reloadStartTime,
    this.reloadDurationMs = 1000,
    this.reloadStartClipAmmo = 0,
    this.reloadStartReserveAmmo = 0,
    required this.map,
    required this.chestPositions,
    required this.safePositions,
    this.fixedChestPosition,
    required this.playerInventory,
    // 关键区域：扩展装备槽默认键为六类，保持与UI一致
    this.equipmentSlots = const <String, Item?>{
      'weapon': null,
      'armor': null,
      'head': null,
      'bag': null,
      'pants': null,
      'shoes': null,
    },
    this.inventoryCapacity = 20,                    // 默认背包容量20格
    this.maxInventoryCapacity = 100,                // 最大可扩容到100格
    this.groundItems = const {},                    // 初始化为空的地面物品映射
    required this.visibleTiles,
    required this.visibleMap,
    required this.ghostManager,
    this.showInventory = false,
    this.showCharacterInfo = false,
    this.showShop = false,
    this.showAlchemy = false,
    this.alchemyStation,
    this.schoolShop,
    this.isGameOver = false,
    this.deathReason = '',
    this.currentPage = GamePage.game,
    this.isNoClipMode = false,
    this.noClipEndTime,
    this.unstuckCooldownEnd,
    this.isWaitingForMovement = false,
    this.unstuckActivatedTime,
    this.isInitialNoClipMode = true,
    this.hasUsedJoystick = false,
    this.lastPosition,
    this.accumulatedDistance = 0.0,
    this.lastHp,
    this.shouldShowDamageEffect = false,
    this.lastDamageAmount = 0.0,
    this.lastAnimationFrame = 0,
    this.broadcastMessages = const [],
    this.currentZoneName,
    this.zoneNameVisibleUntil,
    this.characterSkills = const [],
    this.skillStates = const {},
    this.currentCastingSkillId,
    this.castingProgress = 0.0,
    this.isUsingItem = false,
    this.currentUsingItem,
    this.itemUsageProgress = 0.0,
    this.itemUsageStartTime,
    this.isExploringChest = false,
    this.currentExploringChest,
    this.chestExplorationProgress = 0.0,
    this.chestExplorationStartTime,
    this.isChestSearchOpen = false,
    this.chestPendingItems = const [],
    this.chestVisibleItems = const [],
    required this.gameStartTime,
    this.gameEndTime,
    this.deathTimeStats,
    this.deathTimeInventory,
    this.oxygenSystem,
    this.isInWater = false,
    this.currentOxygen = 10.0,
    this.maxOxygen = 10.0,
    this.oxygenBonus = 0.0,
    this.oxygenRecoveryManager,
    this.showAlchemyEffect = false,
    this.alchemyCandidates = const [],
    this.alchemyResultItem,
    this.alchemyLevelWeights = const {},
  });

  OptimizedGameState copyWith({
    Map<String, dynamic>? characterStats,
    OptimizedPlayerPosition? playerPosition,
    OptimizedMovementState? movementState,
    double? weaponJoystickX,
    double? weaponJoystickY,
    double? weaponJoystickIntensity,
    bool? isWeaponAiming,
    double? lastWeaponAimX,
    double? lastWeaponAimY,
    DateTime? weaponAttackStartTime,
    AttackTemplate? meleeAttackTemplate,
    AttackTemplate? rangedAttackTemplate,
    AttackMode? selectedAttackMode,
    double? weaponDamageAmplify,
    double? weaponCritDamage,
    double? weaponCritChanceBonus,
    int? weaponMagazineSize,
    int? weaponClipAmmo,
    int? weaponTotalAmmo,
    List<Projectile>? projectiles,
    bool? isReloading,
    double? reloadProgress,
    DateTime? reloadStartTime,
    int? reloadDurationMs,
    int? reloadStartClipAmmo,
    int? reloadStartReserveAmmo,
    List<List<String>>? map,
    List<Point<int>>? chestPositions,
    List<Point<int>>? safePositions,
    Point<int>? fixedChestPosition,
    List<Item>? playerInventory,
    Map<String, Item?>? equipmentSlots,
    int? inventoryCapacity,
    int? maxInventoryCapacity,
    Map<Point<int>, List<Item>>? groundItems,
    Set<Point<int>>? visibleTiles,
    List<List<bool>>? visibleMap,
    GhostManager? ghostManager,
    bool? showInventory,
    bool? showCharacterInfo,
    bool? showShop,
    bool? showAlchemy,
    Point<int>? alchemyStation,
    Shop? schoolShop,
    bool? isGameOver,
    String? deathReason,
    GamePage? currentPage,
    bool? isNoClipMode,
    DateTime? noClipEndTime,
    DateTime? unstuckCooldownEnd,
    bool? isWaitingForMovement,
    DateTime? unstuckActivatedTime,
    bool? isInitialNoClipMode,
    bool? hasUsedJoystick,
    OptimizedPlayerPosition? lastPosition,
    double? accumulatedDistance,
    double? lastHp,
    bool? shouldShowDamageEffect,
    double? lastDamageAmount,
    int? lastAnimationFrame,
    List<BroadcastMessage>? broadcastMessages,
    String? currentZoneName,
    DateTime? zoneNameVisibleUntil,
    List<Skill>? characterSkills,
    Map<String, SkillState>? skillStates,
    String? currentCastingSkillId,
    double? castingProgress,
    bool? isUsingItem,
    Item? currentUsingItem,
    double? itemUsageProgress,
    DateTime? itemUsageStartTime,
    bool? isExploringChest,
    Point<int>? currentExploringChest,
    double? chestExplorationProgress,
    DateTime? chestExplorationStartTime,
    bool? isChestSearchOpen,
    List<Item>? chestPendingItems,
    List<Item>? chestVisibleItems,
    DateTime? gameStartTime,
    DateTime? gameEndTime,
    Map<String, dynamic>? deathTimeStats,
    List<Item>? deathTimeInventory,
    OxygenSystem? oxygenSystem,
    bool? isInWater,
    double? currentOxygen,
    double? maxOxygen,
    double? oxygenBonus,
    OxygenRecoveryManager? oxygenRecoveryManager,
    bool? showAlchemyEffect,
    List<Item>? alchemyCandidates,
    Item? alchemyResultItem,
    Map<int, int>? alchemyLevelWeights,
  }) {
    return OptimizedGameState(
      characterStats: characterStats ?? this.characterStats,
      playerPosition: playerPosition ?? this.playerPosition,
      movementState: movementState ?? this.movementState,
      weaponJoystickX: weaponJoystickX ?? this.weaponJoystickX ?? 0.0,
      weaponJoystickY: weaponJoystickY ?? this.weaponJoystickY ?? 0.0,
      weaponJoystickIntensity: weaponJoystickIntensity ?? this.weaponJoystickIntensity ?? 0.0,
      isWeaponAiming: isWeaponAiming ?? this.isWeaponAiming,
      lastWeaponAimX: lastWeaponAimX ?? this.lastWeaponAimX,
      lastWeaponAimY: lastWeaponAimY ?? this.lastWeaponAimY,
      weaponAttackStartTime: weaponAttackStartTime ?? this.weaponAttackStartTime,
      meleeAttackTemplate: meleeAttackTemplate ?? this.meleeAttackTemplate,
      rangedAttackTemplate: rangedAttackTemplate ?? this.rangedAttackTemplate,
      selectedAttackMode: selectedAttackMode ?? this.selectedAttackMode,
      weaponDamageAmplify: weaponDamageAmplify ?? this.weaponDamageAmplify ?? 1.0,
      weaponCritDamage: weaponCritDamage ?? this.weaponCritDamage ?? 1.5,
      weaponCritChanceBonus: weaponCritChanceBonus ?? this.weaponCritChanceBonus ?? 0.0,
      weaponMagazineSize: weaponMagazineSize ?? this.weaponMagazineSize,
      weaponClipAmmo: weaponClipAmmo ?? this.weaponClipAmmo,
      weaponTotalAmmo: weaponTotalAmmo ?? this.weaponTotalAmmo,
      projectiles: projectiles ?? this.projectiles,
      isReloading: isReloading ?? this.isReloading,
      reloadProgress: reloadProgress ?? this.reloadProgress,
      reloadStartTime: reloadStartTime ?? this.reloadStartTime,
      reloadDurationMs: reloadDurationMs ?? this.reloadDurationMs,
      reloadStartClipAmmo: reloadStartClipAmmo ?? this.reloadStartClipAmmo,
      reloadStartReserveAmmo: reloadStartReserveAmmo ?? this.reloadStartReserveAmmo,
      map: map ?? this.map,
      chestPositions: chestPositions ?? this.chestPositions,
      safePositions: safePositions ?? this.safePositions,
      fixedChestPosition: fixedChestPosition ?? this.fixedChestPosition,
      playerInventory: playerInventory ?? this.playerInventory,
      equipmentSlots: equipmentSlots ?? this.equipmentSlots,
      inventoryCapacity: inventoryCapacity ?? this.inventoryCapacity,
      maxInventoryCapacity: maxInventoryCapacity ?? this.maxInventoryCapacity,
      groundItems: groundItems ?? this.groundItems,
      visibleTiles: visibleTiles ?? this.visibleTiles,
      visibleMap: visibleMap ?? this.visibleMap,
      ghostManager: ghostManager ?? this.ghostManager,
      showInventory: showInventory ?? this.showInventory,
      showCharacterInfo: showCharacterInfo ?? this.showCharacterInfo,
      showShop: showShop ?? this.showShop,
      showAlchemy: showAlchemy ?? this.showAlchemy,
      alchemyStation: alchemyStation ?? this.alchemyStation,
      schoolShop: schoolShop ?? this.schoolShop,
      isGameOver: isGameOver ?? this.isGameOver,
      deathReason: deathReason ?? this.deathReason,
      currentPage: currentPage ?? this.currentPage,
      isNoClipMode: isNoClipMode ?? this.isNoClipMode,
      noClipEndTime: noClipEndTime ?? this.noClipEndTime,
      unstuckCooldownEnd: unstuckCooldownEnd ?? this.unstuckCooldownEnd,
      isWaitingForMovement: isWaitingForMovement ?? this.isWaitingForMovement,
      unstuckActivatedTime: unstuckActivatedTime ?? this.unstuckActivatedTime,
      isInitialNoClipMode: isInitialNoClipMode ?? this.isInitialNoClipMode,
      hasUsedJoystick: hasUsedJoystick ?? this.hasUsedJoystick,
      lastPosition: lastPosition ?? this.lastPosition,
      accumulatedDistance: accumulatedDistance ?? this.accumulatedDistance,
      lastHp: lastHp ?? this.lastHp,
      shouldShowDamageEffect: shouldShowDamageEffect ?? this.shouldShowDamageEffect,
      lastDamageAmount: lastDamageAmount ?? this.lastDamageAmount,
      lastAnimationFrame: lastAnimationFrame ?? this.lastAnimationFrame,
      broadcastMessages: broadcastMessages ?? this.broadcastMessages,
      currentZoneName: currentZoneName ?? this.currentZoneName,
      zoneNameVisibleUntil: zoneNameVisibleUntil ?? this.zoneNameVisibleUntil,
      characterSkills: characterSkills ?? this.characterSkills,
      skillStates: skillStates ?? this.skillStates,
      currentCastingSkillId: currentCastingSkillId ?? this.currentCastingSkillId,
      castingProgress: castingProgress ?? this.castingProgress,
      isUsingItem: isUsingItem ?? this.isUsingItem,
      currentUsingItem: currentUsingItem ?? this.currentUsingItem,
      itemUsageProgress: itemUsageProgress ?? this.itemUsageProgress,
      itemUsageStartTime: itemUsageStartTime ?? this.itemUsageStartTime,
      isExploringChest: isExploringChest ?? this.isExploringChest,
      currentExploringChest: currentExploringChest ?? this.currentExploringChest,
      chestExplorationProgress: chestExplorationProgress ?? this.chestExplorationProgress,
      chestExplorationStartTime: chestExplorationStartTime ?? this.chestExplorationStartTime,
      isChestSearchOpen: isChestSearchOpen ?? this.isChestSearchOpen,
      chestPendingItems: chestPendingItems ?? this.chestPendingItems,
      chestVisibleItems: chestVisibleItems ?? this.chestVisibleItems,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      gameEndTime: gameEndTime ?? this.gameEndTime,
      deathTimeStats: deathTimeStats ?? this.deathTimeStats,
      deathTimeInventory: deathTimeInventory ?? this.deathTimeInventory,
      oxygenSystem: oxygenSystem ?? this.oxygenSystem,
      isInWater: isInWater ?? this.isInWater,
      currentOxygen: currentOxygen ?? this.currentOxygen,
      maxOxygen: maxOxygen ?? this.maxOxygen,
      oxygenBonus: oxygenBonus ?? this.oxygenBonus,
      oxygenRecoveryManager: oxygenRecoveryManager ?? this.oxygenRecoveryManager,
      showAlchemyEffect: showAlchemyEffect ?? this.showAlchemyEffect,
      alchemyCandidates: alchemyCandidates ?? this.alchemyCandidates,
      alchemyResultItem: alchemyResultItem ?? this.alchemyResultItem,
      alchemyLevelWeights: alchemyLevelWeights ?? this.alchemyLevelWeights,
    );
  }

  /// 获取实际的最大氧气值（基础值 + 增强值）
  double get actualMaxOxygen => maxOxygen + oxygenBonus;
}

/// 创建初始角色状态的辅助方法
Map<String, dynamic> _createInitialCharacterStats(Map<String, dynamic> characterData) {
  return {
    'name': characterData['name'],
    'hp': (characterData['hp'] as num).toDouble(),
    // 关键区域：支持从角色配置读取最大生命值
    'maxHp': ((characterData['maxHp'] ?? characterData['hp']) as num).toDouble(),
    'san': (characterData['san'] as num).toDouble(),
    // 关键区域：支持从角色配置读取最大精神值
    'maxSan': ((characterData['maxSan'] ?? characterData['san']) as num).toDouble(),
    'food': (characterData['food'] as num).toDouble(),
    // 关键区域：新增 maxFood 表示饱食度上限（可被道具修改）
    'maxFood': ((characterData['maxFood'] ?? characterData['food']) as num).toDouble(),
    'moveSpeed': characterData['moveSpeed'],
    'gold': (characterData['gold'] as num).toDouble(),
    'image': characterData['image'],
    // 关键区域：角色高品质物品概率增幅（0.0为默认概率，0.1表示+10%）
    'rarityBoost': ((characterData['rarityBoost'] ?? 0.0) as num).toDouble(),
    // 关键区域：新增护甲耐久字段，默认 0（未装备）
    'armor': 0.0,
    // 关键区域：新增处分机制 —— 初始处分与上限
    'punish': ((characterData['punish'] ?? 0) as num).toDouble(),
    'maxPunish': 10.0,
    'baseDamage': ((characterData['baseDamage'] ?? 0.0) as num).toDouble(),
    'baseCritChance': ((characterData['baseCritChance'] ?? 0.0) as num).toDouble(),
  };
}

/// 初始化角色技能列表
  List<Skill> _initializeCharacterSkills(String? characterName) {
    if (characterName == null || characterName.isEmpty) {
      return [];
    }
    
    final skills = CharacterSkills.getSkillsForCharacter(characterName);
    return skills;
  }

/// 初始化技能状态映射
Map<String, SkillState> _initializeSkillStates(String? characterName) {
  if (characterName == null || characterName.isEmpty) {
    return {};
  }
  
  final skills = CharacterSkills.getSkillsForCharacter(characterName);
  final skillStates = <String, SkillState>{};
  
  for (final skill in skills) {
    skillStates[skill.id] = SkillState(skillId: skill.id);
  }
  
  return skillStates;
}

/// 优化的游戏状态管理器
class OptimizedGameStateNotifier extends StateNotifier<OptimizedGameState> {
  // 关键区域：保存角色原始数据用于读取 initialItems
  final Map<String, dynamic> _characterData;
  Timer? _movementTimer;
  Timer? _visionUpdateTimer;
  Timer? _unstuckTimer;
  Timer? _hungerTimer;
  Timer? _smoothVisionTimer; // 平滑视野动画定时器
  Timer? _skillCooldownTimer; // 技能冷却时间更新定时器
  Timer? _gameLoopTimer; // 独立的游戏循环定时器，确保UI定期刷新
  Timer? _deathCheckTimer; // 独立的死亡判定定时器
  Timer? _itemUsageTimer; // 物品使用进度定时器
  Timer? _chestExplorationTimer; // 宝箱探索进度定时器
  Timer? _shopRefreshTimer; // 商店刷新检查定时器
  Timer? _itemSpawnTimer; // 物品刷新定时器
  Timer? _ghostUpdateTimer; // 鬼更新定时器
  Timer? _ghostSpawnTimer; // 鬼生成定时器
  Timer? _oxygenRecoveryTimer; // 氧气恢复完成回调定时器（关键：需在 dispose 中取消）
  late VisionSystem _visionSystem;
  late EnhancedVisionSystem _enhancedVisionSystem; // 增强版视野系统
  late SmoothVisionManager _smoothVisionManager; // 平滑视野管理器
  OxygenSystem? _oxygenSystem; // 氧气系统
  final bool _enableGhostSpawn; // 关键区域：控制是否启动鬼生成定时器（用于避免默认provider产生重复计时器）
  
  // 状态更新锁，防止竞争条件
  bool _isUpdatingStats = false;
  
  // 性能优化参数
  static const double _acceleration = 8.0;
  static const double _friction = 6.0;
  static const double _deltaTime = 0.016; // 16ms
  static const int _visionUpdateInterval = 100; // 视野更新间隔(ms)
  static const int _smoothVisionUpdateInterval = 16; // 平滑视野动画间隔(ms) - 60fps
  
  // 缓存变量以减少重复计算
  Point<int>? _lastPlayerGridPosition;
  Set<Point<int>>? _cachedVisibleTiles;

  OptimizedGameStateNotifier(Map<String, dynamic> characterData)
      : _characterData = characterData,
        _enableGhostSpawn = true,
        super(
    OptimizedGameState(
      characterStats: _createInitialCharacterStats(characterData),
      playerPosition: const OptimizedPlayerPosition(x: 10.0, y: 10.0, facingRight: true),
      movementState: const OptimizedMovementState(),
      map: MapData.testMap,
      chestPositions: [], // 初始为空，将在 _initializeGame 中随机生成
      safePositions: [], // 初始为空，将在 _initializeGame 中随机生成
      playerInventory: [], // 玩家从空背包开始
      visibleTiles: {},
      visibleMap: List.generate(
        MapData.testMap.length,
        (y) => List.generate(MapData.testMap[0].length, (x) => false),
      ),
      ghostManager: GhostManager(map: MapData.testMap),
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
      characterSkills: const [],
      skillStates: const {},
      gameStartTime: DateTime.now(),
      gameEndTime: null,
      maxOxygen: (characterData['maxOxygen'] ?? 10.0).toDouble(),
      currentOxygen: (characterData['maxOxygen'] ?? 10.0).toDouble(),
      oxygenRecoveryManager: OxygenRecoveryManager(),
    ),
  ) {
    _initializeGame();
  }

  // 关键区域：无鬼生成版本（用于默认provider，避免重复鬼生成检查）
  OptimizedGameStateNotifier.noGhost(Map<String, dynamic> characterData)
      : _characterData = characterData,
        _enableGhostSpawn = false,
        super(
    OptimizedGameState(
      characterStats: _createInitialCharacterStats(characterData),
      playerPosition: const OptimizedPlayerPosition(x: 10.0, y: 10.0, facingRight: true),
      movementState: const OptimizedMovementState(),
      map: MapData.testMap,
      chestPositions: [], // 初始为空，将在 _initializeGame 中随机生成
      safePositions: [], // 初始为空，将在 _initializeGame 中随机生成
      playerInventory: [], // 玩家从空背包开始
      visibleTiles: {},
      visibleMap: List.generate(
        MapData.testMap.length,
        (y) => List.generate(MapData.testMap[0].length, (x) => false),
      ),
      ghostManager: GhostManager(map: MapData.testMap),
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
      characterSkills: const [],
      skillStates: const {},
      gameStartTime: DateTime.now(),
      gameEndTime: null,
      maxOxygen: (characterData['maxOxygen'] ?? 10.0).toDouble(),
      currentOxygen: (characterData['maxOxygen'] ?? 10.0).toDouble(),
      oxygenRecoveryManager: OxygenRecoveryManager(),
    ),
  ) {
    _initializeGame();
  }

  void _initializeGame() {
    _visionSystem = VisionSystem(map: MapData.testMap);
    _enhancedVisionSystem = EnhancedVisionSystem(map: MapData.testMap); // 初始化增强版视野系统
    _smoothVisionManager = SmoothVisionManager(); // 初始化平滑视野管理器
    _initializeOxygenSystem(); // 初始化氧气系统
    _initializeShop();
    // 关键区域：初始化炼金机位置（依赖商店位置）
    _initializeAlchemyStation();
    _initializeGhosts();
    _setRandomPlayerSpawn();
    _initializeChests(); // 初始化随机宝箱位置
    _initializeSafes(); // 关键区域：初始化保险箱位置（仅建筑内）
    _spawnFixedChestUnderPlayer(); // 关键区域：开局在玩家脚底下生成固定宝箱
    // 关键区域：初始化装备为空并覆盖持久化记录（符合“开局装备栏为空”）
    final clearedSlots = <String, Item?>{
      'weapon': null,
      'armor': null,
      'head': null,
      'bag': null,
      'pants': null,
      'shoes': null,
    };
    state = state.copyWith(equipmentSlots: clearedSlots);
    _saveEquipmentToPrefs();
    // 关键区域：从角色数据读取 initialItems 并注入背包
    _injectInitialItemsFromCharacterData();
    _startMovementTimer();
    _startVisionUpdateTimer();
    _startSmoothVisionTimer(); // 启动平滑视野动画定时器
    _startUnstuckTimer();
    _startHungerTimer();
    // 移除技能冷却定时器
    _startGameLoopTimer(); // 启动独立的游戏循环定时器
    _startDeathCheckTimer(); // 启动独立的死亡判定定时器
    _startShopRefreshTimer(); // 启动商店刷新检查定时器
    _startItemSpawnTimer(); // 启动物品刷新定时器
    _startGhostUpdateTimer(); // 启动鬼的更新定时器
    if (_enableGhostSpawn) {
      _startGhostSpawnTimer(); // 启动鬼的生成定时器
    }
    _updateVision();
  }

  // 关键区域：初始物品注入逻辑（读取 manData 的 initialItems）
  void _injectInitialItemsFromCharacterData() {
    final dynamic itemsDyn = _characterData['initialItems'];
    if (itemsDyn is! List) return;
    final List<String> ids = itemsDyn.map((e) => '$e').toList();
    for (final id in ids) {
      final List<Item> matches = allItems.where((it) => it.id == id).toList();
      if (matches.isEmpty) continue;
      final Item template = matches.first;
      insertItemAtPosition(template, state.playerInventory.length);
    }
  }

  // 关键区域：装备/卸下逻辑与效果应用
  /// 装备物品到指定槽位（weapon/armor/head/bag/pants/shoes）
  bool equipItemToSlot(Item item, String slot) {
    // 关键区域：类型与槽位匹配（英文标准：equipment + equipmentSlot）
    final bool matchesByType = (item.type == 'equipment' && item.equipmentSlot == slot);

    if (!matchesByType) {
      return false;
    }

    // 关键区域：优先按对象身份匹配选中堆叠，其次按 id+count 兜底
    List<Item> inventory = List<Item>.from(state.playerInventory);
    int idx = inventory.indexWhere((i) => identical(i, item));
    if (idx == -1) {
      idx = inventory.indexWhere((i) => i.id == item.id && i.count > 0);
    }
    if (idx == -1) {
      return false; // 背包中不存在
    }

    // 若槽位已占用，先卸下
    final currentEquipped = state.equipmentSlots[slot];
    if (currentEquipped != null) {
      // 关键区域：替换前容量预检——若卸下失败（容量不足），则替换失败并提示
      final bool ok = _unequipInternal(slot, notify: false);
      if (!ok) {
        addBroadcastMessage('背包空间不足', BroadcastMessageType.item, duration: const Duration(seconds: 1));
        return false;
      }
      // 关键区域：卸下后背包已更新，需重新抓取背包并重新定位待装备条目
      inventory = List<Item>.from(state.playerInventory);
      idx = inventory.indexWhere((i) => identical(i, item));
      if (idx == -1) {
        idx = inventory.indexWhere((i) => i.id == item.id && i.count > 0);
      }
      if (idx == -1) {
        return false; // 防御：若异常找不到，终止操作
      }
    }

    // 关键区域：护甲装备耐久用 count 表示——装备时不扣数量，直接移除该件
    final invItem = inventory[idx];
    // 关键区域：任意槽位的护甲（含 armorValue）均按耐久件处理（不消耗数量）
    final bool isArmorWithBlock = ((invItem.effects?['armorValue'] ?? 0) > 0);
    if (isArmorWithBlock) {
      inventory.removeAt(idx);
    } else {
      if (invItem.count > 1) {
        inventory[idx] = Item(
          id: invItem.id,
          name: invItem.name,
          image: invItem.image,
          description: invItem.description,
          effects: invItem.effects,
          type: invItem.type,
          count: invItem.count - 1,
          availableInShop: invItem.availableInShop,
          basePrice: invItem.basePrice,
          usageTime: invItem.usageTime,
          level: invItem.level,
          equipmentSlot: invItem.equipmentSlot,
          weaponParams: invItem.weaponParams,
        );
      } else {
        inventory.removeAt(idx);
      }
    }

    // 关键区域：护甲耐久同步到角色状态，效果中剔除 armorValue
    if (isArmorWithBlock) {
      final Map<String, int> effectsNoArmor = Map<String, int>.from(item.effects ?? const {});
      effectsNoArmor.remove('armorValue');
      _applyeffects(effectsNoArmor);
    } else {
      _applyeffects(item.effects ?? const {});
    }

    // 更新状态：设置槽位与背包
    final updatedSlots = Map<String, Item?>.from(state.equipmentSlots);
    updatedSlots[slot] = item;
    state = state.copyWith(playerInventory: inventory, equipmentSlots: updatedSlots);
    if (slot == 'weapon') {
      _applyWeaponParamsFromItem(item);
    }

    // 播报消息
    addBroadcastMessage('装备了 ${item.name}', BroadcastMessageType.item);

    // 持久化保存
    _saveEquipmentToPrefs();

    return true;
  }

  /// 卸下指定槽位的装备
  bool unequipItemFromSlot(String slot) {
    return _unequipInternal(slot, notify: true);
  }

  bool _unequipInternal(String slot, {bool notify = true}) {
    final equipped = state.equipmentSlots[slot];
    if (equipped == null) return false;

    // 关键区域：卸下前容量检查（不足则失败并提示“背包空间不足”）
    List<Item> preInventory = List<Item>.from(state.playerInventory);
    final bool isEquipment = (equipped.type == 'equipment');
    final bool hasSameId = preInventory.indexWhere((i) => i.id == equipped.id) >= 0;
    final bool needsNewSlot = isEquipment || !hasSameId;

    // 预测卸下后的容量（考虑 inventoryBonus 撤销）
    final int deltaCapacity = -(equipped.effects?['inventoryBonus'] ?? 0);
    final int futureCapacityRaw = state.inventoryCapacity + deltaCapacity;
    final int futureCapacity = futureCapacityRaw.clamp(1, state.maxInventoryCapacity);
    final int futureInvLen = preInventory.length > futureCapacity ? futureCapacity : preInventory.length;
    if (needsNewSlot && futureInvLen >= futureCapacity) {
      if (notify) {
        addBroadcastMessage('背包空间不足', BroadcastMessageType.item, duration: const Duration(seconds: 1));
      }
      return false;
    }

    // 关键区域：撤回装备效果（剔除护甲耐久），并同步耐久回物品
    Map<String, int> effectsForRemoval = Map<String, int>.from(equipped.effects ?? const {});
    if (slot == 'armor' && (effectsForRemoval['armorValue'] ?? 0) > 0) {
      effectsForRemoval.remove('armorValue');
      // 关键区域：直接使用装备件自身的 count 作为耐久写回来源
      final double currentDurability = equipped.count.toDouble();
      final int newCount = currentDurability <= 0 ? 0 : currentDurability.round();
      // 更新装备槽中的对象为最新耐久（避免后续引用旧值）
      final updatedSlotsPre = Map<String, Item?>.from(state.equipmentSlots);
      updatedSlotsPre[slot] = Item(
        id: equipped.id,
        name: equipped.name,
        image: equipped.image,
        description: equipped.description,
        effects: equipped.effects,
        type: equipped.type,
        count: newCount,
        availableInShop: equipped.availableInShop,
        basePrice: equipped.basePrice,
        usageTime: equipped.usageTime,
        level: equipped.level,
        equipmentSlot: equipped.equipmentSlot,
        weaponParams: equipped.weaponParams,
        clipAmmo: equipped.clipAmmo,
        ammoReserve: equipped.ammoReserve,
      );
      state = state.copyWith(equipmentSlots: updatedSlotsPre);
      // 角色护甲清零
      final ch = Map<String, dynamic>.from(state.characterStats);
      ch['armor'] = 0.0;
      state = state.copyWith(characterStats: ch);
    }
    _removeeffects(effectsForRemoval);

    // 将装备返回到背包（合并数量）
    final inventory = List<Item>.from(state.playerInventory);
    if (isEquipment) {
      // 关键区域：护甲装备返回背包时保持当前耐久（count）
      inventory.add(Item(
        id: equipped.id,
        name: equipped.name,
        image: equipped.image,
        description: equipped.description,
        effects: equipped.effects,
        type: equipped.type,
        count: equipped.count,
        availableInShop: equipped.availableInShop,
        basePrice: equipped.basePrice,
        usageTime: equipped.usageTime,
        level: equipped.level,
        equipmentSlot: equipped.equipmentSlot,
        weaponParams: equipped.weaponParams,
        clipAmmo: equipped.clipAmmo,
        ammoReserve: equipped.ammoReserve,

      ));
    } else {
      // 非装备类型仍可合并（例如消耗品）
      final idx = inventory.indexWhere((i) => i.id == equipped.id);
      if (idx >= 0) {
        final existing = inventory[idx];
        inventory[idx] = Item(
          id: existing.id,
          name: existing.name,
          image: existing.image,
          description: existing.description,
          effects: existing.effects,
          type: existing.type,
          count: existing.count + 1,
          availableInShop: existing.availableInShop,
          basePrice: existing.basePrice,
          usageTime: existing.usageTime,
          level: existing.level,
          equipmentSlot: existing.equipmentSlot,
          weaponParams: existing.weaponParams,
          clipAmmo: existing.clipAmmo,
          ammoReserve: existing.ammoReserve,

        );
      } else {
        inventory.add(Item(
          id: equipped.id,
          name: equipped.name,
          image: equipped.image,
          description: equipped.description,
          effects: equipped.effects,
          type: equipped.type,
          count: 1,
          availableInShop: equipped.availableInShop,
          basePrice: equipped.basePrice,
          usageTime: equipped.usageTime,
          level: equipped.level,
          equipmentSlot: equipped.equipmentSlot,
          weaponParams: equipped.weaponParams,
          clipAmmo: equipped.clipAmmo,
          ammoReserve: equipped.ammoReserve,

        ));
      }
    }

    // 清空槽位并更新状态
    final updatedSlots = Map<String, Item?>.from(state.equipmentSlots);
    updatedSlots[slot] = null;
    state = state.copyWith(playerInventory: inventory, equipmentSlots: updatedSlots);
    if (slot == 'weapon') {
      state = state.copyWith(
        selectedAttackMode: AttackMode.melee,
        meleeAttackTemplate: const AttackTemplate(color: ui.Color(0xFFFFA000), distance: 1.2, range: 1.2),
        rangedAttackTemplate: const AttackTemplate(color: ui.Color(0xFF00E5FF), distance: 4.0, range: 12.0),
        weaponDamageAmplify: 1.0,
        weaponCritDamage: 1.5,
        weaponCritChanceBonus: 0.0,
        weaponMagazineSize: 0,
        weaponClipAmmo: 0,
        weaponTotalAmmo: 0,
        projectiles: const [],
      );
    }

    if (notify) {
      addBroadcastMessage('卸下了 ${equipped.name}', BroadcastMessageType.item);
    }

    // 持久化保存
    _saveEquipmentToPrefs();

    return true;
  }

  // 关键区域：应用装备效果（与道具使用效果一致的规则）
  void _applyeffects(Map<String, int> effects) {
    final character = Map<String, dynamic>.from(state.characterStats);

    effects.forEach((effectType, value) {
      switch (effectType) {
        case 'hp':
          final currentHp = (character['hp'] ?? 100).toDouble();
          final double maxHp = (character['maxHp'] ?? 100).toDouble();
          character['hp'] = (currentHp + value).clamp(0, maxHp);
          break;
        case 'food':
          final currentFood = (character['food'] ?? 100).toDouble();
          final double maxFood = (character['maxFood'] ?? 100).toDouble();
          character['food'] = (currentFood + value).clamp(0, maxFood);
          break;
        case 'maxHp':
          final double currentMaxHp = (character['maxHp'] ?? 100).toDouble();
          final double proposed = (currentMaxHp + value).toDouble();
          final double newMaxHp = proposed < 1 ? 1 : proposed;
          character['maxHp'] = newMaxHp;
          final double currentHp2 = (character['hp'] ?? 0).toDouble();
          if (currentHp2 > newMaxHp) character['hp'] = newMaxHp;
          break;
        case 'maxFood':
          final double currentMaxFood = (character['maxFood'] ?? 100).toDouble();
          final double proposedFoodMax = (currentMaxFood + value).toDouble();
          final double newMaxFood = proposedFoodMax < 1 ? 1 : proposedFoodMax;
          character['maxFood'] = newMaxFood;
          final double currentFood2 = (character['food'] ?? 0).toDouble();
          if (currentFood2 > newMaxFood) character['food'] = newMaxFood;
          break;
        case 'san':
          final currentSan = (character['san'] ?? 100).toDouble();
          character['san'] = (currentSan + value).clamp(0, 250);
          break;
        case 'moveSpeed':
          final currentSpeed = (character['moveSpeed'] ?? 100).toDouble();
          character['moveSpeed'] = (currentSpeed + value).clamp(1, double.infinity);
          break;
        case 'gold':
          final currentGold = (character['gold'] ?? 0).toDouble();
          character['gold'] = (currentGold + value).clamp(0, 999999);
          break;
        case 'oxygenBonus':
          final currentOxygenBeforeBonus = state.currentOxygen;
          increaseOxygenCapacity(value.toDouble());
          final newMaxOxygen = state.actualMaxOxygen;
          if (currentOxygenBeforeBonus < newMaxOxygen) {
            _startOxygenRecovery(currentOxygenBeforeBonus, newMaxOxygen);
          }
          break;
        case 'inventoryBonus':
          // 关键区域：装备背包扩容效果——调整背包容量（支持负值撤销）
          final int currentCapacity = state.inventoryCapacity;
          final int proposed = currentCapacity + value;
          // 容量边界：至少为1，不超过最大容量
          final int newCapacity = proposed.clamp(1, state.maxInventoryCapacity);

          // 若为缩容且当前物品超过新容量，则将多余物品掉落在地上
          List<Item> newInventory = List<Item>.from(state.playerInventory);
          if (value < 0 && newInventory.length > newCapacity) {
            final int dropCount = newInventory.length - newCapacity;
            final Point<int> dropPos = state.playerPosition.toPoint();
            for (int i = 0; i < dropCount; i++) {
              final int idx = newInventory.length - 1; // 从末尾开始移除
              final Item item = newInventory[idx];
              _dropItemToGround(item, dropPos);
              newInventory.removeAt(idx);
            }
          }

          // 更新容量与背包
          state = state.copyWith(
            inventoryCapacity: newCapacity,
            playerInventory: newInventory,
          );
          break;
        case 'armorValue':
          // 关键区域：护甲耐久由装备 count 管理，效果不直接改动角色
          break;
        case 'punish':
          final double currentPun = (character['punish'] ?? 0).toDouble();
          final double maxPun = (character['maxPunish'] ?? 10).toDouble();
          final double newPun = (currentPun + value).clamp(0, maxPun);
          character['punish'] = newPun;
          break;
      }
    });

    _safeUpdateCharacterStats((_) => character, '装备效果应用');
  }

  // 关键区域：撤回装备效果（取反应用）
  void _removeeffects(Map<String, int> effects) {
    final reversed = <String, int>{};
    effects.forEach((k, v) => reversed[k] = -v);
    _applyeffects(reversed);
  }

  // 关键区域：装备槽持久化（SharedPreferences）
  Future<void> _saveEquipmentToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> slotIds = {};
      state.equipmentSlots.forEach((slot, item) {
        if (item != null) slotIds[slot] = item.id;
      });
      final jsonStr = slotIds.entries.map((e) => '${e.key}:${e.value}').join('|');
      await prefs.setString('equipmentSlots', jsonStr);
    } catch (_) {}
  }

  Future<void> _loadEquipmentFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('equipmentSlots');
      // 关键区域：若无持久化装备数据，默认不装备任何物品（全部为空）
      if (jsonStr == null || jsonStr.isEmpty) {
        final updatedSlots = <String, Item?>{
          'weapon': null,
          'armor': null,
          'head': null,
          'bag': null,
          'pants': null,
          'shoes': null,
        };
        state = state.copyWith(equipmentSlots: updatedSlots);
        await _saveEquipmentToPrefs();
        return;
      }
      // 关键区域：使用安全的默认槽位映射（六类），避免 Null 导致的类型异常
      final updatedSlots = <String, Item?>{
        'weapon': null,
        'armor': null,
        'head': null,
        'bag': null,
        'pants': null,
        'shoes': null,
      };
      final pairs = jsonStr.split('|');
      for (final p in pairs) {
        if (!p.contains(':')) continue;
        final parts = p.split(':');
        if (parts.length != 2) continue;
        final slot = parts[0];
        final id = parts[1];
        final item = allItems.firstWhere(
          (i) => i.id == id,
          orElse: () => Item(
            id: id,
            name: id,
            image: '',
            description: '',
            effects: const {},
            type: 'equipment',
            equipmentSlot: slot,

          ),
        );
        // 关键区域：护甲耐久用 count 表示——恢复时同步耐久并剔除 armorValue
        if (slot == 'armor' && ((item.effects?['armorValue'] ?? 0) > 0)) {
          final ch = Map<String, dynamic>.from(state.characterStats);
          ch['armor'] = item.count.toDouble();
          state = state.copyWith(characterStats: ch);
          final Map<String, int> effectsNoArmor = Map<String, int>.from(item.effects ?? const {});
          effectsNoArmor.remove('armorValue');
          _applyeffects(effectsNoArmor);
        } else {
          _applyeffects(item.effects ?? const {});
        }
        if (slot == 'hand') {
          // 历史槽位 hand 不再支持，跳过
          continue;
        }
        updatedSlots[slot] = item;
      }
      state = state.copyWith(equipmentSlots: updatedSlots);
      final Item? weaponItem = updatedSlots['weapon'];
      if (weaponItem != null) {
        _applyWeaponParamsFromItem(weaponItem);
      }
    } catch (_) {}
  }

  // 注释：此前的“按角色默认初始化装备”逻辑已移除，
  // 现在开局不装备任何物品（所有槽位为 null）。

  /// 开局在玩家脚底下生成一个固定刷新宝箱，并记录其位置
  /// 关键区域：该宝箱位置固定且用于 100% 掉落 3 个随机物品
  void _spawnFixedChestUnderPlayer() {
    final fixedPos = state.playerPosition.toPoint();
    final updatedChestPositions = List<Point<int>>.from(state.chestPositions);
    if (!updatedChestPositions.contains(fixedPos)) {
      updatedChestPositions.add(fixedPos);
    }
    state = state.copyWith(
      chestPositions: updatedChestPositions,
      fixedChestPosition: fixedPos,
    );
  }

  /// 初始化鬼
  void _initializeGhosts() {
    final walkablePositions = _getWalkablePositions();
    if (walkablePositions.isEmpty) return;
    
    final playerPosition = state.playerPosition.toPoint();
    print('👻 开始初始化鬼 - 玩家位置: (${playerPosition.x}, ${playerPosition.y})');
    
    // 清空现有的鬼
    state.ghostManager.clearAllGhosts();
    
    // 初始化不同类型的鬼
    final ghostTypes = [
      {'type': NormalGhost, 'count': 2, 'name': '普通鬼'},
      {'type': FastGhost, 'count': 1, 'name': '快速鬼'},
      {'type': StrongGhost, 'count': 1, 'name': '强力鬼'},
      {'type': TricksterGhost, 'count': 1, 'name': '诡计鬼'},
    ];
    
    int totalSpawned = 0;
    
    for (final ghostConfig in ghostTypes) {
      final ghostType = ghostConfig['type'] as Type;
      final count = ghostConfig['count'] as int;
      final name = ghostConfig['name'] as String;
      
      for (int i = 0; i < count; i++) {
        final spawnPosition = _findSafeGhostSpawnPosition(walkablePositions, playerPosition);
        if (spawnPosition != null) {
          Ghost newGhost;
          final ghostPosition = GhostPosition(x: spawnPosition.x.toDouble(), y: spawnPosition.y.toDouble());
          
          switch (ghostType) {
            case NormalGhost:
              newGhost = NormalGhost(position: ghostPosition);
              break;
            case FastGhost:
              newGhost = FastGhost(position: ghostPosition);
              break;
            case StrongGhost:
              newGhost = StrongGhost(position: ghostPosition);
              break;
            case TricksterGhost:
              newGhost = TricksterGhost(position: ghostPosition);
              break;
            default:
              newGhost = NormalGhost(position: ghostPosition);
          }
          
          state.ghostManager.addGhost(newGhost);
          totalSpawned++;
          
          print('👻 生成 $name 于位置 (${spawnPosition.x}, ${spawnPosition.y})');
        } else {
          print('⚠️ 无法为 $name 找到安全的生成位置');
        }
      }
    }
    
    print('👻 鬼初始化完成 - 总共生成了 $totalSpawned 个鬼');
  }

  /// 寻找安全的鬼生成位置
  Point<int>? _findSafeGhostSpawnPosition(List<Point<int>> walkablePositions, Point<int> playerPosition) {
    // 过滤掉玩家附近的位置（至少距离15格）
    final safePositions = walkablePositions.where((pos) {
      final distance = _calculateDistance(pos, playerPosition);
      return distance >= 15;
    }).toList();
    
    if (safePositions.isEmpty) {
      // 如果没有足够远的位置，降低要求到10格
      final fallbackPositions = walkablePositions.where((pos) {
        final distance = _calculateDistance(pos, playerPosition);
        return distance >= 10;
      }).toList();
      
      if (fallbackPositions.isNotEmpty) {
        final random = Random();
        return fallbackPositions[random.nextInt(fallbackPositions.length)];
      }
      return null;
    }
    
    // 从安全位置中随机选择一个
    final random = Random();
    return safePositions[random.nextInt(safePositions.length)];
  }

  /// 获取所有可行走的位置
  List<Point<int>> _getWalkablePositions() {
    final walkablePositions = <Point<int>>[];
    final map = state.map;
    
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        if (map[y][x] != 'wall' && map[y][x] != 'water') {
          walkablePositions.add(Point(x, y));
        }
      }
    }
    
    return walkablePositions;
  }

  /// 定义地图中的出生区域
  /// 每个区域包含一个矩形范围和优先级
  static const List<Map<String, dynamic>> _spawnZones = [
    // 左上角草地区域
    {
      'name': '北部草原',
      'minX': 2,
      'maxX': 12,
      'minY': 1,
      'maxY': 10,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 右上角区域
    {
      'name': '东北部',
      'minX': 80,
      'maxX': 100,
      'minY': 1,
      'maxY': 15,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 中部大草原
    {
      'name': '中央平原',
      'minX': 35,
      'maxX': 65,
      'minY': 35,
      'maxY': 50,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
    // 左下角区域
    {
      'name': '西南部',
      'minX': 2,
      'maxX': 20,
      'minY': 70,
      'maxY': 85,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 右下角区域
    {
      'name': '东南部',
      'minX': 80,
      'maxX': 100,
      'minY': 70,
      'maxY': 85,
      'preferredTerrain': ['grass', 'path'],
      'priority': 1,
    },
    // 中下部区域
    {
      'name': '南部平原',
      'minX': 30,
      'maxX': 70,
      'minY': 75,
      'maxY': 85,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
    // 左中部区域
    {
      'name': '西部区域',
      'minX': 2,
      'maxX': 15,
      'minY': 40,
      'maxY': 60,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
    // 右中部区域
    {
      'name': '东部区域',
      'minX': 85,
      'maxX': 100,
      'minY': 40,
      'maxY': 60,
      'preferredTerrain': ['grass', 'path'],
      'priority': 2,
    },
  ];

  /// 设置玩家随机出生位置，在整个地图的不同区域随机选择
  void _setRandomPlayerSpawn() {
    final random = Random();
    Point<int>? validSpawnPoint;
    int attempts = 0;
    const maxAttempts = 200; // 增加尝试次数
    const minDistanceFromGhost = 30.0; // 减少最小距离，让出生点更分散
     const maxDistanceFromGhost = 80.0; // 添加最大距离限制，避免过于远离

    // 首先尝试从预定义的出生区域中选择
    final shuffledZones = List.from(_spawnZones)..shuffle(random);
    
    for (final zone in shuffledZones) {
      final zonePositions = _getPositionsInZone(zone);
      if (zonePositions.isEmpty) continue;

      // 在当前区域中尝试找到合适的出生点
      for (int zoneAttempts = 0; zoneAttempts < 50 && validSpawnPoint == null; zoneAttempts++) {
        final candidatePosition = zonePositions[random.nextInt(zonePositions.length)];
        
        if (_isValidSpawnPosition(candidatePosition, minDistanceFromGhost, maxDistanceFromGhost)) {
          validSpawnPoint = candidatePosition;
          break;
        }
      }
      
      if (validSpawnPoint != null) break;
    }

    // 如果预定义区域都不合适，回退到全地图随机搜索
    if (validSpawnPoint == null) {
      final walkablePositions = _getWalkablePositions();
      
      while (validSpawnPoint == null && attempts < maxAttempts) {
        final candidatePosition = walkablePositions[random.nextInt(walkablePositions.length)];
        
        if (_isValidSpawnPosition(candidatePosition, minDistanceFromGhost, maxDistanceFromGhost)) {
          validSpawnPoint = candidatePosition;
        }
        
        attempts++;
      }
    }

    // 如果还是找不到合适的位置，找一个距离鬼适中的位置
    if (validSpawnPoint == null) {
      validSpawnPoint = _findBalancedSpawnPosition();
    }

    // 最后的后备方案
    validSpawnPoint ??= Point(10, 10);

    // 更新玩家位置
    final String? initialZone = getZoneNameAt(validSpawnPoint.x, validSpawnPoint.y);
    state = state.copyWith(
      playerPosition: OptimizedPlayerPosition(
        x: validSpawnPoint.x.toDouble(),
        y: validSpawnPoint.y.toDouble(),
        facingRight: true,
      ),
      currentZoneName: initialZone,
      zoneNameVisibleUntil: initialZone != null ? DateTime.now().add(const Duration(seconds: 3)) : null,
    );
  }

  /// 获取指定区域内的所有可行走位置
  List<Point<int>> _getPositionsInZone(Map<String, dynamic> zone) {
    final positions = <Point<int>>[];
    final map = state.map;
    final preferredTerrain = List<String>.from(zone['preferredTerrain']);
    
    final minX = (zone['minX'] as int).clamp(0, map[0].length - 1);
    final maxX = (zone['maxX'] as int).clamp(0, map[0].length - 1);
    final minY = (zone['minY'] as int).clamp(0, map.length - 1);
    final maxY = (zone['maxY'] as int).clamp(0, map.length - 1);
    
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final terrain = map[y][x];
        // 优先选择偏好地形，但也接受其他可行走地形
        if (preferredTerrain.contains(terrain) || 
            (terrain != 'wall' && terrain != 'water' && terrain != 'building')) {
          positions.add(Point(x, y));
        }
      }
    }
    
    return positions;
  }

  /// 检查位置是否适合作为出生点
  bool _isValidSpawnPosition(Point<int> position, double minDistance, double maxDistance) {
    // 检查地形是否可行走
    final terrain = state.map[position.y][position.x];
    if (terrain == 'wall' || terrain == 'water') {
      return false;
    }

    // 检查与鬼的距离
    for (final ghost in state.ghostManager.ghosts) {
      if (ghost.position != null) {
        final distance = _calculateDistance(position, ghost.position!.toPoint());
        if (distance < minDistance || distance > maxDistance) {
          return false;
        }
      }
    }

    return true;
  }

  /// 寻找一个距离鬼适中的位置
  Point<int> _findBalancedSpawnPosition() {
    final walkablePositions = _getWalkablePositions();
    Point<int>? bestPosition;
    double bestScore = -1;

    for (final position in walkablePositions) {
      double totalDistance = 0;
      int ghostCount = 0;

      for (final ghost in state.ghostManager.ghosts) {
        if (ghost.position != null) {
          totalDistance += _calculateDistance(position, ghost.position!.toPoint());
          ghostCount++;
        }
      }

      if (ghostCount > 0) {
        final averageDistance = totalDistance / ghostCount;
        // 寻找平均距离在30-60之间的位置
        if (averageDistance >= 30 && averageDistance <= 60) {
          final score = 60 - (averageDistance - 45).abs(); // 45是理想距离
          if (score > bestScore) {
            bestScore = score;
            bestPosition = position;
          }
        }
      }
    }

    return bestPosition ?? walkablePositions.first;
  }

  /// 计算两点之间的距离
  double _calculateDistance(Point<int> point1, Point<int> point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// 初始化商店
  void _initializeShop() {
    // 在地图中找到商店位置（假设在坐标 (5, 5)）
    final shopPosition = Point<int>(5, 5);
    final shop = Shop(
      position: shopPosition,
      items: [],
      lastPriceChange: DateTime.now(),
    );
    
    // 刷新商店商品
    shop.refreshItems();
    
    state = state.copyWith(schoolShop: shop);
  }

  /// 初始化炼金机位置
  void _initializeAlchemyStation() {
    // 关键区域：炼金机固定刷新坐标（31, 31）
    // 说明：忽略商店位置，始终将炼金机设置在 (31,31)
    state = state.copyWith(alchemyStation: const Point<int>(31, 31));
  }

  /// 启动移动定时器
  void _startMovementTimer() {
    // 先取消现有定时器
    _movementTimer?.cancel();
    
    // 启动新的移动定时器
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateMovement();
    });
    
  }

  /// 启动视野更新定时器（降低频率以提高性能）
  void _startVisionUpdateTimer() {
    _visionUpdateTimer = Timer.periodic(
      const Duration(milliseconds: _visionUpdateInterval), 
      (timer) {
        _updateVision();
      }
    );
  }

  /// 启动平滑视野动画定时器（高频率更新以保证流畅性）
  void _startSmoothVisionTimer() {
    _smoothVisionTimer = Timer.periodic(
      const Duration(milliseconds: _smoothVisionUpdateInterval), 
      (timer) {
        _updateSmoothVisionAnimations();
      }
    );
  }

  /// 启动脱离卡死状态更新定时器
  void _startUnstuckTimer() {
    _unstuckTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 每100ms检查一次
      (timer) {
        _updateUnstuckState();
      }
    );
  }

  /// 启动饥饿扣血定时器
  void _startHungerTimer() {
    _hungerTimer = Timer.periodic(
      const Duration(seconds: 1), // 每秒检查一次
      (timer) {
        _updateHungerDamage();
      }
    );
  }

  /// 启动技能冷却时间更新定时器
  void _startSkillCooldownTimer() {
    _skillCooldownTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 每100ms更新一次冷却状态
      (timer) {
        _updateSkillCooldowns();
      }
    );
  }

  /// 启动独立的游戏循环定时器
  void _startGameLoopTimer() {
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _updateGameLoop();
      }
    );
  }

  /// 启动独立的死亡判定定时器
  void _startDeathCheckTimer() {
    _deathCheckTimer = Timer.periodic(
      const Duration(milliseconds: 200), // 每200ms检查一次死亡条件
      (timer) {
        _checkGameOverConditions();
      }
    );
  }

  /// 启动商店刷新检查定时器
  void _startShopRefreshTimer() {
    _shopRefreshTimer = Timer.periodic(
      const Duration(seconds: 1), // 每秒检查一次商店是否需要刷新
      (timer) {
        _checkShopRefresh();
      }
    );
  }

  /// 独立的游戏循环更新，确保UI定期刷新
  void _updateGameLoop() {
    // 强制触发UI更新，确保技能倒计时、视野等元素能够实时显示
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 更新氧气系统
    _updateOxygenSystem();
    _pruneProjectiles();
    _resolveRangedHits();
    _resolveMeleeHits();
    _updateReloadProgress();
    
    // 通过更新动画帧计数器来强制触发UI刷新
    // 这确保了即使玩家不移动，UI也会定期更新
    state = state.copyWith(
      lastAnimationFrame: currentTime,
    );
  }

  void _resolveRangedHits() {
    if (state.projectiles.isEmpty) return;
    if (state.selectedAttackMode != AttackMode.ranged) return;
    final ghosts = state.ghostManager.ghosts;
    if (ghosts.isEmpty) return;
    final double speedTilesPerSec = state.rangedAttackTemplate.range;
    final double maxDistTiles = state.rangedAttackTemplate.distance;
    final DateTime now = DateTime.now();
    final double px = state.playerPosition.x;
    final double py = state.playerPosition.y;
    final double offsetR = 0.45;
    final List<Projectile> remaining = [];
    for (final p in state.projectiles) {
      final int elapsed = now.difference(p.startTime).inMilliseconds;
      if (elapsed < 0) continue;
      final double travelTiles = math.min(maxDistTiles, (speedTilesPerSec <= 0 ? 0.0 : (speedTilesPerSec * elapsed / 1000.0)));
      final double sx = px + math.cos(p.angle) * offsetR;
      final double sy = py + math.sin(p.angle) * offsetR;
      final double ex = sx + math.cos(p.angle) * travelTiles;
      final double ey = sy + math.sin(p.angle) * travelTiles;

      bool hitSomeone = false;
      for (final g in ghosts) {
        if (g.isInvisible || g.position == null) continue;
        final double gx = g.position!.x;
        final double gy = g.position!.y;
        final double d = _distancePointToSegment(gx, gy, sx, sy, ex, ey);
        if (d <= 0.35) {
          final ({int value, bool isCrit}) damage = _computeDamage(isRanged: true);
          g.applyDamage(damage.value, isCrit: damage.isCrit);
          if (g.hp <= 0) {
            state.ghostManager.removeGhost(g);
          }
          hitSomeone = true;
          break;
        }
      }

      if (!hitSomeone) {
        remaining.add(p);
      }
    }

    if (remaining.length != state.projectiles.length) {
      state = state.copyWith(projectiles: remaining, lastAnimationFrame: DateTime.now().millisecondsSinceEpoch);
    }
  }

  void _resolveMeleeHits() {
    final DateTime? start = state.weaponAttackStartTime;
    if (start == null) return;
    final int elapsed = DateTime.now().difference(start).inMilliseconds;
    final int maxDuration = 320;
    if (elapsed < 0 || elapsed > maxDuration) return;
    final ghosts = state.ghostManager.ghosts;
    if (ghosts.isEmpty) return;
    final double px = state.playerPosition.x;
    final double py = state.playerPosition.y;
    final double jx = state.weaponJoystickX ?? 0.0;
    final double jy = state.weaponJoystickY ?? 0.0;
    final double angle = math.atan2(jy, (jx == 0.0 && jy == 0.0) ? 1e-6 : jx);
    final double radius = state.meleeAttackTemplate.distance;
    final double sweep = state.meleeAttackTemplate.range;
    for (final g in ghosts) {
      if (g.isInvisible || g.position == null) continue;
      if (g.lastMeleeHitAt != null && g.lastMeleeHitAt == start) continue;
      final double dx = g.position!.x - px;
      final double dy = g.position!.y - py;
      final double dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radius) continue;
      final double ang = math.atan2(dy, dx == 0.0 && dy == 0.0 ? 1e-6 : dx);
      double diff = _normAngle(ang - angle);
      if (diff.abs() <= sweep / 2) {
        final ({int value, bool isCrit}) damage = _computeDamage(isRanged: false);
        g.applyDamage(damage.value, isCrit: damage.isCrit);
        g.lastMeleeHitAt = start;
        if (g.hp <= 0) {
          state.ghostManager.removeGhost(g);
        }
      }
    }
    state = state.copyWith(lastAnimationFrame: DateTime.now().millisecondsSinceEpoch);
  }

  double _normAngle(double a) {
    while (a > math.pi) a -= 2 * math.pi;
    while (a < -math.pi) a += 2 * math.pi;
    return a;
  }

  double _distancePointToSegment(double px, double py, double x1, double y1, double x2, double y2) {
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    if (dx == 0 && dy == 0) {
      final double ddx = px - x1;
      final double ddy = py - y1;
      return math.sqrt(ddx * ddx + ddy * ddy);
    }
    final double t = (((px - x1) * dx) + ((py - y1) * dy)) / (dx * dx + dy * dy);
    final double clampedT = t.clamp(0.0, 1.0);
    final double cx = x1 + clampedT * dx;
    final double cy = y1 + clampedT * dy;
    final double ddx = px - cx;
    final double ddy = py - cy;
    return math.sqrt(ddx * ddx + ddy * ddy);
  }

  ({int value, bool isCrit}) _computeDamage({required bool isRanged}) {
    final double baseDamage = ((state.characterStats['baseDamage'] ?? 0) as num).toDouble();
    final double amp = (state.weaponDamageAmplify ?? 1.0).toDouble();
    double dmg = baseDamage * amp;
    final double baseCritChance = ((state.characterStats['baseCritChance'] ?? 0.0) as num).toDouble();
    final double bonusCrit = (state.weaponCritChanceBonus ?? 0.0).toDouble();
    final double critChance = (baseCritChance + bonusCrit).clamp(0.0, 1.0);
    final double critMult = (state.weaponCritDamage ?? 1.5).toDouble();
    bool isCrit = false;
    if (critChance > 0.0 && math.Random().nextDouble() < critChance) {
      dmg *= critMult;
      isCrit = true;
    }
    final int result = dmg.round();
    final int finalValue = result <= 0 ? 1 : result;
    return (value: finalValue, isCrit: isCrit);
  }

  void _pruneProjectiles() {
    if (state.projectiles.isEmpty) return;
    final double distTiles = state.rangedAttackTemplate.distance;
    final double speedTilesPerSec = state.rangedAttackTemplate.range;
    final int maxMs = speedTilesPerSec <= 0 ? 320 : ((distTiles / speedTilesPerSec) * 1000).ceil();
    final DateTime now = DateTime.now();
    final List<Projectile> kept = state.projectiles.where((p) {
      final int elapsed = now.difference(p.startTime).inMilliseconds;
      return elapsed <= maxMs;
    }).toList();
    if (kept.length != state.projectiles.length) {
      state = state.copyWith(projectiles: kept);
    }
  }

  void _updateReloadProgress() {
    if (!state.isReloading || state.reloadStartTime == null) return;
    final int elapsed = DateTime.now().difference(state.reloadStartTime!).inMilliseconds;
    final double prog = (elapsed / state.reloadDurationMs).clamp(0.0, 1.0);
    final int mag = state.weaponMagazineSize;
    final int startClip = state.reloadStartClipAmmo;
    final int startReserve = state.reloadStartReserveAmmo;
    final int maxLoadable = math.min(mag - startClip, startReserve);
    final int loadedSoFar = (maxLoadable * prog).floor();
    final int expectedClip = (startClip + loadedSoFar).clamp(0, mag);
    final int expectedReserve = (startReserve - loadedSoFar).clamp(0, 1 << 30);

    final Item? w = state.equipmentSlots['weapon'];
    final Map<String, Item?> slots = Map<String, Item?>.from(state.equipmentSlots);
    if (w != null) {
      slots['weapon'] = Item(
        id: w.id,
        name: w.name,
        image: w.image,
        description: w.description,
        effects: w.effects,
        type: w.type,
        count: w.count,
        availableInShop: w.availableInShop,
        basePrice: w.basePrice,
        usageTime: w.usageTime,
        level: w.level,
        equipmentSlot: w.equipmentSlot,
        weaponParams: w.weaponParams,
        clipAmmo: expectedClip,
        ammoReserve: expectedReserve,
      );
    }

    state = state.copyWith(
      reloadProgress: prog,
      weaponClipAmmo: expectedClip,
      weaponTotalAmmo: expectedReserve,
      equipmentSlots: slots,
    );

    // 关键区域：达到满弹或备用耗尽或进度完成时，结束换弹
    final bool finished = prog >= 1.0 || expectedClip >= mag || expectedReserve <= 0;
    if (finished) {
      state = state.copyWith(isReloading: false, reloadStartTime: null);
    }
  }

  /// 检查商店是否需要刷新
  void _checkShopRefresh() {
    final shop = state.schoolShop;
    if (shop != null && shop.shouldRefresh()) {
      // 商店需要刷新，调用刷新方法
      shop.refreshItems();
      // 更新状态以触发UI刷新
      state = state.copyWith(schoolShop: shop);
      print('🔄 商店自动刷新触发 - 时间: ${DateTime.now()}');
    }
  }

  /// 启动物品刷新定时器
  void _startItemSpawnTimer() {
    // 首次刷新延迟30秒，之后根据ItemSpawner的间隔设置
    final initialDelay = Duration(seconds: ItemSpawner.getNextSpawnInterval());
    
    print('🎁 物品刷新系统启动 - 首次刷新将在${initialDelay.inSeconds}秒后进行 - 时间: ${DateTime.now()}');
    // 关键区域：首次定时器作为成员存储，确保在 dispose 时可取消
    _itemSpawnTimer = Timer(initialDelay, () {
      // 关键区域：在 Notifier 被销毁后避免继续更新状态
      if (!mounted) return;
      _trySpawnItem();
      if (!mounted) return;
      _scheduleNextItemSpawn();
    });
  }

  /// 安排下次物品刷新
  void _scheduleNextItemSpawn() {
    final nextInterval = Duration(seconds: ItemSpawner.getNextSpawnInterval());
    
    print('⏰ 安排下次物品刷新 - 将在${nextInterval.inSeconds}秒后进行 - 时间: ${DateTime.now()}');
    
    // 关键区域：递归定时器在回调开始检查 mounted，避免 dispose 后调用
    _itemSpawnTimer = Timer(nextInterval, () {
      if (!mounted) return;
      _trySpawnItem();
      if (!mounted) return;
      _scheduleNextItemSpawn(); // 递归安排下次刷新
    });
  }

  /// 尝试刷新一个物品到地图上
  void _trySpawnItem() {
    final playerPosition = state.playerPosition.toPoint();
    final chestPositions = state.chestPositions;
    final existingGroundItems = state.groundItems;
    // 关键区域：读取角色概率增幅（rarityBoost），用于提升高品质地面物品概率
    final double rarityBoost = ((state.characterStats['rarityBoost'] ?? 0.0) as num).toDouble();
    
    // 尝试刷新物品
    final spawnResult = ItemSpawner.trySpawnItem(
      playerPosition,
      chestPositions,
      existingGroundItems,
      rarityBoost: rarityBoost,
    );
    
    if (spawnResult != null) {
      final position = spawnResult.key;
      final item = spawnResult.value;
      
      // 更新地面物品状态
      final updatedGroundItems = Map<Point<int>, List<Item>>.from(existingGroundItems);
      updatedGroundItems[position] = [item];
      
      // 更新游戏状态
      state = state.copyWith(groundItems: updatedGroundItems);
      
      // 添加刷新成功的播报消息
      addBroadcastMessage(
        '发现了 ${item.name} (${ItemSpawner.getLevelDisplayName(item.level)})',
        BroadcastMessageType.item,
      );
      
      print('🎁 物品刷新成功: ${item.name} (等级${item.level}) 位置(${position.x}, ${position.y}) - 时间: ${DateTime.now()}');
    }
  }

  /// 启动鬼更新定时器
  void _startGhostUpdateTimer() {
    _ghostUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 每100ms更新一次鬼的状态，提高移动流畅度
      (timer) {
        _updateGhosts();
      }
    );
    print('👻 鬼更新系统启动 - 更新间隔: 100ms - 时间: ${DateTime.now()}');
  }

  /// 更新所有鬼的状态
  void _updateGhosts() {
    final playerPosition = state.playerPosition.toPoint();
    final ghostCount = state.ghostManager.ghosts.length;
    
    // 更新所有鬼的状态
    state.ghostManager.updateAll(
      playerPosition,
      _onPlayerAttackedByGhost,
      _onGhostDetectPlayer,
    );
    
    // 强制触发UI更新以显示鬼的新位置
    state = state.copyWith(
      lastAnimationFrame: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 当鬼攻击玩家时的回调
  void _onPlayerAttackedByGhost(Map<String, int> effects) {
    print('👻 鬼攻击玩家! 效果: $effects');
    
    // 应用攻击效果到玩家
    _safeUpdateCharacterStats((stats) {
      final updatedStats = Map<String, dynamic>.from(stats);
      
      effects.forEach((key, value) {
        if (!updatedStats.containsKey(key)) return;
        if (key == 'hp' && value < 0) {
          // 关键区域：护甲格挡鬼攻击伤害并扣减耐久
          final double incoming = (-value).toDouble();
          final double applied = _applyArmorBlock(updatedStats, incoming);
          final double currentHp = (updatedStats['hp'] ?? 0).toDouble();
          final double maxHp = (updatedStats['maxHp'] ?? 100).toDouble();
          updatedStats['hp'] = (currentHp - applied).clamp(0, maxHp);
        } else {
          final double currentValue = (updatedStats[key] ?? 0).toDouble();
          updatedStats[key] = (currentValue + value).clamp(0, double.infinity);
        }
      });
      
      return updatedStats;
    }, '鬼攻击效果');
    
    // 添加播报消息
    addBroadcastMessage(
      '被鬼攻击了！',
      BroadcastMessageType.damage,
    );
  }

  /// 当鬼检测到玩家时的回调
  void _onGhostDetectPlayer() {
    print('👻 鬼发现了玩家!');
    
    // 添加播报消息
    addBroadcastMessage(
      '鬼发现了你！',
      BroadcastMessageType.system,
    );
  }

  /// 启动鬼生成定时器
  void _startGhostSpawnTimer() {
    // 每60秒检查一次是否需要生成新的鬼
    _ghostSpawnTimer = Timer.periodic(
      const Duration(seconds: 60),
      (timer) {
        _checkAndSpawnGhosts();
      }
    );
    print('👻 鬼生成系统启动 - 检查间隔: 60秒 - 时间: ${DateTime.now()}');
  }

  /// 检查并生成新的鬼
  void _checkAndSpawnGhosts() {
    final currentGhostCount = state.ghostManager.ghosts.length;
    final int punish = ((state.characterStats['punish'] ?? 0) as num).toInt().clamp(0, 10);
    final int minGhosts = (1 + (punish ~/ 3)).clamp(1, 8);
    final int maxGhosts = (6 + punish).clamp(minGhosts, 12);

    print('👻 检查鬼数量 - 当前: $currentGhostCount, 处分: $punish, 最小: $minGhosts, 最大: $maxGhosts'); 

    if (currentGhostCount < minGhosts) {
      final spawnCount = (minGhosts - currentGhostCount).clamp(1, 3);
      _spawnRandomGhosts(spawnCount);
    } else if (currentGhostCount < maxGhosts) {
      final random = Random();
      final double probability = 0.2 + (punish * 0.05); // 处分越高，生成概率越高
      if (random.nextDouble() < probability.clamp(0.0, 0.8)) {
        _spawnRandomGhosts(1);
      }
    } else if (currentGhostCount > maxGhosts) {
      // 处分较低时，尝试减少鬼数量（随机移除一个）
      final random = Random();
      if (random.nextDouble() < 0.2) {
        final ghosts = state.ghostManager.ghosts;
        if (ghosts.isNotEmpty) {
          state.ghostManager.removeGhost(ghosts[random.nextInt(ghosts.length)]);
        }
      }
    }
  }

  /// 生成随机类型的鬼
  void _spawnRandomGhosts(int count) {
    final walkablePositions = _getWalkablePositions();
    if (walkablePositions.isEmpty) return;
    
    final playerPosition = state.playerPosition.toPoint();
    final random = Random();
    
    // 定义鬼类型权重
    final ghostTypeWeights = [
      {'type': NormalGhost, 'weight': 40, 'name': '普通鬼'},
      {'type': FastGhost, 'weight': 25, 'name': '快速鬼'},
      {'type': StrongGhost, 'weight': 20, 'name': '强力鬼'},
      {'type': TricksterGhost, 'weight': 15, 'name': '诡计鬼'},
    ];
    
    for (int i = 0; i < count; i++) {
      final spawnPosition = _findSafeGhostSpawnPosition(walkablePositions, playerPosition);
      if (spawnPosition != null) {
        // 根据权重随机选择鬼类型
        final totalWeight = ghostTypeWeights.fold<int>(0, (sum, item) => sum + (item['weight'] as int));
        final randomValue = random.nextInt(totalWeight);
        
        int currentWeight = 0;
        Type selectedType = NormalGhost;
        String selectedName = '普通鬼';
        
        for (final ghostConfig in ghostTypeWeights) {
          currentWeight += ghostConfig['weight'] as int;
          if (randomValue < currentWeight) {
            selectedType = ghostConfig['type'] as Type;
            selectedName = ghostConfig['name'] as String;
            break;
          }
        }
        
        // 创建鬼
        Ghost newGhost;
        final ghostPosition = GhostPosition(x: spawnPosition.x.toDouble(), y: spawnPosition.y.toDouble());
        switch (selectedType) {
          case NormalGhost:
            newGhost = NormalGhost(position: ghostPosition);
            break;
          case FastGhost:
            newGhost = FastGhost(position: ghostPosition);
            break;
          case StrongGhost:
            newGhost = StrongGhost(position: ghostPosition);
            break;
          case TricksterGhost:
            newGhost = TricksterGhost(position: ghostPosition);
            break;
          default:
            newGhost = NormalGhost(position: ghostPosition);
        }
        
        state.ghostManager.addGhost(newGhost);
        print('👻 动态生成 $selectedName 于位置 (${spawnPosition.x}, ${spawnPosition.y})');
        
        // 添加播报消息
        addBroadcastMessage(
          '新的鬼出现了！',
          BroadcastMessageType.system,
        );
      } else {
        print('⚠️ 无法找到安全的鬼生成位置');
      }
    }
  }

  /// 更新脱离卡死状态
  void _updateUnstuckState() {
    final now = DateTime.now();
    bool needsUpdate = false;
    
    // 检查无视地形模式是否应该结束
    if (state.isNoClipMode && 
        state.noClipEndTime != null && 
        now.isAfter(state.noClipEndTime!)) {
      state = state.copyWith(
        isNoClipMode: false,
        noClipEndTime: null,
      );
      needsUpdate = true;
      print('无视地形模式已结束');
    }
    
    // 如果有更新，触发UI刷新
    if (needsUpdate) {
      // 状态已经更新，StateNotifier会自动通知监听者
    }
  }

  /// 安全更新角色状态，防止竞争条件
  void _safeUpdateCharacterStats(Map<String, dynamic> Function(Map<String, dynamic>) updateFunction, String debugInfo) {
    // 检查是否已经被 dispose
    if (!mounted) {
      print('_safeUpdateCharacterStats: OptimizedGameStateNotifier 已被 dispose，跳过状态更新');
      return;
    }
    
    if (_isUpdatingStats) {
      return;
    }
    
    _isUpdatingStats = true;
    try {
      final currentStats = Map<String, dynamic>.from(state.characterStats);
      // 应用更新函数（基于当前快照）
      final updatedStats = updateFunction(currentStats);
      // 仅合并“被更新的键”，保留最新状态中的其它键值
      final latestStats = Map<String, dynamic>.from(state.characterStats);
      updatedStats.forEach((key, value) {
        final prev = currentStats[key];
        final bool changed = !currentStats.containsKey(key) || prev != value;
        if (changed) {
          latestStats[key] = value;
        }
      });
      state = state.copyWith(characterStats: latestStats);
    } finally {
      _isUpdatingStats = false;
    }
  }

  /// 更新饥饿扣血逻辑
  void _updateHungerDamage() {
    _safeUpdateCharacterStats((currentStats) {
      final currentFood = currentStats['food'] ?? 0;
      final currentHp = currentStats['hp'] ?? 0;
      

      
      // 当饱食度为0且生命值大于0时，每秒扣1生命值
      if (currentFood <= 0 && currentHp > 0) {
        final damageAmount = 1.0; // 饥饿扣血量
        final updatedStats = Map<String, dynamic>.from(currentStats);
        // 关键区域：饥饿伤害支持护甲格挡
        final double applied = _applyArmorBlock(updatedStats, damageAmount);
        final newHp = (currentHp - applied).clamp(0, currentStats['maxHp'] ?? 100);
        

        
        // 检测生命值变化并触发伤害效果
        final hpChanged = currentHp != newHp;
        
        if (hpChanged) {
          // 更新生命值
          // 使用已更新护甲耐久的统计映射
          updatedStats['hp'] = newHp.toDouble();
          
          // 更新其他状态
          state = state.copyWith(
            lastHp: currentHp.toDouble(),
            shouldShowDamageEffect: true,
            lastDamageAmount: applied,
          );
          
          // 添加饥饿伤害播报消息
          addBroadcastMessage(
            '饥饿扣血 -${applied.toStringAsFixed(1)}',
            BroadcastMessageType.damage,
          );
          
          // 检查是否死亡
          if (newHp <= 0) {
            // 这里可以触发游戏结束逻辑
          }
          
          return updatedStats;
        }
      }
      
      // 没有变化，返回原状态
      return currentStats;
    }, '饥饿系统扣血');
  }

  // 关键区域：护甲抗伤机制——先削弱50%，再按等级百分比分配给护甲与玩家
  double _applyArmorBlock(Map<String, dynamic> updatedStats, double damage) {
    if (damage <= 0) return 0.0;
    // 关键区域：支持多件护甲——按等级优先，其次按耐久优先，选择一件参与格挡
    final List<MapEntry<String, Item>> candidates = state.equipmentSlots.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .where((e) => (e.value.effects?['armorValue'] ?? 0) > 0 && e.value.count > 0)
        .toList();
    if (candidates.isEmpty) {
      return damage;
    }
    candidates.sort((a, b) {
      if (b.value.level != a.value.level) {
        return b.value.level.compareTo(a.value.level); // 等级降序
      }
      return b.value.count.compareTo(a.value.count); // 耐久降序
    });
    final String chosenSlot = candidates.first.key;
    final Item armorItem = candidates.first.value;
    final double currentDurability = armorItem.count.toDouble();
    final double reduced = damage * 0.5;
    final int level = armorItem.level;
    final Map<int, double> ratios = const {
      1: 0.20,
      2: 0.40,
      3: 0.50,
      4: 0.60,
      5: 0.70,
      6: 0.90,
    };
    final double armorShare = ratios[level] ?? 0.0;
    double toArmor = reduced * armorShare;
    double toPlayer = reduced - toArmor;
    final double absorbedByArmor = toArmor.clamp(0.0, currentDurability);
    final double overflow = toArmor - absorbedByArmor;
    toPlayer += overflow;
    final double newDurability = (currentDurability - absorbedByArmor).clamp(0.0, double.infinity);
    updatedStats['armor'] = newDurability;
    // 关键区域：同步选择的装备件耐久（count）
    int newCount = newDurability.round();
    if (newCount < 0) newCount = 0;
    final updatedSlots = Map<String, Item?>.from(state.equipmentSlots);
    updatedSlots[chosenSlot] = Item(
      id: armorItem.id,
      name: armorItem.name,
      image: armorItem.image,
      description: armorItem.description,
      effects: armorItem.effects,
      type: armorItem.type,
      count: newCount,
      availableInShop: armorItem.availableInShop,
      basePrice: armorItem.basePrice,
      usageTime: armorItem.usageTime,
      level: armorItem.level,
      equipmentSlot: armorItem.equipmentSlot,

    );
    state = state.copyWith(equipmentSlots: updatedSlots);
    return toPlayer;
  }

  /// 计算修正后的移动速度（考虑水中和饱食度影响）
  double _getModifiedMoveSpeed() {
    final baseSpeed = state.characterStats['moveSpeed'] ?? 100.0;
    double modifiedSpeed = baseSpeed;
    
    // 水中移动速度降低10%
    if (_oxygenSystem?.isUnderwater == true) {
      modifiedSpeed *= 0.9; // 降低10%
      print('移动速度：水中移动，速度降低10% -> ${modifiedSpeed.toStringAsFixed(1)}');
    }
    
    // 饱食度影响移动速度（关键区域：使用动态 maxFood）
    final currentFood = state.characterStats['food'] ?? 0;
    final double maxFood = (state.characterStats['maxFood'] ?? 100).toDouble();
    final foodPercentage = (currentFood / maxFood).clamp(0.0, 1.0);
    
    // 当饱食度低于50%时开始影响移动速度
    if (foodPercentage < 0.5) {
      // 饱食度从50%到0%，移动速度从100%线性降低到50%
      final hungerSpeedMultiplier = 0.5 + (foodPercentage * 1.0); // 0.5 到 1.0
      modifiedSpeed *= hungerSpeedMultiplier;
      print('移动速度：饱食度影响，当前饱食度${foodPercentage.toStringAsFixed(2)}，速度倍数${hungerSpeedMultiplier.toStringAsFixed(2)} -> ${modifiedSpeed.toStringAsFixed(1)}');
    }
    
    return modifiedSpeed;
  }

  /// 优化的移动更新
  void _updateMovement() {
    final movement = state.movementState;
    final position = state.playerPosition;
    
    // 如果没有移动输入且速度为0，跳过计算
    if (!movement.isMoving && 
        movement.velocityX.abs() < 0.01 && 
        movement.velocityY.abs() < 0.01) {
      return;
    }
    
    // 计算基于玩家移动速度的最大速度（使用修正后的速度）
    final modifiedSpeed = _getModifiedMoveSpeed();
    final currentMaxSpeed = (modifiedSpeed / 20.0).clamp(0.1, double.infinity); // 移除上限，只保留最小值0.1防止零速度
    
    // 计算目标速度
    final targetVelocityX = movement.joystickX * currentMaxSpeed * movement.joystickIntensity;
    final targetVelocityY = movement.joystickY * currentMaxSpeed * movement.joystickIntensity;
    
    // 应用加速度或摩擦力
    double newVelocityX, newVelocityY;
    
    if (movement.isMoving) {
      // 加速到目标速度
      newVelocityX = movement.velocityX + (targetVelocityX - movement.velocityX) * _acceleration * _deltaTime;
      newVelocityY = movement.velocityY + (targetVelocityY - movement.velocityY) * _acceleration * _deltaTime;
    } else {
      // 应用摩擦力减速
      newVelocityX = movement.velocityX * (1.0 - _friction * _deltaTime);
      newVelocityY = movement.velocityY * (1.0 - _friction * _deltaTime);
      
      // 速度很小时直接停止
      if (newVelocityX.abs() < 0.01) newVelocityX = 0.0;
      if (newVelocityY.abs() < 0.01) newVelocityY = 0.0;
    }
    
    // 计算新位置
    final newX = position.x + newVelocityX * _deltaTime;
    final newY = position.y + newVelocityY * _deltaTime;
    
    // 改进的碰撞检测 - 支持滑动移动
    double finalX = position.x;
    double finalY = position.y;
    double finalVelocityX = newVelocityX;
    double finalVelocityY = newVelocityY;
    
    // 首先尝试完整移动
    if (_canMoveToPosition(newX, newY)) {
      finalX = newX;
      finalY = newY;
    } else {
      // 如果无法完整移动，尝试分别在X轴和Y轴上移动（滑动效果）
      bool canMoveX = _canMoveToPosition(newX, position.y);
      bool canMoveY = _canMoveToPosition(position.x, newY);
      
      if (canMoveX) {
        // 可以在X轴移动
        finalX = newX;
        finalY = position.y;
        // 保持X轴速度，停止Y轴速度
        finalVelocityY = 0.0;
      } else if (canMoveY) {
        // 可以在Y轴移动
        finalX = position.x;
        finalY = newY;
        // 保持Y轴速度，停止X轴速度
        finalVelocityX = 0.0;
      } else {
        // 两个方向都无法移动，停止所有速度
        finalX = position.x;
        finalY = position.y;
        finalVelocityX = 0.0;
        finalVelocityY = 0.0;
      }
    }
    
    // 创建新位置对象
    final newPosition = position.copyWith(x: finalX, y: finalY);
    final newMovement = movement.copyWith(
      velocityX: finalVelocityX,
      velocityY: finalVelocityY,
    );
    
    // 只有位置真正改变时才更新状态和应用地形效果
    if (newPosition != position || newMovement != movement) {
      // 检查是否需要开始脱离卡死冷却
      if (newPosition != position && state.isWaitingForMovement) {
        _startUnstuckCooldown();
      }
      
      // 计算移动距离
      double movementDistance = 0.0;
      if (newPosition != position) {
        movementDistance = _calculateMovementDistance(position, newPosition);
        
        // 累积移动距离
        final newAccumulatedDistance = state.accumulatedDistance + movementDistance;
        
        // 当累积距离达到1格时，应用地形效果
        if (newAccumulatedDistance >= 1.0) {
          final currentTerrain = _getCurrentTerrain();
          final gridsToProcess = newAccumulatedDistance.floor();
          
          // 应用地形效果
          _applyTerrainEffects(currentTerrain, gridsToProcess.toDouble());
          
          // 重置累积距离，保留小数部分
          final remainingDistance = newAccumulatedDistance - gridsToProcess;
          final int newGridX = newPosition.x.round();
          final int newGridY = newPosition.y.round();
          final String? zoneName = getZoneNameAt(newGridX, newGridY);
          final String? prevZoneName = getZoneNameAt(position.x.round(), position.y.round());
          DateTime? newVisibleUntil = state.zoneNameVisibleUntil;
          if (zoneName != null && zoneName != prevZoneName) {
            newVisibleUntil = DateTime.now().add(const Duration(seconds: 3));
          } else if (zoneName == null && prevZoneName != null) {
            newVisibleUntil = null;
          }
          
          // 更新状态，包括新的累积距离
          state = state.copyWith(
            playerPosition: newPosition,
            movementState: newMovement,
            lastPosition: position,
            accumulatedDistance: remainingDistance,
            currentZoneName: zoneName,
            zoneNameVisibleUntil: newVisibleUntil,
          );
        } else {
          // 距离不足1格，只更新位置和累积距离
          final int newGridX = newPosition.x.round();
          final int newGridY = newPosition.y.round();
          final String? zoneName = getZoneNameAt(newGridX, newGridY);
          final String? prevZoneName = getZoneNameAt(position.x.round(), position.y.round());
          DateTime? newVisibleUntil = state.zoneNameVisibleUntil;
          if (zoneName != null && zoneName != prevZoneName) {
            newVisibleUntil = DateTime.now().add(const Duration(seconds: 3));
          } else if (zoneName == null && prevZoneName != null) {
            newVisibleUntil = null;
          }
          state = state.copyWith(
            playerPosition: newPosition,
            movementState: newMovement,
            lastPosition: position,
            accumulatedDistance: newAccumulatedDistance,
            currentZoneName: zoneName,
            zoneNameVisibleUntil: newVisibleUntil,
          );
        }
      } else {
        // 位置没变，只更新移动状态
        state = state.copyWith(
          movementState: newMovement,
        );
      }
    }
  }

  /// 更新视野
  void _updateVision() {

    final playerGridPosition = Point(
      state.playerPosition.x.round(),
      state.playerPosition.y.round(),
    );
    
    // 检查是否需要强制更新视野（基于时间或精神值变化）
    final currentSanity = (state.characterStats['san'] ?? 100).toDouble();
    final maxSanity = (state.characterStats['maxSan'] ?? 100).toDouble();
    
    // 如果玩家网格位置没有改变且精神值没有显著变化，可以跳过视野计算
    // 但仍然需要更新平滑视野动画，所以不能完全跳过
    bool positionChanged = _lastPlayerGridPosition != playerGridPosition;
    
    // 即使位置没有变化，也要定期更新视野以支持动态效果
    // 这里我们移除了过于严格的缓存机制
    
    // 检查位置有效性
    if (playerGridPosition.x < 0 || 
        playerGridPosition.x >= state.map[0].length ||
        playerGridPosition.y < 0 || 
        playerGridPosition.y >= state.map.length) {
      return;
    }

    try {
      // 使用增强版视野系统获取带有可见性级别的瓦片（传递精神值和氧气视野修正）
      final tilesWithVisibility = _enhancedVisionSystem.getVisibleTilesWithLevel(
        playerGridPosition,
        sanityValue: currentSanity,
        maxSanity: maxSanity,
        oxygenVisionMultiplier: _oxygenSystem?.visionFactor,
      );
      
      // 提取完全可见的瓦片用于兼容性（包括有雾霾装饰的可见瓦片）
      final newVisibleTiles = tilesWithVisibility.entries
          .where((entry) => entry.value == TileVisibility.fullyVisible || 
                           entry.value == TileVisibility.visibleWithFogDecoration)
          .map((entry) => entry.key)
          .toSet();
      
      // 更新缓存（只在位置改变时更新位置缓存）
      if (positionChanged) {
        _lastPlayerGridPosition = playerGridPosition;
        _cachedVisibleTiles = newVisibleTiles;
      }
      
      // 更新已探索区域
      final newVisibleMap = List.generate(
        state.visibleMap.length,
        (y) => List<bool>.from(state.visibleMap[y]),
      );
      
      for (final tile in newVisibleTiles) {
        if (tile.y >= 0 && tile.y < newVisibleMap.length &&
            tile.x >= 0 && tile.x < newVisibleMap[0].length) {
          newVisibleMap[tile.y][tile.x] = true;
        }
      }
      
      // 更新平滑视野管理器，使用新的可见性级别系统
      _smoothVisionManager.updateVisionWithLevels(tilesWithVisibility);
      
      // 始终更新状态以确保UI能够响应视野变化
      // 即使位置没有改变，精神值或其他因素可能影响视野
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        visibleTiles: newVisibleTiles,
        visibleMap: newVisibleMap,
        lastAnimationFrame: currentTime, // 强制触发UI更新
      );
    } catch (e) {
      if (kDebugMode) {
        print('视野计算错误: $e');
      }
    }
  }

  /// 更新平滑视野动画
  void _updateSmoothVisionAnimations() {
    final needsRepaint = _smoothVisionManager.updateAnimations();
    
    // 如果动画有更新，触发重绘
    if (needsRepaint) {
      // 通过更新一个无关紧要的状态来触发重绘
      // 这里我们可以使用一个专门的动画帧计数器
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        // 添加一个动画帧标识，用于触发重绘
        lastAnimationFrame: currentTime,
      );
    }
  }

  /// 精确的碰撞检测 - 优化贴墙移动体验
  bool _canMoveToPosition(double x, double y) {
    // 检查是否处于无视地形模式（包括初始无碰撞模式和脱离卡死模式）
    if (state.isNoClipMode || state.isInitialNoClipMode) {
      final now = DateTime.now();
      
      // 检查脱离卡死的无视地形模式是否已过期
      if (state.isNoClipMode && state.noClipEndTime != null && now.isAfter(state.noClipEndTime!)) {
        // 无视地形模式已过期，关闭该模式
        state = state.copyWith(
          isNoClipMode: false,
          noClipEndTime: null,
        );
        print('无视地形模式已结束');
      } else {
        // 仍在无视地形模式中，只检查地图边界
        final gridX = x.floor();
        final gridY = y.floor();
        return gridX >= 0 && gridX < state.map[0].length &&
               gridY >= 0 && gridY < state.map.length;
      }
    }
    
    // 计算角色的碰撞半径
    // sizeScale = 0.6, collisionScale = 0.8
    // 实际碰撞半径 = 0.6 * 0.8 * 0.5 = 0.24 瓦片单位
    const sizeScale = 0.6;
    const collisionScale = 0.8;
    final characterHalfSize = sizeScale * collisionScale * 0.5;
    
    // 添加水平偏移量，让角色更容易贴墙移动
    // 左边判定向左偏移，右边判定也向左偏移
    final horizontalOffset = 0.2; // 向左偏移0.2瓦片单位，接近角色半径大小
    
    final samplePoints = [
      Point(x, y), // 中心点
      // 四个角点 - 添加水平偏移优化贴墙体验
      Point(x - characterHalfSize - horizontalOffset, y - characterHalfSize), // 左上角（向左偏移）
      Point(x + characterHalfSize - horizontalOffset, y - characterHalfSize), // 右上角（向左偏移）
      Point(x - characterHalfSize - horizontalOffset, y + characterHalfSize), // 左下角（向左偏移）
      Point(x + characterHalfSize - horizontalOffset, y + characterHalfSize), // 右下角（向左偏移）
      // 四个边缘中点 - 添加水平偏移
      Point(x - characterHalfSize - horizontalOffset, y), // 左边缘中点（向左偏移）
      Point(x + characterHalfSize - horizontalOffset, y), // 右边缘中点（向左偏移）
      Point(x, y - characterHalfSize), // 上边缘中点（保持不变）
      Point(x, y + characterHalfSize), // 下边缘中点（保持不变）
    ];
    
    // 检查每个采样点是否在有效范围内且不与墙壁碰撞
    for (final point in samplePoints) {
      final gridX = point.x.floor();
      final gridY = point.y.floor();
      
      // 边界检查
      if (gridX < 0 || gridX >= state.map[0].length ||
          gridY < 0 || gridY >= state.map.length) {
        return false;
      }
      
      // 墙壁碰撞检测
      if (state.map[gridY][gridX] == 'wall') {
        return false;
      }
    }
    
    return true;
  }

  /// 摇杆移动
  void onJoystickMove(double x, double y, double intensity) {
    // 如果正在使用物品或探索宝箱，禁止移动
    if (state.isUsingItem || state.isExploringChest) {
      return;
    }
    
    // 检查是否首次使用摇杆，如果是则启动初始无碰撞模式的倒计时
    if (state.isInitialNoClipMode && !state.hasUsedJoystick && intensity > 0.1) {
      final now = DateTime.now();
      final endTime = now.add(const Duration(seconds: 1));
      
      // 标记已使用摇杆，并设置一秒后结束初始无碰撞模式
      state = state.copyWith(
        hasUsedJoystick: true,
        noClipEndTime: endTime,
      );
      
      // 启动定时器，一秒后关闭初始无碰撞模式
      // 关键区域：在定时器回调开始检查 mounted，避免销毁后触发
      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        if (state.isInitialNoClipMode) {
          state = state.copyWith(
            isInitialNoClipMode: false,
            noClipEndTime: null,
          );
          print('初始无碰撞模式已结束');
        }
      });
      
      print('玩家开始使用摇杆，初始无碰撞模式将在1秒后结束');
    }
    
    final movement = state.movementState;
    final position = state.playerPosition;
    
    final newMovement = movement.copyWith(
      joystickX: x,
      joystickY: y,
      joystickIntensity: intensity,
      isMoving: intensity > 0.1,
    );
    
    final newPosition = position.copyWith(
      facingRight: x.abs() > 0.1 ? x > 0 : position.facingRight,
    );
    
    // 只有状态真正改变时才更新
    if (newMovement != movement || newPosition != position) {
      state = state.copyWith(
        movementState: newMovement,
        playerPosition: newPosition,
      );
    }
  }

  /// 摇杆停止
  void onJoystickStop() {
    final movement = state.movementState;
    
    final newMovement = movement.copyWith(
      joystickX: 0.0,
      joystickY: 0.0,
      joystickIntensity: 0.0,
      isMoving: false,
    );
    
    if (newMovement != movement) {
      state = state.copyWith(movementState: newMovement);
    }
  }

  void onWeaponJoystickMove(double x, double y, double intensity) {
    final double prevX = state.weaponJoystickX ?? 0.0;
    final double prevY = state.weaponJoystickY ?? 0.0;
    const double alpha = 0.35;
    double sx = prevX * (1 - alpha) + x * alpha;
    double sy = prevY * (1 - alpha) + y * alpha;
    final double mag = math.sqrt(sx * sx + sy * sy);
    if (mag > 1.0 && mag > 0.0) {
      sx /= mag;
      sy /= mag;
    }
    final bool aiming = intensity > 0.05;
    final newState = state.copyWith(
      weaponJoystickX: sx,
      weaponJoystickY: sy,
      weaponJoystickIntensity: intensity,
      isWeaponAiming: aiming,
      lastWeaponAimX: aiming ? sx : state.lastWeaponAimX,
      lastWeaponAimY: aiming ? sy : state.lastWeaponAimY,
      lastAnimationFrame: DateTime.now().millisecondsSinceEpoch,
    );
    if (newState != state) {
      state = newState;
    }
  }

  void onWeaponJoystickRelease(bool canceled, double x, double y, double intensity) {
    if (canceled) {
      state = state.copyWith(
        weaponJoystickX: 0.0,
        weaponJoystickY: 0.0,
        weaponJoystickIntensity: 0.0,
        isWeaponAiming: false,
        weaponAttackStartTime: null,
        lastAnimationFrame: DateTime.now().millisecondsSinceEpoch,
      );
      // 关键区域：移除自动回弹药逻辑，弹药不自动恢复
      return;
    }
    final now = DateTime.now();
    if (state.selectedAttackMode == AttackMode.melee) {
      state = state.copyWith(
        weaponJoystickX: x,
        weaponJoystickY: y,
        weaponJoystickIntensity: intensity,
        isWeaponAiming: false,
        weaponAttackStartTime: now,
        lastAnimationFrame: now.millisecondsSinceEpoch,
      );
      // 关键区域：同步近战挥刀动画时长
      Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        if (state.weaponAttackStartTime != null && state.weaponAttackStartTime == now) {
          state = state.copyWith(
            weaponAttackStartTime: null,
            lastAnimationFrame: DateTime.now().millisecondsSinceEpoch,
          );
        }
      });
    } else {
      if (state.isReloading) {
        return;
      }
      final int clip = state.weaponClipAmmo;
      final int mag = state.weaponMagazineSize;
      if (mag > 0 && clip <= 0) {
        return;
      }
      final double dirX = x;
      final double dirY = y;
      final double angle = math.atan2(dirY, (dirX == 0.0 && dirY == 0.0) ? 1e-6 : dirX);
      final List<Projectile> ps = List<Projectile>.from(state.projectiles);
      ps.add(Projectile(startTime: now, angle: angle));
      // 关键区域：射击后同步弹夹弹药到装备武器对象
      final Item? w = state.equipmentSlots['weapon'];
      final Map<String, Item?> slots = Map<String, Item?>.from(state.equipmentSlots);
      if (w != null) {
        slots['weapon'] = Item(
          id: w.id,
          name: w.name,
          image: w.image,
          description: w.description,
          effects: w.effects,
          type: w.type,
          count: w.count,
          availableInShop: w.availableInShop,
          basePrice: w.basePrice,
          usageTime: w.usageTime,
          level: w.level,
          equipmentSlot: w.equipmentSlot,
          weaponParams: w.weaponParams,
          clipAmmo: math.max(0, clip - 1),
          ammoReserve: state.weaponTotalAmmo,
        );
      }
      state = state.copyWith(
        weaponJoystickX: x,
        weaponJoystickY: y,
        weaponJoystickIntensity: intensity,
        isWeaponAiming: false,
        projectiles: ps,
        lastAnimationFrame: now.millisecondsSinceEpoch,
        weaponClipAmmo: mag > 0 ? (clip - 1) : clip,
        equipmentSlots: slots,
      );
    }
  }

  void fireWeapon() {
    final now = DateTime.now();
    if (state.selectedAttackMode == AttackMode.melee) {
      final double jx = state.weaponJoystickX ?? 0.0;
      final double jy = state.weaponJoystickY ?? 0.0;
      final double ax = (jx == 0.0 && jy == 0.0) ? state.lastWeaponAimX : jx;
      final double ay = (jx == 0.0 && jy == 0.0) ? state.lastWeaponAimY : jy;
      state = state.copyWith(
        weaponJoystickX: ax,
        weaponJoystickY: ay,
        weaponAttackStartTime: now,
        lastAnimationFrame: now.millisecondsSinceEpoch,
      );
      // 关键区域：同步近战挥刀动画时长
      Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        if (state.weaponAttackStartTime != null && state.weaponAttackStartTime == now) {
          state = state.copyWith(
            weaponAttackStartTime: null,
            lastAnimationFrame: DateTime.now().millisecondsSinceEpoch,
          );
        }
      });
      return;
    }
    if (state.isReloading) {
      return;
    }
    final int clip = state.weaponClipAmmo;
    final int mag = state.weaponMagazineSize;
    if (mag > 0 && clip <= 0) {
      return;
    }
    double dirX = state.weaponJoystickX ?? 0.0;
    double dirY = state.weaponJoystickY ?? 0.0;
    if (dirX == 0.0 && dirY == 0.0) {
      dirX = state.lastWeaponAimX;
      dirY = state.lastWeaponAimY;
    }
    if (dirX == 0.0 && dirY == 0.0) {
      dirX = state.playerPosition.facingRight ? 1.0 : -1.0;
      dirY = 0.0;
    }
    final double angle = math.atan2(dirY, (dirX == 0.0 && dirY == 0.0) ? 1e-6 : dirX);
    final List<Projectile> ps = List<Projectile>.from(state.projectiles);
    ps.add(Projectile(startTime: now, angle: angle));
    // 关键区域：射击后同步弹夹弹药到装备武器对象
    final Item? w = state.equipmentSlots['weapon'];
    final Map<String, Item?> slots = Map<String, Item?>.from(state.equipmentSlots);
    if (w != null) {
      slots['weapon'] = Item(
        id: w.id,
        name: w.name,
        image: w.image,
        description: w.description,
        effects: w.effects,
        type: w.type,
        count: w.count,
        availableInShop: w.availableInShop,
        basePrice: w.basePrice,
        usageTime: w.usageTime,
        level: w.level,
        equipmentSlot: w.equipmentSlot,
        weaponParams: w.weaponParams,
        clipAmmo: math.max(0, state.weaponClipAmmo - 1),
        ammoReserve: state.weaponTotalAmmo,
      );
    }
    state = state.copyWith(
      projectiles: ps,
      lastAnimationFrame: now.millisecondsSinceEpoch,
      weaponClipAmmo: mag > 0 ? (clip - 1) : clip,
      equipmentSlots: slots,
    );
  }

  void startReload() {
    if (state.selectedAttackMode != AttackMode.ranged) return;
    if (state.isReloading) return;
    final int mag = state.weaponMagazineSize;
    final int clip = state.weaponClipAmmo;
    final int reserve = state.weaponTotalAmmo;
    if (mag <= 0 || reserve <= 0 || clip >= mag) return;
    state = state.copyWith(
      isReloading: true,
      reloadStartTime: DateTime.now(),
      reloadProgress: 0.0,
      reloadStartClipAmmo: clip,
      reloadStartReserveAmmo: reserve,
      lastAnimationFrame: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // 关键区域：设置近战攻击模板（颜色、攻击距离、范围）
  void setMeleeAttackTemplate(ui.Color color, double distance, double range) {
    state = state.copyWith(
      meleeAttackTemplate: AttackTemplate(color: color, distance: distance, range: range),
    );
  }

  // 关键区域：设置远程攻击模板（颜色、攻击距离、范围）
  void setRangedAttackTemplate(ui.Color color, double distance, double range) {
    state = state.copyWith(
      rangedAttackTemplate: AttackTemplate(color: color, distance: distance, range: range),
    );
  }

  // 关键区域：选择攻击模式（近战/远程）
  void selectAttackMode(AttackMode mode) {
    state = state.copyWith(selectedAttackMode: mode);
  }

  // 关键区域：从物品读取武器模板与伤害参数并应用
  void _applyWeaponParamsFromItem(Item item) {
    final params = item.weaponParams ?? const {};
    final String typeStr = (params['attackType'] ?? params['近战/远程'] ?? 'melee').toString();
    final AttackMode mode = (typeStr == 'ranged' || typeStr == '远程') ? AttackMode.ranged : AttackMode.melee;
    final int colorInt = (params['effectColor'] ?? params['颜色效果'] ?? 0xFFFFA000) as int;
    final double distance = ((params['distance'] ?? params['距离'] ?? (mode == AttackMode.melee ? 1 : 4)) as num).toDouble();
    final double range = ((params['range'] ?? params['范围'] ?? (mode == AttackMode.melee ? 1.2 : 12.0)) as num).toDouble();
    final double amp = ((params['damageAmplify'] ?? params['增幅伤害'] ?? 1.0) as num).toDouble();
    final double critDmg = ((params['critDamage'] ?? params['暴击伤害'] ?? 1.5) as num).toDouble();
    final double critChance = ((params['critChanceBonus'] ?? params['暴击几率加成'] ?? 0.0) as num).toDouble();
    final int magazine = ((params['magazineSize'] ?? 0) as num).toInt();
    final int ammoTotal = ((params['ammoTotal'] ?? 0) as num).toInt();
    final int reloadMs = ((params['reloadMs'] ?? 1000) as num).toInt();

    if (mode == AttackMode.melee) {
      state = state.copyWith(
        selectedAttackMode: AttackMode.melee,
        meleeAttackTemplate: AttackTemplate(color: ui.Color(colorInt), distance: distance, range: range),
        weaponDamageAmplify: amp,
        weaponCritDamage: critDmg,
        weaponCritChanceBonus: critChance,
        weaponMagazineSize: 0,
        weaponClipAmmo: 0,
        weaponTotalAmmo: 0,
        reloadDurationMs: 1000,
        );
    } else {
      // 关键区域：为当前武器初始化/同步独立弹药
      final Item? equipped = state.equipmentSlots['weapon'];
      final int initClip = equipped?.clipAmmo ?? item.clipAmmo ?? (magazine > 0 ? magazine : 0);
      final int initReserve = equipped?.ammoReserve ?? item.ammoReserve ?? ammoTotal;
      final updatedSlots = Map<String, Item?>.from(state.equipmentSlots);
      updatedSlots['weapon'] = Item(
        id: item.id,
        name: item.name,
        image: item.image,
        description: item.description,
        effects: item.effects,
        type: item.type,
        count: item.count,
        availableInShop: item.availableInShop,
        basePrice: item.basePrice,
        usageTime: item.usageTime,
        level: item.level,
        equipmentSlot: item.equipmentSlot,
        weaponParams: item.weaponParams,
        clipAmmo: initClip,
        ammoReserve: initReserve,
      );
      state = state.copyWith(
        equipmentSlots: updatedSlots,
        selectedAttackMode: AttackMode.ranged,
        rangedAttackTemplate: AttackTemplate(color: ui.Color(colorInt), distance: distance, range: range),
        weaponDamageAmplify: amp,
        weaponCritDamage: critDmg,
        weaponCritChanceBonus: critChance,
        weaponMagazineSize: magazine,
        weaponClipAmmo: initClip,
        weaponTotalAmmo: initReserve,
        reloadDurationMs: reloadMs,
      );
    }
  }

  /// 切换背包显示
  void toggleInventory() {
    state = state.copyWith(showInventory: !state.showInventory);
  }

  /// 打开背包
  void openInventory() {
    state = state.copyWith(showInventory: true);
  }

  /// 关闭背包
  void closeInventory() {
    state = state.copyWith(showInventory: false);
  }

  /// 切换角色信息面板显示
  void toggleCharacterInfo() {
    state = state.copyWith(showCharacterInfo: !state.showCharacterInfo);
  }

  /// 切换商店显示
  void toggleShop() {
    state = state.copyWith(showShop: !state.showShop);
  }

  /// 切换炼金界面显示
  void toggleAlchemy() {
    // 关键区域：炼金界面开关，与商店逻辑保持一致
    state = state.copyWith(showAlchemy: !state.showAlchemy);
  }

  /// 检查玩家是否靠近宝箱
  bool isNearChest() {
    // 玩家像素坐标转换为网格坐标
    // 注意：玩家初始位置(10.0, 10.0)对应网格(0, 0)，所以需要先减去偏移量
    final playerGridX = ((state.playerPosition.x - 10.0) / 40).round();
    final playerGridY = ((state.playerPosition.y - 10.0) / 40).round();
    final playerPos = Point(playerGridX, playerGridY);
    
    print('isNearChest - 玩家位置: 像素(${state.playerPosition.x}, ${state.playerPosition.y}), 网格($playerGridX, $playerGridY)');
    print('isNearChest - 宝箱数量: ${state.chestPositions.length}');
    
    for (final chestPos in state.chestPositions) {
      final distance = _calculateDistance(playerPos, chestPos);
      print('isNearChest - 宝箱位置: (${chestPos.x}, ${chestPos.y}), 距离: $distance');
      if (distance <= 1.5) { // 允许1.5格的交互距离
        print('isNearChest - 玩家靠近宝箱，距离: $distance <= 1.5');
        return true;
      }
    }
    print('isNearChest - 玩家不靠近任何宝箱');
    return false;
  }

  /// 打开指定位置的宝箱（点击时使用）
  void openChestAtPosition(Point<int> chestPosition) {
    
    // 检查宝箱是否存在
    if (!state.chestPositions.contains(chestPosition)) {
      print('openChestAtPosition - 宝箱不存在于指定位置');
      return;
    }

    // 如果已经在探索宝箱，则取消当前探索
    if (state.isExploringChest) {
      cancelChestExploration();
    }
    
    // 开始宝箱探索进度，并打开搜索页面
    // 关键区域：初始化“待揭示队列”和“当前宝箱内容”，采用逐步揭示逻辑
    final initialItems = _getRandomChestItems();
    state = state.copyWith(
      isExploringChest: true,
      isChestSearchOpen: true,
      currentExploringChest: chestPosition,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: DateTime.now(),
      chestPendingItems: initialItems,
      chestVisibleItems: const [],
    );
    
    // 启动宝箱探索计时器
    _startChestExplorationTimer(chestPosition);
    
    // 显示开始探索的消息
    addBroadcastMessage('开始探索宝箱...', BroadcastMessageType.item);
    print('openChestAtPosition - 开始探索宝箱: (${chestPosition.x}, ${chestPosition.y})');
  }

  /// 打开指定位置的保险箱（点击时使用）
  void openSafeAtPosition(Point<int> safePosition) {
    if (!state.safePositions.contains(safePosition)) {
      return;
    }
    if (state.isExploringChest) {
      cancelChestExploration();
    }
    final initialItems = _getRandomSafeItemsAtPosition(safePosition);
    state = state.copyWith(
      isExploringChest: true,
      isChestSearchOpen: true,
      currentExploringChest: safePosition,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: DateTime.now(),
      chestPendingItems: initialItems,
      chestVisibleItems: const [],
    );
    _startChestExplorationTimer(safePosition);
    addBroadcastMessage('开始探索保险箱...', BroadcastMessageType.item);
  }

  /// 打开宝箱（原有的距离检查方法）
  void openChest() {
    print('openChest - 开始执行');
    if (!isNearChest()) {
      print('openChest - 玩家不靠近宝箱，退出');
      return;
    }
    
    final playerGridX = ((state.playerPosition.x - 10.0) / 40).round();
    final playerGridY = ((state.playerPosition.y - 10.0) / 40).round();
    final playerPos = Point(playerGridX, playerGridY);
    
    print('openChest - 玩家位置: ($playerGridX, $playerGridY)');
    
    // 找到最近的宝箱
    Point<int>? nearestChest;
    double minDistance = double.infinity;
    
    for (final chestPos in state.chestPositions) {
      final distance = _calculateDistance(playerPos, chestPos);
      print('openChest - 检查宝箱: (${chestPos.x}, ${chestPos.y}), 距离: $distance');
      if (distance <= 1.5 && distance < minDistance) {
        minDistance = distance;
        nearestChest = chestPos;
        print('openChest - 找到更近的宝箱: (${chestPos.x}, ${chestPos.y}), 距离: $distance');
      }
    }
    
    if (nearestChest != null) {
      print('openChest - 找到最近宝箱: (${nearestChest.x}, ${nearestChest.y}), 距离: $minDistance');
      
      // 使用进度条机制打开宝箱
      openChestAtPosition(nearestChest);
    } else {
      print('openChest - 未找到可打开的宝箱');
    }
  }

  /// 获取宝箱随机物品
  List<Item> _getRandomChestItems() {
    // 关键区域：固定宝箱100%掉落3个随机物品；同时在建筑内提升高品质概率
    final isFixedChest = state.currentExploringChest != null &&
        state.fixedChestPosition != null &&
        state.currentExploringChest == state.fixedChestPosition;
    final chestPos = state.currentExploringChest;
    // 关键区域：角色概率增幅（rarityBoost）接入宝箱物品生成
    final double rarityBoost = ((state.characterStats['rarityBoost'] ?? 0.0) as num).toDouble();
    if (isFixedChest) {
      // 固定宝箱：位置已知，按位置生成并保持掉落数量为3
      if (chestPos != null) {
        return ItemSpawner.generateChestItemsAtPosition(chestPos, minItems: 3, maxItems: 3, rarityBoost: rarityBoost);
      }
      return ItemSpawner.generateChestItems(minItems: 3, maxItems: 3, rarityBoost: rarityBoost);
    }
    // 普通宝箱：若有当前位置，使用位置增强概率（建筑内提升高品质概率）
    if (chestPos != null) {
      return ItemSpawner.generateChestItemsAtPosition(chestPos, minItems: 1, maxItems: 3, rarityBoost: rarityBoost);
    }
    return ItemSpawner.generateChestItems(minItems: 1, maxItems: 3, rarityBoost: rarityBoost);
  }

  /// 获取适合放置宝箱的位置（建筑内优先，其次草地与路径）
  // 关键区域：仅收集“建筑”格子作为可放置宝箱的位置
  // 说明：为满足“每50个建筑物格子上要有一个宝箱”，宝箱位置限定在建筑格（terrain == 'building'）。
  List<Point<int>> _getChestSuitablePositions() {
    final suitablePositions = <Point<int>>[];
    for (int y = 0; y < MapData.testMap.length; y++) {
      for (int x = 0; x < MapData.testMap[y].length; x++) {
        if (MapData.testMap[y][x] == 'building') {
          suitablePositions.add(Point(x, y));
        }
      }
    }
    return suitablePositions;
  }

  // 关键区域：统计建筑格数量
  // 说明：遍历 MapData.testMap，计算 terrain == 'building' 的格子总数。
  int _countBuildingTiles() {
    int count = 0;
    for (int y = 0; y < MapData.testMap.length; y++) {
      for (int x = 0; x < MapData.testMap[y].length; x++) {
        if (MapData.testMap[y][x] == 'building') {
          count++;
        }
      }
    }
    return count;
  }

  // 关键区域：计算目标宝箱数量（每50个建筑格一个宝箱）
  // 说明：向下取整，满足“每50个建筑物格子上要有一个宝箱”的数量约束。
  int _computeTargetChestCount() {
    final buildingTiles = _countBuildingTiles();
    return buildingTiles ~/ 50;
  }

  // 关键区域：计算目标保险箱数量（比宝箱更少更稀有）
  // 说明：按宝箱目标数量的40%生成保险箱数量；当宝箱目标为0时保险箱也为0；
  // 当宝箱目标为1时，至少生成1个保险箱以保证存在感。
  int _computeTargetSafeCount() {
    final int chestTarget = _computeTargetChestCount();
    if (chestTarget <= 0) return 0;
    if (chestTarget == 1) return 1;
    return (chestTarget * 2) ~/ 5; // 40%
  }

  /// 获取固定的测试宝箱位置（三个相邻的宝箱）


  /// 随机生成宝箱位置
  List<Point<int>> _generateRandomChestPositions({int chestCount = 5}) {
    
    final random = math.Random();
    final suitablePositions = _getChestSuitablePositions();
    final chestPositions = <Point<int>>[];
    
    if (suitablePositions.isEmpty) {
      print('警告：没有找到适合放置宝箱的位置');
      return chestPositions;
    }
    
    // 确保不会生成超过可用位置数量的宝箱
    final maxChests = math.min(chestCount, suitablePositions.length);
    
    // 随机选择不重复的位置
    final selectedPositions = <Point<int>>[];
    while (selectedPositions.length < maxChests) {
      final randomIndex = random.nextInt(suitablePositions.length);
      final position = suitablePositions[randomIndex];
      
      // 确保位置不重复
      if (!selectedPositions.contains(position)) {
        selectedPositions.add(position);
      }
    }
    
    return selectedPositions;
  }

  /// 获取保险箱随机物品（仅 Lv3/4/5/6）
  List<Item> _getRandomSafeItemsAtPosition(Point<int> position, {int minItems = 1, int maxItems = 3}) {
    final int count = minItems + math.Random().nextInt(maxItems - minItems + 1);
    final List<Item> candidates = allItems
        .where((it) => it.type == 'item' && it.level >= 3 && it.level <= 6 && it.id != 'gold')
        .toList();

    if (candidates.isEmpty) {
      return const [];
    }

    // 建筑内倍率（复用宝箱权重倾斜）
    final terrain = MapData.testMap[position.y][position.x];
    final bool inBuilding = terrain == 'building';
    final Map<int, double> base = {
      3: 20.0,
      4: 10.0,
      5: 8.0,
      6: 2.0,
    };
    final Map<int, double> mult = {
      3: 1.5,
      4: 1.8,
      5: 2.2,
      6: 2.5,
    };
    final double rarityBoost = ((state.characterStats['rarityBoost'] ?? 0.0) as num).toDouble();

    List<Item> result = [];
    for (int i = 0; i < count; i++) {
      double totalWeight = 0.0;
      final Map<Item, double> weights = {};
      for (final it in candidates) {
        final double b = base[it.level] ?? 1.0;
        final double m = inBuilding ? (mult[it.level] ?? 1.0) : 1.0;
        final double w = _applyRarityBoostForSafe(b * m, it.level, rarityBoost);
        weights[it] = w;
        totalWeight += w;
      }
      if (totalWeight <= 0.0) break;
      final double roll = math.Random().nextDouble() * totalWeight;
      double acc = 0.0;
      Item? picked;
      for (final entry in weights.entries) {
        acc += entry.value;
        if (roll <= acc) {
          picked = entry.key;
          break;
        }
      }
      if (picked != null) {
        result.add(picked);
      }
    }

    return result;
  }

  double _applyRarityBoostForSafe(double baseWeight, int level, double rarityBoost) {
    final double boost = rarityBoost <= 0 ? 0.0 : rarityBoost;
    if (level >= 4) {
      return baseWeight * (1.0 + boost);
    }
    return baseWeight;
  }

  /// 初始化保险箱位置（数量规则与宝箱保持一致）
  void _initializeSafes() {
    final targetCount = _computeTargetSafeCount();
    final random = math.Random();
    final suitablePositions = _getChestSuitablePositions();
    final selected = <Point<int>>[];
    while (selected.length < math.min(targetCount, suitablePositions.length)) {
      final pos = suitablePositions[random.nextInt(suitablePositions.length)];
      if (!selected.contains(pos)) {
        selected.add(pos);
      }
    }
    state = state.copyWith(safePositions: selected);
  }

  /// 智能补充保险箱：只在数量不足时添加
  void _replenishSafesIfNeeded() {
    final currentCount = state.safePositions.length;
    final targetCount = _computeTargetSafeCount();
    if (currentCount >= targetCount) return;
    final needToAdd = targetCount - currentCount;
    final existing = Set<Point<int>>.from(state.safePositions);
    final suitablePositions = _getChestSuitablePositions();
    final available = suitablePositions.where((p) => !existing.contains(p)).toList();
    if (available.isEmpty) return;
    final random = math.Random();
    final newPositions = <Point<int>>[];
    final maxAdd = math.min(needToAdd, available.length);
    for (int i = 0; i < maxAdd; i++) {
      final idx = random.nextInt(available.length);
      newPositions.add(available.removeAt(idx));
    }
    final updated = List<Point<int>>.from(state.safePositions)..addAll(newPositions);
    state = state.copyWith(safePositions: updated);
  }

  /// 初始化宝箱位置
  void _initializeChests() {
    // 关键区域：初始化时按建筑格动态确定目标宝箱数量
    final targetCount = _computeTargetChestCount();
    final initialChestPositions = _generateRandomChestPositions(chestCount: targetCount);
    state = state.copyWith(chestPositions: initialChestPositions);
    print('初始化宝箱位置，数量：${initialChestPositions.length}（目标：$targetCount，建筑格：${_countBuildingTiles()}）');
    _spawnPrincipalOfficeChest();
  }

  /// 刷新宝箱位置（在宝箱被打开后调用）
  void _refreshChestPositions() {
    // 关键区域：刷新时按建筑格动态确定目标宝箱数量
    final targetCount = _computeTargetChestCount();
    final newChestPositions = _generateRandomChestPositions(chestCount: targetCount);
    state = state.copyWith(chestPositions: newChestPositions);
    print('宝箱位置已刷新，新位置: ${newChestPositions.map((p) => '(${p.x}, ${p.y})').join(', ')}（目标：$targetCount）');
    _spawnPrincipalOfficeChest();
  }

  void _spawnPrincipalOfficeChest() {
    final zoneList = kZones.where((z) => z.name == '校长办公室').toList();
    if (zoneList.isEmpty) return;
    final z = zoneList.first;
    Point<int>? pos;
    for (int y = z.minY; y <= z.maxY && pos == null; y++) {
      for (int x = z.minX; x <= z.maxX; x++) {
        if (MapData.testMap[y][x] == 'building') {
          pos = Point<int>(x, y);
          break;
        }
      }
    }
    if (pos == null) return;
    final updated = List<Point<int>>.from(state.chestPositions);
    if (!updated.contains(pos)) {
      updated.add(pos);
      state = state.copyWith(chestPositions: updated);
    }
  }

  /// 智能补充宝箱：只在宝箱数量不足时添加新宝箱
  void _replenishChestsIfNeeded() {
    final currentChestCount = state.chestPositions.length;
    // 关键区域：按建筑格动态确定目标宝箱数量
    final targetChestCount = _computeTargetChestCount();
    
    // 如果当前宝箱数量已经足够，不需要补充
    if (currentChestCount >= targetChestCount) {
      print('宝箱数量充足 ($currentChestCount/$targetChestCount)，无需补充');
      return;
    }
    
    // 计算需要补充的宝箱数量
    final needToAdd = targetChestCount - currentChestCount;
    print('当前宝箱数量: $currentChestCount，目标数量: $targetChestCount，需要补充: $needToAdd（建筑格：${_countBuildingTiles()}）');
    
    // 获取当前已存在的宝箱位置
    final existingPositions = Set<Point<int>>.from(state.chestPositions);
    
    // 生成新的宝箱位置，避免与现有位置重复
    final suitablePositions = _getChestSuitablePositions();
    final availablePositions = suitablePositions.where((pos) => !existingPositions.contains(pos)).toList();
    
    if (availablePositions.isEmpty) {
      print('警告：没有可用的位置来补充宝箱');
      return;
    }
    
    // 随机选择新的宝箱位置
    final random = math.Random();
    final newPositions = <Point<int>>[];
    final maxNewChests = math.min(needToAdd, availablePositions.length);
    
    for (int i = 0; i < maxNewChests; i++) {
      final randomIndex = random.nextInt(availablePositions.length);
      final newPosition = availablePositions.removeAt(randomIndex);
      newPositions.add(newPosition);
    }
    
    // 更新宝箱位置列表
    final updatedChestPositions = List<Point<int>>.from(state.chestPositions);
    updatedChestPositions.addAll(newPositions);
    
    state = state.copyWith(chestPositions: updatedChestPositions);
    
    print('补充了 ${newPositions.length} 个宝箱，新位置: ${newPositions.map((p) => '(${p.x}, ${p.y})').join(', ')}');
    print('当前所有宝箱位置: ${updatedChestPositions.map((p) => '(${p.x}, ${p.y})').join(', ')}');
  }

  /// 购买商品
  bool buyItem(ShopItem shopItem) {
    final character = state.characterStats;
    final currentMoney = character['gold'] ?? 0;
    
    // 检查是否有足够的金币和库存
    if (currentMoney < shopItem.currentPrice || shopItem.stock <= 0) {
      return false; // 金币不足或库存不足
    }
    
    // 检查背包容量
    if (state.playerInventory.length >= state.inventoryCapacity) {
      // 背包已满，将物品掉落到玩家位置
      _dropItemToGround(shopItem.item, state.playerPosition.toPoint());
      
      // 扣除金币（即使物品掉落也要扣钱）
      final updatedCharacter = Map<String, dynamic>.from(character);
      updatedCharacter['gold'] = currentMoney - shopItem.currentPrice;
      
      // 减少商品库存
      shopItem.stock--;
      
      // 更新状态
      state = state.copyWith(
        characterStats: updatedCharacter,
      );
      
      // 添加背包已满的播报消息
      addBroadcastMessage(
        '背包已满，${shopItem.item.name} 掉落在地上',
        BroadcastMessageType.item,
      );
      
      return true; // 购买成功但物品掉落
    }
    
    // 扣除金币
    final updatedCharacter = Map<String, dynamic>.from(character);
    updatedCharacter['gold'] = currentMoney - shopItem.currentPrice;

    // 减少商品库存
    shopItem.stock--;

    // 尝试堆叠插入到背包（末尾位置），失败则改为掉落在地面
    final success = insertItemAtPosition(shopItem.item, state.playerInventory.length);
    if (!success) {
      _dropItemToGround(shopItem.item, state.playerPosition.toPoint());
      state = state.copyWith(characterStats: updatedCharacter);
      addBroadcastMessage('背包空间不足，购买物品已掉落：${shopItem.item.name}', BroadcastMessageType.item);
      return true; // 购买成功但物品掉落
    }

    // 更新金币（背包已由插入方法更新）
    state = state.copyWith(characterStats: updatedCharacter);

    // 添加购买成功的播报消息
    addBroadcastMessage('购买了 ${shopItem.item.name}', BroadcastMessageType.item);
    return true; // 购买成功
  }

  /// 将物品掉落到地面
  void _dropItemToGround(Item item, Point<int> position) {
    final currentGroundItems = Map<Point<int>, List<Item>>.from(state.groundItems);
    
    // 如果该位置已有物品，添加到列表中；否则创建新列表
    if (currentGroundItems.containsKey(position)) {
      currentGroundItems[position]!.add(item);
    } else {
      currentGroundItems[position] = [item];
    }
    
    // 更新状态
    state = state.copyWith(groundItems: currentGroundItems);
  }

  /// 从地面拾取物品
  bool pickupItemFromGround(Point<int> position, Item item) {
    // 使用堆叠插入逻辑，不再仅以格数判断
    final currentGroundItems = Map<Point<int>, List<Item>>.from(state.groundItems);
    
    // 检查该位置是否有物品
    if (!currentGroundItems.containsKey(position)) {
      return false;
    }
    
    final itemsAtPosition = currentGroundItems[position]!;
    final itemIndex = itemsAtPosition.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) {
      return false; // 物品不在该位置
    }
    
    // 从地面移除物品
    itemsAtPosition.removeAt(itemIndex);
    
    // 如果该位置没有物品了，移除该位置
    if (itemsAtPosition.isEmpty) {
      currentGroundItems.remove(position);
    }
    
    // 添加物品到背包（堆叠：仅对“物品”生效）
    final newInventory = List<Item>.from(state.playerInventory);
    const int stackLimit = 16;
    int remaining = item.count;

    if (item.type == 'item') {
      // 合并到已有堆叠
      for (int i = 0; i < newInventory.length && remaining > 0; i++) {
        final invItem = newInventory[i];
        if (invItem.id == item.id && invItem.type == 'item') {
          final int free = stackLimit - invItem.count;
          if (free > 0) {
            final int addCount = remaining < free ? remaining : free;
        newInventory[i] = Item(
          id: invItem.id,
          name: invItem.name,
          image: invItem.image,
          description: invItem.description,
          effects: invItem.effects,
          type: invItem.type,
          count: invItem.count + addCount,
          availableInShop: invItem.availableInShop,
          basePrice: invItem.basePrice,
          usageTime: invItem.usageTime,
          level: invItem.level,
          equipmentSlot: invItem.equipmentSlot,
          weaponParams: invItem.weaponParams,

        );
            remaining -= addCount;
          }
        }
      }

      // 需要新增堆叠时检查容量
      while (remaining > 0) {
        final int neededStacks = (remaining + stackLimit - 1) ~/ stackLimit;
        final int availableSlots = state.inventoryCapacity - newInventory.length;
        if (availableSlots < neededStacks) {
          // 回滚地面物品列表（把拿走的放回）
          final backItems = currentGroundItems[position] ?? <Item>[];
          backItems.add(item);
          currentGroundItems[position] = backItems;
          addBroadcastMessage('背包空间不足，无法拾取', BroadcastMessageType.item);
          return false;
        }
        final int toAdd = remaining > stackLimit ? stackLimit : remaining;
        newInventory.add(Item(
          id: item.id,
          name: item.name,
          image: item.image,
          description: item.description,
          effects: item.effects,
          type: item.type,
          count: toAdd,
          availableInShop: item.availableInShop,
          basePrice: item.basePrice,
          usageTime: item.usageTime,
          level: item.level,
          equipmentSlot: item.equipmentSlot,
          weaponParams: item.weaponParams,

        ));
        remaining -= toAdd;
      }
    } else {
      // 非堆叠类型按单件处理，需要至少1个槽位
      if (newInventory.length >= state.inventoryCapacity) {
        final backItems = currentGroundItems[position] ?? <Item>[];
        backItems.add(item);
        currentGroundItems[position] = backItems;
        addBroadcastMessage('背包已满，无法拾取', BroadcastMessageType.item);
        return false;
      }
      newInventory.add(item);
    }
    
    // 更新状态
    state = state.copyWith(
      playerInventory: newInventory,
      groundItems: currentGroundItems,
    );
    
    // 添加拾取成功的播报消息
    addBroadcastMessage('拾取了 ${item.name}${item.count > 1 ? ' x ${item.count}' : ''}', BroadcastMessageType.item);
    
    return true;
  }

  /// 移动背包中的物品到指定位置
  bool moveItemInInventory(int fromIndex, int toIndex) {
    // 检查索引是否有效
    if (fromIndex < 0 || toIndex < 0 || toIndex >= state.inventoryCapacity) {
      return false;
    }
    
    // 检查源位置是否有效（必须在当前物品范围内）
    if (fromIndex >= state.playerInventory.length) {
      return false;
    }
    
    // 如果源位置和目标位置相同，不需要移动
    if (fromIndex == toIndex) {
      return true;
    }
    
    // 创建一个固定大小的稀疏数组来表示背包格子
    final inventoryGrid = <Item?>[...List.filled(state.inventoryCapacity, null)];
    
    // 将现有物品按顺序放入网格的前面位置
    for (int i = 0; i < state.playerInventory.length; i++) {
      inventoryGrid[i] = state.playerInventory[i];
    }
    
    // 获取要移动的物品
    final itemToMove = inventoryGrid[fromIndex];
    if (itemToMove == null) {
      return false;
    }
    
    // 执行移动操作
    if (toIndex < state.playerInventory.length && inventoryGrid[toIndex] != null) {
      // 目标位置有物品，交换位置
      final targetItem = inventoryGrid[toIndex];
      inventoryGrid[fromIndex] = targetItem;
      inventoryGrid[toIndex] = itemToMove;
    } else {
      // 目标位置是空格子，直接移动
      inventoryGrid[fromIndex] = null;
      inventoryGrid[toIndex] = itemToMove;
    }
    
    // 重新整理背包，移除空位并保持物品顺序
    final newInventory = <Item>[];
    for (int i = 0; i < inventoryGrid.length; i++) {
      if (inventoryGrid[i] != null) {
        newInventory.add(inventoryGrid[i]!);
      }
    }
    
    // 更新背包状态
    state = state.copyWith(playerInventory: newInventory);
    
    return true;
  }
  
  /// 将物品添加到背包的指定位置（用于拖拽到空格子）
  bool insertItemAtPosition(Item item, int targetIndex) {
    final inventory = List<Item>.from(state.playerInventory);

    // 目标位置边界检查
    if (targetIndex < 0 || targetIndex >= state.inventoryCapacity) {
      return false;
    }

    // 堆叠逻辑：仅对 type == 'item' 生效
    const int stackLimit = 16;
    int remaining = item.count;

    if (item.type == 'item') {
      // 先尝试合并到已有同类堆叠
      for (int i = 0; i < inventory.length && remaining > 0; i++) {
        final invItem = inventory[i];
        if (invItem.id == item.id && invItem.type == 'item') {
          final int free = stackLimit - invItem.count;
          if (free > 0) {
            final int addCount = remaining < free ? remaining : free;
        inventory[i] = Item(
          id: invItem.id,
          name: invItem.name,
          image: invItem.image,
          description: invItem.description,
          effects: invItem.effects,
          type: invItem.type,
          count: invItem.count + addCount,
          availableInShop: invItem.availableInShop,
          basePrice: invItem.basePrice,
          usageTime: invItem.usageTime,
          level: invItem.level,
          equipmentSlot: invItem.equipmentSlot,
          weaponParams: invItem.weaponParams,

        );
            remaining -= addCount;
          }
        }
      }

      // 若仍有剩余，计算新增堆叠所需槽位
      while (remaining > 0) {
        final int neededStacks = (remaining + stackLimit - 1) ~/ stackLimit;
        final int availableSlots = state.inventoryCapacity - inventory.length;
        if (availableSlots < neededStacks) {
          return false; // 容量不足，拒绝插入
        }

        final int toAdd = remaining > stackLimit ? stackLimit : remaining;
        final Item stackItem = Item(
          id: item.id,
          name: item.name,
          image: item.image,
          description: item.description,
          effects: item.effects,
          type: item.type,
          count: toAdd,
          availableInShop: item.availableInShop,
          basePrice: item.basePrice,
          usageTime: item.usageTime,
          level: item.level,
          equipmentSlot: item.equipmentSlot,
          weaponParams: item.weaponParams,

        );

        if (targetIndex >= inventory.length) {
          inventory.add(stackItem);
        } else {
          inventory.insert(targetIndex, stackItem);
          targetIndex++; // 多个堆叠依次插入
        }
        remaining -= toAdd;
      }
    } else {
      // 非堆叠类型需要至少1个槽位
      if (inventory.length >= state.inventoryCapacity) {
        return false;
      }
      if (targetIndex >= inventory.length) {
        inventory.add(item);
      } else {
        inventory.insert(targetIndex, item);
      }
    }

    // 更新背包状态
    state = state.copyWith(playerInventory: inventory);
    return true;
  }

  /// 炼金合成（按背包索引选择两个物品）
  /// 关键区域：仅支持同类“物品”堆叠的升级式合成，产物插入或掉落复用现有逻辑
  bool performAlchemyByIndices(int indexA, int indexB) {
    final inventory = List<Item>.from(state.playerInventory);
    // 索引有效性检查
    if (indexA < 0 || indexB < 0 || indexA >= inventory.length || indexB >= inventory.length) {
      addBroadcastMessage('请选择两个有效物品', BroadcastMessageType.system);
      return false;
    }

    final itemA = inventory[indexA];
    final itemB = inventory[indexB];

    // 关键区域：Level6 不参与炼金（双保险校验）
    if (itemA.level == 6 || itemB.level == 6) {
      addBroadcastMessage('Level6 物品不参与炼金', BroadcastMessageType.system);
      return false;
    }

    // 类型与同类检查
    if (itemA.type != 'item' || itemB.type != 'item') {
      addBroadcastMessage('只能合成“物品”类型', BroadcastMessageType.system);
      return false;
    }
    if (itemA.id != itemB.id) {
      addBroadcastMessage('仅支持相同物品的炼金', BroadcastMessageType.system);
      return false;
    }

    // 同一堆叠至少需要2个
    if (indexA == indexB && itemA.count < 2) {
      addBroadcastMessage('同一堆叠至少需要2个', BroadcastMessageType.system);
      return false;
    }

    // 产物等级：取两者较高等级+1，最大不超过7
    final int newLevel = (math.max(itemA.level, itemB.level) + 1).clamp(1, 7);
    final Item product = Item(
      id: itemA.id,
      name: itemA.name,
      image: itemA.image,
      description: itemA.description,
      effects: itemA.effects,
      type: itemA.type,
      count: 1,
      availableInShop: false,
      basePrice: itemA.basePrice,
      usageTime: itemA.usageTime,
      level: newLevel,
      equipmentSlot: itemA.equipmentSlot,
      weaponParams: itemA.weaponParams,

    );

    // 消耗材料
    if (indexA == indexB) {
      final int newCount = itemA.count - 2;
      if (newCount > 0) {
        inventory[indexA] = Item(
          id: itemA.id,
          name: itemA.name,
          image: itemA.image,
          description: itemA.description,
          effects: itemA.effects,
          type: itemA.type,
          count: newCount,
          availableInShop: itemA.availableInShop,
          basePrice: itemA.basePrice,
          usageTime: itemA.usageTime,
          level: itemA.level,
          equipmentSlot: itemA.equipmentSlot,
          weaponParams: itemA.weaponParams,

        );
      } else {
        inventory.removeAt(indexA);
      }
    } else {
      // 分别减少两个堆叠各1个
      int removeShift = 0;
      // 先处理较小索引，避免位移问题
      final int first = indexA < indexB ? indexA : indexB;
      final int second = indexA < indexB ? indexB : indexA;
      final Item firstItem = inventory[first];
      final int firstNewCount = firstItem.count - 1;
      if (firstNewCount > 0) {
        inventory[first] = Item(
          id: firstItem.id,
          name: firstItem.name,
          image: firstItem.image,
          description: firstItem.description,
          effects: firstItem.effects,
          type: firstItem.type,
          count: firstNewCount,
          availableInShop: firstItem.availableInShop,
          basePrice: firstItem.basePrice,
          usageTime: firstItem.usageTime,
          level: firstItem.level,
          equipmentSlot: firstItem.equipmentSlot,
          weaponParams: firstItem.weaponParams,

        );
      } else {
        inventory.removeAt(first);
        removeShift = 1;
      }
      // 再处理第二个（考虑可能的位移）
      final int adjustedSecond = second - removeShift;
      final Item secondItem = inventory[adjustedSecond];
      final int secondNewCount = secondItem.count - 1;
      if (secondNewCount > 0) {
        inventory[adjustedSecond] = Item(
          id: secondItem.id,
          name: secondItem.name,
          image: secondItem.image,
          description: secondItem.description,
          effects: secondItem.effects,
          type: secondItem.type,
          count: secondNewCount,
          availableInShop: secondItem.availableInShop,
          basePrice: secondItem.basePrice,
          usageTime: secondItem.usageTime,
          level: secondItem.level,
          equipmentSlot: secondItem.equipmentSlot,
          weaponParams: secondItem.weaponParams,

        );
      } else {
        inventory.removeAt(adjustedSecond);
      }
    }

    // 先更新背包以反映消耗
    state = state.copyWith(playerInventory: inventory);

    // 插入产物；若容量不足则掉落地面
    final bool inserted = insertItemAtPosition(product, state.playerInventory.length);
    if (!inserted) {
      _dropItemToGround(product, state.playerPosition.toPoint());
      addBroadcastMessage('背包已满，产物掉落在地面', BroadcastMessageType.item);
    } else {
      addBroadcastMessage('炼金成功，获得 ${product.name} Lv${product.level}', BroadcastMessageType.item);
    }

    return true;
  }

  /// 启动炼金抽奖特效（按背包索引选择十个物品）
  /// 关键区域：立即消耗材料，关闭炼金页面，计算候选与最终结果，开启特效覆盖层
  bool startAlchemyEffectByIndicesList(List<int> indices) {
    final inventory = List<Item>.from(state.playerInventory);

    // 数量校验
    if (indices.length != 10) {
      addBroadcastMessage('需要选择10件物品进行炼金', BroadcastMessageType.system);
      return false;
    }

    // 索引有效性校验，并构建移除映射
    final Map<int, int> removalMap = <int, int>{};
    final List<Item> selectedItems = <Item>[];
    for (final idx in indices) {
      if (idx < 0 || idx >= inventory.length) {
        addBroadcastMessage('包含无效背包索引', BroadcastMessageType.system);
        return false;
      }
      final item = inventory[idx];
      removalMap[idx] = (removalMap[idx] ?? 0) + 1;
      selectedItems.add(item);
    }

    // 金币保护
    if (selectedItems.any((it) => it.id == 'gold' || it.name == '金币')) {
      addBroadcastMessage('金币为特殊道具，不能参与炼金', BroadcastMessageType.system);
      return false;
    }

    // 关键区域：Level6 不参与炼金（双保险校验）
    if (selectedItems.any((it) => it.level == 6)) {
      addBroadcastMessage('Level6 物品不参与炼金', BroadcastMessageType.system);
      return false;
    }

    // 计数校验
    for (final entry in removalMap.entries) {
      final item = inventory[entry.key];
      if (item.count < entry.value) {
        addBroadcastMessage('材料数量不足', BroadcastMessageType.system);
        return false;
      }
    }

    // 概率分布：根据所选物品 level 计算 (level+1) 的权重
    final Map<int, int> levelWeights = <int, int>{};
    for (final it in selectedItems) {
      final int outLevel = (it.level + 1).clamp(1, 7);
      levelWeights[outLevel] = (levelWeights[outLevel] ?? 0) + 1;
    }

    // 加权随机选择结果等级
    const int total = 10;
    int roll = math.Random().nextInt(total); // 0..9
    int acc = 0;
    int resultLevel = 1;
    final List<int> sortedLevels = levelWeights.keys.toList()..sort();
    for (final lvl in sortedLevels) {
      acc += levelWeights[lvl] ?? 0;
      if (roll < acc) {
        resultLevel = lvl;
        break;
      }
    }

    // 候选与模板产物（按结果等级从现有物品中选择）
    final List<Item> candidates = allItems
        .where((it) => it.type == 'item' && it.level == resultLevel && it.id != 'gold')
        .toList();

    if (candidates.isEmpty) {
      addBroadcastMessage('没有该等级的现有物品，炼金失败', BroadcastMessageType.system);
      return false;
    }

    final Item template = candidates[math.Random().nextInt(candidates.length)];
    final Item product = Item(
      id: template.id,
      name: template.name,
      image: template.image,
      description: template.description,
      effects: template.effects,
      type: template.type,
      count: 1,
      availableInShop: template.availableInShop,
      basePrice: template.basePrice,
      usageTime: template.usageTime,
      level: template.level,
      equipmentSlot: template.equipmentSlot,
      weaponParams: template.weaponParams,

    );

    // 消耗材料：按堆叠索引批量扣减
    final List<int> uniqueIndicesDesc = removalMap.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in uniqueIndicesDesc) {
      final Item cur = inventory[idx];
      final int toRemove = removalMap[idx] ?? 0;
      final int newCount = cur.count - toRemove;
      if (newCount > 0) {
        inventory[idx] = Item(
          id: cur.id,
          name: cur.name,
          image: cur.image,
          description: cur.description,
          effects: cur.effects,
          type: cur.type,
          count: newCount,
          availableInShop: cur.availableInShop,
          basePrice: cur.basePrice,
          usageTime: cur.usageTime,
          level: cur.level,
          equipmentSlot: cur.equipmentSlot,
          weaponParams: cur.weaponParams,

        );
      } else {
        inventory.removeAt(idx);
      }
    }

    // 关键区域：更新状态——关闭炼金页面，开启特效并携带候选与结果
    state = state.copyWith(
      playerInventory: inventory,
      showAlchemy: false,
      showAlchemyEffect: true,
      alchemyCandidates: candidates,
      alchemyResultItem: product,
      // 关键区域：保存等级概率权重供动画轨道按权重混合各等级
      alchemyLevelWeights: levelWeights,
    );

    addBroadcastMessage('开始炼金…', BroadcastMessageType.item, duration: const Duration(milliseconds: 800));
    return true;
  }

  /// 完成炼金抽奖特效：将结果物品放入背包并关闭特效
  /// 关键区域：插入失败则掉落在脚边，同时清理特效状态
  bool finalizeAlchemyEffect() {
    final Item? product = state.alchemyResultItem;
    if (product == null) {
      return false;
    }

    // 插入产物；若容量不足则掉落地面
    final bool inserted = insertItemAtPosition(product, state.playerInventory.length);
    if (!inserted) {
      _dropItemToGround(product, state.playerPosition.toPoint());
      addBroadcastMessage('背包已满，产物掉落在地面', BroadcastMessageType.item);
    } else {
      addBroadcastMessage('炼金成功，获得 ${product.name} Lv${product.level}', BroadcastMessageType.item);
    }

    // 关闭特效并清理数据
    state = state.copyWith(
      showAlchemyEffect: false,
      alchemyCandidates: const [],
      alchemyResultItem: null,
      // 关键区域：清理动画概率权重
      alchemyLevelWeights: const {},
    );

    return true;
  }

  /// 炼金合成（按背包索引选择十个物品）
  /// 关键区域：十个才能开始炼金；按所选物品的 level 贡献概率，生成结果等级为 (level+1) 的加权随机；最大不超过7
  /// 关键区域：产物的物品类型从所选材料中随机挑选一个作为基底（id、名称、图片等沿用），仅覆盖 level 与 count=1
  bool performAlchemyByIndicesList(List<int> indices) {
    final inventory = List<Item>.from(state.playerInventory);

    // 数量校验
    if (indices.length != 10) {
      addBroadcastMessage('需要选择10件物品进行炼金', BroadcastMessageType.system);
      return false;
    }

    // 索引有效性校验，并构建移除映射（允许“物品”与“装备”作为材料）
    final Map<int, int> removalMap = <int, int>{};
    final List<Item> selectedItems = <Item>[];
    for (final idx in indices) {
      if (idx < 0 || idx >= inventory.length) {
        addBroadcastMessage('包含无效背包索引', BroadcastMessageType.system);
        return false;
      }
      final item = inventory[idx];
      removalMap[idx] = (removalMap[idx] ?? 0) + 1;
      selectedItems.add(item);
    }

    // 金币保护：若误选金币则直接拒绝（UI已过滤，这里双保险）
    if (selectedItems.any((it) => it.id == 'gold' || it.name == '金币')) {
      addBroadcastMessage('金币为特殊道具，不能参与炼金', BroadcastMessageType.system);
      return false;
    }

    // 计数校验：每个堆叠需要足够数量
    for (final entry in removalMap.entries) {
      final item = inventory[entry.key];
      if (item.count < entry.value) {
        addBroadcastMessage('材料数量不足', BroadcastMessageType.system);
        return false;
      }
    }

    // 概率分布：根据所选物品 level 计算 (level+1) 的权重
    final Map<int, int> levelWeights = <int, int>{};
    for (final it in selectedItems) {
      final int outLevel = (it.level + 1).clamp(1, 7);
      levelWeights[outLevel] = (levelWeights[outLevel] ?? 0) + 1;
    }

    // 加权随机选择结果等级
    final int total = indices.length; // 固定为10
    int roll = math.Random().nextInt(total); // 0..9
    int acc = 0;
    int resultLevel = 1;
    final List<int> sortedLevels = levelWeights.keys.toList()..sort();
    for (final lvl in sortedLevels) {
      acc += levelWeights[lvl] ?? 0;
      if (roll < acc) {
        resultLevel = lvl;
        break;
      }
    }

    // 关键区域：产物为 props.dart 中“现有物品”，按结果等级选择，不生成新物品
    // 说明：仅选择类型为“物品”的模板，且排除金币（id=='gold'）
    final List<Item> candidates = allItems
        .where((it) => it.type == 'item' && it.level == resultLevel && it.id != 'gold')
        .toList();

    if (candidates.isEmpty) {
      addBroadcastMessage('没有该等级的现有物品，炼金失败', BroadcastMessageType.system);
      return false;
    }

    final Item template = candidates[math.Random().nextInt(candidates.length)];
    final Item product = Item(
      id: template.id,
      name: template.name,
      image: template.image,
      description: template.description,
      effects: template.effects,
      type: template.type, // 固定为“物品”
      count: 1,
      availableInShop: template.availableInShop,
      basePrice: template.basePrice,
      usageTime: template.usageTime,
      level: template.level,
      equipmentSlot: template.equipmentSlot,
      weaponParams: template.weaponParams,

    );

    // 消耗材料：按堆叠索引批量扣减
    final List<int> uniqueIndicesDesc = removalMap.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in uniqueIndicesDesc) {
      final Item cur = inventory[idx];
      final int toRemove = removalMap[idx] ?? 0;
      final int newCount = cur.count - toRemove;
      if (newCount > 0) {
        inventory[idx] = Item(
          id: cur.id,
          name: cur.name,
          image: cur.image,
          description: cur.description,
          effects: cur.effects,
          type: cur.type,
          count: newCount,
          availableInShop: cur.availableInShop,
          basePrice: cur.basePrice,
          usageTime: cur.usageTime,
          level: cur.level,
          equipmentSlot: cur.equipmentSlot,
          weaponParams: cur.weaponParams,

        );
      } else {
        inventory.removeAt(idx);
      }
    }

    // 更新背包以反映消耗
    state = state.copyWith(playerInventory: inventory);

    // 插入产物；若容量不足则掉落地面
    final bool inserted = insertItemAtPosition(product, state.playerInventory.length);
    if (!inserted) {
      _dropItemToGround(product, state.playerPosition.toPoint());
      addBroadcastMessage('背包已满，产物掉落在地面', BroadcastMessageType.item);
    } else {
      addBroadcastMessage('炼金成功，获得 ${product.name} Lv${product.level}', BroadcastMessageType.item);
    }

    return true;
  }

  /// 丢弃背包中的物品到地面
  bool dropItemFromInventory(Item item) {
    // 检查物品是否在背包中
    final inventory = List<Item>.from(state.playerInventory);
    final itemIndex = inventory.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) {
      return false; // 物品不在背包中
    }
    
    // 从背包中移除物品
    final itemToDrop = inventory[itemIndex];
    
    // 关键区域：护甲装备的 count 表示耐久——丢弃时整件丢弃，保持耐久
    final bool isArmorWithBlock = (itemToDrop.type == 'equipment' && ((itemToDrop.effects?['armorValue'] ?? 0) > 0));
    if (isArmorWithBlock) {
      inventory.removeAt(itemIndex);
      _dropItemToGround(itemToDrop, state.playerPosition.toPoint());
    } else {
      // 如果物品数量大于1，只丢弃一个
      if (itemToDrop.count > 1) {
        inventory[itemIndex] = Item(
          id: itemToDrop.id,
          name: itemToDrop.name,
          image: itemToDrop.image,
          description: itemToDrop.description,
          effects: itemToDrop.effects,
          type: itemToDrop.type,
          count: itemToDrop.count - 1,
          availableInShop: itemToDrop.availableInShop,
          basePrice: itemToDrop.basePrice,
          usageTime: itemToDrop.usageTime,
          level: itemToDrop.level,
          equipmentSlot: itemToDrop.equipmentSlot,
          weaponParams: itemToDrop.weaponParams,

        );
        final singleItem = Item(
          id: itemToDrop.id,
          name: itemToDrop.name,
          image: itemToDrop.image,
          description: itemToDrop.description,
          effects: itemToDrop.effects,
          type: itemToDrop.type,
          count: 1,
          availableInShop: itemToDrop.availableInShop,
          basePrice: itemToDrop.basePrice,
          usageTime: itemToDrop.usageTime,
          level: itemToDrop.level,
          equipmentSlot: itemToDrop.equipmentSlot,
          weaponParams: itemToDrop.weaponParams,

        );
        _dropItemToGround(singleItem, state.playerPosition.toPoint());
      } else {
        inventory.removeAt(itemIndex);
        _dropItemToGround(itemToDrop, state.playerPosition.toPoint());
      }
    }
    
    // 更新背包状态
    state = state.copyWith(playerInventory: inventory);
    
    // 添加丢弃物品的播报消息
    addBroadcastMessage(
      '丢弃了 ${item.name}',
      BroadcastMessageType.item,
    );
    
    return true;
  }

  /// 开始使用物品（启动进度条）
  bool useItem(Item item) {
    // 检查是否已经在使用物品
    if (state.isUsingItem) {
      return false; // 已经在使用物品，不能同时使用多个
    }
    
    // 检查物品是否在背包中
    final inventory = List<Item>.from(state.playerInventory);
    final itemIndex = inventory.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) {
      return false; // 物品不在背包中
    }
    
    // 关闭背包页面
    state = state.copyWith(showInventory: false);
    
    // 开始使用物品
    state = state.copyWith(
      isUsingItem: true,
      currentUsingItem: item,
      itemUsageProgress: 0.0,
      itemUsageStartTime: DateTime.now(),
    );
    
    // 启动物品使用计时器
    _startItemUsageTimer(item);
    
    // 添加开始使用物品的播报消息
    addBroadcastMessage(
      '开始使用 ${item.name}...',
      BroadcastMessageType.item,
    );
    
    return true; // 开始使用成功
  }
  
  /// 启动物品使用计时器
  void _startItemUsageTimer(Item item) {
    _itemUsageTimer?.cancel(); // 取消之前的计时器
    
    const updateInterval = Duration(milliseconds: 50); // 20fps更新
    final totalDuration = Duration(milliseconds: item.usageTime);
    
    _itemUsageTimer = Timer.periodic(updateInterval, (timer) {
      if (!state.isUsingItem || state.currentUsingItem?.id != item.id) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(state.itemUsageStartTime!);
      final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
      
      if (progress >= 1.0) {
        // 使用完成，应用物品效果
        timer.cancel();
        _completeItemUsage(item);
      } else {
        // 更新进度
        state = state.copyWith(itemUsageProgress: progress);
      }
    });
  }

  /// 启动宝箱探索计时器
  void _startChestExplorationTimer(Point<int> chestPosition) {
    _chestExplorationTimer?.cancel(); // 取消之前的计时器
    
    const updateInterval = Duration(milliseconds: 50); // 20fps更新
    
    _chestExplorationTimer = Timer.periodic(updateInterval, (timer) {
      if (!state.isExploringChest || state.currentExploringChest != chestPosition) {
        timer.cancel();
        return;
      }

      // 关键区域：逐个搜索——仅对队列首项计时，完成后揭示并重置下一个项的起始时间
      if (state.chestPendingItems.isEmpty) {
        // 全部揭示完成
        state = state.copyWith(chestExplorationProgress: 1.0);
        timer.cancel();
        return;
      }

      final startTime = state.chestExplorationStartTime;
      if (startTime == null) {
        timer.cancel();
        return;
      }

      final currentItem = state.chestPendingItems.first;
      final itemDurationMs = _getChestItemSearchDurationMs(currentItem);
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsedMs / itemDurationMs).clamp(0.0, 1.0);

      if (elapsedMs >= itemDurationMs) {
        // 当前项搜索完成，揭示该物品
        final newPending = List<Item>.from(state.chestPendingItems);
        final newVisible = List<Item>.from(state.chestVisibleItems);
        if (newPending.isNotEmpty) {
          newVisible.add(newPending.removeAt(0));
        }

        state = state.copyWith(
          chestPendingItems: newPending,
          chestVisibleItems: newVisible,
          chestExplorationProgress: newPending.isEmpty ? 1.0 : 0.0,
          chestExplorationStartTime: newPending.isEmpty ? state.chestExplorationStartTime : DateTime.now(),
        );

        if (newPending.isEmpty) {
          // 队列为空，停止计时器（页面保持打开，等待玩家操作）
          timer.cancel();
        }
      } else {
        // 更新当前项的搜索进度
        state = state.copyWith(chestExplorationProgress: progress);
      }
    });
  }

  // 关键区域：按物品等级设置搜索时间（level 越高耗时越长）
  int _getChestItemSearchDurationMs(Item item) {
    final int l = item.level.clamp(0, 7);
    // 基础 1200ms，等级每提升增加 600ms（0→1200ms，5→~4800ms）
    return 1200 + l * 600;
  }

  /// 完成宝箱探索，获得物品
  void _completeChestExploration(Point<int> chestPosition) {
    // 检查宝箱是否仍然存在
    if (!state.chestPositions.contains(chestPosition)) {
      // 宝箱已经不存在，重置状态
      state = state.copyWith(
        isExploringChest: false,
        currentExploringChest: null,
        chestExplorationProgress: 0.0,
        chestExplorationStartTime: null,
      );
      return;
    }
    
    // 移除已打开的宝箱
    final updatedChestPositions = List<Point<int>>.from(state.chestPositions);
    updatedChestPositions.remove(chestPosition);
    // 关键区域：初始固定宝箱点击后应消失——不再重生
    // 保持普通宝箱原逻辑（移除后由补充机制补齐数量），固定宝箱不再重新添加
    
    // 随机获得物品
    final randomItems = _getRandomChestItems();
    print('_completeChestExploration - 获得物品: ${randomItems.map((item) => item.name).toList()}');
    
    // 关键区域：背包容量检查——满背包时，宝箱物品自动掉落在地上
    final updatedInventory = List<Item>.from(state.playerInventory);
    final int freeSlots = state.inventoryCapacity - updatedInventory.length;
    final List<Item> itemsToInventory = freeSlots > 0
        ? randomItems.take(freeSlots).toList()
        : <Item>[];
    final List<Item> itemsToDrop = (freeSlots >= randomItems.length)
        ? <Item>[]
        : randomItems.sublist(itemsToInventory.length);

    // 先添加能装下的
    if (itemsToInventory.isNotEmpty) {
      updatedInventory.addAll(itemsToInventory);
    }
    // 装不下的直接掉落到玩家当前位置
    if (itemsToDrop.isNotEmpty) {
      final dropPos = state.playerPosition.toPoint();
      for (final item in itemsToDrop) {
        _dropItemToGround(item, dropPos);
        // 与购买逻辑一致的提示
        addBroadcastMessage(
          '背包已满，${item.name} 掉落在地上',
          BroadcastMessageType.item,
        );
      }
    }
    
    // 更新状态
    state = state.copyWith(
      chestPositions: updatedChestPositions,
      playerInventory: updatedInventory,
      isExploringChest: false,
      currentExploringChest: null,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: null,
    );
    
    // 显示获得物品的消息（仅显示成功进入背包的物品）
    if (itemsToInventory.isNotEmpty) {
      final itemNames = itemsToInventory.map((item) => item.name).join('、');
      addBroadcastMessage('打开宝箱获得：$itemNames', BroadcastMessageType.item, duration: const Duration(seconds: 3));
      print('_completeChestExploration - 显示消息: 打开宝箱获得：$itemNames');
    }
    
    // 智能补充宝箱：只在宝箱数量不足时添加新宝箱
    _replenishChestsIfNeeded();
  }
  
  /// 完成物品使用，应用效果
  void _completeItemUsage(Item item) {
    // 检查物品是否在背包中（优先使用对象身份匹配，以确保选中堆叠）
    final inventory = List<Item>.from(state.playerInventory);
    int itemIndex = inventory.indexWhere((i) => identical(i, item));
    if (itemIndex == -1) {
      // 回退：按 id + count 尝试匹配（避免同 id 不同堆叠被误选）
      itemIndex = inventory.indexWhere((i) => i.id == item.id && i.count == item.count);
    }
    
    if (itemIndex == -1) {
      // 物品不在背包中，取消使用
      cancelItemUsage();
      return;
    }
    
    // 关键区域：金币为特殊物品——一次使用消耗选中堆叠的全部数量
    final bool isGold = item.id == 'gold';
    final int quantityToConsume = isGold ? item.count : 1;

    // 应用物品效果（金币按堆叠数量整体生效）
    final character = Map<String, dynamic>.from(state.characterStats);
    bool hasEffect = false;
    
    item.effects.forEach((effectType, value) {
      switch (effectType) {
        case 'hp':
          // 关键区域：生命值上限不固定，需依赖可变的 maxHp
          // 使用当前角色的 maxHp 作为生命值上限进行限制，避免固定 100 上限
          final currentHp = character['hp'] ?? 100;
          final double maxHp = (character['maxHp'] ?? 100).toDouble();
          final int delta = isGold ? (value * quantityToConsume) : value;
          final newHp = (currentHp + delta).clamp(0, maxHp);
          character['hp'] = newHp;
          hasEffect = true;
          break;
        case 'food':
          // 关键区域：饱食度上限不固定，依赖可变的 maxFood
          final currentFood = character['food'] ?? 100;
          final double maxFood = (character['maxFood'] ?? 100).toDouble();
          final int delta = isGold ? (value * quantityToConsume) : value;
          final newFood = (currentFood + delta).clamp(0, maxFood);
          character['food'] = newFood;
          hasEffect = true;
          break;
        case 'maxHp':
          // 关键区域：允许道具修改生命值上限
          final double currentMaxHp = (character['maxHp'] ?? 100).toDouble();
          final double proposed = (currentMaxHp + (isGold ? (value * quantityToConsume) : value)).toDouble();
          final double newMaxHp = proposed < 1 ? 1 : proposed;
          character['maxHp'] = newMaxHp;
          // 若当前生命值超过新上限则进行夹取
          final double currentHp2 = (character['hp'] ?? 0).toDouble();
          if (currentHp2 > newMaxHp) {
            character['hp'] = newMaxHp;
          }
          hasEffect = true;
          break;
        case 'maxFood':
          // 关键区域：允许道具修改饱食度上限
          final double currentMaxFood = (character['maxFood'] ?? 100).toDouble();
          final double proposedFoodMax = (currentMaxFood + (isGold ? (value * quantityToConsume) : value)).toDouble();
          final double newMaxFood = proposedFoodMax < 1 ? 1 : proposedFoodMax;
          character['maxFood'] = newMaxFood;
          // 若当前饱食度超过新上限则进行夹取
          final double currentFood2 = (character['food'] ?? 0).toDouble();
          if (currentFood2 > newMaxFood) {
            character['food'] = newMaxFood;
          }
          hasEffect = true;
          break;
        case 'san':
          final currentSan = character['san'] ?? 100;
          final int deltaSan = isGold ? (value * quantityToConsume) : value;
          final newSan = (currentSan + deltaSan).clamp(0, 250); // 精神值上限限制为250
          character['san'] = newSan;
          hasEffect = true;
          break;
        case 'moveSpeed':
          final currentSpeed = character['moveSpeed'] ?? 100;
          final int deltaSpeed = isGold ? (value * quantityToConsume) : value;
          final newSpeed = (currentSpeed + deltaSpeed).clamp(1, double.infinity); // 移除上限，只保留最小值1防止负速度
          character['moveSpeed'] = newSpeed;
          hasEffect = true;
          break;
        case 'gold':
          final currentGold = character['gold'] ?? 0;
          final int deltaGold = value * quantityToConsume;
          final newGold = (currentGold + deltaGold).clamp(0, 999999);
          character['gold'] = newGold;
          hasEffect = true;
          break;
        case 'oxygenBonus':
          // 记录增加氧气上限前的当前氧气值
          final currentOxygenBeforeBonus = state.currentOxygen;
          // 增加氧气上限
          final double deltaOxygenBonus = isGold ? (value * quantityToConsume).toDouble() : value.toDouble();
          increaseOxygenCapacity(deltaOxygenBonus);
          // 检查是否需要启动氧气恢复进度条
          final newMaxOxygen = state.actualMaxOxygen;
          if (currentOxygenBeforeBonus < newMaxOxygen) {
            _startOxygenRecovery(currentOxygenBeforeBonus, newMaxOxygen);
          }
          hasEffect = true;
          break;
        case 'punish':
          // 关键区域：处分值按 0..10 夹取
          final currentPun = (character['punish'] ?? 0).toDouble();
          final double maxPun = (character['maxPunish'] ?? 10).toDouble();
          final int deltaPun = isGold ? (value * quantityToConsume) : value;
          final double newPun = (currentPun + deltaPun).clamp(0, maxPun);
          character['punish'] = newPun;
          hasEffect = true;
          break;
      }
    });
    
    if (hasEffect) {
      // 从背包中移除物品：金币一次消耗整个堆叠；其他物品按照原逻辑（-1 或移除）
      if (isGold) {
        inventory.removeAt(itemIndex);
      } else {
        if (item.count > 1) {
          inventory[itemIndex] = Item(
            id: item.id,
            name: item.name,
            image: item.image,
            description: item.description,
            effects: item.effects,
            type: item.type,
            count: item.count - 1,
            availableInShop: item.availableInShop,
            basePrice: item.basePrice,
            usageTime: item.usageTime,
            level: item.level,
            equipmentSlot: item.equipmentSlot,
            weaponParams: item.weaponParams,
          );
        } else {
          inventory.removeAt(itemIndex);
        }
      }
      
      // 先安全合并角色属性，再更新其它状态字段
      _safeUpdateCharacterStats((_) => character, '物品使用完成');
      state = state.copyWith(
        playerInventory: inventory,
        isUsingItem: false,
        currentUsingItem: null,
        itemUsageProgress: 0.0,
        itemUsageStartTime: null,
      );
      
      // 添加使用完成的播报消息
      addBroadcastMessage(
        '使用了 ${item.name}${isGold ? ' x ${quantityToConsume}' : ''}',
        BroadcastMessageType.item,
      );
    } else {
      // 没有效果，取消使用
      cancelItemUsage();
    }
  }
  
  /// 取消物品使用
  void cancelItemUsage() {
    if (!state.isUsingItem) return;
    
    final item = state.currentUsingItem;
    
    // 取消计时器
    _itemUsageTimer?.cancel();
    
    // 消耗物品但不应用效果
    if (item != null) {
      final inventory = List<Item>.from(state.playerInventory);
      final itemIndex = inventory.indexWhere((i) => i.id == item.id);
      
      if (itemIndex != -1) {
        if (item.count > 1) {
          inventory[itemIndex] = Item(
            id: item.id,
            name: item.name,
            image: item.image,
            description: item.description,
            effects: item.effects,
            type: item.type,
            count: item.count - 1,
            availableInShop: item.availableInShop,
            basePrice: item.basePrice,
            usageTime: item.usageTime,
            level: item.level,
            equipmentSlot: item.equipmentSlot,
            weaponParams: item.weaponParams,
          );
        } else {
          inventory.removeAt(itemIndex);
        }
        
        // 更新背包
        state = state.copyWith(playerInventory: inventory);
        
        // 添加取消使用的播报消息
        addBroadcastMessage(
          '取消使用 ${item.name}，物品已消耗',
          BroadcastMessageType.item,
        );
      }
    }
    
    // 重置物品使用状态
    state = state.copyWith(
      isUsingItem: false,
      currentUsingItem: null,
      itemUsageProgress: 0.0,
      itemUsageStartTime: null,
    );
  }

  /// 取消宝箱探索
  void cancelChestExploration() {
    if (!state.isExploringChest) return;
    
    // 如果当前处于搜索页面，统一走关闭逻辑（掉落未取物品并移除宝箱）
    if (state.isChestSearchOpen) {
      closeChestSearch();
      return;
    }
    
    // 取消计时器
    _chestExplorationTimer?.cancel();
    
    // 重置宝箱探索状态，但不移除宝箱
    state = state.copyWith(
      isExploringChest: false,
      currentExploringChest: null,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: null,
    );
    
    // 添加取消探索的播报消息
    addBroadcastMessage(
      '取消探索宝箱',
      BroadcastMessageType.item,
    );
  }

  /// 将宝箱中的物品放入背包（点击/快捷方式）
  /// 关键区域：容量校验与原子更新，避免状态不同步
  bool transferChestItemToInventory(Item item) {
    // 复制当前状态
    final inventory = List<Item>.from(state.playerInventory);
    final visible = List<Item>.from(state.chestVisibleItems);

    // 从宝箱可见列表移除该物品
    final index = visible.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return false; // 该物品当前不可见或已被转移
    }
    final removed = visible.removeAt(index);

    // 堆叠逻辑（仅对 type == 'item' 生效，上限16）
    const int stackLimit = 16;
    int remaining = removed.count;

    if (removed.type == 'item') {
      // 先尝试合并到已有同类堆叠
      for (int i = 0; i < inventory.length && remaining > 0; i++) {
        final invItem = inventory[i];
        if (invItem.id == removed.id && invItem.type == 'item') {
          final int free = stackLimit - invItem.count;
          if (free > 0) {
            final int addCount = remaining < free ? remaining : free;
            inventory[i] = Item(
              id: invItem.id,
              name: invItem.name,
              image: invItem.image,
              description: invItem.description,
              effects: invItem.effects,
              type: invItem.type,
              count: invItem.count + addCount,
              availableInShop: invItem.availableInShop,
              basePrice: invItem.basePrice,
              usageTime: invItem.usageTime,
              level: invItem.level,
              equipmentSlot: invItem.equipmentSlot,
              weaponParams: invItem.weaponParams,

            );
            remaining -= addCount;
          }
        }
      }

      // 若仍有剩余，计算新增堆叠所需槽位
      while (remaining > 0) {
        final int neededStacks = (remaining + stackLimit - 1) ~/ stackLimit;
        final int availableSlots = state.inventoryCapacity - inventory.length;
        if (availableSlots < neededStacks) {
          // 回滚宝箱可见列表，拒绝整个操作
          visible.insert(index, removed);
          addBroadcastMessage('背包空间不足，无法放入', BroadcastMessageType.item);
          return false;
        }
        final int toAdd = remaining > stackLimit ? stackLimit : remaining;
            inventory.add(Item(
              id: removed.id,
              name: removed.name,
              image: removed.image,
              description: removed.description,
              effects: removed.effects,
              type: removed.type,
              count: toAdd,
              availableInShop: removed.availableInShop,
              basePrice: removed.basePrice,
              usageTime: removed.usageTime,
              level: removed.level,
              equipmentSlot: removed.equipmentSlot,
              weaponParams: removed.weaponParams,

            ));
        remaining -= toAdd;
      }
    } else {
      // 非堆叠类型按单件处理：需要1个槽位
      if (inventory.length >= state.inventoryCapacity) {
        visible.insert(index, removed);
        addBroadcastMessage('背包已满，无法放入', BroadcastMessageType.item);
        return false;
      }
      inventory.add(removed);
    }

    // 更新状态
    state = state.copyWith(
      playerInventory: inventory,
      chestVisibleItems: visible,
    );
    addBroadcastMessage('已放入背包：${removed.name}${removed.count > 1 ? ' x ${removed.count}' : ''}', BroadcastMessageType.item);
    return true;
  }

  /// 将宝箱中的物品放入背包指定格子（拖拽到格子）
  /// 关键区域：组合插入与移除，保证一次操作完成
  bool transferChestItemToInventoryAtSlot(Item item, int targetIndex) {
    // 容量边界检查
    if (targetIndex < 0 || targetIndex >= state.inventoryCapacity) {
      return false;
    }

    // 背包满则拒绝
    if (state.playerInventory.length >= state.inventoryCapacity) {
      addBroadcastMessage('背包已满，无法放入', BroadcastMessageType.item);
      return false;
    }

    // 先尝试在指定位置插入
    final success = insertItemAtPosition(item, targetIndex);
    if (!success) {
      return false;
    }

    // 插入成功后，从宝箱可见列表移除该物品
    final visible = List<Item>.from(state.chestVisibleItems);
    final index = visible.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      visible.removeAt(index);
      state = state.copyWith(chestVisibleItems: visible);
    }

    addBroadcastMessage('已放入背包：${item.name}', BroadcastMessageType.item);
    return true;
  }

  /// 关闭宝箱搜索页面
  /// 关键区域：剩余物品全部掉落在地上，并移除宝箱
  void closeChestSearch() {
    if (!state.isChestSearchOpen) {
      return;
    }

    // 取消可能仍在运行的计时器
    _chestExplorationTimer?.cancel();

    final chestPos = state.currentExploringChest;
    final dropPos = chestPos ?? state.playerPosition.toPoint();

    // 掉落所有未转移的可见物品
    if (state.chestVisibleItems.isNotEmpty) {
      for (final item in state.chestVisibleItems) {
        _dropItemToGround(item, dropPos);
      }
      addBroadcastMessage('关闭宝箱，未取走物品已掉落在地上', BroadcastMessageType.item);
    }

    // 移除对应的容器（宝箱或保险箱）
    final updatedChestPositions = List<Point<int>>.from(state.chestPositions);
    final updatedSafePositions = List<Point<int>>.from(state.safePositions);
    if (chestPos != null) {
      if (updatedChestPositions.contains(chestPos)) {
        updatedChestPositions.remove(chestPos);
      } else if (updatedSafePositions.contains(chestPos)) {
        updatedSafePositions.remove(chestPos);
      }
    }

    // 重置相关状态并关闭页面
    state = state.copyWith(
      chestPositions: updatedChestPositions,
      safePositions: updatedSafePositions,
      isChestSearchOpen: false,
      chestPendingItems: const [],
      chestVisibleItems: const [],
      isExploringChest: false,
      currentExploringChest: null,
      chestExplorationProgress: 0.0,
      chestExplorationStartTime: null,
    );

    // 智能补充宝箱：只在宝箱数量不足时添加新宝箱
    _replenishChestsIfNeeded();
    _replenishSafesIfNeeded();
  }

  /// 触发游戏结束
  void triggerGameOver(String reason) {
    // 添加游戏结束的播报消息
    addBroadcastMessage(
      '游戏结束: $reason',
      BroadcastMessageType.system,
    );
    
    // 保存死亡时的数据快照
    final deathTimeStats = Map<String, dynamic>.from(state.characterStats);
    final deathTimeInventory = List<Item>.from(state.playerInventory);
    
    state = state.copyWith(
      isGameOver: true,
      deathReason: reason,
      gameEndTime: DateTime.now(),
      deathTimeStats: deathTimeStats,
      deathTimeInventory: deathTimeInventory,
    );
    
    // 停止所有计时器
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    _deathCheckTimer?.cancel(); // 停止死亡判定定时器
  }



  /// 根据地形类型扣除角色状态
  void _applyTerrainEffects(String terrainType, double distance) {
    if (distance <= 0) return;
    
    // 检查是否有技能正在施法，施法期间不消耗饱食度和精神值
    final isAnyCasting = state.skillStates.values.any((skillState) => skillState.isCasting);
    if (isAnyCasting) {
      return;
    }
    
    _safeUpdateCharacterStats((currentStats) {
      final updatedStats = Map<String, dynamic>.from(currentStats);
      final random = Random();
      
      // 计算移动格数（每格约为1个单位距离）
      final gridsMoved = distance;
      
      switch (terrainType) {
        case 'grass': // 草地
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.5-1饱食度
            final foodDeduction = 0.5 + random.nextDouble() * 0.5;
            // 关键区域：改为使用动态 maxFood 进行夹取
            final double maxFoodGrass = (updatedStats['maxFood'] ?? 100).toDouble();
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, maxFoodGrass);
            
            // 随机扣除0-1精神值
            final sanDeduction = random.nextDouble();
            updatedStats['san'] = ((updatedStats['san'] ?? 0) - sanDeduction).clamp(0, 250); // 精神值上限限制为250
          }
          break;
          
        case 'building': // 建筑里
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.2-1饱食度
            final foodDeduction = 0.2 + random.nextDouble() * 0.8;
            final double maxFoodBuilding = (updatedStats['maxFood'] ?? 100).toDouble();
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, maxFoodBuilding);
            
            // 随机扣除0.8-2精神值
            final sanDeduction = 0.8 + random.nextDouble() * 1.2;
            updatedStats['san'] = ((updatedStats['san'] ?? 0) - sanDeduction).clamp(0, 250); // 精神值上限限制为250
          }
          break;
          
        case 'woods': // 树林里
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.5-1饱食度
            final foodDeduction = 0.5 + random.nextDouble() * 0.5;
            final double maxFoodWoods = (updatedStats['maxFood'] ?? 100).toDouble();
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, maxFoodWoods);
            
            // 随机扣除0-1精神值
            final sanDeduction = random.nextDouble();
            updatedStats['san'] = ((updatedStats['san'] ?? 0) - sanDeduction).clamp(0, 250); // 精神值上限限制为250
            
            // 随机扣除0-0.5生命值
            final hpDeduction = random.nextDouble() * 0.5;
            // 关键区域：树林环境伤害支持护甲格挡
            final double applied = _applyArmorBlock(updatedStats, hpDeduction);
            final double currentHp = (updatedStats['hp'] ?? 0).toDouble();
            final double maxHp = (updatedStats['maxHp'] ?? 100).toDouble();
            updatedStats['hp'] = (currentHp - applied).clamp(0, maxHp);
          }
          break;
          
        case 'path': // 路上
          for (int i = 0; i < gridsMoved.ceil(); i++) {
            // 随机扣除0.2-0.5饱食度
            final foodDeduction = 0.2 + random.nextDouble() * 0.3;
            final double maxFoodPath = (updatedStats['maxFood'] ?? 100).toDouble();
            updatedStats['food'] = ((updatedStats['food'] ?? 0) - foodDeduction).clamp(0, maxFoodPath);
            
            // 随机恢复0-0.5精神值
            final sanRecovery = random.nextDouble() * 0.5;
            updatedStats['san'] = ((updatedStats['san'] ?? 0) + sanRecovery).clamp(0, 250); // 精神值上限限制为250
          }
          break;
          
        default:
          // 其他地形类型暂时不扣除状态
          break;
      }
      
      return updatedStats;
    }, '移动系统地形效果-$terrainType');
  }

  /// 获取当前位置的地形类型
  String _getCurrentTerrain() {
    final position = state.playerPosition;
    final gridX = position.x.round().clamp(0, state.map[0].length - 1);
    final gridY = position.y.round().clamp(0, state.map.length - 1);
    
    return state.map[gridY][gridX];
  }

  /// 计算两点之间的距离
  double _calculateMovementDistance(OptimizedPlayerPosition from, OptimizedPlayerPosition to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// 检查游戏结束条件
  void _checkGameOverConditions() {
    // 如果游戏已经结束，立即停止判定
    if (state.isGameOver) {
      _deathCheckTimer?.cancel();
      return;
    }

    final position = state.playerPosition;
    final character = state.characterStats;
    
    // 检查生命值
    if (character['hp'] != null && character['hp'] <= 0) {
      _deathCheckTimer?.cancel(); // 立即停止死亡判定定时器
      triggerGameOver('生命值耗尽');
      return;
    }
    
    // 检查理智值
    if (character['san'] != null && character['san'] <= 0) {
      _deathCheckTimer?.cancel(); // 立即停止死亡判定定时器
      triggerGameOver('理智崩溃');
      return;
    }
    
    // 检查是否走到了特殊位置（比如出口）
    final gridX = position.x.round();
    final gridY = position.y.round();
    
    if (gridX >= 0 && gridX < state.map[0].length && 
        gridY >= 0 && gridY < state.map.length) {
      final tile = state.map[gridY][gridX];
      
      // 如果走到了特殊的结束位置
      if (tile == 'exit') {
        _deathCheckTimer?.cancel(); // 立即停止死亡判定定时器
        triggerGameOver('成功逃离学校！');
        return;
      }
    }
  }

  /// 脱离卡死功能 - 激活1秒无视地形移动模式
  void unstuckPlayer() {
    // 检查是否已经被 dispose
    if (!mounted) {
      print('unstuckPlayer: OptimizedGameStateNotifier 已被 dispose，跳过执行');
      return;
    }
    
    final now = DateTime.now();
    
    // 检查是否在冷却期间
    if (state.unstuckCooldownEnd != null && now.isBefore(state.unstuckCooldownEnd!)) {
      return;
    }
    
    // 激活无视地形模式，持续1秒
    final noClipEndTime = now.add(const Duration(seconds: 1));
    
    state = state.copyWith(
      isNoClipMode: true,
      noClipEndTime: noClipEndTime,
      isWaitingForMovement: true,  // 等待玩家移动以开始冷却
      unstuckActivatedTime: now,   // 记录激活时间
      unstuckCooldownEnd: null,    // 清除之前的冷却时间
    );
  }

  /// 开始脱离卡死冷却计时
  void _startUnstuckCooldown() {
    if (!state.isWaitingForMovement) return;
    
    final now = DateTime.now();
    final cooldownEndTime = now.add(const Duration(seconds: 60));
    
    state = state.copyWith(
      isWaitingForMovement: false,
      unstuckCooldownEnd: cooldownEndTime,
    );
  }

  /// 寻找最近的可移动空地
  Point<int>? _findNearestEmptySpace(int startX, int startY) {
    final mapHeight = state.map.length;
    final mapWidth = state.map[0].length;
    
    // 首先检查当前位置是否已经是可移动的
    if (_isEmptySpace(startX, startY)) {
      return Point(startX, startY);
    }
    
    // 使用广度优先搜索找到最近的空地
    final visited = <Point<int>>{};
    final queue = <Point<int>>[];
    
    queue.add(Point(startX, startY));
    visited.add(Point(startX, startY));
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      // 检查8个方向的相邻位置（包括对角线）
      final directions = [
        Point(0, -1),  // 上
        Point(0, 1),   // 下
        Point(-1, 0),  // 左
        Point(1, 0),   // 右
        Point(-1, -1), // 左上
        Point(1, -1),  // 右上
        Point(-1, 1),  // 左下
        Point(1, 1),   // 右下
      ];
      
      for (final direction in directions) {
        final newX = current.x + direction.x;
        final newY = current.y + direction.y;
        final newPoint = Point(newX, newY);
        
        // 检查边界和是否已访问
        if (newX >= 0 && newX < mapWidth &&
            newY >= 0 && newY < mapHeight &&
            !visited.contains(newPoint)) {
          
          visited.add(newPoint);
          
          // 检查这个位置是否是可移动的空地
          if (_isEmptySpace(newX, newY)) {
            return newPoint;
          }
          
          // 如果不是空地，加入队列继续搜索
          queue.add(newPoint);
        }
      }
    }
    
    // 如果没有找到空地，尝试寻找任何非墙壁位置
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (state.map[y][x] != 'wall' && state.map[y][x] != 'water') {
          return Point(x, y);
        }
      }
    }
    
    // 最后的备选方案：返回地图中心
    final centerX = mapWidth ~/ 2;
    final centerY = mapHeight ~/ 2;
    return Point(centerX, centerY);
  }

  /// 检查指定位置是否是可移动的空地
  bool _isEmptySpace(int x, int y) {
    if (x < 0 || x >= state.map[0].length || y < 0 || y >= state.map.length) {
      return false;
    }
    
    final tile = state.map[y][x];
    
    // 不可通行的地块类型
    final impassableTiles = {'wall', 'water', 'building'};
    
    // 如果不是不可通行的地块，则认为是可移动的
    // 这包括：grass, path, woods, exit, door, shop, chest 等
    return !impassableTiles.contains(tile);
  }

  /// 检查指定位置是否是水瓦片
  bool _isWaterTile(int x, int y) {
    if (x < 0 || x >= state.map[0].length || y < 0 || y >= state.map.length) {
      return false;
    }
    return state.map[y][x] == 'water';
  }

  /// 初始化氧气系统
  void _initializeOxygenSystem() {
    _oxygenSystem = OxygenSystem(
      maxOxygen: state.actualMaxOxygen,
      onHealthDamage: (damage) {
        // 检查是否已经被 dispose
        if (!mounted) {
          print('氧气系统：OptimizedGameStateNotifier 已被 dispose，跳过伤害处理');
          return;
        }
        
        print('氧气系统：收到伤害回调 $damage');
        // 氧气耗尽时扣除生命值 - 参考饱食度扣血方案
        _safeUpdateCharacterStats((currentStats) {
          print('氧气系统：当前统计数据 $currentStats');
          final currentHp = currentStats['hp'] ?? 0;
          print('氧气系统：当前生命值 $currentHp');
          
          // 当氧气耗尽且生命值大于0时，扣除生命值
          if (currentHp > 0) {
            final damageAmount = damage.toDouble(); // 氧气扣血量
            final updatedStats = Map<String, dynamic>.from(currentStats);
            // 关键区域：氧气伤害支持护甲格挡
            final double applied = _applyArmorBlock(updatedStats, damageAmount);
            final newHp = (currentHp - applied).clamp(0, currentStats['maxHp'] ?? 100);
            
            print('氧气系统：计算新生命值 $newHp (原值: $currentHp, 伤害: $damageAmount)');
            
            // 检测生命值变化并触发伤害效果
            final hpChanged = currentHp != newHp;
            
            if (hpChanged) {
              print('氧气系统：生命值发生变化，更新状态');
              // 更新生命值
              updatedStats['hp'] = newHp.toDouble();
              
              // 更新其他状态，触发伤害效果
              state = state.copyWith(
                lastHp: currentHp.toDouble(),
                shouldShowDamageEffect: true,
                lastDamageAmount: applied,
              );
              
              // 添加氧气伤害播报消息
              addBroadcastMessage(
                '氧气耗尽！生命值 -${applied.toStringAsFixed(1)}',
                BroadcastMessageType.damage,
              );
              
              // 检查是否死亡
              if (newHp <= 0) {
                triggerGameOver('溺水而死');
              }
              
              return updatedStats;
            } else {
              print('氧气系统：生命值未发生变化');
            }
          } else {
            print('氧气系统：生命值已为0，不扣血');
          }
          
          // 没有变化，返回原状态
          return currentStats;
        }, '氧气耗尽伤害');
      },
      onVisionChange: (visionMultiplier) {
        // 检查是否已经被 dispose
        if (!mounted) {
          print('氧气系统：OptimizedGameStateNotifier 已被 dispose，跳过视野变化处理');
          return;
        }
        
        // 水中视野变化时更新视野系统
        _updateVision();
      },
    );
    
    // 更新游戏状态中的氧气系统引用
    state = state.copyWith(oxygenSystem: _oxygenSystem);
  }

  /// 更新氧气系统状态
  void _updateOxygenSystem() {
    if (_oxygenSystem == null) return;
    
    final playerPos = state.playerPosition.toPoint();
    final isInWater = _isWaterTile(playerPos.x, playerPos.y);
    
    // 检查玩家是否进入或离开水中
    if (isInWater != state.isInWater) {
      if (isInWater) {
        _oxygenSystem!.enterWater();
      } else {
        _oxygenSystem!.exitWater();
      }
      
      // 更新游戏状态
      state = state.copyWith(
        isInWater: isInWater,
        currentOxygen: _oxygenSystem!.currentOxygen,
      );
    } else {
      // 无论在水中还是陆地上，都要同步氧气值（确保背包界面显示正确）
      state = state.copyWith(
        currentOxygen: _oxygenSystem!.currentOxygen,
      );
    }
  }

  /// 重置游戏状态
  void resetGame() {
    // 检查是否已经被 dispose，如果是则直接返回
    if (!mounted) {
      return;
    }
    
    // 停止所有计时器
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    
    // 重置状态到初始值
    final currentCharacterStats = state.characterStats;
    final characterName = currentCharacterStats['name'] as String?;
    state = OptimizedGameState(
      characterStats: _createInitialCharacterStats(currentCharacterStats),
      playerPosition: const OptimizedPlayerPosition(x: 10.0, y: 10.0, facingRight: true),
      movementState: const OptimizedMovementState(),
      map: MapData.testMap,
      chestPositions: [],
      safePositions: [],
      playerInventory: [],
      visibleTiles: {},
      visibleMap: List.generate(
        MapData.testMap.length,
        (y) => List.generate(MapData.testMap[0].length, (x) => false),
      ),
      ghostManager: GhostManager(map: MapData.testMap),
      showInventory: false,
      showCharacterInfo: false,
      showShop: false,
      isGameOver: false,
      deathReason: '',
      characterSkills: _initializeCharacterSkills(characterName),
      skillStates: _initializeSkillStates(characterName),
      gameStartTime: DateTime.now(),
      gameEndTime: null,
    );
    
    // 重新初始化游戏
    _initializeGame();
  }

  /// 重置伤害效果状态
  void resetDamageEffect() {
    state = state.copyWith(
      shouldShowDamageEffect: false,
      lastDamageAmount: 0.0,
    );
  }

  /// 添加播报消息
  void addBroadcastMessage(String text, BroadcastMessageType type, {Duration? duration}) {
    // 检查是否已存在相同的消息（相同文本和类型，且未过期）
    final now = DateTime.now();
    BroadcastMessage? existingMessage;
    try {
      existingMessage = state.broadcastMessages.firstWhere(
        (message) => 
          message.text == text && 
          message.type == type && 
          now.difference(message.timestamp) <= message.displayDuration,
      );
    } catch (e) {
      existingMessage = null;
    }
    
    // 如果找到相同且未过期的消息，则不添加新消息
    if (existingMessage != null) {
      return;
    }
    
    final message = BroadcastMessage(
      text: text,
      type: type,
      timestamp: DateTime.now(),
      displayDuration: duration ?? const Duration(seconds: 3),
    );
    
    final updatedMessages = List<BroadcastMessage>.from(state.broadcastMessages)
      ..add(message);
    
    // 限制消息数量，最多保留10条
    if (updatedMessages.length > 10) {
      updatedMessages.removeAt(0);
    }
    
    state = state.copyWith(broadcastMessages: updatedMessages);
  }

  /// 清理过期的播报消息
  void cleanupExpiredMessages() {
    final now = DateTime.now();
    final activeMessages = state.broadcastMessages
        .where((message) => now.difference(message.timestamp) <= message.displayDuration)
        .toList();
    
    if (activeMessages.length != state.broadcastMessages.length) {
      state = state.copyWith(broadcastMessages: activeMessages);
    }
  }

  /// 清除所有播报消息
  void clearAllBroadcastMessages() {
    state = state.copyWith(broadcastMessages: []);
  }



  /// 获取平滑视野管理器
  SmoothVisionManager? get smoothVisionManager => _smoothVisionManager;

  // ===== 技能系统相关方法 =====
  
  /// 使用技能
  void useSkill(String skillId) {
    final skillState = state.skillStates[skillId];
    if (skillState == null) {
      return;
    }
    
    // 获取技能数据
    final skill = SkillData.getSkillById(skillId);
    if (skill == null) {
      return;
    }
    
    // 检查技能是否在冷却中
    if (skillState.isOnCooldown(skill.cooldownSeconds)) {
      final remainingTime = skillState.getRemainingCooldown(skill.cooldownSeconds);
      addBroadcastMessage(
        '技能冷却中，剩余 $remainingTime 秒',
        BroadcastMessageType.system,
      );
      return;
    }
    
    // 检查技能是否正在使用中
    if (skillState.isCurrentlyCasting) {
      addBroadcastMessage(
        '技能正在使用中',
        BroadcastMessageType.system,
      );
      return;
    }
    
    // 开始使用技能
    _startSkillExecution(skill, skillState);
  }
  
  /// 开始执行技能
  void _startSkillExecution(Skill skill, SkillState skillState) {

    final now = DateTime.now();
    
    // 更新技能状态为施法状态
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    updatedSkillStates[skill.id] = skillState.copyWith(
      isCasting: true,
      castStartTime: now,
    );
    
    state = state.copyWith(
      skillStates: updatedSkillStates,
      currentCastingSkillId: skill.id,
      castingProgress: 0.0,
    );

    
    // 添加技能开始使用的播报消息
    addBroadcastMessage(
      '开始使用技能: ${skill.name}',
      BroadcastMessageType.system,
    );
    
    // 设置技能执行完成的定时器
    // 关键区域：在定时器回调开始检查 mounted，避免销毁后触发
    Timer(Duration(seconds: skill.castTimeSeconds), () {
      if (!mounted) return;
      _completeSkillExecution(skill);
    });
  }
  
  /// 完成技能执行
  void _completeSkillExecution(Skill skill) {
    final now = DateTime.now();
    final skillState = state.skillStates[skill.id];
    
    if (skillState == null || !skillState.isCurrentlyCasting) {
      return;
    }
    
    // 先更新技能状态：结束施法状态，开始冷却
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    updatedSkillStates[skill.id] = skillState.copyWith(
      isCasting: false,
      castStartTime: null,
      lastUsedTime: now,
    );
    
    // 更新技能状态到当前state中，清除施法状态
    state = state.copyWith(
      skillStates: updatedSkillStates,
      currentCastingSkillId: null,
      castingProgress: 0.0,
    );
    
    // 应用技能效果（这会进一步更新state）
    _applySkillEffects(skill);
    
    // 添加技能完成的播报消息
    addBroadcastMessage(
      '技能 ${skill.name} 使用完成',
      BroadcastMessageType.system,
    );
  }
  
  /// 应用技能效果
  void _applySkillEffects(Skill skill) {
    // 特殊处理烹饪技能
    if (skill.id == 'cooking') {
      _applyCookingSkillEffect(skill);
      return;
    }
    
    final effect = skill.effect;
    final newStats = Map<String, dynamic>.from(state.characterStats);
    
    // 应用技能效果并收集结果消息
    final effectResults = effect.apply();
    final messages = <String>[];
    
    // 处理各种效果
    effectResults.forEach((effectType, value) {
      switch (effectType) {
        case 'health':
          final currentHp = (newStats['hp'] ?? 0).toDouble();
          final maxHp = (newStats['maxHp'] ?? 100).toDouble();
          final newHp = (currentHp + value).clamp(0, maxHp);
          newStats['hp'] = newHp;
          messages.add('恢复生命值 +$value (${currentHp.toStringAsFixed(1)} → ${newHp.toStringAsFixed(1)})');
          break;
        case 'sanity':
          final currentSan = (newStats['san'] ?? 0).toDouble();
          final maxSan = 250.0; // 精神值上限固定为250
          final newSan = (currentSan + value).clamp(0, 250); // 精神值上限限制为250
          newStats['san'] = newSan;
          messages.add('恢复精神值 +$value (${currentSan.toStringAsFixed(1)} → ${newSan.toStringAsFixed(1)})');
          break;
        case 'food':
          final currentFood = (newStats['food'] ?? 0).toDouble();
          // 关键区域：改为使用动态 maxFood
          final double maxFood = (newStats['maxFood'] ?? 100).toDouble();
          final newFood = (currentFood + value).clamp(0, maxFood);
          newStats['food'] = newFood;
          messages.add('恢复饱食度 +${value.toStringAsFixed(1)} (${currentFood.toStringAsFixed(1)} → ${newFood.toStringAsFixed(1)})');
          break;
        case 'gold':
          final currentGold = (newStats['gold'] ?? 0).toDouble();
          final newGold = currentGold + value;
          newStats['gold'] = newGold;
          messages.add('获得金币 +$value (${currentGold.toStringAsFixed(0)} → ${newGold.toStringAsFixed(0)})');
          break;
        case 'damage':
          // 伤害效果暂时不实现
          break;
      }
    });
    
    // 创建播报消息列表
    final broadcastMessages = <BroadcastMessage>[];
    for (final message in messages) {
      broadcastMessages.add(BroadcastMessage(
        text: message,
        type: BroadcastMessageType.heal,
        timestamp: DateTime.now(),
        displayDuration: const Duration(seconds: 3),
      ));
    }
    
    // 合并现有播报消息
    final updatedMessages = List<BroadcastMessage>.from(state.broadcastMessages)
      ..addAll(broadcastMessages);
    
    // 限制消息数量
    while (updatedMessages.length > 10) {
      updatedMessages.removeAt(0);
    }
    
    // 一次性更新所有状态，确保状态变化被正确传播
    state = state.copyWith(
      characterStats: newStats,
      broadcastMessages: updatedMessages,
      // 使用动画帧标识确保状态变化被检测到
      lastAnimationFrame: state.lastAnimationFrame + 1,
    );
  }

  /// 应用烹饪技能特殊效果
  void _applyCookingSkillEffect(Skill skill) {
    // 确保获取最新的游戏状态
    final currentState = state;
    final newStats = Map<String, dynamic>.from(currentState.characterStats);
    final messages = <String>[];
    final random = Random();
    
    // 烹饪技能：不需要食物，等待施法时间后获得随机属性
    messages.add('烹饪完成！制作了美味的料理');
    
    // 随机生命值 1-10
    final hpGain = random.nextInt(10) + 1;
    final currentHp = (newStats['hp'] ?? 0).toDouble();
    final maxHp = (newStats['maxHp'] ?? 100).toDouble();
    final newHp = (currentHp + hpGain).clamp(0, maxHp);
    newStats['hp'] = newHp;
    messages.add('恢复生命值 +$hpGain (${currentHp.toStringAsFixed(1)} → ${newHp.toStringAsFixed(1)})');
    
    // 随机精神值 1-10
    final sanGain = random.nextInt(10) + 1;
    final currentSan = (newStats['san'] ?? 0).toDouble();
    final maxSan = 250.0; // 精神值上限固定为250
    final newSan = (currentSan + sanGain).clamp(0, 250); // 精神值上限限制为250
    newStats['san'] = newSan;
    messages.add('恢复精神值 +$sanGain (${currentSan.toStringAsFixed(1)} → ${newSan.toStringAsFixed(1)})');
    
    // 随机饱食度 10-50
    final foodGain = random.nextInt(41) + 10; // 10-50的随机数
    final currentFood = (newStats['food'] ?? 0).toDouble();
    // 关键区域：改为使用动态 maxFood
    final double maxFood = (newStats['maxFood'] ?? 100).toDouble();
    final newFood = (currentFood + foodGain).clamp(0, maxFood);
    newStats['food'] = newFood;
    messages.add('恢复饱食度 +$foodGain (${currentFood.toStringAsFixed(1)} → ${newFood.toStringAsFixed(1)})');
    
    // 立即更新状态并强制通知UI
    
    // 创建播报消息列表
    final broadcastMessages = <BroadcastMessage>[];
    for (final message in messages) {
      broadcastMessages.add(BroadcastMessage(
        text: message,
        type: BroadcastMessageType.heal,
        timestamp: DateTime.now(),
        displayDuration: const Duration(seconds: 3),
      ));
    }
    
    // 合并现有播报消息
    final updatedMessages = List<BroadcastMessage>.from(state.broadcastMessages)
      ..addAll(broadcastMessages);
    
    // 限制消息数量
    while (updatedMessages.length > 10) {
      updatedMessages.removeAt(0);
    }
    
    // 使用copyWith确保状态更新被正确传播，一次性更新所有状态
    final oldState = state;
    state = state.copyWith(
      characterStats: newStats,
      broadcastMessages: updatedMessages,
      // 使用动画帧标识确保状态变化被检测到
      lastAnimationFrame: state.lastAnimationFrame + 1,
    );
    

  }



  /// 取消技能施法
  void cancelSkillCasting() {
    
    // 查找当前正在施法的技能
    String? castingSkillId;
    SkillState? castingSkillState;
    
    for (final entry in state.skillStates.entries) {
      if (entry.value.isCurrentlyCasting) {
        castingSkillId = entry.key;
        castingSkillState = entry.value;
        break;
      }
    }
    
    if (castingSkillId == null || castingSkillState == null) {
      return;
    }
    
    // 获取技能数据
    final skill = SkillData.getSkillById(castingSkillId);
    if (skill == null) {
      return;
    }
    
    final now = DateTime.now();
    
    // 更新技能状态：结束施法，设置一半冷却时间
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    updatedSkillStates[castingSkillId] = castingSkillState.copyWith(
      isCasting: false,
      castStartTime: null,
      lastUsedTime: now, // 设置为当前时间，这样冷却时间会是一半
    );
    
    // 更新游戏状态
    state = state.copyWith(
      skillStates: updatedSkillStates,
      currentCastingSkillId: null,
      castingProgress: 0.0,
    );
    
    // 添加取消施法的播报消息
    addBroadcastMessage(
      '取消施法: ${skill.name}（冷却时间减半）',
      BroadcastMessageType.system,
    );
  }

  /// 更新技能冷却状态和施法进度
  void _updateSkillCooldowns() {
    final now = DateTime.now();
    bool hasUpdates = false;
    final updatedSkillStates = Map<String, SkillState>.from(state.skillStates);
    String? currentCastingSkillId;
    double castingProgress = 0.0;
    
    // 检查所有技能的冷却状态和施法进度
    updatedSkillStates.forEach((skillId, skillState) {
      // 检查施法进度
      if (skillState.isCurrentlyCasting && skillState.castStartTime != null) {
        final skill = SkillData.getSkillById(skillId);
        if (skill != null) {
          final castDuration = Duration(seconds: skill.castTimeSeconds);
          final elapsed = now.difference(skillState.castStartTime!);
          final progress = (elapsed.inMilliseconds / castDuration.inMilliseconds).clamp(0.0, 1.0);
          
          currentCastingSkillId = skillId;
          castingProgress = progress;
          hasUpdates = true;
          
          // 如果施法时间已完成，这里不处理，让定时器处理
        }
      }
      // 如果技能正在冷却中，检查是否已经冷却完成
      if (skillState.lastUsedTime != null) {
        final skill = SkillData.getSkillById(skillId);
        if (skill != null) {
          final timeSinceLastUse = now.difference(skillState.lastUsedTime!);
          final cooldownDuration = Duration(seconds: skill.cooldownSeconds);
          
          // 检查冷却状态变化，强制更新UI以显示倒计时
          hasUpdates = true; // 始终标记为有更新，确保UI能显示实时倒计时
          
          // 如果冷却时间已过，可以清除lastUsedTime（可选）
          if (timeSinceLastUse >= cooldownDuration && skillState.lastUsedTime != null) {
            // 技能冷却完成，可以选择清除lastUsedTime或保留用于UI显示
            // 这里我们保留lastUsedTime，让UI层决定如何显示
          }
        }
      }
    });
    
    // 强制更新状态以触发UI刷新，确保技能倒计时和施法进度能实时显示
    if (hasUpdates || state.skillStates.isNotEmpty) {
      // 通过更新一个时间戳来强制触发UI刷新
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        skillStates: updatedSkillStates,
        currentCastingSkillId: currentCastingSkillId,
        castingProgress: castingProgress,
        lastAnimationFrame: currentTime, // 使用动画帧计数器来触发UI更新
      );
    }
  }
  
  /// 获取技能状态（用于UI显示）
  SkillState? getSkillState(String skillId) {
    return state.skillStates[skillId];
  }
  
  /// 获取角色的技能列表
  List<Skill> getCharacterSkills() {
    return state.characterSkills;
  }



  /// 获取物品使用剩余时间（秒）
  double getItemUsageRemainingTime() {
    if (!state.isUsingItem || state.currentUsingItem == null || state.itemUsageStartTime == null) {
      return 0.0;
    }
    
    final item = state.currentUsingItem!;
    final totalDuration = Duration(milliseconds: item.usageTime);
    final elapsed = DateTime.now().difference(state.itemUsageStartTime!);
    final remaining = totalDuration - elapsed;
    
    return remaining.inMilliseconds > 0 ? remaining.inMilliseconds / 1000.0 : 0.0;
  }

  /// 获取宝箱探索剩余时间（秒）
  double getChestExplorationRemainingTime() {
    if (!state.isExploringChest || state.chestExplorationStartTime == null) {
      return 0.0;
    }
    
    const totalDuration = Duration(seconds: 3); // 宝箱探索需要3秒
    final elapsed = DateTime.now().difference(state.chestExplorationStartTime!);
    final remaining = totalDuration - elapsed;
    
    return remaining.inMilliseconds > 0 ? remaining.inMilliseconds / 1000.0 : 0.0;
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _visionUpdateTimer?.cancel();
    _smoothVisionTimer?.cancel();
    _unstuckTimer?.cancel();
    _hungerTimer?.cancel();
    _skillCooldownTimer?.cancel();
    _gameLoopTimer?.cancel();
    _deathCheckTimer?.cancel();
    _itemUsageTimer?.cancel();
    _chestExplorationTimer?.cancel();
    _shopRefreshTimer?.cancel();
    _itemSpawnTimer?.cancel();
    _ghostUpdateTimer?.cancel();
    _ghostSpawnTimer?.cancel();
    _oxygenRecoveryTimer?.cancel(); // 关键区域：取消匿名恢复完成定时器，避免 dispose 后仍更新状态
    super.dispose();
  }

  /// 启动氧气恢复进度条
  void _startOxygenRecovery(double fromOxygen, double toOxygen) {
    // 首先启动氧气系统的内置恢复机制
    _oxygenSystem?.forceStartRecovery();
    
    // 启动氧气恢复管理器（视觉进度条）
    state.oxygenRecoveryManager?.startRecovery(
      startOxygen: fromOxygen,
      targetOxygen: toOxygen,
      duration: const Duration(seconds: 3), // 3秒恢复时间
      onProgress: (currentOxygen) {
        // 关键区域：在 Notifier 被销毁后避免继续更新状态
        if (!mounted) return;
        // 更新游戏状态中的当前氧气值
        state = state.copyWith(currentOxygen: currentOxygen);
        // 同步到氧气系统（如果存在）
        _oxygenSystem?.setCurrentOxygen(currentOxygen);
      },
    );
    
    // 设置恢复完成后的回调（关键：改为成员定时器并在 dispose 中取消）
    _oxygenRecoveryTimer?.cancel();
    _oxygenRecoveryTimer = Timer(const Duration(seconds: 3), () {
      // 关键区域：在 Notifier 被销毁后避免继续更新状态
      if (!mounted) return;
      // 恢复完成，确保氧气值达到上限
      state = state.copyWith(currentOxygen: toOxygen);
      _oxygenSystem?.setCurrentOxygen(toOxygen);
      state.oxygenRecoveryManager?.completeRecovery();
    });
  }

  /// 增加氧气上限
  void increaseOxygenCapacity(double amount) {
    state = state.copyWith(
      oxygenBonus: state.oxygenBonus + amount,
    );
    
    // 更新氧气系统的最大氧气值（setMaxOxygen会自动处理当前氧气值的调整）
    _oxygenSystem?.setMaxOxygen(state.actualMaxOxygen);
    
    // 同步游戏状态中的当前氧气值
    state = state.copyWith(
      currentOxygen: _oxygenSystem?.currentOxygen ?? state.currentOxygen,
    );
  }
}

/// 优化的游戏状态提供者
final optimizedGameStateProvider = StateNotifierProvider<OptimizedGameStateNotifier, OptimizedGameState>((ref) {
  // 关键区域：默认provider使用“无鬼生成”版本，避免产生重复的鬼生成定时器
  return OptimizedGameStateNotifier.noGhost(manData[0]);
});

/// 优化的玩家位置提供者
final optimizedPlayerPositionProvider = Provider<OptimizedPlayerPosition>((ref) {
  return ref.watch(optimizedGameStateProvider).playerPosition;
});

/// 优化的移动状态提供者
final optimizedMovementStateProvider = Provider<OptimizedMovementState>((ref) {
  return ref.watch(optimizedGameStateProvider).movementState;
});

/// 优化的可见区域提供者
final optimizedVisibleTilesProvider = Provider<Set<Point<int>>>((ref) {
  return ref.watch(optimizedGameStateProvider).visibleTiles;
});
// 关键区域：攻击模式枚举（近战/远程）
enum AttackMode { melee, ranged }

// 关键区域：攻击模板（颜色、攻击距离、范围）
class AttackTemplate {
  final ui.Color color;
  final double distance;
  final double range;
  const AttackTemplate({
    required this.color,
    required this.distance,
    required this.range,
  });
}

class Projectile {
  final DateTime startTime;
  final double angle;
  const Projectile({
    required this.startTime,
    required this.angle,
  });
}

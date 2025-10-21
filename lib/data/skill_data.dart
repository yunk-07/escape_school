/**
 * 技能系统数据配置文件
 * 
 * 此文件定义了游戏中技能系统的相关数据结构，包括：
 * - 技能类型枚举
 * - 技能数据类
 * - 技能效果类
 * - 角色技能配置
 */

import 'dart:math';

/// 技能类型枚举
enum SkillType {
  cooking,    // 烹饪技能
  healing,    // 治疗技能
  combat,     // 战斗技能
  utility,    // 实用技能
}

/// 技能效果范围类
class EffectRange {
  final int min;
  final int max;

  const EffectRange(this.min, this.max);

  /// 生成随机值
  int generateValue() {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }
}

/// 技能效果类
class SkillEffect {
  final EffectRange? healthRestore;     // 恢复生命值范围
  final EffectRange? sanityRestore;     // 恢复精神值范围
  final EffectRange? foodRestore;       // 恢复饱食度范围
  final EffectRange? goldGain;          // 获得金币范围
  final EffectRange? damage;            // 造成伤害范围

  const SkillEffect({
    this.healthRestore,
    this.sanityRestore,
    this.foodRestore,
    this.goldGain,
    this.damage,
  });

  /// 应用技能效果，返回实际效果值
  Map<String, int> apply() {
    final result = <String, int>{};

    if (healthRestore != null) {
      result['health'] = healthRestore!.generateValue();
    }

    if (sanityRestore != null) {
      result['sanity'] = sanityRestore!.generateValue();
    }

    if (foodRestore != null) {
      result['food'] = foodRestore!.generateValue();
    }

    if (goldGain != null) {
      result['gold'] = goldGain!.generateValue();
    }

    if (damage != null) {
      result['damage'] = damage!.generateValue();
    }

    return result;
  }
}

/// 技能数据类
class Skill {
  final String id;              // 技能ID
  final String name;            // 技能名称
  final String description;     // 技能描述
  final SkillType type;         // 技能类型
  final int cooldownSeconds;    // 冷却时间（秒）
  final int castTimeSeconds;    // 施法时间（秒）
  final SkillEffect effect;     // 技能效果
  final String? iconPath;       // 技能图标路径
  final bool canMoveWhileCasting; // 施法时是否可以移动

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cooldownSeconds,
    required this.castTimeSeconds,
    required this.effect,
    this.iconPath,
    this.canMoveWhileCasting = false, // 默认不可移动
  });
}

/// 技能状态类（用于跟踪冷却和施法状态）
class SkillState {
  final String skillId;
  final DateTime? lastUsedTime;     // 上次使用时间
  final DateTime? castStartTime;    // 开始施法时间
  final bool isCasting;             // 是否正在施法

  const SkillState({
    required this.skillId,
    this.lastUsedTime,
    this.castStartTime,
    this.isCasting = false,
  });

  /// 检查技能是否在冷却中
  bool isOnCooldown(int cooldownSeconds) {
    if (lastUsedTime == null) return false;
    final now = DateTime.now();
    final cooldownEnd = lastUsedTime!.add(Duration(seconds: cooldownSeconds));
    return now.isBefore(cooldownEnd);
  }

  /// 获取剩余冷却时间（秒）
  int getRemainingCooldown(int cooldownSeconds) {
    if (!isOnCooldown(cooldownSeconds)) return 0;
    final now = DateTime.now();
    final cooldownEnd = lastUsedTime!.add(Duration(seconds: cooldownSeconds));
    return cooldownEnd.difference(now).inSeconds;
  }

  /// 检查是否正在施法
  bool get isCurrentlyCasting => isCasting && castStartTime != null;

  /// 获取剩余施法时间（秒）
  int getRemainingCastTime(int castTimeSeconds) {
    if (!isCurrentlyCasting) return 0;
    final now = DateTime.now();
    final castEnd = castStartTime!.add(Duration(seconds: castTimeSeconds));
    return castEnd.difference(now).inSeconds.clamp(0, castTimeSeconds);
  }

  /// 复制并更新状态
  SkillState copyWith({
    DateTime? lastUsedTime,
    DateTime? castStartTime,
    bool? isCasting,
  }) {
    return SkillState(
      skillId: skillId,
      lastUsedTime: lastUsedTime ?? this.lastUsedTime,
      castStartTime: castStartTime ?? this.castStartTime,
      isCasting: isCasting ?? this.isCasting,
    );
  }
}

/// 预定义技能数据
class SkillData {
  /// 烹饪技能
  static const cooking = Skill(
    id: 'cooking',
    name: '烹饪',
    description: '制作美味的食物，恢复饱食度、生命值和精神值',
    type: SkillType.cooking,
    cooldownSeconds: 60,
    castTimeSeconds: 6,
    effect: SkillEffect(
      foodRestore: EffectRange(10, 60),    // 随机恢复10-60饱食度
      healthRestore: EffectRange(1, 10),   // 随机恢复1-10生命值
      sanityRestore: EffectRange(1, 10),   // 随机恢复1-10精神值
    ),
    canMoveWhileCasting: false, // 烹饪时不可移动
  );

  /// 获取所有技能
  static List<Skill> getAllSkills() {
    return [cooking];
  }

  /// 根据ID获取技能
  static Skill? getSkillById(String id) {
    try {
      return getAllSkills().firstWhere((skill) => skill.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// 角色技能配置
class CharacterSkills {
  static const Map<String, List<String>> characterSkillMap = {
    '厨师': ['cooking'],
    '已经困了': [],
    '速度之王': [],
  };

  /// 获取角色的技能列表
  static List<Skill> getSkillsForCharacter(String characterName) {
    final skillIds = characterSkillMap[characterName] ?? [];
    return skillIds.map((id) => SkillData.getSkillById(id)!).toList();
  }
}
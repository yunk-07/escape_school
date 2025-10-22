// time.dart
// 游戏时间计算工具类 - 处理游戏内时间与现实时间的转换

class GameTime {
  // 游戏时间转换比例：1分钟现实时间 = 1小时游戏时间
  static const int _minutesToHours = 1;
  
  /// 将游戏运行的毫秒数转换为游戏内时间
  /// [gameTimeMs] 游戏运行的毫秒数
  /// 返回格式化的时间字符串
  static String formatGameTime(int gameTimeMs) {
    // 将毫秒转换为分钟（现实时间）
    double realMinutes = gameTimeMs / (1000 * 60);
    
    // 1分钟现实时间 = 1小时游戏时间
    double gameHours = realMinutes * _minutesToHours;
    
    // 计算游戏内的天、小时、分钟
    int days = gameHours.floor() ~/ 24;
    int hours = gameHours.floor() % 24;
    int minutes = ((gameHours - gameHours.floor()) * 60).floor();
    
    // 格式化输出
    if (days > 0) {
      return '${days}天${hours}小时${minutes}分钟';
    } else if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else {
      return '${minutes}分钟';
    }
  }
  
  /// 获取简化的生存时间显示
  /// [gameTimeMs] 游戏运行的毫秒数
  /// 返回简化格式的时间字符串
  static String formatSurvivalTime(int gameTimeMs) {
    double realMinutes = gameTimeMs / (1000 * 60);
    double gameHours = realMinutes * _minutesToHours;
    
    int days = gameHours.floor() ~/ 24;
    int hours = gameHours.floor() % 24;
    int minutes = ((gameHours - gameHours.floor()) * 60).floor();
    
    if (days > 0) {
      return '${days}天${hours}时';
    } else if (hours > 0) {
      return '${hours}时${minutes}分';
    } else if (minutes > 0) {
      return '${minutes}分钟';
    } else {
      return '不足1分钟';
    }
  }
  
  /// 将游戏时间转换为详细的时间信息
  /// [gameTimeMs] 游戏运行的毫秒数
  /// 返回包含天、小时、分钟的Map
  static Map<String, int> getDetailedTime(int gameTimeMs) {
    double realMinutes = gameTimeMs / (1000 * 60);
    double gameHours = realMinutes * _minutesToHours;
    
    int days = gameHours.floor() ~/ 24;
    int hours = gameHours.floor() % 24;
    int minutes = ((gameHours - gameHours.floor()) * 60).floor();
    
    return {
      'days': days,
      'hours': hours,
      'minutes': minutes,
    };
  }
}
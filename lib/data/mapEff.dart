// 地形效果数据
class MapEff {
  static const terrainEffects = {
    'grass': {
      'explore': [
        {'text': '在草丛中发现了一些草药！生命值+5', 'hp': 5},
        {'text': '发现了一些野果！饱食度+3', 'food': 3},
        {'text': '什么也没发现...', 'hp': 0},
      ],
      'move': {'food': -1, 'san': 0},
    },
    'path': {
      'explore': [
        {'text': '在路上捡到了金币！金币+10', 'gold': 10},
        {'text': '遇到商人交易获得金币！金币+15', 'gold': 15},
        {'text': '被路过的旅人帮助，精神值+5', 'san': 5},
      ],
      'move': {'food': -0.5, 'san': 0},
    },
    'woods': {
      'explore': [
        {'text': '在树林中采集了蘑菇！饱食度+5', 'food': 5},
        {'text': '被野生动物惊吓，精神值-3', 'san': -3},
        {'text': '发现了一个隐藏的宝箱！金币+20', 'gold': 20},
      ],
      'move': {'food': -2, 'san': -1},
    },
    'building': {
      'explore': [
        {'text': '在建筑内找到了补给！生命值+10，饱食度+5', 'hp': 10, 'food': 5},
        {'text': '发现了一个宝箱！金币+30', 'gold': 30},
        {'text': '在书架上发现了一本有趣的书，精神值+8', 'san': 8},
      ],
      'move': {'food': -1, 'san': 1},
    },
    'water': {
      'explore': {'text': '在水中无法进行探索'},
      'move': {'text': '无法进入水中'},
    },
    'wall': {
      'explore': {'text': '墙壁无法探索'},
      'move': {'text': '无法穿过墙壁'},
    },
  };
}
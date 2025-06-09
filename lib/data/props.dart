// data/props.dart
class Item {
  final String id;
  final String name;
  final String image;
  final String description;
  final Map<String, int> effects; // {hp: 10, gold: 5}
  final String type; // 新增：物品类型
  final int count;   // 新增：物品数量
  final bool availableInShop; // 新增：是否在商店出售
  final int basePrice;       // 新增：基础价格

  Item({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.effects,
    this.type = 'misc', // 默认类型
    this.count = 1,
    this.availableInShop = false, // 默认不在商店出售
    this.basePrice = 0,
  });
}

final List<Item> allItems = [
  Item(
    id: 'hanbao',
    name: '美去人通便汉堡',
    image: 'images/items/hanbao.png',
    description: '钻研肠胃科主任为何把最灵的药藏在这里',
    effects: {'hp': -2,'food': 20},
    type: 'potion',
    availableInShop: false,
    basePrice: 16
  ),
  Item(
    id: 'fish01',
    name: '半生不熟鱼',
    image: 'images/items/fish01.png',
    description: '苦心钻研匠心制造还没煮熟的鱼',
    effects: {'hp': -5,'food':10,'san':-5,'att':-1},
    type: 'potion',
    availableInShop: true,
    basePrice: 8
  ),
  Item(
    id: 'fish02',
    name: '熟鱼',
    image: 'images/items/fish02.png',
    description: '30年阳寿换来一条煮熟的鱼',
    effects: {'hp': -30,'food':50,'san':20},
    type: 'potion',
    availableInShop: true,
    basePrice: 12
  ),
  Item(
    id: 'fish03',
    name: '尘封已久的鱼',
    image: 'images/items/fish03.png',
    description: '这样吃了没事吧？反正举报也没用管他的',
    effects: {'hp': -10,'food':5,'san':-15,'att':-1},
    type: 'potion',
    availableInShop: true,
    basePrice: 8
  ),
];
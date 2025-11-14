class Zone {
  final String name;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  const Zone({required this.name, required this.minX, required this.maxX, required this.minY, required this.maxY});
}

const List<Zone> kZones = [
  Zone(name: '商会', minX: 1, maxX: 12, minY: 3, maxY: 12),
  Zone(name: '西区女生宿舍', minX: 1, maxX: 12, minY: 16, maxY: 18),
  Zone(name: '西区男生宿舍B', minX: 3, maxX: 12, minY: 23, maxY: 30),
  Zone(name: '西区男生宿舍A', minX: 3, maxX: 12, minY: 34, maxY: 41),
  Zone(name: '西区停车棚', minX: 3, maxX: 13, minY: 44, maxY: 49),
  Zone(name: 'VR机房', minX: 25, maxX: 32, minY: 44, maxY: 47),
  Zone(name: '教学楼', minX: 22, maxX: 34, minY: 26, maxY: 40),
  Zone(name: '西区体育馆', minX: 45, maxX: 51, minY: 23,maxY: 29),
  Zone(name: '行政楼', minX: 55, maxX: 77, minY: 35,maxY: 41),
  Zone(name: '西区超市', minX: 18, maxX: 23, minY: 4,maxY: 14),
  Zone(name: '西区食堂', minX: 24, maxX: 31, minY: 4,maxY: 13),
  Zone(name: '智能制造区', minX: 39, maxX: 50, minY: 4,maxY: 7),
  Zone(name: '车间', minX: 51, maxX: 54, minY: 4,maxY: 7),
  Zone(name: '器材室', minX: 57, maxX: 61, minY: 4,maxY: 7),
  Zone(name: '操场厕所', minX: 57, maxX: 61, minY: 10,maxY: 14),
  Zone(name: '西区篮球场', minX: 35, maxX: 54, minY: 10,maxY: 19),
  Zone(name: '操场', minX: 64, maxX: 77, minY: 3,maxY: 31),
  Zone(name: '东区篮球场', minX: 78, maxX: 87, minY: 22,maxY: 32),
  Zone(name: '东区足球场', minX: 78, maxX: 87, minY: 15,maxY: 20),
  Zone(name: '东区食堂', minX: 91, maxX: 101, minY: 2,maxY: 9),
  Zone(name: '东区宿舍B', minX: 90, maxX: 99, minY: 15,maxY: 22),
  Zone(name: '东区宿舍A', minX: 90, maxX: 99, minY: 23,maxY: 30),
  Zone(name: '东区教学楼', minX: 91, maxX: 99, minY: 35,maxY: 37),
  Zone(name: '保安亭', minX: 71, maxX: 76, minY: 46,maxY: 50),
  Zone(name: '东区体育馆', minX: 85, maxX: 88, minY: 35,maxY: 41),
  Zone(name: '商务基地', minX: 80, maxX: 90, minY: 44,maxY: 47),
  Zone(name: '校长办公室', minX: 59, maxX: 63, minY: 39,maxY: 41),
];

String? getZoneNameAt(int x, int y) {
  for (final z in kZones) {
    if (x >= z.minX && x <= z.maxX && y >= z.minY && y <= z.maxY) {
      return z.name;
    }
  }
  return null;
}
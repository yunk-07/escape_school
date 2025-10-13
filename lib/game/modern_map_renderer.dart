import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../data/props.dart';
import '../data/shop.dart';
import '../data/character_config.dart';

/// 现代化地图渲染器
/// 使用CustomPainter和RepaintBoundary优化性能，支持图片贴图
class ModernMapRenderer extends StatefulWidget {
  final double playerX;
  final double playerY;
  final int horizontalTiles;
  final int verticalTiles;
  final List<List<String>> map;
  final List<List<bool>> visibleMap;
  final Set<Point<int>> visibleTiles;
  final List<Point<int>> chestPositions;
  final Shop? schoolShop;
  final Map<String, String> terrainImages;
  final CharacterConfig characterConfig;
  final VoidCallback? onOpenChest;
  final VoidCallback? onOpenShop;

  const ModernMapRenderer({
    Key? key,
    required this.playerX,
    required this.playerY,
    required this.horizontalTiles,
    required this.verticalTiles,
    required this.map,
    required this.visibleMap,
    required this.visibleTiles,
    required this.chestPositions,
    this.schoolShop,
    required this.terrainImages,
    required this.characterConfig,
    this.onOpenChest,
    this.onOpenShop,
  }) : super(key: key);

  @override
  State<ModernMapRenderer> createState() => _ModernMapRendererState();
}

class _ModernMapRendererState extends State<ModernMapRenderer> {
  final Map<String, ui.Image> _loadedImages = {};
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      // 加载地形贴图
      final terrainTypes = ['grass', 'wall', 'water', 'woods', 'path', 'building'];
      for (String terrain in terrainTypes) {
        final image = await _loadImage('images/map/$terrain.png');
        if (image != null) {
          _loadedImages[terrain] = image;
        }
      }
      
      // 加载特殊物品贴图
      final chestImage = await _loadImage('images/map/chest.png');
      if (chestImage != null) {
        _loadedImages['chest'] = chestImage;
      }
      
      final shopImage = await _loadImage('images/map/shop.png');
      if (shopImage != null) {
        _loadedImages['shop'] = shopImage;
      }
      
      // 加载玩家贴图（根据角色配置）
      final playerImage = await _loadImage(widget.characterConfig.imagePath);
      if (playerImage != null) {
        _loadedImages['player'] = playerImage;
      }

      setState(() {
        _imagesLoaded = true;
      });
    } catch (e) {
      print('加载图片时出错: $e');
      setState(() {
        _imagesLoaded = true; // 即使出错也设置为true，使用颜色块作为后备
      });
    }
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await DefaultAssetBundle.of(context).load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('无法加载图片 $assetPath: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_imagesLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕尺寸动态计算瓦片大小
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final tileSize = min(screenWidth / widget.horizontalTiles, screenHeight / widget.verticalTiles);
        
        return RepaintBoundary(
          child: CustomPaint(
            painter: MapPainter(
              playerX: widget.playerX,
              playerY: widget.playerY,
              horizontalTiles: widget.horizontalTiles,
              verticalTiles: widget.verticalTiles,
              map: widget.map,
              visibleMap: widget.visibleMap,
              visibleTiles: widget.visibleTiles,
              chestPositions: widget.chestPositions,
              schoolShop: widget.schoolShop,
              terrainImages: widget.terrainImages,
              characterConfig: widget.characterConfig,
              loadedImages: _loadedImages,
              tileSize: tileSize,
            ),
            size: Size(screenWidth, screenHeight),
          ),
        );
      },
    );
  }
}

class MapPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final int horizontalTiles;
  final int verticalTiles;
  final List<List<String>> map;
  final List<List<bool>> visibleMap;
  final Set<Point<int>> visibleTiles;
  final List<Point<int>> chestPositions;
  final Shop? schoolShop;
  final Map<String, String> terrainImages;
  final CharacterConfig characterConfig;
  final Map<String, ui.Image> loadedImages;
  final double tileSize;

  late final Paint _tilePaint;
  late final Paint _gridPaint;
  late final Paint _playerPaint;
  late final Paint _chestPaint;
  late final Paint _shopPaint;

  MapPainter({
    required this.playerX,
    required this.playerY,
    required this.horizontalTiles,
    required this.verticalTiles,
    required this.map,
    required this.visibleMap,
    required this.visibleTiles,
    required this.chestPositions,
    this.schoolShop,
    required this.terrainImages,
    required this.characterConfig,
    required this.loadedImages,
    required this.tileSize,
  }) {
    _tilePaint = Paint()..style = PaintingStyle.fill;
    _gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    _playerPaint = Paint()..style = PaintingStyle.fill;
    _chestPaint = Paint()..color = Colors.amber;
    _shopPaint = Paint()..color = Colors.green;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 计算地图偏移
    final mapOffsetX = (playerX - playerX.round()) * tileSize;
    final mapOffsetY = (playerY - playerY.round()) * tileSize;

    // 计算可见区域
    final startX = playerX.round() - horizontalTiles ~/ 2;
    final startY = playerY.round() - verticalTiles ~/ 2;
    final endX = startX + horizontalTiles;
    final endY = startY + verticalTiles;

    // 绘制地形
    _drawTerrain(canvas, startX, startY, endX, endY, mapOffsetX, mapOffsetY);
    
    // 绘制网格
    _drawGrid(canvas, mapOffsetX, mapOffsetY);
    
    // 绘制物品
    _drawItems(canvas, startX, startY, endX, endY, mapOffsetX, mapOffsetY);
    
    // 绘制玩家
    _drawPlayer(canvas, mapOffsetX, mapOffsetY);
  }

  void _drawTerrain(Canvas canvas, int startX, int startY, int endX, int endY, 
                   double offsetX, double offsetY) {
    // 调试输出
    if (kDebugMode && visibleTiles.isNotEmpty) {
      print('渲染地形: visibleTiles数量=${visibleTiles.length}, 前5个=${visibleTiles.take(5).toList()}');
    }
    
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final screenX = (x - startX) * tileSize - offsetX;
        final screenY = (y - startY) * tileSize - offsetY;
        
        // 检查是否在地图范围内
        if (x >= 0 && x < map[0].length && y >= 0 && y < map.length) {
          final terrain = map[y][x];
          final isVisible = visibleTiles.contains(Point(x, y));
          
          // 只显示当前圆形视野内的地形，视野外完全不可见
          if (isVisible) {
            _drawTerrainTile(canvas, terrain, screenX, screenY, 1.0);
          }
        } else {
          // 地图外区域绘制为黑色
          _tilePaint.color = Colors.black;
          canvas.drawRect(
            Rect.fromLTWH(screenX, screenY, tileSize, tileSize),
            _tilePaint,
          );
        }
      }
    }
  }

  void _drawTerrainTile(Canvas canvas, String terrain, double x, double y, double opacity) {
    final rect = Rect.fromLTWH(x, y, tileSize, tileSize);
    
    // 尝试使用图片贴图
    if (loadedImages.containsKey(terrain)) {
      final image = loadedImages[terrain]!;
      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint,
      );
    } else {
      // 后备颜色方案
      Color tileColor;
      switch (terrain) {
        case 'wall':
          tileColor = Colors.grey[800]!;
          break;
        case 'grass':
          tileColor = Colors.green[300]!;
          break;
        case 'woods':
          tileColor = Colors.green[700]!;
          break;
        case 'water':
          tileColor = Colors.blue[400]!;
          break;
        case 'path':
          tileColor = Colors.brown[300]!;
          break;
        case 'building':
          tileColor = Colors.grey[600]!;
          break;
        default:
          tileColor = Colors.grey[400]!;
      }

      _tilePaint.color = tileColor.withOpacity(opacity);
      canvas.drawRect(rect, _tilePaint);
    }
  }

  void _drawGrid(Canvas canvas, double offsetX, double offsetY) {
    // 绘制垂直线
    for (int i = 0; i <= horizontalTiles; i++) {
      final x = i * tileSize - offsetX;
      canvas.drawLine(
        Offset(x, -offsetY),
        Offset(x, verticalTiles * tileSize - offsetY),
        _gridPaint,
      );
    }

    // 绘制水平线
    for (int i = 0; i <= verticalTiles; i++) {
      final y = i * tileSize - offsetY;
      canvas.drawLine(
        Offset(-offsetX, y),
        Offset(horizontalTiles * tileSize - offsetX, y),
        _gridPaint,
      );
    }
  }

  void _drawItems(Canvas canvas, int startX, int startY, int endX, int endY,
                 double offsetX, double offsetY) {
    // 绘制宝箱
    for (final chestPos in chestPositions) {
      if (chestPos.x >= startX && chestPos.x < endX &&
          chestPos.y >= startY && chestPos.y < endY &&
          visibleTiles.contains(chestPos)) {
        final screenX = (chestPos.x - startX) * tileSize - offsetX;
        final screenY = (chestPos.y - startY) * tileSize - offsetY;
        
        // 尝试使用宝箱贴图
        if (loadedImages.containsKey('chest')) {
          final image = loadedImages['chest']!;
          
          // 计算保持宽高比的显示尺寸
          final imageAspectRatio = image.width / image.height;
          double displayWidth, displayHeight;
          
          if (imageAspectRatio > 1.0) {
            // 宽图：以宽度为准
            displayWidth = tileSize;
            displayHeight = tileSize / imageAspectRatio;
          } else {
            // 高图或正方形：以高度为准
            displayHeight = tileSize;
            displayWidth = tileSize * imageAspectRatio;
          }
          
          // 居中显示
          final centerX = screenX + tileSize / 2;
          final centerY = screenY + tileSize / 2;
          final drawX = centerX - displayWidth / 2;
          final drawY = centerY - displayHeight / 2;
          
          final rect = Rect.fromLTWH(drawX, drawY, displayWidth, displayHeight);
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            rect,
            Paint(),
          );
        } else {
          // 后备方案：绘制圆形
          canvas.drawCircle(
            Offset(screenX + tileSize * 0.5, screenY + tileSize * 0.5),
            tileSize * 0.3,
            _chestPaint,
          );
        }
      }
    }

    // 绘制商店
    if (schoolShop != null) {
      final shopPos = schoolShop!.position;
      if (shopPos.x >= startX && shopPos.x < endX &&
          shopPos.y >= startY && shopPos.y < endY &&
          visibleTiles.contains(Point(shopPos.x.toInt(), shopPos.y.toInt()))) {
        final screenX = (shopPos.x - startX) * tileSize - offsetX;
        final screenY = (shopPos.y - startY) * tileSize - offsetY;
        
        // 尝试使用商店贴图
        if (loadedImages.containsKey('shop')) {
          final image = loadedImages['shop']!;
          
          // 计算保持宽高比的显示尺寸
          final imageAspectRatio = image.width / image.height;
          double displayWidth, displayHeight;
          
          if (imageAspectRatio > 1.0) {
            // 宽图：以宽度为准
            displayWidth = tileSize;
            displayHeight = tileSize / imageAspectRatio;
          } else {
            // 高图或正方形：以高度为准
            displayHeight = tileSize;
            displayWidth = tileSize * imageAspectRatio;
          }
          
          // 居中显示
          final centerX = screenX + tileSize / 2;
          final centerY = screenY + tileSize / 2;
          final drawX = centerX - displayWidth / 2;
          final drawY = centerY - displayHeight / 2;
          
          final rect = Rect.fromLTWH(drawX, drawY, displayWidth, displayHeight);
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            rect,
            Paint(),
          );
        } else {
          // 后备方案：绘制矩形
          canvas.drawRect(
            Rect.fromLTWH(screenX + tileSize * 0.1, screenY + tileSize * 0.1, 
                         tileSize * 0.8, tileSize * 0.8),
            _shopPaint,
          );
        }
      }
    }
  }

  void _drawPlayer(Canvas canvas, double offsetX, double offsetY) {
    // 计算玩家在屏幕上的位置（始终在屏幕中心）
    final screenX = (horizontalTiles / 2) * tileSize - tileSize / 2;
    final screenY = (verticalTiles / 2) * tileSize - tileSize / 2;
    
    // 使用角色配置中的缩放比例
    final characterSizeScale = characterConfig.sizeScale;
    
    // 尝试使用玩家贴图
    if (loadedImages.containsKey('player')) {
      final image = loadedImages['player']!;
      
      // 统一所有角色贴图为正方形大小，不保持宽高比（允许扭曲）
      // 这确保所有角色的碰撞检测大小一致
      final uniformSize = tileSize * characterSizeScale;
      
      // 居中显示，应用角色配置的偏移量
      final centerX = screenX + tileSize / 2 + characterConfig.spriteOffsetX;
      final centerY = screenY + tileSize / 2 + characterConfig.spriteOffsetY;
      final drawX = centerX - uniformSize / 2;
      final drawY = centerY - uniformSize / 2;
      
      final rect = Rect.fromLTWH(drawX, drawY, uniformSize, uniformSize);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint(),
      );
    } else {
      // 后备方案：绘制蓝色圆形，使用角色配置的缩放比例
      _playerPaint.color = Colors.blue;
      canvas.drawCircle(
        Offset(
          screenX + tileSize / 2 + characterConfig.spriteOffsetX, 
          screenY + tileSize / 2 + characterConfig.spriteOffsetY
        ),
        tileSize * characterSizeScale * 0.4,
        _playerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.playerX != playerX ||
           oldDelegate.playerY != playerY ||
           oldDelegate.visibleTiles != visibleTiles ||
           oldDelegate.chestPositions != chestPositions ||
           oldDelegate.schoolShop != schoolShop;
  }
}
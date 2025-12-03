import 'package:flutter/material.dart';

/// 扇形轮播组件：用于展示物品卡片，支持扇形排列和动画效果
///
/// 主要功能和使用方法：
/// 1. items：要展示的物品列表，每个元素是一个Widget
/// 2. initialPage：初始选中的页面索引
/// 3. onItemChanged：选中项改变时的回调函数
///
/// 内部键说明：
/// - _currentIndex：当前选中的卡片索引
/// - _animationController：控制卡片切换的动画控制器

/**
 * 扇形轮盘组件库
 * 提供两种主要组件：FanCarousel 和 FanFilter
 * 
 * 使用方法：
 * 1. FanCarousel - 用于展示卡片式内容的轮播组件
 *    参数说明：
 *    - items: 要展示的组件列表
 *    - onItemChanged: 当选中项改变时的回调函数
 *    - itemWidth: 卡片宽度，默认为120
 *    - itemHeight: 卡片高度，默认为240
 *    - fanRadius: 扇形半径，控制整体布局大小，默认为500
 *    - rotationAngle: 旋转角度，影响卡片排列，默认为60
 *    - initialPage: 初始显示的页面索引，默认为0
 * 
 * 2. FanFilter - 用于实现从屏幕边缘弹出的半圆筛选选项
 *    参数说明：
 *    - options: 选项文本列表
 *    - selectedIndex: 当前选中的选项索引
 *    - onOptionSelected: 当选项被选中时的回调函数
 *    - isLeftSide: 是否显示在屏幕左侧，true为左侧，false为右侧
 * 
 * 内部键作用：
 * - _currentIndex: 记录当前选中的卡片索引
 * - _pageController: 控制页面滚动和布局
 * - _animationController: 控制FanFilter组件的动画效果
 * - _animation: 定义FanFilter的动画曲线和值范围
 */

/// 扇形轮盘组件
/// 用于实现扇形布局的轮盘筛选和卡片轮播展示
class FanCarousel extends StatefulWidget {
  final List<Widget> items;
  final Function(int)? onItemChanged;
  final double itemWidth;
  final double itemHeight;
  final double fanRadius;
  final double rotationAngle;
  final int initialPage;

  const FanCarousel({
    super.key,
    required this.items,
    this.onItemChanged,
    this.itemWidth = 150, // 缩小卡片宽度，确保全部展示
    this.itemHeight = 250, // 缩小卡片高度，确保全部展示
    this.fanRadius = 400, // 缩小扇形半径，适应更小卡片
    this.rotationAngle = 45, // 减小旋转角度，使卡片更紧凑
    this.initialPage = 0,
  });

  @override
  State<FanCarousel> createState() => _FanCarouselState();
}

class _FanCarouselState extends State<FanCarousel> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    _pageController = PageController(
      viewportFraction: 0.3, // 减小viewportFraction，使一页能显示更多卡片
      initialPage: _currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (widget.onItemChanged != null) {
      widget.onItemChanged!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          '暂无物品',
          style: TextStyle(
            color: Color.fromRGBO(189, 189, 189, 1.0),
            fontSize: 16,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 扇形背景效果
        Container(
          width: widget.fanRadius * 2,
          height: widget.fanRadius,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 1.2, // 增大半径
              colors: [
                Color.fromRGBO(0, 0, 0, 0.5), // 加深颜色
                Color.fromRGBO(0, 0, 0, 0.2),
                Color.fromRGBO(0, 0, 0, 0.0), // 替换Colors.transparent
              ],
              stops: [0.0, 0.5, 1.0], // 添加渐变停止点
            ),
          ),
        ),

        // 卡片轮播区域
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // 增大宽度
          height: widget.fanRadius,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const PageScrollPhysics(), // 使用页面滚动物理效果，增加滑动惯性
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              // 增强扇形效果：更大的缩放和旋转
              // 添加动画效果，使卡片切换特写时有平滑过渡
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  // 计算当前页面的滚动位置
                  if (_pageController.position.hasContentDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
                  }

                  // 卡片过渡动画：缩放、旋转和阴影效果
                  final double animatedScale =
                      0.8 + (value * 0.2); // 从0.8到1.0的平滑缩放
                  final double animatedRotation = value * 0; // 旋转角度为0，保持卡片直立

                  return Transform(
                    alignment: Alignment.center,
                    transform:
                        Matrix4.identity()
                          ..scale(animatedScale)
                          ..rotateY(animatedRotation)
                          ..translate(0.0, -value * 10), // 减小上移效果，避免卡片超出范围
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12), // 增大圆角，增强现代感
                        boxShadow: [
                          // 主阴影 - 大幅增强立体感
                          BoxShadow(
                            color: Color.fromRGBO(
                              0,
                              0,
                              0,
                              value > 0.5 ? 0.9 : value * 0.8,
                            ),
                            blurRadius: value > 0.5 ? 50 : value * 25,
                            spreadRadius: value > 0.5 ? 8 : value * 3,
                            offset: Offset(0, value * 25), // 增强阴影偏移
                          ),
                          // 边缘光晕 - 增强层次感
                          if (value > 0.3)
                            BoxShadow(
                              color: Colors.white.withOpacity(
                                value > 0.5 ? 0.4 : value * 0.2,
                              ),
                              blurRadius: value > 0.5 ? 25 : value * 15,
                              spreadRadius: value > 0.5 ? 3 : value * 2,
                              offset: Offset(0, -value * 12),
                            ),
                          // 内部阴影 - 增强深度感
                          if (value > 0.5)
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                value > 0.7 ? 0.6 : value * 0.3,
                              ),
                              blurRadius: value > 0.7 ? 15 : value * 8,
                              spreadRadius: -3,
                              offset: Offset(0, value * 8),
                            ),
                          // 侧面阴影 - 增强3D效果
                          if (value > 0.5)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: Offset(value * 10, 0),
                            ),
                        ],
                      ),
                      child: widget.items[index],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 扇形筛选轮盘组件
/// 用于实现从屏幕边缘弹出的半圆筛选选项
class FanFilter extends StatefulWidget {
  final List<String> options;
  final int selectedIndex;
  final Function(int) onOptionSelected;
  final bool isLeftSide;

  const FanFilter({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onOptionSelected,
    required this.isLeftSide,
  });

  @override
  State<FanFilter> createState() => _FanFilterState();
}

class _FanFilterState extends State<FanFilter>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.selectedIndex,
      viewportFraction: 0.35, // 增大viewportFraction，使一个页面能显示3个项目
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width; // 不再使用
    final screenHeight = MediaQuery.of(context).size.height;
    final fanRadius = 150.0;

    return SizedBox(
      width: 100,
      height: screenHeight * 0.6,
      child: Stack(
        alignment:
            widget.isLeftSide ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          // 半圆背景效果
          Transform.translate(
            offset: Offset(widget.isLeftSide ? -fanRadius : fanRadius, 0),
            child: Container(
              width: fanRadius * 2,
              height: fanRadius * 2,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center:
                      widget.isLeftSide
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  radius: 1.0,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.5),
                    Color.fromRGBO(0, 0, 0, 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 垂直滑动选项列表
          SizedBox(
            width: 80,
            height: screenHeight * 0.6,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.options.length,
              onPageChanged: (index) {
                widget.onOptionSelected(index);
              },
              itemBuilder: (context, index) {
                final bool isSelected = index == widget.selectedIndex;

                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final scale = isSelected ? 1.0 : 0.8;

                    return Transform.scale(
                      scale: scale * _animation.value,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          widget.onOptionSelected(index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  isSelected
                                      ? [
                                        const Color.fromRGBO(45, 55, 72, 0.9),
                                        const Color.fromRGBO(26, 32, 44, 0.9),
                                      ]
                                      : [
                                        Color.fromRGBO(0, 0, 0, 0.4),
                                        Color.fromRGBO(0, 0, 0, 0.2),
                                      ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft:
                                  widget.isLeftSide
                                      ? Radius.zero
                                      : const Radius.circular(5),
                              bottomLeft:
                                  widget.isLeftSide
                                      ? Radius.zero
                                      : const Radius.circular(5),
                              topRight:
                                  widget.isLeftSide
                                      ? const Radius.circular(5)
                                      : Radius.zero,
                              bottomRight:
                                  widget.isLeftSide
                                      ? const Radius.circular(5)
                                      : Radius.zero,
                            ),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Color.fromRGBO(255, 193, 7, 0.8)
                                      : Color.fromRGBO(158, 158, 158, 0.4),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Color.fromRGBO(255, 193, 7, 0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.options[index],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.amber : Color(0xFFE0E0E0),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 14,
                              shadows:
                                  isSelected
                                      ? [
                                        const Shadow(
                                          color: Color(0x8A000000),
                                          blurRadius: 3,
                                          offset: Offset(1, 1),
                                        ),
                                      ]
                                      : [],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

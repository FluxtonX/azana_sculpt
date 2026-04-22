import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

enum RulerPickerStyle { barChart, traditional }

class RulerPicker extends StatefulWidget {
  final int min;
  final int max;
  final int initialValue;
  final String unit;
  final RulerPickerStyle style;
  final ValueChanged<int> onChanged;

  const RulerPicker({
    super.key,
    required this.min,
    required this.max,
    required this.initialValue,
    required this.unit,
    this.style = RulerPickerStyle.barChart,
    required this.onChanged,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late ScrollController _scrollController;
  late int _currentValue;
  late double itemWidth;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    itemWidth = widget.style == RulerPickerStyle.traditional ? 10.0 : 50.0;
    _scrollController = ScrollController(
      initialScrollOffset: (widget.initialValue - widget.min) * itemWidth,
    );
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    int newValue = widget.min + (_scrollController.offset / itemWidth).round();
    newValue = newValue.clamp(widget.min, widget.max);
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == RulerPickerStyle.traditional) {
      return _buildTraditionalRuler();
    }
    return _buildBarChartRuler();
  }

  Widget _buildBarChartRuler() {
    return SizedBox(
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Large Value Display at Top
          Positioned(
            top: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currentValue.toString(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 110,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: -4,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.unit,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5D6A78),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // 2. Bar Chart Scrollable Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.max - widget.min + 1,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 2 - 25,
              ),
              itemBuilder: (context, index) {
                final val = widget.min + index;
                final isSelected = val == _currentValue;

                // Stepped height increase every 5 units for a "ratio-based" progression
                final int steppedVal =
                    ((val - widget.min) ~/ 5) * 5 + widget.min;
                final double relativeValue =
                    (steppedVal - widget.min) / (widget.max - widget.min);
                final double barHeight = 50 + (relativeValue * 140);

                return GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      index * 50.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 50,
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // The Bar (Rounded Top, Flat Bottom)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32, // Thick bars
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : const Color(0xFFE5EBF2),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Only show the label for the CURRENTLY selected value
                          Opacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            child: Text(
                              val.toString(),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionalRuler() {
    // Each integer unit has 10 sub-ticks, each 6px wide = 60px per integer
    const double subTickWidth = 6.0;

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Large Value Display
          Positioned(
            top: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currentValue.toString(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 90,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: -3,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.unit,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D6A78),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // 2. Tick Marks Ruler
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            height: 130,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: (widget.max - widget.min) * 10 + 1,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 2 - 3,
              ),
              itemBuilder: (context, index) {
                final bool isMajor = index % 10 == 0;
                final bool isHalf = index % 5 == 0 && !isMajor;
                final int integerVal = widget.min + (index ~/ 10);

                // Tick height: major > half > minor
                final double tickHeight = isMajor ? 50 : (isHalf ? 35 : 20);
                // Tick width: major thicker
                final double tickWidth = isMajor ? 2.5 : 1.5;

                // Distance-based opacity for labels
                final int distFromSelected = (integerVal - _currentValue).abs();
                final bool isSelectedLabel = integerVal == _currentValue;
                final double labelOpacity = (1.0 - (distFromSelected * 0.15))
                    .clamp(0.3, 1.0);

                return Container(
                  width: subTickWidth,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tick mark
                      Container(
                        width: tickWidth,
                        height: tickHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBCC5D0),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Label only on major ticks
                      if (isMajor)
                        Text(
                          integerVal.toString(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isSelectedLabel ? 20 : 16,
                            fontWeight: isSelectedLabel
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSelectedLabel
                                ? AppTheme.primary
                                : Color.fromRGBO(144, 161, 180, labelOpacity),
                          ),
                        )
                      else
                        const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Center Capsule Indicator
          Positioned(
            bottom: 55,
            child: IgnorePointer(
              child: Container(
                width: 28,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

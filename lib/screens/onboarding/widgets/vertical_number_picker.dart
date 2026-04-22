import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class VerticalNumberPicker extends StatefulWidget {
  final int min;
  final int max;
  final int initialValue;
  final ValueChanged<int> onChanged;

  const VerticalNumberPicker({
    super.key,
    required this.min,
    required this.max,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<VerticalNumberPicker> createState() => _VerticalNumberPickerState();
}

class _VerticalNumberPickerState extends State<VerticalNumberPicker> {
  late FixedExtentScrollController _controller;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _controller = FixedExtentScrollController(
      initialItem: widget.initialValue - widget.min,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 80.0;
    
    return SizedBox(
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Central Peach Capsule (Fixed Background)
          Container(
            width: 180,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2F0),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
          
          // 2. Scrollable Numbers
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: itemHeight,
            perspective: 0.005,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedValue = widget.min + index;
              });
              widget.onChanged(_selectedValue);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.max - widget.min + 1,
              builder: (context, index) {
                final val = widget.min + index;
                final isSelected = val == _selectedValue;
                
                // Calculate distance for fading neighbors
                final distance = (val - _selectedValue).abs();
                final opacity = (1.0 - (distance * 0.3)).clamp(0.2, 1.0);
                
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isSelected ? 56 : 42,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected 
                          ? AppTheme.primary.withOpacity(0.8) // Darker pink for selected
                          : AppTheme.textLight.withOpacity(opacity),
                    ),
                    child: Text(val.toString()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

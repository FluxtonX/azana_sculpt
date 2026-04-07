// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Drag-to-reveal before/after photo comparison slider.
/// Pass [beforeWidget] and [afterWidget] to fill each side.
class PhotoComparisonSlider extends StatefulWidget {
  final Widget beforeWidget;
  final Widget afterWidget;
  final double height;

  const PhotoComparisonSlider({
    super.key,
    required this.beforeWidget,
    required this.afterWidget,
    this.height = 200,
  });

  @override
  State<PhotoComparisonSlider> createState() => _PhotoComparisonSliderState();
}

class _PhotoComparisonSliderState extends State<PhotoComparisonSlider> {
  double _dividerPosition = 0.5; // 0.0 = all before, 1.0 = all after

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _dividerPosition =
                  (_dividerPosition + details.delta.dx / totalWidth)
                      .clamp(0.05, 0.95);
            });
          },
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                // After (full width, behind)
                SizedBox(
                  width: totalWidth,
                  height: widget.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.afterWidget,
                  ),
                ),

                // Before (clipped to left portion)
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _dividerPosition,
                    child: SizedBox(
                      width: totalWidth,
                      height: widget.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.beforeWidget,
                      ),
                    ),
                  ),
                ),

                // Labels
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _buildLabel('BEFORE'),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _buildLabel('AFTER'),
                ),

                // Divider line
                Positioned(
                  left: totalWidth * _dividerPosition - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2.5,
                    color: Colors.white,
                  ),
                ),

                // Drag handle
                Positioned(
                  left: totalWidth * _dividerPosition - 18,
                  top: widget.height / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Positioned(
                  left: totalWidth * _dividerPosition - 2,
                  top: widget.height / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

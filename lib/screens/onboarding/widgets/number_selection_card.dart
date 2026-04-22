import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class NumberSelectionCard extends StatelessWidget {
  final int number;
  final bool isSelected;
  final VoidCallback onTap;

  const NumberSelectionCard({
    super.key,
    required this.number,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.5)
                : const Color(0xFFE5E9EF),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.5)
                    : const Color(0xFFE5E9EF),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFFAAB5C3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

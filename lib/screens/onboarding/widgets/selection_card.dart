import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class SelectionCard extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    this.icon,
    this.imageAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : assert(icon != null || imageAsset != null, 'Either icon or imageAsset must be provided');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
        child: Row(
          children: [
            // Icon or Asset circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.15)
                    : const Color(0xFFF1F4F8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        width: 22,
                        height: 22,
                      )
                    : Icon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFF8896A6),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textDark,
                ),
              ),
            ),
            // Checkmark
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class GridSelectionCard extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const GridSelectionCard({
    super.key,
    this.icon,
    this.imageAsset,
    required this.label,
    this.subtitle,
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or Asset Image
              if (imageAsset != null)
                Image.asset(
                  imageAsset!,
                  width: 36,
                  height: 36,
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 36,
                  color: isSelected ? AppTheme.primary : const Color(0xFF8896A6),
                ),
              const SizedBox(height: 12),
              // Label
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  color: isSelected ? AppTheme.primary : AppTheme.textDark,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.7)
                        : const Color(0xFFAAB5C3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class UnitToggle extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const UnitToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8), // Soft grey background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9EF), width: 1),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = value == option;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withOpacity(0.6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF5D6A78),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

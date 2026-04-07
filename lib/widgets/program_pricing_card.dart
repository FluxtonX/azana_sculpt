import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ProgramPricingCard extends StatelessWidget {
  const ProgramPricingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'CARDIO90 ELITE Program',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ),

            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'A premium transformation coaching program for women ready to commit to long-term change.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'First Month:',
                style: TextStyle(fontSize: 15, color: AppTheme.textDark),
              ),
              Text(
                '£49',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Then:',
                style: TextStyle(fontSize: 15, color: AppTheme.textDark),
              ),
              Text(
                '£99/month',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textMedium),
                SizedBox(width: 8),
                Text(
                  'Minimum commitment: 20 weeks',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

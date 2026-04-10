import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../widgets/coach_card.dart';

class AllCoachesScreen extends StatelessWidget {
  const AllCoachesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Elite Coaches'),
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.textDark,
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: DatabaseService().getCoachesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final coaches = snapshot.data ?? [];

          if (coaches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.textLight),
                  SizedBox(height: 16),
                  Text(
                    'No coaches available yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              return CoachCard(
                coach: coaches[index],
                isHorizontal: false,
                onTap: () {
                  // Navigate to coach profile detail if needed
                },
              );
            },
          );
        },
      ),
    );
  }
}

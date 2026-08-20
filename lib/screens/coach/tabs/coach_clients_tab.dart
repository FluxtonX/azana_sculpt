import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../add_client_screen.dart';
import '../assign_workout_screen.dart';
import '../assign_meal_plan_screen.dart';
import '../chat_screen.dart';

class CoachClientsTab extends StatefulWidget {
  const CoachClientsTab({super.key});

  @override
  State<CoachClientsTab> createState() => _CoachClientsTabState();
}

class _CoachClientsTabState extends State<CoachClientsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildSearchAndFilter(),
              const SizedBox(height: 20),
              StreamBuilder<List<UserModel>>(
                stream: DatabaseService().getCoachClientsStream(coachId),
                builder: (context, snapshot) {
                  final clients = snapshot.data ?? [];
                  final filteredClients = clients.where((client) {
                    final query = _searchQuery.toLowerCase();
                    return (client.fullName ?? '').toLowerCase().contains(query) ||
                        client.email.toLowerCase().contains(query);
                  }).toList();

                  return Text(
                    '${filteredClients.length} clients',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: DatabaseService().getCoachClientsStream(coachId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final clients = snapshot.data ?? [];
                    final filteredClients = clients.where((client) {
                      final query = _searchQuery.toLowerCase();
                      return (client.fullName ?? '').toLowerCase().contains(query) ||
                          client.email.toLowerCase().contains(query);
                    }).toList();

                    if (filteredClients.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No clients yet' : 'No results found',
                              style: const TextStyle(fontSize: 18, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Add your first client to start coaching'
                                  : 'Try searching with a different name or email',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredClients.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildClientCard(filteredClients[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Clients',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddClientScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Client'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.textOnDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: AppTheme.textLight, size: 20),
                hintText: 'Search clients...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const Icon(Icons.tune, color: AppTheme.textLight, size: 20),
        ),
      ],
    );
  }

  Widget _buildClientCard(UserModel client) {
    final name = client.fullName ?? 'No Name';
    final email = client.email;
    final coachId = AuthService().currentUser?.uid ?? '';

    String avatarChar = '';
    if (name.isNotEmpty) {
      avatarChar = name[0].toUpperCase();
    } else if (email.isNotEmpty) {
      avatarChar = email[0].toUpperCase();
    } else {
      avatarChar = '?';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  avatarChar,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'No Name',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                tooltip: 'Chat with Client',
                onPressed: () {
                  final chatId = '${client.uid}_$coachId';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        otherUser: client,
                        currentUserId: coachId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Assignment status stream
          StreamBuilder<Map<String, dynamic>?>(
            stream: DatabaseService().getClientAssignmentStream(client.uid),
            builder: (context, snapshot) {
              final assignedProgram = snapshot.data?['assignedProgram'] as Map<String, dynamic>?;
              final assignedMealPlan = snapshot.data?['assignedMealPlan'] as Map<String, dynamic>?;

              final programTitle = assignedProgram?['programTitle'] as String?;
              final mealPlanTitle = assignedMealPlan?['title'] as String?;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            programTitle != null ? 'Workout: $programTitle' : 'Workout: None Assigned',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: programTitle != null ? FontWeight.w600 : FontWeight.normal,
                              color: programTitle != null ? AppTheme.textDark : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu, size: 16, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mealPlanTitle != null ? 'Meal: $mealPlanTitle' : 'Meal: None Assigned',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: mealPlanTitle != null ? FontWeight.w600 : FontWeight.normal,
                              color: mealPlanTitle != null ? AppTheme.textDark : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Assign action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignWorkoutScreen(client: client),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fitness_center, size: 16),
                  label: const Text('Assign Workout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignMealPlanScreen(client: client),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant, size: 16),
                  label: const Text('Assign Meal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



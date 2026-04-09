import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_theme.dart';
import '../../../models/program_model.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../create_program_screen.dart';
import '../manage_program_workouts_screen.dart';

class CoachProgramsTab extends StatefulWidget {
  const CoachProgramsTab({super.key});

  @override
  State<CoachProgramsTab> createState() => _CoachProgramsTabState();
}

class _CoachProgramsTabState extends State<CoachProgramsTab> {
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
              _buildSearchBox(),
              const SizedBox(height: 20),
              StreamBuilder<List<ProgramModel>>(
                stream: DatabaseService().getProgramsStream(coachId),
                builder: (context, snapshot) {
                  final programs = snapshot.data ?? [];
                  final filteredPrograms = programs.where((p) {
                    final query = _searchQuery.toLowerCase();
                    return p.title.toLowerCase().contains(query) ||
                        p.description.toLowerCase().contains(query);
                  }).toList();

                  return Text(
                    '${filteredPrograms.length} programs',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<ProgramModel>>(
                  stream: DatabaseService().getProgramsStream(coachId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      String errorMessage = snapshot.error.toString();
                      if (errorMessage.contains('permission-denied')) {
                        errorMessage = 'Permission Denied: Please update your Firestore security rules to allow programs access.';
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }

                    final programs = snapshot.data ?? [];
                    final filteredPrograms = programs.where((p) {
                      final query = _searchQuery.toLowerCase();
                      return p.title.toLowerCase().contains(query) ||
                          p.description.toLowerCase().contains(query);
                    }).toList();

                    if (filteredPrograms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No programs yet' : 'No results found',
                              style: const TextStyle(fontSize: 18, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Create your first training program'
                                  : 'Try searching with a different title or description',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredPrograms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildProgramCard(context, filteredPrograms[index]);
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
          'Programs',
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
              MaterialPageRoute(builder: (context) => const CreateProgramScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Program'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.textOnDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
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
          hintText: 'Search programs...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, ProgramModel program) {
    final createdStr = DateFormat('M/d/yyyy').format(program.createdAt);

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (program.status == 'active' ? Colors.green : Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              program.status,
              style: TextStyle(
                fontSize: 10,
                color: program.status == 'active' ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            program.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            program.description,
            style: const TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Duration: ${program.duration} • Created: $createdStr',
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageProgramWorkoutsScreen(program: program),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Manage Workouts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textDark,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildIconButton(Icons.copy_outlined),
              const SizedBox(width: 12),
              _buildIconButton(
                Icons.delete_outline,
                color: Colors.red.shade400,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Program'),
                      content: const Text('Are you sure you want to delete this program?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await DatabaseService().deleteProgram(program.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Icon(icon, color: color ?? AppTheme.textLight, size: 18),
      ),
    );
  }
}


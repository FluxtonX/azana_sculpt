import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../constants/app_theme.dart';
import '../../../models/program_model.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import 'manage_program_workouts_screen.dart';

class CreateProgramScreen extends StatefulWidget {
  const CreateProgramScreen({super.key});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();
  String _selectedGoal = 'Fat Loss';
  bool _isLoading = false;

  final List<Map<String, String>> _templates = [
    {
      'title': '90-Day Fat Burn',
      'desc':
          'High-intensity program focused on caloric deficit and lean muscle retention.',
      'duration': '90 Days',
      'goal': 'Fat Loss',
    },
    {
      'title': 'Hypertrophy Max',
      'desc':
          'Targeted muscle growth program with progressive overload principles.',
      'duration': '12 Weeks',
      'goal': 'Muscle Gain',
    },
    {
      'title': 'Elite Mobility',
      'desc':
          'Advanced flexibility and joint health for long-term athletic performance.',
      'duration': '30 Days',
      'goal': 'Mobility',
    },
  ];

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _titleController.text = template['title']!;
      _descController.text = template['desc']!;
      _durationController.text = template['duration']!;
      _selectedGoal = template['goal']!;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final coachId = AuthService().currentUser?.uid;
      if (coachId == null) throw 'User not logged in';

      final program = ProgramModel(
        id: const Uuid().v4(),
        coachId: coachId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        duration: _durationController.text.trim(),
        createdAt: DateTime.now(),
        tags: [_selectedGoal],
      );

      await DatabaseService().createProgram(program);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManageProgramWorkoutsScreen(program: program),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Program Designer',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildProgressHeader(),
              const SizedBox(height: 32),

              Text(
                'Quick Templates',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    return GestureDetector(
                      onTap: () => _applyTemplate(t),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t['title']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t['duration']!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
              _buildTextField(
                label: 'Program Title',
                controller: _titleController,
                hint: 'e.g., 90-Day Transformation',
                icon: Icons.title_rounded,
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Description',
                controller: _descController,
                hint: 'Describe the program goals...',
                maxLines: 4,
                icon: Icons.description_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Duration',
                controller: _durationController,
                hint: 'e.g., 90 days, 12 weeks',
                icon: Icons.timer_outlined,
                validator: (v) => v!.isEmpty ? 'Please enter a duration' : null,
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProgram,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'CONTINUE TO WORKOUTS',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      children: [
        _buildStepIndicator('1', 'Basic Info', true),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        _buildStepIndicator('2', 'Workouts', false),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        _buildStepIndicator('3', 'Exercises', false),
      ],
    );
  }

  Widget _buildStepIndicator(String step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primary : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.primary : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppTheme.primary.withOpacity(0.5), size: 20)
                : null,
            hintStyle: GoogleFonts.outfit(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

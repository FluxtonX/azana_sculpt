// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/assessment_progress_bar.dart';
import '../../widgets/unit_selector_field.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/selection_toggle.dart';
import '../../widgets/labelled_checkbox.dart';
import '../../widgets/option_card.dart';
import '../../widgets/assessment_slider.dart';
import '../../widgets/program_pricing_card.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 6;
  bool _isSubmitting = false;

  // Step 1 Data
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedAgeRange;

  // Step 2 Data
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  // Step 3 Data
  bool? _isTakingMedication;
  final List<String> _selectedMedicalConditions = [];

  // Step 4 Data
  String? _selectedActivityLevel;
  bool? _hasGymAccess;
  double _weightliftingExperience = 1;
  final List<String> _selectedEquipment = [];
  String? _selectedSleepQuality;

  // Step 5 Data
  final TextEditingController _fitnessGoalController = TextEditingController();
  final TextEditingController _bodyVisionController = TextEditingController();
  double _commitmentLevel = 5;
  double _motivationLevel = 3;
  final TextEditingController _mentalBarriersController =
      TextEditingController();
  String? _coachingPreference;

  // Step 6 Data
  String? _investmentReadiness;
  String? _commitmentReadiness;
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  Future<void> _nextPage() async {
    if (_currentStep < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      // Handle completion & Save to Firestore
      final user = AuthService().currentUser;
      if (user == null) return;

      try {
        // Fetch existing profile to preserve the role
        final existingProfile = await DatabaseService().getUserProfile(user.uid);
        final String userRole = existingProfile?.role ?? 'client';

        final userData = UserModel(
          uid: user.uid,
          email: user.email ?? _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          ageRange: _selectedAgeRange,
          height: _heightController.text.trim(),
          weight: _weightController.text.trim(),
          heightUnit: _heightUnit,
          weightUnit: _weightUnit,
          isTakingMedication: _isTakingMedication,
          medicalConditions: _selectedMedicalConditions,
          activityLevel: _selectedActivityLevel,
          hasGymAccess: _hasGymAccess,
          weightliftingExperience: _weightliftingExperience,
          equipment: _selectedEquipment,
          sleepQuality: _selectedSleepQuality,
          fitnessGoal: _fitnessGoalController.text.trim(),
          bodyVision: _bodyVisionController.text.trim(),
          commitmentLevel: _commitmentLevel,
          motivationLevel: _motivationLevel,
          mentalBarriers: _mentalBarriersController.text.trim(),
          coachingPreference: _coachingPreference,
          investmentReadiness: _investmentReadiness,
          commitmentReadiness: _commitmentReadiness,
          referral: _referralController.text.trim(),
          socialMedia: _socialMediaController.text.trim(),
          role: userRole,
          updatedAt: DateTime.now(),
        );

        await DatabaseService().saveUserProfile(userData);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _previousPage() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 1
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textMedium,
                ),
                onPressed: _previousPage,
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textMedium,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Column(
          children: const [
            Text(
              'Azana Sculpt',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            Text(
              'Assessment',
              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Text(
              '$_currentStep/$_totalSteps',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMedium,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: AssessmentProgressBar(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
          _buildStep6(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Welcome! ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text('👋', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's start with your personal information",
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequiredLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _buildInputDecoration('Enter your full name'),
                ),
                const SizedBox(height: 20),
                _buildRequiredLabel('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('your.email@example.com'),
                ),
                const SizedBox(height: 20),
                _buildRequiredLabel('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('WhatsApp preferred'),
                ),
                const Text(
                  'We prefer WhatsApp for quick communication',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLight),
                ),
                const SizedBox(height: 20),
                AppDropdownField(
                  label: 'Age Range',
                  hint: 'Select your age range',
                  items: const ['18-24', '25-34', '35-44', '45+'],
                  value: _selectedAgeRange,
                  onChanged: (val) => setState(() => _selectedAgeRange = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : AppButton(
                  text: _currentStep == _totalSteps ? 'Submit Assessment' : 'Continue',
                  onPressed: _nextPage,
                  isFullWidth: true,
                ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Physical Information ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text('📏', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Help us understand your starting point",
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                UnitSelectorField(
                  label: 'Current Height',
                  hint: 'e.g., 173',
                  unit: _heightUnit,
                  units: const ['cm', 'ft'],
                  controller: _heightController,
                  onUnitChanged: (val) => setState(() => _heightUnit = val!),
                ),
                const SizedBox(height: 24),
                UnitSelectorField(
                  label: 'Current Weight',
                  hint: 'e.g., 65',
                  unit: _weightUnit,
                  units: const ['kg', 'lbs'],
                  controller: _weightController,
                  onUnitChanged: (val) => setState(() => _weightUnit = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Medical & Health ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text('🏥', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Your safety is our top priority",
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectionToggle(
                  label: 'Are you currently taking any medication?',
                  value: _isTakingMedication,
                  onChanged: (val) => setState(() => _isTakingMedication = val),
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Medical Conditions'),
                const Text(
                  'Select any that apply to you',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 16),
                ...[
                  'High Blood Pressure',
                  'Heart Condition (history of heart attack, stroke)',
                  'Diabetes (Type 1 or Type 2)',
                  'Asthma or respiratory issues',
                  'Joint / Back Problems (arthritis, herniated disc)',
                  'Eating Disorder history',
                  'None of the above',
                  'Other',
                ].map(
                  (condition) => LabelledCheckbox(
                    label: condition,
                    isSelected: _selectedMedicalConditions.contains(condition),
                    onChanged: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMedicalConditions.add(condition);
                        } else {
                          _selectedMedicalConditions.remove(condition);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Fitness Background ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text('💪', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Tell us about your fitness journey",
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequiredLabel('Current Activity Level'),
                const SizedBox(height: 16),
                _buildOptionCard(
                  'Sedentary',
                  'Little or no exercise',
                  'ActivityLevel',
                ),
                _buildOptionCard(
                  'Lightly Active',
                  '1-3 days/week',
                  'ActivityLevel',
                ),
                _buildOptionCard(
                  'Moderately Active',
                  '3-5 days/week',
                  'ActivityLevel',
                ),
                _buildOptionCard(
                  'Very Active',
                  '6-7 days/week',
                  'ActivityLevel',
                ),
                _buildOptionCard(
                  'Extremely Active',
                  'Daily intense activity',
                  'ActivityLevel',
                ),
                const SizedBox(height: 32),
                SelectionToggle(
                  label: 'Do you currently have access to a gym?',
                  value: _hasGymAccess,
                  onChanged: (val) => setState(() => _hasGymAccess = val),
                ),
                const SizedBox(height: 32),
                AssessmentSlider(
                  label: 'Weightlifting Experience',
                  value: _weightliftingExperience,
                  max: 5,
                  divisions: 4,
                  minLabel: 'Beginner',
                  maxLabel: 'Expert',
                  onChanged: (val) =>
                      setState(() => _weightliftingExperience = val),
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Equipment Access'),
                const Text(
                  'Select all that apply',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildEquipmentCheckbox('Gym Membership')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEquipmentCheckbox('Home Equipment')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildEquipmentCheckbox('Cardio Machines')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEquipmentCheckbox('Bodyweight Only')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildEquipmentCheckbox('Outdoor Space')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEquipmentCheckbox('None')),
                  ],
                ),
                const SizedBox(height: 32),
                AppDropdownField(
                  label: 'Sleep Quality',
                  hint: 'How would you describe your sleep?',
                  items: const ['Poor', 'Fair', 'Good', 'Excellent'],
                  value: _selectedSleepQuality,
                  onChanged: (val) =>
                      setState(() => _selectedSleepQuality = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Goals & Mindset ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text('🎯', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "What drives you to transform?",
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequiredLabel('Primary Fitness Goal'),
                const Text(
                  'What is your main focus?',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fitnessGoalController,
                  maxLines: 2,
                  decoration: _buildInputDecoration(
                    'e.g., Fat loss, Muscle tone, Strength...',
                  ),
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Dream Body Vision'),
                const Text(
                  'Describe your ideal body in 12-16 weeks',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bodyVisionController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    'Paint a picture of how you see yourself...',
                  ),
                ),
                const SizedBox(height: 32),
                AssessmentSlider(
                  label: 'Commitment Level',
                  value: _commitmentLevel,
                  divisions: 9,
                  minLabel: 'Not serious',
                  maxLabel: 'Extremely serious',
                  onChanged: (val) => setState(() => _commitmentLevel = val),
                ),
                const SizedBox(height: 32),
                AssessmentSlider(
                  label: 'Motivation Level',
                  value: _motivationLevel,
                  max: 5,
                  divisions: 4,
                  minLabel: 'Not motivated',
                  maxLabel: 'Extremely motivated',
                  onChanged: (val) => setState(() => _motivationLevel = val),
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Mental Barriers'),
                const Text(
                  "What's your biggest mental hurdle?",
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mentalBarriersController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    'e.g., Discipline, Time management, Confidence...',
                  ),
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Coaching Support Preference'),
                const SizedBox(height: 16),
                _buildOptionCard("I'm not sure yet", null, 'Coaching'),
                _buildOptionCard(
                  "Full coaching guidance (custom plan, nutrition, support)",
                  null,
                  'Coaching',
                ),
                _buildOptionCard("Other", null, 'Coaching'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStep6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Final Step ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text('🚀', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Ready to commit to your transformation?",
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 32),
          const ProgramPricingCard(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequiredLabel('Investment Readiness'),
                const Text(
                  'Which best describes you right now?',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  "Yes — I'm ready to invest at this level",
                  null,
                  'Investment',
                ),
                _buildOptionCard(
                  "I'm not in a position to invest right now",
                  null,
                  'Investment',
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Commitment Readiness'),
                const SizedBox(height: 16),
                _buildOptionCard(
                  "Yes — I'm ready to begin my transformation now",
                  null,
                  'Commitment',
                ),
                _buildOptionCard(
                  "No — I'm not ready at this time",
                  null,
                  'Commitment',
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('How did you hear about this program?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referralController,
                  decoration: _buildInputDecoration(
                    'e.g., Instagram, Facebook, Friend, Ad...',
                  ),
                ),
                const SizedBox(height: 32),
                _buildRequiredLabel('Social Media Profile'),
                const Text(
                  'Please share your Instagram or Facebook handle',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _socialMediaController,
                  decoration: _buildInputDecoration('@username'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Important - Please Read',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'If your application is successful, I will contact you using the number you provided. Please double-check your contact details before submitting.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String title, String? subtitle, String type) {
    bool isSelected = false;
    VoidCallback onTap = () {};

    if (type == 'ActivityLevel') {
      isSelected = _selectedActivityLevel == title;
      onTap = () => setState(() => _selectedActivityLevel = title);
    } else if (type == 'Coaching') {
      isSelected = _coachingPreference == title;
      onTap = () => setState(() => _coachingPreference = title);
    } else if (type == 'Investment') {
      isSelected = _investmentReadiness == title;
      onTap = () => setState(() => _investmentReadiness = title);
    } else if (type == 'Commitment') {
      isSelected = _commitmentReadiness == title;
      onTap = () => setState(() => _commitmentReadiness = title);
    }

    return OptionCard(
      title: title,
      subtitle: subtitle,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildEquipmentCheckbox(String label) {
    return LabelledCheckbox(
      label: label,
      isSelected: _selectedEquipment.contains(label),
      onChanged: (selected) {
        setState(() {
          if (selected) {
            _selectedEquipment.add(label);
          } else {
            _selectedEquipment.remove(label);
          }
        });
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _previousPage,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              foregroundColor: AppTheme.textMedium,
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: AppButton(
            text: _currentStep == _totalSteps
                ? 'Submit Application'
                : 'Continue',
            onPressed: _nextPage,
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textLight),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}

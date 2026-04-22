import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../widgets/assessment_progress_bar.dart';
import '../../widgets/app_button.dart';
import 'steps/age_step.dart';
import 'steps/height_step.dart';
import 'steps/weight_step.dart';
import 'steps/supplements_step.dart';
import 'steps/supplements_grid_step.dart';
import 'steps/activity_step.dart';
import 'steps/goal_step.dart';
import 'steps/target_step.dart';
import 'steps/exercise_experience_step.dart';
import 'steps/equipment_step.dart';
import 'steps/sleep_step.dart';
import 'steps/commitment_step.dart';
import 'steps/motivation_step.dart';
import 'steps/challenge_step.dart';
import 'steps/support_step.dart';
import 'steps/investment_step.dart';
import 'steps/readiness_step.dart';
import 'steps/source_step.dart';
import 'steps/social_step.dart';
import 'steps/success_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 20;

  // Data state
  int _selectedAge = 18;
  int _selectedHeight = 175;
  final String _heightUnit = 'cm';
  int _selectedWeight = 63;
  String _weightUnit = 'kg';
  String _supplementsOption = '';
  List<String> _selectedSupplements = [];
  int _activityLevel = 3;
  String _selectedGoal = '';
  final TextEditingController _dreamBodyController = TextEditingController();
  bool? _hasGymAccess;
  String _selectedExperience = '';
  List<String> _selectedEquipment = [];
  String _selectedSleepQuality = '';
  int _commitmentLevel = 1;
  int _motivationLevel = 1;
  final TextEditingController _challengeController = TextEditingController();
  String _selectedSupport = '';
  bool? _isReadyToInvest;
  bool? _isReadyToStart;
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _socialController = TextEditingController();

  @override
  void dispose() {
    _dreamBodyController.dispose();
    _challengeController.dispose();
    _sourceController.dispose();
    _socialController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      // Final submission logic
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
    final bool isLastStep = _currentStep == _totalSteps;

    return Scaffold(
      backgroundColor: isLastStep ? AppTheme.primary : AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 1. High-Fidelity Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of $_totalSteps',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isLastStep ? Colors.white : AppTheme.textLight,
                        ),
                      ),
                      Text(
                        '${((_currentStep / _totalSteps) * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLastStep ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AssessmentProgressBar(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    isAlternative: isLastStep,
                  ),
                ],
              ),
            ),

            // 2. Main Content (Modular Steps)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  AgeStep(
                    selectedAge: _selectedAge,
                    onAgeChanged: (val) => setState(() => _selectedAge = val),
                  ),
                  HeightStep(
                    selectedHeight: _selectedHeight,
                    unit: _heightUnit,
                    onHeightChanged: (val) => setState(() => _selectedHeight = val),
                  ),
                  WeightStep(
                    selectedWeight: _selectedWeight,
                    unit: _weightUnit,
                    onWeightChanged: (val) => setState(() => _selectedWeight = val),
                    onUnitChanged: (val) => setState(() => _weightUnit = val),
                  ),
                  SupplementsStep(
                    selectedOption: _supplementsOption,
                    onOptionChanged: (val) => setState(() => _supplementsOption = val),
                  ),
                  SupplementsGridStep(
                    selectedSupplements: _selectedSupplements,
                    onSupplementsChanged: (val) => setState(() => _selectedSupplements = val),
                  ),
                  ActivityStep(
                    activityLevel: _activityLevel,
                    onActivityChanged: (val) => setState(() => _activityLevel = val),
                  ),
                  GoalStep(
                    selectedGoal: _selectedGoal,
                    onGoalChanged: (val) => setState(() => _selectedGoal = val),
                  ),
                  TargetStep(
                    answerController: _dreamBodyController,
                    hasGymAccess: _hasGymAccess,
                    onGymAccessChanged: (val) => setState(() => _hasGymAccess = val),
                  ),
                  ExerciseExperienceStep(
                    selectedExperience: _selectedExperience,
                    onExperienceChanged: (val) => setState(() => _selectedExperience = val),
                  ),
                  EquipmentStep(
                    selectedEquipment: _selectedEquipment,
                    onEquipmentChanged: (val) => setState(() => _selectedEquipment = val),
                  ),
                  SleepStep(
                    selectedSleep: _selectedSleepQuality,
                    onSleepChanged: (val) => setState(() => _selectedSleepQuality = val),
                  ),
                  CommitmentStep(
                    selectedLevel: _commitmentLevel,
                    onLevelChanged: (val) => setState(() => _commitmentLevel = val),
                  ),
                  MotivationStep(
                    selectedLevel: _motivationLevel,
                    onLevelChanged: (val) => setState(() => _motivationLevel = val),
                  ),
                  ChallengeStep(
                    challengeController: _challengeController,
                  ),
                  SupportStep(
                    selectedSupport: _selectedSupport,
                    onSupportChanged: (val) => setState(() => _selectedSupport = val),
                  ),
                  InvestmentStep(
                    isReadyToInvest: _isReadyToInvest,
                    onInvestChanged: (val) => setState(() => _isReadyToInvest = val),
                  ),
                  ReadinessStep(
                    isReadyToStart: _isReadyToStart,
                    onReadinessChanged: (val) => setState(() => _isReadyToStart = val),
                  ),
                  SourceStep(
                    sourceController: _sourceController,
                  ),
                  SocialStep(
                    socialController: _socialController,
                  ),
                  const SuccessStep(),
                ],
              ),
            ),

            // 3. Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: isLastStep
                  ? Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: "Get Start",
                            backgroundColor: Colors.white,
                            textColor: AppTheme.primary,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            text: "View My Profile →",
                            backgroundColor: Colors.white.withOpacity(0.2),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    )
                  : _currentStep == 1
                      ? AppButton(
                          text: "Continue",
                          onPressed: _nextPage,
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _previousPage,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppTheme.primary, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "Back",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppButton(
                                text: "Continue",
                                onPressed: _nextPage,
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

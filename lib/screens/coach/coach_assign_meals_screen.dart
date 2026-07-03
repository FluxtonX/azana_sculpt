import 'dart:math' as math;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/meal_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class CoachAssignMealsScreen extends StatefulWidget {
  final UserModel? initialClient;

  const CoachAssignMealsScreen({super.key, this.initialClient});

  @override
  State<CoachAssignMealsScreen> createState() => _CoachAssignMealsScreenState();
}

class _CoachAssignMealsScreenState extends State<CoachAssignMealsScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _selectedClient;
  String _selectedDay = 'Mon';
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late final AnimationController _uploadAnimationController;
  bool _usePdfUpload = true;

  final TextEditingController _caloriesController = TextEditingController(
    text: '2000',
  );
  final TextEditingController _proteinController = TextEditingController(
    text: '150',
  );
  final TextEditingController _carbsController = TextEditingController(
    text: '200',
  );
  final TextEditingController _fatController = TextEditingController(
    text: '60',
  );

  final List<MealModel> _meals = [];
  bool _isLoading = false;
  PlatformFile? _selectedPdf;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.initialClient;
    _uploadAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _uploadAnimationController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client first')),
      );
      return;
    }

    if (_usePdfUpload && _selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a PDF meal plan first.')),
      );
      return;
    }

    if (!_usePdfUpload && _meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one meal first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_usePdfUpload) {
      await _uploadPdfPlan();
      return;
    }

    final plan = DailyMealPlan(
      day: _selectedDay,
      targetCalories: _caloriesController.text,
      targetProtein: _proteinController.text,
      targetCarbs: _carbsController.text,
      targetFat: _fatController.text,
      meals: _meals,
    );

    try {
      await DatabaseService().saveMealPlan(_selectedClient!.uid, plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meal plan assigned for $_selectedDay!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final isPdf =
        file.extension?.toLowerCase() == 'pdf' ||
        file.name.toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a PDF file only.')),
        );
      }
      return;
    }

    const maxBytes = 25 * 1024 * 1024;
    if (file.size > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF must be 25 MB or smaller.')),
        );
      }
      return;
    }

    setState(() {
      _selectedPdf = file;
      _uploadProgress = null;
    });
  }

  Future<void> _uploadPdfPlan() async {
    try {
      final client = _selectedClient!;
      final pdf = _selectedPdf!;
      final path = pdf.path;
      if (path == null || path.isEmpty) {
        throw 'Unable to read selected PDF file.';
      }

      final cleanName = pdf.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storagePath =
          'meal_plans/${client.uid}/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final ref = FirebaseStorage.instance.ref(storagePath);

      final uploadTask = ref.putFile(
        File(path),
        SettableMetadata(contentType: 'application/pdf'),
      );
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          final totalBytes = snapshot.totalBytes;
          if (totalBytes <= 0 || !mounted) return;
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / totalBytes;
          });
        },
        onError: (_) {
          if (mounted) setState(() => _uploadProgress = null);
        },
      );

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      final pdfPlan = MealPlanPdf(
        fileName: pdf.name,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        uploadedAt: DateTime.now().toIso8601String(),
      );

      final oldPdf = await DatabaseService().getMealPlanPdf(client.uid);
      await DatabaseService().saveMealPlanPdf(client.uid, pdfPlan);
      if (oldPdf != null &&
          oldPdf.storagePath.isNotEmpty &&
          oldPdf.storagePath != storagePath) {
        try {
          await FirebaseStorage.instance.ref(oldPdf.storagePath).delete();
        } catch (_) {
          // The Firestore record is already updated; ignore stale storage cleanup failures.
        }
      }

      if (mounted) {
        setState(() {
          _selectedPdf = null;
          _uploadProgress = null;
        });
        _showUploadSuccessSheet(client);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF upload error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  void _showUploadSuccessSheet(UserModel client) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Meal plan uploaded',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "The PDF is now available in ${((client.fullName ?? '').isNotEmpty ? client.fullName! : 'your client')}'s Meals tab.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textMedium,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addMeal() {
    _showMealDialog();
  }

  void _showMealDialog({MealModel? existingMeal, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealEntryDialog(
        existingMeal: existingMeal,
        onSave: (meal) {
          setState(() {
            if (index != null) {
              _meals[index] = meal;
            } else {
              _meals.add(meal);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientSelector(),
                  const SizedBox(height: 18),
                  _buildPlanModeSelector(),
                  const SizedBox(height: 32),
                  if (_usePdfUpload) ...[
                    _buildPdfUploadCard(),
                  ] else ...[
                    _buildNutritionTargets(),
                    const SizedBox(height: 24),
                    _buildDaySelector(),
                    const SizedBox(height: 24),
                    _buildMealListHeader(),
                    const SizedBox(height: 16),
                    _buildMealList(),
                  ],
                  if (!_usePdfUpload) ...[
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.textDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: const Text(
          'Assign Meal Plan',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Client',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedClient != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                  child: Text(
                    (_selectedClient!.fullName ?? '').isNotEmpty
                        ? _selectedClient!.fullName![0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_selectedClient!.fullName ?? '').isNotEmpty
                            ? _selectedClient!.fullName!
                            : 'Client',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Goal: ${_selectedClient!.fitnessGoal ?? "Not set"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showClientPicker,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: ElevatedButton(
                onPressed: _showClientPicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Select Client'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildModeItem(
            title: 'Upload PDF',
            icon: Icons.picture_as_pdf_rounded,
            active: _usePdfUpload,
            onTap: () => setState(() => _usePdfUpload = true),
          ),
          _buildModeItem(
            title: 'Manual Meals',
            icon: Icons.restaurant_menu_rounded,
            active: !_usePdfUpload,
            onTap: () => setState(() => _usePdfUpload = false),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required String title,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppTheme.textMedium,
                size: 19,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.textMedium,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Select Client',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: DatabaseService().getCoachClientsStream(
                  AuthService().currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final clients = snapshot.data!;
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (client.fullName ?? '').isNotEmpty
                                ? client.fullName![0].toUpperCase()
                                : 'C',
                          ),
                        ),
                        title: Text(
                          (client.fullName ?? '').isNotEmpty
                              ? client.fullName!
                              : 'Client',
                        ),
                        subtitle: Text(client.email),
                        onTap: () {
                          setState(() => _selectedClient = client);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfUploadCard() {
    final hasPdf = _selectedPdf != null;
    final hasClient = _selectedClient != null;
    final progress = _uploadProgress ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF Meal Plan Upload',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Upload once. Client sees it instantly in Meals.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUploadAnimation(hasPdf: hasPdf, progress: progress),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildFlowStep(
                number: '1',
                label: hasClient ? 'Client ready' : 'Select client',
                active: hasClient,
              ),
              const SizedBox(width: 8),
              _buildFlowStep(
                number: '2',
                label: hasPdf ? 'PDF selected' : 'Choose PDF',
                active: hasPdf,
              ),
              const SizedBox(width: 8),
              _buildFlowStep(
                number: '3',
                label: _isLoading ? 'Uploading' : 'Send plan',
                active: _isLoading || (_uploadProgress ?? 0) >= 1,
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: _isLoading ? null : _pickPdf,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasPdf
                    ? AppTheme.primary.withOpacity(0.08)
                    : const Color(0xFFFFF7F4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasPdf
                      ? AppTheme.primary.withOpacity(0.45)
                      : AppTheme.primary.withOpacity(0.16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      hasPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.note_add_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPdf ? _selectedPdf!.name : 'Choose meal plan PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPdf
                              ? '${_formatFileSize(_selectedPdf!.size)} selected'
                              : 'PDF only, up to 25 MB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    hasPdf ? Icons.check_circle_rounded : Icons.upload_rounded,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_uploadProgress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppTheme.primaryLight.withOpacity(0.30),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% uploaded',
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Do not close this screen',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (hasPdf && !_isLoading) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: hasClient ? _savePlan : null,
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Upload Plan to Client',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadAnimation({
    required bool hasPdf,
    required double progress,
  }) {
    final ringProgress = _isLoading
        ? progress.clamp(0.04, 1.0).toDouble()
        : hasPdf
        ? 1.0
        : 0.0;

    return AnimatedBuilder(
      animation: _uploadAnimationController,
      builder: (context, child) {
        final t = _uploadAnimationController.value;
        final float = math.sin(t * math.pi * 2) * 7;

        return Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF7F4),
                AppTheme.primary.withOpacity(0.08),
                AppTheme.primaryLight.withOpacity(0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 34,
                top: 34 + float,
                child: _buildFloatingUploadIcon(Icons.restaurant_rounded),
              ),
              Positioned(
                right: 34,
                bottom: 34 - float,
                child: _buildFloatingUploadIcon(Icons.local_drink_rounded),
              ),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.16),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: ringProgress,
                        strokeWidth: 7,
                        backgroundColor: AppTheme.primaryLight.withOpacity(
                          0.22,
                        ),
                        color: AppTheme.primary,
                      ),
                    ),
                    Icon(
                      hasPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.cloud_upload_rounded,
                      size: 38,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Text(
                  _isLoading
                      ? 'Uploading meal plan...'
                      : hasPdf
                      ? 'Ready to upload'
                      : 'PDF meal plan workflow',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingUploadIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.primary.withOpacity(0.70), size: 20),
    );
  }

  Widget _buildFlowStep({
    required String number,
    required String label,
    required bool active,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withOpacity(0.10)
              : AppTheme.primary.withOpacity(0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? AppTheme.primary.withOpacity(0.32)
                : AppTheme.divider.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: active ? AppTheme.primary : Colors.white,
              child: Text(
                number,
                style: TextStyle(
                  color: active ? Colors.white : AppTheme.textMedium,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? AppTheme.primaryDark : AppTheme.textMedium,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Widget _buildNutritionTargets() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition Target',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildTargetField('Daily Calories', _caloriesController, 'kcal'),
              const SizedBox(width: 12),
              _buildTargetField('Protein', _proteinController, 'g'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTargetField('Carbs', _carbsController, 'g'),
              const SizedBox(width: 12),
              _buildTargetField('Fat', _fatController, 'g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetField(
    String label,
    TextEditingController controller,
    String unit,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Week Day',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.map((day) {
                final isSelected = _selectedDay == day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFF9F5F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textMedium,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Assign Meals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        IconButton(
          onPressed: _addMeal,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMealList() {
    if (_meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No meals added for this day',
              style: TextStyle(
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meal = _meals[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getMealEmoji(meal.type),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${meal.type} • ${meal.calories} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () =>
                    _showMealDialog(existingMeal: meal, index: index),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => setState(() => _meals.removeAt(index)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMealEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍲';
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _selectedPdf != null
                    ? 'Upload PDF Meal Plan'
                    : 'Assign Meal Plan to Client',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class MealEntryDialog extends StatefulWidget {
  final MealModel? existingMeal;
  final Function(MealModel) onSave;

  const MealEntryDialog({super.key, this.existingMeal, required this.onSave});

  @override
  State<MealEntryDialog> createState() => _MealEntryDialogState();
}

class _MealEntryDialogState extends State<MealEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _timeController;
  late TextEditingController _prepTimeController;
  late TextEditingController _ingredientsController;
  late TextEditingController _instructionsController;
  String _selectedType = 'Breakfast';

  @override
  void initState() {
    super.initState();
    final meal = widget.existingMeal;
    _titleController = TextEditingController(text: meal?.title ?? '');
    _caloriesController = TextEditingController(text: meal?.calories ?? '');
    _proteinController = TextEditingController(text: meal?.protein ?? '');
    _carbsController = TextEditingController(text: meal?.carbs ?? '');
    _fatController = TextEditingController(text: meal?.fat ?? '');
    _timeController = TextEditingController(text: meal?.time ?? '08:00 AM');
    _prepTimeController = TextEditingController(
      text: meal?.prepTime ?? '15 min',
    );
    _ingredientsController = TextEditingController(
      text: meal?.ingredients.join('\n') ?? '',
    );
    _instructionsController = TextEditingController(
      text: meal?.instructions.join('\n') ?? '',
    );
    _selectedType = meal?.type ?? 'Breakfast';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Meal Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDropdown(),
              const SizedBox(height: 16),
              _buildField('Meal Title', _titleController, 'e.g. Avocado Toast'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField('Time', _timeController, '08:00 AM'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      'Prep Time',
                      _prepTimeController,
                      '15 min',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField('Calories', _caloriesController, '0'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Protein (g)', _proteinController, '0'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField('Carbs (g)', _carbsController, '0'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('Fat (g)', _fatController, '0')),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                'Ingredients (one per line)',
                _ingredientsController,
                '',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Instructions (one per line)',
                _instructionsController,
                '',
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final meal = MealModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text,
                        type: _selectedType,
                        time: _timeController.text,
                        calories: _caloriesController.text,
                        protein: _proteinController.text,
                        carbs: _carbsController.text,
                        fat: _fatController.text,
                        ingredients: _ingredientsController.text
                            .split('\n')
                            .where((s) => s.isNotEmpty)
                            .toList(),
                        instructions: _instructionsController.text
                            .split('\n')
                            .where((s) => s.isNotEmpty)
                            .toList(),
                        prepTime: _prepTimeController.text,
                      );
                      widget.onSave(meal);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Meal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Meal Type',
        filled: true,
        fillColor: const Color(0xFFF9F5F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        'Breakfast',
        'Lunch',
        'Dinner',
        'Snack',
      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() => _selectedType = v!),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9F5F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

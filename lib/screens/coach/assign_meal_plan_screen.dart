import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';

class AssignMealPlanScreen extends StatefulWidget {
  final UserModel client;
  const AssignMealPlanScreen({super.key, required this.client});

  @override
  State<AssignMealPlanScreen> createState() => _AssignMealPlanScreenState();
}

class _AssignMealPlanScreenState extends State<AssignMealPlanScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _pickedFile;
  String? _pickedFileName;
  bool _isLoading = false;
  double _uploadProgress = 0;

  // For selecting existing meal plans
  Map<String, dynamic>? _selectedExistingPlan;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
        _pickedFileName = result.files.single.name;
        _selectedExistingPlan = null; // clear existing selection
      });
    }
  }

  Future<void> _assign() async {
    final coachId = AuthService().currentUser?.uid ?? '';

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the meal plan.')),
      );
      return;
    }

    // If using existing plan, assign directly
    if (_selectedExistingPlan != null) {
      setState(() => _isLoading = true);
      try {
        await DatabaseService().assignMealPlanToClient(
          clientUid: widget.client.uid,
          mealPlanTitle: _selectedExistingPlan!['title'] ?? '',
          pdfUrl: _selectedExistingPlan!['pdfUrl'] ?? '',
          note: _noteController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal plan assigned successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a PDF file or select an existing plan.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      // 1. Upload PDF to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
            'meal_plans/$coachId/${DateTime.now().millisecondsSinceEpoch}_$_pickedFileName',
          );

      final uploadTask = storageRef.putFile(_pickedFile!);
      uploadTask.snapshotEvents.listen((event) {
        if (mounted) {
          setState(() {
            _uploadProgress =
                event.bytesTransferred / event.totalBytes;
          });
        }
      });
      await uploadTask;
      final pdfUrl = await storageRef.getDownloadURL();

      // 2. Save meal plan to Firestore
      await DatabaseService().saveMealPlanToFirestore(
        coachId: coachId,
        title: _titleController.text.trim(),
        pdfUrl: pdfUrl,
      );

      // 3. Assign to client
      await DatabaseService().assignMealPlanToClient(
        clientUid: widget.client.uid,
        mealPlanTitle: _titleController.text.trim(),
        pdfUrl: pdfUrl,
        note: _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal plan uploaded and assigned!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';
    final clientName = widget.client.fullName ?? widget.client.email;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Assign Meal Plan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accent.withOpacity(0.15),
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Assigning meal plan',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Existing meal plans
            Text(
              'Select Existing Plan',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getCoachMealPlansStream(coachId),
              builder: (context, snapshot) {
                final plans = snapshot.data ?? [];
                if (plans.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Text(
                      'No saved meal plans. Upload a new one below.',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return Column(
                  children: plans.map((plan) {
                    final isSelected =
                        _selectedExistingPlan?['id'] == plan['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedExistingPlan = isSelected ? null : plan;
                          _pickedFile = null;
                          _pickedFileName = null;
                          if (!isSelected) {
                            _titleController.text = plan['title'] ?? '';
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accent.withOpacity(0.1)
                              : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accent
                                : AppTheme.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: isSelected
                                  ? AppTheme.accent
                                  : AppTheme.textLight,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plan['title'] ?? '',
                                style: GoogleFonts.outfit(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppTheme.accent, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR UPLOAD NEW',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Plan Title',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Week 1 Clean Bulk Plan',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textLight),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // PDF picker
            GestureDetector(
              onTap: _selectedExistingPlan != null ? null : _pickPdf,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _pickedFile != null
                      ? AppTheme.primary.withOpacity(0.06)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pickedFile != null
                        ? AppTheme.primary
                        : AppTheme.divider,
                    width: _pickedFile != null ? 2 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _pickedFile != null
                          ? Icons.picture_as_pdf
                          : Icons.upload_file,
                      size: 40,
                      color: _pickedFile != null
                          ? AppTheme.primary
                          : AppTheme.textLight,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pickedFile != null
                          ? _pickedFileName ?? 'PDF Selected'
                          : 'Tap to select PDF',
                      style: GoogleFonts.outfit(
                        color: _pickedFile != null
                            ? AppTheme.primary
                            : AppTheme.textLight,
                        fontWeight: _pickedFile != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (_selectedExistingPlan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Deselect existing plan to upload new',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_isLoading && _uploadProgress > 0 && _uploadProgress < 1) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppTheme.divider,
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                'Uploading ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                    color: AppTheme.textLight, fontSize: 12),
              ),
            ],

            const SizedBox(height: 16),

            Text(
              'Note for Client (Optional)',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Drink 3L water daily, avoid fried food...',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textLight),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _assign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  disabledBackgroundColor:
                      AppTheme.accent.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Assign Meal Plan',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

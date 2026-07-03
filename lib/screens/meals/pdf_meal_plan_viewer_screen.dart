import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_theme.dart';
import '../../models/meal_model.dart';

class PdfMealPlanViewerScreen extends StatefulWidget {
  final MealPlanPdf pdf;

  const PdfMealPlanViewerScreen({super.key, required this.pdf});

  @override
  State<PdfMealPlanViewerScreen> createState() =>
      _PdfMealPlanViewerScreenState();
}

class _PdfMealPlanViewerScreenState extends State<PdfMealPlanViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _pageNumber = 1;
  int _pageCount = 0;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final progress = _pageCount == 0 ? 0.0 : _pageNumber / _pageCount;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCFA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDark.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SfPdfViewer.network(
                      widget.pdf.downloadUrl,
                      controller: _pdfController,
                      canShowPaginationDialog: true,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                      pageSpacing: 12,
                      enableDoubleTapZooming: true,
                      onDocumentLoaded: (details) {
                        setState(() {
                          _pageCount = details.document.pages.count;
                          _pageNumber = 1;
                          _isLoading = false;
                        });
                      },
                      onPageChanged: (details) {
                        setState(() => _pageNumber = details.newPageNumber);
                      },
                      onDocumentLoadFailed: (details) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open PDF: ${details.description}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      color: AppTheme.surface.withOpacity(0.76),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Meal Plan',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _pageCount == 0
                            ? 'Preparing plan'
                            : 'Page $_pageNumber of $_pageCount',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                icon: Icons.open_in_new_rounded,
                onPressed: _openExternally,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanSummaryCard(progress),
        ],
      ),
    );
  }

  Widget _buildPlanSummaryCard(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary.withOpacity(0.16),
                      AppTheme.primaryLight.withOpacity(0.32),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pdf.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coach nutrition plan',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppTheme.primaryLight.withOpacity(0.28),
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildNutritionChip(
                Icons.local_fire_department_rounded,
                'Macros',
              ),
              const SizedBox(width: 8),
              _buildNutritionChip(Icons.water_drop_rounded, 'Hydration'),
              const SizedBox(width: 8),
              _buildNutritionChip(Icons.schedule_rounded, 'Daily meals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppTheme.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.keyboard_arrow_up_rounded,
            onPressed: _pageNumber > 1 ? _pdfController.previousPage : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Swipe vertically to read',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _pageCount == 0
                      ? 'Loading pages'
                      : '$_pageNumber / $_pageCount',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onPressed: _pageCount == 0 || _pageNumber < _pageCount
                ? _pdfController.nextPage
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: enabled ? Colors.white : AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Icon(
            icon,
            color: enabled ? AppTheme.textDark : AppTheme.textLight,
            size: 22,
          ),
        ),
      ),
    );
  }

  Future<void> _openExternally() async {
    await launchUrl(
      Uri.parse(widget.pdf.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}

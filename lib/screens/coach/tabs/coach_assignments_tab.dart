import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../models/workout_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/google_drive_service.dart';

class CoachAssignmentsTab extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const CoachAssignmentsTab({super.key, this.onMenuPressed});

  @override
  State<CoachAssignmentsTab> createState() => _CoachAssignmentsTabState();
}

class _CoachAssignmentsTabState extends State<CoachAssignmentsTab> {
  bool _isHistory = false;
  final Set<String> _selectedClientIds = {};
  String _searchQuery = '';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _driveUrlController = TextEditingController();

  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isLibraryLoading = true;
  List<Map<String, String>> _libraryFolders = [];
  String? _selectedLibraryFolderId;

  List<ExerciseModel> _folderVideos = [];
  final Set<String> _selectedDriveVideoIds = {};
  bool _isVideosLoading = false;
  String _selectedSourceType = 'google_drive';
  Map<String, List<Map<String, dynamic>>> _youtubeWorkoutGroups = {};
  String? _selectedYoutubeCategory;
  final List<Map<String, dynamic>> _selectedYoutubeWorkouts = [];

  bool _isAssigning = false;
  String _rootFolderId = '1aCGjE-q2mHanGuS0JecipGHZ3aqAljR0';
  bool _isWeeklyPlan = false;

  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5};

  final Color _bgColor = const Color(0xFFF7F2EF);
  final Color _darkColor = const Color(0xFF171412);
  final Color _mutedColor = const Color(0xFF82746E);
  final Color _softPrimary = const Color(0xFFFFF1EC);
  final Color _greenColor = const Color(0xFF2E9B63);

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
    _loadYoutubeWorkoutLibrary();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _driveUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchLibrary() async {
    if (_rootFolderId.isEmpty) return;

    setState(() => _isLibraryLoading = true);

    try {
      final folders = await _driveService.fetchSubfolders(_rootFolderId);
      setState(() {
        _libraryFolders = folders;
        _isLibraryLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching library: $e');
      setState(() {
        _libraryFolders = [];
        _isLibraryLoading = false;
      });
    }
  }

  Future<void> _fetchVideos(String folderId) async {
    setState(() {
      _isVideosLoading = true;
      _folderVideos = [];
      _selectedDriveVideoIds.clear();
    });

    try {
      final videos = await _driveService.fetchFolderVideos(folderId);
      setState(() {
        _folderVideos = videos;
        _isVideosLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching videos: $e');
      setState(() => _isVideosLoading = false);
    }
  }

  Future<void> _loadYoutubeWorkoutLibrary() async {
    try {
      final response = await rootBundle.loadString('assets/data/workout.json');
      final data = json.decode(response) as List<dynamic>;
      final groups = <String, List<Map<String, dynamic>>>{};
      var currentCategory = 'GENERAL';

      for (final raw in data) {
        final item = Map<String, dynamic>.from(raw as Map);
        final name = (item['`']?.toString() ?? '').trim();
        final video = (item['Training Video']?.toString() ?? '').trim();
        if (name.isEmpty) continue;

        if (video.isEmpty) {
          currentCategory = name;
          groups.putIfAbsent(currentCategory, () => []);
          continue;
        }

        groups.putIfAbsent(currentCategory, () => []).add(item);
      }

      if (!mounted) return;
      setState(() {
        _youtubeWorkoutGroups = groups;
        _selectedYoutubeCategory = groups.keys.isNotEmpty
            ? groups.keys.first
            : null;
      });
    } catch (e) {
      debugPrint('Error loading YouTube workout library: $e');
    }
  }

  Future<void> _handleAssignWorkouts(String coachId) async {
    final selectedWorkouts = _selectedAssignmentWorkouts();
    if (selectedWorkouts.isEmpty ||
        _selectedClientIds.isEmpty ||
        (_isWeeklyPlan && _selectedWeekdays.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a workout, weekdays and at least one client',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final scheduledDates = _isWeeklyPlan
          ? (_selectedWeekdays.map(_nextDateForWeekday).toList()..sort())
          : [DateTime.now()];

      for (final workout in selectedWorkouts) {
        await DatabaseService().assignWorkoutToClient(
          coachId: coachId,
          clientIds: _selectedClientIds.toList(),
          workoutTitle: workout.title,
          driveUrl: workout.videoUrl,
          sourceType: workout.sourceType,
          youtubeWorkout: workout.youtubeWorkout,
          driveWorkout: workout.driveWorkout,
          notes: _notesController.text,
          scheduledDates: scheduledDates,
        );
      }

      if (!mounted) return;

      _titleController.clear();
      _notesController.clear();
      _driveUrlController.clear();
      setState(() {
        _selectedClientIds.clear();
        _selectedDriveVideoIds.clear();
        _selectedLibraryFolderId = null;
        _selectedYoutubeWorkouts.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Videos assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  List<_AssignmentWorkoutDraft> _selectedAssignmentWorkouts() {
    if (_selectedSourceType == 'google_drive') {
      return _folderVideos
          .where((video) => _selectedDriveVideoIds.contains(video.id))
          .where((video) => (video.videoUrl ?? '').isNotEmpty)
          .map(
            (video) => _AssignmentWorkoutDraft(
              title: video.name,
              videoUrl: video.videoUrl!,
              sourceType: 'google_drive',
              driveWorkout: video.toMap(),
            ),
          )
          .toList();
    }

    return _selectedYoutubeWorkouts
        .where(
          (workout) => (workout['Training Video']?.toString() ?? '').isNotEmpty,
        )
        .map(
          (workout) => _AssignmentWorkoutDraft(
            title: workout['`']?.toString() ?? 'Workout',
            videoUrl: workout['Training Video']?.toString() ?? '',
            sourceType: 'youtube',
            youtubeWorkout: _normalizeYoutubeWorkout(workout),
          ),
        )
        .toList();
  }

  DateTime _nextDateForWeekday(int weekday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var daysUntil = weekday - today.weekday;
    if (daysUntil < 0) daysUntil += 7;
    return today.add(Duration(days: daysUntil));
  }

  Map<String, dynamic>? _normalizeYoutubeWorkout(
    Map<String, dynamic>? workout,
  ) {
    if (workout == null) return null;

    return {
      'name': workout['`']?.toString() ?? '',
      'workingSets': workout['WORKING SETS']?.toString() ?? '',
      'reps': workout['REPS']?.toString() ?? '',
      'tempo': workout['TEMPO']?.toString() ?? '',
      'eccentric': workout['']?.toString() ?? '',
      'concentric': workout['__1']?.toString() ?? '',
      'isometric': workout['__2']?.toString() ?? '',
      'rest': workout['REST']?.toString() ?? '',
      'notes': workout['Notes']?.toString() ?? '',
      'detailedNotes': workout['NOTES']?.toString() ?? '',
      'trainingVideo': workout['Training Video']?.toString() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildSummaryCard(coachId),
                  const SizedBox(height: 18),
                  _buildToggle(),
                  const SizedBox(height: 18),
                  _isHistory
                      ? _buildHistoryView(coachId)
                      : _buildAssignNewView(coachId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Video\nAssignments',
                style: GoogleFonts.outfit(
                  fontSize: 31,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  color: _darkColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plan workouts and assign videos faster.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: widget.onMenuPressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.78)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String coachId) {
    return StreamBuilder<List<UserModel>>(
      stream: DatabaseService().getCoachClientsStream(coachId),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF251716),
                AppTheme.primary.withOpacity(0.90),
                const Color(0xFFD37763),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.22),
                blurRadius: 50,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  value: _folderVideos.length.toString(),
                  label: 'Library Videos',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryBox(
                  value: _selectedClientIds.length.toString(),
                  label: 'Selected Clients',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryBox(
                  value: clients.length.toString(),
                  label: 'Total Clients',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.white.withOpacity(0.73),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('Assign New', !_isHistory)),
          const SizedBox(width: 5),
          Expanded(child: _buildToggleButton('History', _isHistory)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isHistory = label == 'History'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : _mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAssignNewView(String coachId) {
    return Column(
      children: [
        _buildStepCard(
          number: '1',
          title: 'Select Workout Source',
          subtitle: 'Choose Google Drive videos or GYMLAB YouTube workouts',
          child: Column(
            children: [
              _buildSourceSelector(),
              const SizedBox(height: 14),
              if (_selectedSourceType == 'google_drive')
                _isLibraryLoading
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildLibrarySelector()
              else
                _buildYoutubeSelector(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          number: '2',
          title: 'Assignment Details',
          subtitle: 'Add notes and choose weekly workout days',
          child: Column(
            children: [
              _buildInputField(
                'Instructions',
                'Add any specific notes or modifications...',
                isMultiline: true,
                controller: _notesController,
                icon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: 11),
              _buildScheduleModeSelector(),
              if (_isWeeklyPlan) ...[
                const SizedBox(height: 11),
                _buildWeekdayPlanner(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          number: '3',
          title: 'Select Clients',
          subtitle: 'Choose one or multiple clients',
          child: Column(
            children: [
              _buildClientSearch(),
              const SizedBox(height: 14),
              StreamBuilder<List<UserModel>>(
                stream: DatabaseService().getCoachClientsStream(coachId),
                builder: (context, snapshot) {
                  final clients = snapshot.data ?? [];
                  final filtered = clients.where((c) {
                    final name = (c.fullName ?? '').toLowerCase();
                    final email = c.email.toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || email.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildSmallEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No clients found',
                    );
                  }

                  return SizedBox(
                    height: 126,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return _buildClientCheckbox(filtered[index]);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildAssignButton(coachId),
      ],
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(radius: 30),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _softPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _darkColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.black.withOpacity(0.06)),
          Padding(padding: const EdgeInsets.all(17), child: child),
        ],
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSourceChip(
            label: 'Google Drive',
            icon: Icons.folder_open_rounded,
            value: 'google_drive',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSourceChip(
            label: 'YouTube',
            icon: Icons.play_circle_fill_rounded,
            value: 'youtube',
          ),
        ),
      ],
    );
  }

  Widget _buildSourceChip({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedSourceType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSourceType = value;
          _titleController.clear();
          _driveUrlController.clear();
          _selectedDriveVideoIds.clear();
          _selectedYoutubeWorkouts.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFFBF7F4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : _darkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubeSelector() {
    if (_youtubeWorkoutGroups.isEmpty) {
      return _buildSmallEmptyState(
        icon: Icons.play_disabled_outlined,
        title: 'No YouTube workouts found',
      );
    }

    final categories = _youtubeWorkoutGroups.keys.toList();
    final selectedCategory =
        _selectedYoutubeCategory != null &&
            _youtubeWorkoutGroups.containsKey(_selectedYoutubeCategory)
        ? _selectedYoutubeCategory!
        : categories.first;
    final workouts = _youtubeWorkoutGroups[selectedCategory] ?? [];

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          isExpanded: true,
          decoration: _dropdownDecoration('Muscle Group'),
          items: categories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedYoutubeCategory = value;
              _selectedYoutubeWorkouts.clear();
              _titleController.clear();
              _driveUrlController.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        _buildYoutubeWorkoutDropdown(workouts),
        const SizedBox(height: 12),
        _buildSelectedWorkoutSummary(
          _selectedYoutubeWorkouts
              .map((workout) => workout['`']?.toString() ?? 'Workout')
              .toList(),
        ),
      ],
    );
  }

  Widget _buildYoutubeWorkoutDropdown(List<Map<String, dynamic>> workouts) {
    return _buildMultiSelectDropdownShell(
      label: 'YouTube Workouts',
      valueText: _selectedYoutubeWorkouts.isEmpty
          ? 'Select one or more videos'
          : '${_selectedYoutubeWorkouts.length} selected',
      child: PopupMenuButton<int>(
        tooltip: 'Select YouTube workouts',
        position: PopupMenuPosition.under,
        onSelected: (index) {
          final workout = workouts[index];
          setState(() {
            final exists = _selectedYoutubeWorkouts.any(
              (selected) =>
                  selected['Training Video'] == workout['Training Video'],
            );
            if (exists) {
              _selectedYoutubeWorkouts.removeWhere(
                (selected) =>
                    selected['Training Video'] == workout['Training Video'],
              );
            } else {
              _selectedYoutubeWorkouts.add(workout);
            }
          });
        },
        itemBuilder: (context) {
          return List.generate(workouts.length, (index) {
            final workout = workouts[index];
            final isSelected = _selectedYoutubeWorkouts.any(
              (selected) =>
                  selected['Training Video'] == workout['Training Video'],
            );
            return PopupMenuItem<int>(
              value: index,
              child: _buildPopupCheckboxRow(
                title: workout['`']?.toString() ?? 'Workout',
                isSelected: isSelected,
              ),
            );
          });
        },
        child: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _darkColor,
      ),
      filled: true,
      fillColor: const Color(0xFFFBF7F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildMultiSelectDropdownShell({
    required String label,
    required String valueText,
    required Widget child,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectedWorkoutSummary(List<String> titles) {
    if (titles.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No videos selected yet',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _mutedColor,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: titles.take(8).map((title) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _softPrimary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
          ),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLibrarySelector() {
    if (_libraryFolders.isEmpty) {
      return _buildEmptyLibraryState();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Drive Library',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _mutedColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showFolderIdDialog,
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Set Folder ID',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: _libraryFolders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final folder = _libraryFolders[index];
              return _buildFolderCard(folder);
            },
          ),
        ),
        if (_selectedLibraryFolderId != null) ...[
          const SizedBox(height: 16),
          _isVideosLoading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildVideoSelector(),
        ],
      ],
    );
  }

  Widget _buildFolderCard(Map<String, String> folder) {
    final isSelected = _selectedLibraryFolderId == folder['id'];

    return GestureDetector(
      onTap: () {
        final id = folder['id'];
        if (id == null) return;

        setState(() => _selectedLibraryFolderId = id);
        _fetchVideos(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 145,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? _softPrimary : const Color(0xFFFBF7F4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.28)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniIcon(Icons.folder_open_rounded),
                const Spacer(),
                Text(
                  folder['name'] ?? 'Folder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to load videos',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    if (_folderVideos.isEmpty) {
      return Text(
        'No videos found in this folder',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.redAccent,
        ),
      );
    }

    final selectedTitles = _folderVideos
        .where((video) => _selectedDriveVideoIds.contains(video.id))
        .map((video) => video.name)
        .toList();

    return Column(
      children: [
        _buildMultiSelectDropdownShell(
          label: 'Google Drive Videos',
          valueText: _selectedDriveVideoIds.isEmpty
              ? 'Select one or more videos'
              : '${_selectedDriveVideoIds.length} selected',
          child: PopupMenuButton<String>(
            tooltip: 'Select Google Drive videos',
            position: PopupMenuPosition.under,
            onSelected: (videoId) {
              setState(() {
                if (_selectedDriveVideoIds.contains(videoId)) {
                  _selectedDriveVideoIds.remove(videoId);
                } else {
                  _selectedDriveVideoIds.add(videoId);
                }
              });
            },
            itemBuilder: (context) {
              return _folderVideos.map((video) {
                return PopupMenuItem<String>(
                  value: video.id,
                  child: _buildPopupCheckboxRow(
                    title: video.name,
                    isSelected: _selectedDriveVideoIds.contains(video.id),
                  ),
                );
              }).toList();
            },
            child: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ),
        const SizedBox(height: 12),
        _buildSelectedWorkoutSummary(selectedTitles),
      ],
    );
  }

  Widget _buildPopupCheckboxRow({
    required String title,
    required bool isSelected,
  }) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.divider,
              width: 1.4,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: _darkColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLibraryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          _miniIcon(Icons.folder_off_outlined, size: 48, iconSize: 26),
          const SizedBox(height: 14),
          Text(
            'Library Not Connected',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open your Google Drive folder, share it as anyone with link, then paste folder ID.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 18),
          _smallPrimaryButton(
            text: 'Connect My Drive',
            onTap: _showFolderIdDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    bool isMultiline = false,
    TextEditingController? controller,
    IconData icon = Icons.edit_rounded,
  }) {
    return Container(
      height: isMultiline ? 92 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          _miniIcon(icon, size: 34, iconSize: 18),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: isMultiline ? 3 : 1,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _darkColor,
              ),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _darkColor,
                ),
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor.withOpacity(0.72),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayPlanner() {
    const days = [(1, 'Mon'), (2, 'Tue'), (3, 'Wed'), (4, 'Thu'), (5, 'Fri')];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniIcon(Icons.calendar_month_rounded, size: 34, iconSize: 18),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Weekly Plan',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
              ),
              Text(
                '${_selectedWeekdays.length} days',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: days.map((day) {
              final isSelected = _selectedWeekdays.contains(day.$1);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: day.$1 == 5 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedWeekdays.remove(day.$1);
                        } else {
                          _selectedWeekdays.add(day.$1);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        day.$2,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : _mutedColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleModeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildScheduleModeButton(
              label: 'Daily',
              subtitle: 'Assign today',
              icon: Icons.today_rounded,
              isSelected: !_isWeeklyPlan,
              onTap: () => setState(() => _isWeeklyPlan = false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildScheduleModeButton(
              label: 'Weekly',
              subtitle: 'Pick days',
              icon: Icons.calendar_view_week_rounded,
              isSelected: _isWeeklyPlan,
              onTap: () => setState(() => _isWeeklyPlan = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleModeButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : _darkColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white.withOpacity(0.78)
                          : _mutedColor,
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

  Widget _buildClientSearch() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _miniIcon(Icons.search_rounded, size: 34, iconSize: 18),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _darkColor,
              ),
              decoration: InputDecoration(
                hintText: 'Search clients...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCheckbox(UserModel client) {
    final isSelected = _selectedClientIds.contains(client.uid);
    final name = client.fullName ?? 'Client';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedClientIds.remove(client.uid);
          } else {
            _selectedClientIds.add(client.uid);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _softPrimary : const Color(0xFFFBF7F4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.30)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.22),
                        AppTheme.primary,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
                Text(
                  isSelected ? 'Selected' : 'Tap select',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton(String coachId) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAssigning ? null : () => _handleAssignWorkouts(coachId),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withOpacity(0.45),
          elevation: 0,
          shadowColor: AppTheme.primary.withOpacity(0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: _isAssigning
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Assign to Selected Clients',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryView(String coachId) {
    return Column(
      children: [
        _buildClientSearch(),
        const SizedBox(height: 18),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getCoachAssignmentsHistoryStream(coachId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final history = snapshot.data ?? [];

            if (history.isEmpty) {
              return _buildSmallEmptyState(
                icon: Icons.history_rounded,
                title: 'No assignment history found',
              );
            }

            return Column(
              children: history.map((assignment) {
                return _buildHistoryCard(assignment);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> assignment) {
    final title = assignment['workoutTitle'] ?? 'Workout';
    final date = (assignment['assignedAt'] as String).split('T').first;
    final status = assignment['status'] ?? 'pending';
    final completed = status == 'completed';
    final clientId = assignment['clientId'] ?? '';
    final assignmentId = assignment['id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniIcon(Icons.videocam_rounded, size: 50, iconSize: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<UserModel?>(
                  future: DatabaseService().getUserProfile(clientId),
                  builder: (context, snapshot) {
                    final name = snapshot.data?.fullName ?? '...';
                    return Text(
                      'Assigned to $name • $date',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _mutedColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: completed ? const Color(0xFFEAF8EF) : _softPrimary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 14,
                        color: completed ? _greenColor : AppTheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        completed ? 'Completed' : 'Pending',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: completed ? _greenColor : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: _mutedColor),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(assignmentId);
              } else if (value == 'edit') {
                _showEditDialog(assignment);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniIcon(IconData icon, {double size = 38, double iconSize = 21}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.38),
      ),
      child: Icon(icon, color: AppTheme.primary, size: iconSize),
    );
  }

  Widget _smallPrimaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildSmallEmptyState({
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          _miniIcon(icon, size: 54, iconSize: 28),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _darkColor,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF37261F).withOpacity(0.07),
          blurRadius: 35,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: const Text(
          'This will remove the assigned video from the client\'s view.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService().deleteAssignment(assignmentId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Assignment deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> assignment) {
    final titleController = TextEditingController(
      text: assignment['workoutTitle'],
    );
    final notesController = TextEditingController(text: assignment['notes']);

    DateTime editedDate = assignment['scheduledDate'] != null
        ? DateTime.parse(assignment['scheduledDate'])
        : DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Workout Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Schedule Date'),
                  subtitle: Text(
                    '${editedDate.day}/${editedDate.month}/${editedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: editedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => editedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await DatabaseService().updateAssignment(
                    assignmentId: assignment['id'],
                    workoutTitle: titleController.text,
                    notes: notesController.text,
                    scheduledDate: editedDate,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment updated')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderIdDialog() {
    final controller = TextEditingController(text: _rootFolderId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Google Drive Root Folder ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter Folder ID from Drive URL',
            helperText: "Tip: Use 'root' for your main Drive",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rootFolderId = controller.text;
                _fetchLibrary();
              });
              Navigator.pop(context);
            },
            child: const Text('Save & Sync'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentWorkoutDraft {
  final String title;
  final String videoUrl;
  final String sourceType;
  final Map<String, dynamic>? youtubeWorkout;
  final Map<String, dynamic>? driveWorkout;

  const _AssignmentWorkoutDraft({
    required this.title,
    required this.videoUrl,
    required this.sourceType,
    this.youtubeWorkout,
    this.driveWorkout,
  });
}

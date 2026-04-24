import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import 'exercise_detail_screen.dart';
import '../../services/google_drive_service.dart';
import 'workout_complete_screen.dart';

class ExerciseFetchScreen extends StatefulWidget {
  final String driveUrl;
  final VoidCallback? onProgressUpdated;
  final VoidCallback? onNavigateHome;
  final VoidCallback? onNavigateProgress;

  const ExerciseFetchScreen({
    super.key,
    required this.driveUrl,
    this.onProgressUpdated,
    this.onNavigateHome,
    this.onNavigateProgress,
  });

  @override
  State<ExerciseFetchScreen> createState() => _ExerciseFetchScreenState();
}

class _ExerciseFetchScreenState extends State<ExerciseFetchScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<String> _exerciseNames = [];
  List<String> _filteredExercises = [];
  Map<String, String> _folderIds = {};
  List<String> _unlockedFolders = [];
  final GoogleDriveService _driveService = GoogleDriveService();
  
  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Animation Controllers
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initScreen();
  }

  @override
  void dispose() {
    _driveService.dispose();
    _searchController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('imported_exercises');

    if (stored != null && stored.isNotEmpty) {
      final unlocked = prefs.getStringList('unlocked_folders') ?? [];
      final folderIdsJson = prefs.getString('folder_ids');
      final Map<String, String> folderIds = {};
      if (folderIdsJson != null) {
        try {
          final map = jsonDecode(folderIdsJson) as Map<String, dynamic>;
          map.forEach((key, value) => folderIds[key] = value.toString());
        } catch (e) {
          debugPrint('Failed to decode folder_ids: $e');
        }
      }

      setState(() {
        _exerciseNames = stored;
        _filteredExercises = stored;
        _folderIds = folderIds;
        _unlockedFolders = unlocked.isEmpty && stored.isNotEmpty
            ? [stored.first]
            : unlocked;
        _isLoading = false;
      });
      _listAnimationController.forward();
    } else {
      _fetchExercises();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredExercises = _exerciseNames
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
    // Restart animation for filtered results
    _listAnimationController.reset();
    _listAnimationController.forward();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredExercises = _exerciseNames;
        _listAnimationController.reset();
        _listAnimationController.forward();
      }
    });
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mainFolderId = widget.driveUrl
          .split('/folders/')
          .last
          .split('?')
          .first;

      final subfolders = await _driveService.fetchSubfolders(mainFolderId);

      final Map<String, String> folderIdMap = {};
      final List<String> names = [];

      for (var folder in subfolders) {
        final name = folder['name']!;
        final id = folder['id']!;
        names.add(name);
        folderIdMap[name] = id;
      }

      names.sort();

      setState(() {
        _exerciseNames = names;
        _filteredExercises = names;
        _folderIds = folderIdMap;
        if (_unlockedFolders.isEmpty && names.isNotEmpty) {
          _unlockedFolders = [names.first];
        }
        _isLoading = false;
      });
      _listAnimationController.forward();

      if (names.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('imported_exercises', names);
        await prefs.setString('folder_ids', jsonEncode(folderIdMap));
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch categories: $e';
        _isLoading = false;
      });
    }
  }

  bool _isLocked(String folderName) {
    if (_unlockedFolders.isEmpty && _exerciseNames.isNotEmpty) {
      _unlockedFolders.add(_exerciseNames.first);
      _saveUnlockedProgress();
    }
    return !_unlockedFolders.contains(folderName);
  }

  Future<void> _saveUnlockedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_folders', _unlockedFolders);
  }

  void _unlockNext(String currentFolder) {
    final currentIndex = _exerciseNames.indexOf(currentFolder);
    if (currentIndex != -1 && currentIndex < _exerciseNames.length - 1) {
      final nextFolder = _exerciseNames[currentIndex + 1];
      if (!_unlockedFolders.contains(nextFolder)) {
        setState(() {
          _unlockedFolders.add(nextFolder);
        });
        _saveUnlockedProgress();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 New Category Unlocked: ${nextFolder.toUpperCase()}!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  // Title
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    left: _isSearching ? -60 : 0,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isSearching ? 0.0 : 1.0,
                        child: const Text(
                          'Exercises',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Refresh Button
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    right: _isSearching ? -60 : 54,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isSearching ? 0.0 : 1.0,
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.textDark, size: 22),
                        onPressed: _isSearching ? null : _fetchExercises,
                      ),
                    ),
                  ),

                  // Search Field Expanding Background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    right: 54,
                    left: _isSearching ? 0 : constraints.maxWidth - 54,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isSearching ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: constraints.maxWidth - 54,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: false, // Don't autofocus to avoid keyboard popping aggressively
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Find your workout...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14),
                                    ),
                                    onChanged: _onSearchChanged,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Search Icon / Close Icon
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _toggleSearch,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isSearching ? AppTheme.primary : const Color(0xFFF7EBE8),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isSearching ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ] : [],
                        ),
                        child: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: _isSearching ? Colors.white : AppTheme.textDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: const [
          SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
          ? _buildErrorView()
          : _buildExerciseList(),
    );
  }



  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchExercises,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_filteredExercises.isEmpty && _isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              ),
              child: Icon(Icons.search_off_rounded, size: 80, color: AppTheme.textLight.withOpacity(0.3)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No workouts found',
              style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final name = _filteredExercises[index];
        return AnimatedBuilder(
          animation: _listAnimationController,
          builder: (context, child) {
            final delay = index * 0.1;
            final start = delay.clamp(0.0, 1.0);
            final end = (delay + 0.5).clamp(0.0, 1.0);
            
            final opacity = CurvedAnimation(
              parent: _listAnimationController,
              curve: Interval(start, end, curve: Curves.easeOut),
            ).value;
            
            final slide = CurvedAnimation(
              parent: _listAnimationController,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            ).value;

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - slide)),
                child: child,
              ),
            );
          },
          child: _buildExerciseCard(name),
        );
      },
    );
  }

  Widget _buildExerciseCard(String title) {
    final categoryImages = {
      'arms': 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=2070',
      'back': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=2070',
      'biceps': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070',
      'cardio': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=1974',
      'chest': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070',
      'glutes': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=2070',
      'legs': 'https://images.unsplash.com/photo-1434608519344-49d77a699e1d?q=80&w=2070',
      'shoulder': 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=2070',
      'triceps': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=1974',
    };

    final imageUrl = categoryImages[title.toLowerCase()] ??
        categoryImages.values.elementAt(title.length % categoryImages.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                        stops: const [0.0, 0.4],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9E5C62),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bookmark_border_rounded, size: 18, color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Imported from Google Drive • Exercise Set',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStat(Icons.timer_outlined, '15 min'),
                    const SizedBox(width: 20),
                    _buildStat(Icons.local_fire_department_outlined, '120 kcal'),
                    const SizedBox(width: 20),
                    _buildStat(Icons.bar_chart_rounded, 'Intermediate'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLocked(title)
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExerciseDetailScreen(
                                  folderName: title,
                                  folderId: _folderIds[title],
                                ),
                              ),
                            );

                            if (result is WorkoutCompletionAction) {
                              _unlockNext(title);
                              widget.onProgressUpdated?.call();
                              if (result == WorkoutCompletionAction.backHome) {
                                widget.onNavigateHome?.call();
                              } else if (result ==
                                  WorkoutCompletionAction.viewProgress) {
                                widget.onNavigateProgress?.call();
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLocked(title) ? Colors.grey[300] : AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLocked(title) ? 'LOCKED' : 'START EXERCISE',
                          style: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_isLocked(title) ? Icons.lock_outline_rounded : Icons.play_circle_fill_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
      ],
    );
  }
}

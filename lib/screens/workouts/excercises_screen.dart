import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import 'exercise_detail_screen.dart';
import '../../services/google_drive_service.dart';

class ExerciseFetchScreen extends StatefulWidget {
  final String driveUrl;
  const ExerciseFetchScreen({super.key, required this.driveUrl});

  @override
  State<ExerciseFetchScreen> createState() => _ExerciseFetchScreenState();
}

class _ExerciseFetchScreenState extends State<ExerciseFetchScreen> {
  bool _isLoading = true;
  String? _error;
  List<String> _exerciseNames = [];
  Map<String, String> _folderIds = {};
  List<String> _unlockedFolders = []; // List of folder names that are unlocked
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void dispose() {
    _driveService.dispose();
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
        _folderIds = folderIds;
        _unlockedFolders = unlocked.isEmpty && stored.isNotEmpty ? [stored.first] : unlocked;
        _isLoading = false;
      });
    } else {
      _fetchExercises();
    }
  }

  Future<void> _saveUnlockedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_folders', _unlockedFolders);
  }

  bool _isLocked(String folderName) {
    // If we have no unlocked folders yet, unlock the first one
    if (_unlockedFolders.isEmpty && _exerciseNames.isNotEmpty) {
      _unlockedFolders.add(_exerciseNames.first);
      _saveUnlockedProgress();
    }
    return !_unlockedFolders.contains(folderName);
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

  String _convertUrl(String url) {
    // Handle Folders
    if (url.contains('/folders/')) {
      final regExp = RegExp(r'/folders/([a-zA-Z0-9-_]{25,})');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        // Using the embedded view which is MUCH easier to parse without login
        return 'https://drive.google.com/embeddedfolderview?id=$id';
      }
    }
    // Handle Spreadsheets
    if (url.contains('/spreadsheets/d/')) {
      final regExp = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        return 'https://docs.google.com/spreadsheets/d/$id/export?format=csv';
      }
    }
    // Handle regular files
    if (url.contains('/file/d/')) {
      final regExp = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final id = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }
    return url;
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
        _folderIds = folderIdMap;
        if (_unlockedFolders.isEmpty && names.isNotEmpty) {
          _unlockedFolders = [names.first];
        }
        _isLoading = false;
      });

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

  Future<void> _saveAndFinish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('imported_exercises', _exerciseNames);

      if (!mounted) return;

      // We don't need a snackbar here as it's auto-saving
      // Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Failed to auto-save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textDark,
              size: 22,
            ),
            onPressed: _fetchExercises,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EBE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.search,
                  color: AppTheme.textDark,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchExercises,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exerciseNames.length,
              itemBuilder: (context, index) {
                final name = _exerciseNames[index];
                return _buildExerciseCard(name);
              },
            ),
    );
  }

  Widget _buildExerciseCard(String title) {
    // Generate a different image for each category for better look
    final categoryImages = {
      'arms':
          'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=2070',
      'back':
          'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=2070',
      'biceps':
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070',
      'cardio':
          'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=1974',
      'chest':
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070',
      'glutes':
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=2070',
      'legs':
          'https://images.unsplash.com/photo-1434608519344-49d77a699e1d?q=80&w=2070',
      'shoulder':
          'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=2070',
      'triceps':
          'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=1974',
    };

    final imageUrl =
        categoryImages[title.toLowerCase()] ??
        categoryImages.values.elementAt(title.length % categoryImages.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  // Dark gradient overlay for badges
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 18,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RAW GOOGLE DRIVE NAME
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

                // Stats Row
                Row(
                  children: [
                    _buildStat(Icons.timer_outlined, '15 min'),
                    const SizedBox(width: 20),
                    _buildStat(
                      Icons.local_fire_department_outlined,
                      '120 kcal',
                    ),
                    const SizedBox(width: 20),
                    _buildStat(Icons.bar_chart_rounded, 'Intermediate'),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLocked(title) ? null : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(
                            folderName: title,
                            folderId: _folderIds[title],
                          ),
                        ),
                      );
                      
                      if (result == true) {
                        _unlockNext(title);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLocked(title) ? Colors.grey[300] : AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLocked(title) ? 'LOCKED' : 'START EXERCISE',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isLocked(title) ? Icons.lock_outline_rounded : Icons.play_circle_fill_rounded, 
                          size: 20
                        ),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

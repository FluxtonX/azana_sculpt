import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutTestingScreen extends StatefulWidget {
  const WorkoutTestingScreen({super.key});

  @override
  State<WorkoutTestingScreen> createState() => _WorkoutTestingScreenState();
}

class _WorkoutTestingScreenState extends State<WorkoutTestingScreen> {
  Map<String, List<dynamic>> _categoryGroups = {};
  List<String> _categories = [];
  bool _isLoading = true;
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      setState(() => _debugInfo = "Loading JSON...");
      final String response = await rootBundle.loadString('assets/data/workout.json');
      final List<dynamic> data = json.decode(response);

      Map<String, List<dynamic>> groups = {};
      String currentCategory = "GENERAL";
      List<String> categoryNames = [];

      int itemsProcessed = 0;
      int categoriesFound = 0;

      for (var item in data) {
        itemsProcessed++;
        // Use backtick as key, or fallback to first key if backtick doesn't exist
        String name = (item['`']?.toString() ?? item.values.first?.toString() ?? '').trim();
        String video = (item['Training Video']?.toString() ?? '').trim();
        
        // Lenient category detection: 
        // If it has no video link/name AND has a name, it's likely a category header
        bool isCategory = video.isEmpty && name.isNotEmpty;
        
        if (isCategory) {
          currentCategory = name;
          categoriesFound++;
          if (!categoryNames.contains(currentCategory)) {
            categoryNames.add(currentCategory);
          }
          groups[currentCategory] = [];
        } else if (name.isNotEmpty) {
          if (!groups.containsKey(currentCategory)) {
            groups[currentCategory] = [];
            if (!categoryNames.contains(currentCategory)) categoryNames.add(currentCategory);
          }
          groups[currentCategory]!.add(item);
        }
      }

      setState(() {
        _categoryGroups = groups;
        _categories = categoryNames;
        _isLoading = false;
        _debugInfo = "Processed $itemsProcessed items, found $categoriesFound categories.";
      });
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      setState(() {
        _isLoading = false;
        _debugInfo = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Workout Lab',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB9FF66)))
          : _categories.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No categories found", style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(_debugInfo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final exerciseCount = _categoryGroups[category]?.length ?? 0;

                if (exerciseCount == 0) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryExerciseListScreen(
                          categoryName: category,
                          exercises: _categoryGroups[category]!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B1B1F),
                          const Color(0xFF1B1B1F).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFB9FF66).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.fitness_center,
                            size: 100,
                            color: const Color(0xFFB9FF66).withOpacity(0.05),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category,
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$exerciseCount Exercises Available',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: const Color(0xFFB9FF66),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Positioned(
                          right: 24,
                          top: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white24,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CategoryExerciseListScreen extends StatelessWidget {
  final String categoryName;
  final List<dynamic> exercises;

  const CategoryExerciseListScreen({
    super.key,
    required this.categoryName,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final workout = exercises[index];
          final String name = workout['`'] ?? 'Unknown';
          final String videoUrl = workout['Training Video'] ?? '';
          final bool hasVideo = videoUrl.isNotEmpty && videoUrl.startsWith('http');

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasVideo ? const Color(0xFFB9FF66).withOpacity(0.1) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  title: Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          hasVideo ? Icons.play_circle_fill : Icons.videocam_off_outlined,
                          size: 18,
                          color: hasVideo ? const Color(0xFFB9FF66) : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasVideo ? 'Tutorial Available' : 'No Video Available',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: hasVideo ? const Color(0xFFB9FF66) : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: hasVideo 
                    ? IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white54),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(url: videoUrl, title: name),
                            ),
                          );
                        },
                      )
                    : null,
                ),
                if (hasVideo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveWorkoutScreen(workout: workout),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB9FF66),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'START WORKOUT',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> workout;
  const ActiveWorkoutScreen({super.key, required this.workout});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.workout['Training Video']?.toString() ?? '');
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        disableDragSeek: false,
        loop: true,
        isLive: false,
        forceHD: false,
        enableCaption: true,
        useHybridComposition: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube() async {
    final url = widget.workout['Training Video']?.toString() ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.workout['`']?.toString() ?? 'Workout';
    
    // Define the stats to display based on user request
    final stats = [
      {'label': 'WORKING SETS', 'value': widget.workout['WORKING SETS']?.toString() ?? ''},
      {'label': 'REPS', 'value': widget.workout['REPS']?.toString() ?? ''},
      {'label': 'TEMPO', 'value': widget.workout['TEMPO']?.toString() ?? ''},
      {'label': 'REST', 'value': widget.workout['REST']?.toString() ?? ''},
      {'label': 'ECCENTRIC', 'value': widget.workout['']?.toString() ?? ''},
      {'label': 'CONCENTRIC', 'value': widget.workout['__1']?.toString() ?? ''},
      {'label': 'ISOMETRIC', 'value': widget.workout['__2']?.toString() ?? ''},
      {'label': 'Notes', 'value': widget.workout['Notes']?.toString() ?? ''},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Area
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFB9FF66).withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: const Color(0xFFB9FF66),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _launchYouTube,
                  icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFFB9FF66), size: 16),
                  label: Text(
                    "Video stuck? Play in YouTube App",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFB9FF66),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stat['label']!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat['value']!.isEmpty ? '—' : stat['value']!,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: const Color(0xFFB9FF66),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Instructions/Detailed Notes Section
            if (widget.workout['NOTES'] != null && widget.workout['NOTES'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, color: Color(0xFFB9FF66), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "DETAILED INSTRUCTIONS",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.workout['NOTES'].toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.url);
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        useHybridComposition: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _launchYouTube,
            tooltip: 'Open in YouTube App',
          ),
        ],
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFFB9FF66),
        ),
      ),
    );
  }
}

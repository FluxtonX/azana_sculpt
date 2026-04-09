import 'dart:io';
import 'package:azana_sculpt/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/badge_service.dart';
import '../../services/streak_service.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart';
import '../login/login_screen.dart';
import 'badges_screen.dart';
import '../programs/premium_programs_screen.dart';
import 'client_edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<BadgeModel> _unlockedBadges = [];
  int _streakCount = 0;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _loadGamificationData();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('client_profile_image_$uid');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _localImageFile = File(imagePath);
      });
    }
  }

  Future<void> _loadGamificationData() async {
    final streak = await StreakService().loadStreak();
    final badges = await BadgeService().loadUnlockedBadges();
    if (mounted) {
      setState(() {
        _streakCount = streak.currentStreak;
        _unlockedBadges = badges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = AuthService().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return StreamBuilder<UserModel?>(
      stream: DatabaseService().userProfileStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: RefreshIndicator(
            onRefresh: () async {
              await _loadGamificationData();
              await _loadLocalImage();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      _buildProfileHeader(user),
                      Positioned(
                        top: 220,
                        left: 20,
                        right: 20,
                        child: _buildStatsOverlay(user),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildProfileInfoCard(user),
                        const SizedBox(height: 24),
                        if (_unlockedBadges.isNotEmpty) ...[
                          _buildBadgesPreviewRow(context),
                          const SizedBox(height: 24),
                        ],
                        _buildMenuSection(context, user),
                        const SizedBox(height: 24),
                        _buildPremiumCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    final avatarUrl =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?.fullName ?? 'User')}&background=random&color=fff';

    return Container(
      width: double.infinity,
      height: 280,
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: _localImageFile != null
                  ? FileImage(_localImageFile!) as ImageProvider
                  : NetworkImage(avatarUrl),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'User Profile',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'user@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.fitness_center_rounded,
                user?.activityLevel?.split(' ')[0] ?? 'Active',
                'Level',
              ),
              _buildStatItem(
                Icons.track_changes_rounded,
                '${user?.weight ?? "0"}${user?.weightUnit ?? "kg"}',
                'Current',
              ),
              _buildStatItem(
                Icons.local_fire_department_rounded,
                '$_streakCount${_streakCount >= 7 ? " 🔥" : ""}',
                'Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCard(UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Age Range', user?.ageRange ?? 'Not set'),
          const Divider(height: 32),
          _buildInfoRow(
            'Height',
            '${user?.height ?? "-"} ${user?.heightUnit ?? "cm"}',
          ),
          const Divider(height: 32),
          _buildInfoRow(
            'Current Weight',
            '${user?.weight ?? "-"} ${user?.weightUnit ?? "kg"}',
          ),
          const SizedBox(height: 24),
          const Text(
            'Primary Goal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user?.fitnessGoal != null) _buildGoalTag(user!.fitnessGoal!),
              if (user?.coachingPreference != null)
                _buildGoalTag('Coaching Requested'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppTheme.textLight),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildBadgesPreviewRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BadgesScreen()),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _unlockedBadges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final badge = _unlockedBadges[i];
                return Tooltip(
                  message: badge.title,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        badge.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.person_outline_rounded,
            'Edit Profile',
            onTap: () async {
              if (user != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientEditProfileScreen(user: user),
                  ),
                );
                _loadLocalImage();
              }
            },
          ),
          StreamBuilder<int>(
            stream: (user?.role == 'coach')
                ? DatabaseService().getUnreadMessagesCountStream(user!.uid)
                : (user?.coachId != null)
                    ? DatabaseService().getChatUnreadCountStream('${user!.uid}_${user!.coachId}', user!.uid)
                    : Stream.value(0),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return _buildMenuItem(
                'assets/icons/message.png',
                'Messages',
                badgeCount: unreadCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagesScreen(isActive: true)),
                  );
                },
              );
            },
          ),
          _buildMenuItem(
            Icons.track_changes_rounded,
            'Goals & Preferences',
            onTap: () {},
          ),
          _buildMenuItem(
            Icons.emoji_events_rounded,
            'Achievements',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
          ),
          _buildMenuItem(
            Icons.workspace_premium_rounded,
            'Elite Access',
            iconColor: AppTheme.accent,
            textColor: AppTheme.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumProgramsScreen()),
            ),
          ),
          _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () {}),
          _buildMenuItem(
            Icons.logout_rounded,
            'Log Out',
            isTrailing: false,
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    dynamic icon,
    String title, {
    bool isTrailing = true,
    Color iconColor = AppTheme.textDark,
    Color textColor = AppTheme.textDark,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildLeadingIcon(icon, iconColor),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: isTrailing
          ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLeadingIcon(dynamic icon, Color color) {
    if (icon is IconData) {
      return Icon(icon, color: color, size: 22);
    } else if (icon is String) {
      return Image.asset(
        icon,
        width: 22,
        height: 22,
        color: color,
      );
    }
    return const SizedBox(width: 22, height: 22);
  }

  Widget _buildPremiumCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumProgramsScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCDA96E), Color(0xFFD4847A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Unlock Elite Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Elite members see 3× better results on average.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.88),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildEliteChip('Advanced Programmes'),
                const SizedBox(width: 8),
                _buildEliteChip('Meal Plans'),
                const SizedBox(width: 8),
                _buildEliteChip('Coaching'),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Upgrade for your full transformation →',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEliteChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

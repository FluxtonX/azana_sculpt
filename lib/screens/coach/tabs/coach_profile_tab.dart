import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../models/user_model.dart';
import '../coach_edit_profile_screen.dart';

class CoachProfileTab extends StatefulWidget {
  const CoachProfileTab({super.key});

  @override
  State<CoachProfileTab> createState() => _CoachProfileTabState();
}

class _CoachProfileTabState extends State<CoachProfileTab> {
  // Card approx height for overlap calculation
  static const double _statsCardHeight = 185.0;
  static const double _overlapAmount = 85.0;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('coach_profile_image_$uid');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _localImageFile = File(imagePath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F6),
        body: Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: StreamBuilder<UserModel?>(
        stream: DatabaseService().userProfileStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final user = snapshot.data;

          return RefreshIndicator(
            onRefresh: () async {
              await _loadLocalImage();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header + Stats Card overlapping ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildGradientHeader(user),
                      Positioned(
                        bottom: -_overlapAmount,
                        left: 20,
                        right: 20,
                        child: _buildStatsCard(user),
                      ),
                    ],
                  ),

                  // Spacer = remaining card height that wasn't covered by overlap
                  const SizedBox(height: _statsCardHeight - _overlapAmount + 20),

                  // ── About & Specialties ──
                  _buildAboutAndSpecialtiesCard(user),
                  const SizedBox(height: 16),

                  // ── Member Since / Status ──
                  _buildMemberStatusCard(user),
                  const SizedBox(height: 16),

                  // ── Menu Items ──
                  _buildMenuSection(context, user),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildGradientHeader(UserModel? user) {
    final name = user?.fullName ?? 'Coach';
    final email = user?.email ?? 'No Email Provided';
    final avatarUrl =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: _overlapAmount + 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: _localImageFile != null 
                      ? FileImage(_localImageFile!) as ImageProvider
                      : NetworkImage(avatarUrl),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Text(
                  'Professional Coach',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  YOUR STATS CARD
  // ─────────────────────────────────────────────
  Widget _buildStatsCard(UserModel? user) {
    return Container(
      height: _statsCardHeight,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                'Your Stats',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppTheme.textLight.withOpacity(0.7),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('24', 'Active\nClients', Icons.person_outline_rounded),
              _buildStatItem('12', 'Programs\nCreated', Icons.badge_outlined),
              _buildStatItem('284', 'Total\nSessions', Icons.track_changes_outlined),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          val,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textLight,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  ABOUT & SPECIALTIES CARD
  // ─────────────────────────────────────────────
  Widget _buildAboutAndSpecialtiesCard(UserModel? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About Section
            const Text(
              'About',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              user?.bio ?? 'Certified professional trainer with 10+ years experience',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
            const SizedBox(height: 16),

            // Specialties Section
            const Text(
              'Specialties',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: (user?.specialties ?? ['Strength Training', 'Weight Loss', 'HIIT'])
                  .map((s) => _buildTag(s))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4A72FF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MEMBER SINCE / STATUS CARD
  // ─────────────────────────────────────────────
  Widget _buildMemberStatusCard(UserModel? user) {
    String formattedDate = 'Unknown';
    if (user?.createdAt != null) {
      final date = user!.createdAt!;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      formattedDate = '${months[date.month - 1]} ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Member Since', style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                const SizedBox(height: 6),
                Text(formattedDate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: const Text('Active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MENU SECTION
  // ─────────────────────────────────────────────
  Widget _buildMenuSection(BuildContext context, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              Icons.person_outline_rounded, 
              'Edit Profile', 
              false,
              onTap: () async {
                if (user != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CoachEditProfileScreen(user: user)),
                  );
                  _loadLocalImage(); // Reload image after coming back
                }
              },
            ),
            _buildMenuItem(Icons.settings_outlined, 'Settings', false),
            _buildMenuItem(
              Icons.logout_rounded,
              'Log Out',
              true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, bool isLogout, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Icon(icon, color: isLogout ? const Color(0xFFE53935) : AppTheme.textDark, size: 22),
          title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isLogout ? const Color(0xFFE53935) : AppTheme.textDark)),
          trailing: Icon(Icons.chevron_right, color: AppTheme.textLight.withOpacity(0.5), size: 20),
          onTap: onTap,
        ),
        if (!isLogout) Divider(height: 1, indent: 60, endIndent: 20, thickness: 0.4, color: Colors.grey.shade200),
      ],
    );
  }
}

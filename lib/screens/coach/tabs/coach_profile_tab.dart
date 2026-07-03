
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../coach_edit_profile_screen.dart';

class CoachProfileTab extends StatefulWidget {
  const CoachProfileTab({super.key});

  @override
  State<CoachProfileTab> createState() => _CoachProfileTabState();
}

class _CoachProfileTabState extends State<CoachProfileTab> {
  File? _localImageFile;

  final Color _bgColor = const Color(0xFFF7F2EF);
  final Color _darkColor = const Color(0xFF171412);
  final Color _mutedColor = const Color(0xFF82746E);
  final Color _softPrimary = const Color(0xFFFFF1EC);
  final Color _greenColor = const Color(0xFF2E9B63);
  final Color _redColor = const Color(0xFFE53935);

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
        backgroundColor: Color(0xFFF7F2EF),
        body: Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
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
            color: AppTheme.primary,
            onRefresh: () async => _loadLocalImage(),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 115),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHero(context, user),
                    const SizedBox(height: 16),
                    _buildStatsGrid(user),
                    const SizedBox(height: 16),
                    _buildAboutAndSpecialtiesCard(user),
                    const SizedBox(height: 16),
                    _buildMemberStatusCard(user),
                    const SizedBox(height: 16),
                    _buildMenuSection(context, user),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, UserModel? user) {
    final name = user?.fullName ?? 'Coach';
    final email = user?.email ?? 'No Email Provided';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    final avatarUrl =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
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
            color: AppTheme.primary.withOpacity(0.24),
            blurRadius: 50,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -70,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -38,
            bottom: -45,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _glassPill('Coach Profile'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      if (user != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CoachEditProfileScreen(user: user),
                          ),
                        );
                        _loadLocalImage();
                      }
                    },
                    child: _glassIcon(Icons.edit_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(31),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 35,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                            image: DecorationImage(
                              image: _localImageFile != null
                                  ? FileImage(_localImageFile!)
                                  : NetworkImage(avatarUrl) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _localImageFile == null
                              ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                              : null,
                        ),
                        Positioned(
                          right: 4,
                          bottom: 5,
                          child: _onlineDot(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1,
                            letterSpacing: -0.7,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: const Text(
                            '🏆 Professional Coach',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserModel? user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '24',
            'Active\nClients',
            Icons.groups_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            '12',
            'Programs\nCreated',
            Icons.assignment_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            '284',
            'Total\nSessions',
            Icons.track_changes_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          _smallIcon(icon),
          const SizedBox(height: 9),
          Text(
            val,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutAndSpecialtiesCard(UserModel? user) {
    final specialties =
        user?.specialties ?? ['Strength Training', 'Weight Loss', 'HIIT'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'About Coach',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: _darkColor,
                ),
              ),
              const Spacer(),
              _smallIcon(Icons.auto_awesome_rounded, size: 36, iconSize: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.bio ??
                'Certified professional trainer with 10+ years experience',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.black.withOpacity(0.06)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: specialties.map((s) => _buildTag(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _softPrimary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMemberStatusCard(UserModel? user) {
    String formattedDate = 'Unknown';

    if (user?.createdAt != null) {
      final date = user!.createdAt!;
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      formattedDate = '${months[date.month - 1]} ${date.year}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 30),
      child: Row(
        children: [
          _smallIcon(Icons.calendar_month_rounded, size: 42, iconSize: 20),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Member Since',
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '● Active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _greenColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _cardDecoration(radius: 30),
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
                  MaterialPageRoute(
                    builder: (context) => CoachEditProfileScreen(user: user),
                  ),
                );
                _loadLocalImage();
              }
            },
          ),
          _buildMenuItem(Icons.settings_outlined, 'Settings', false),
          _buildMenuItem(
            Icons.logout_rounded,
            'Log Out',
            true,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFFF7F2EF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  content: const Text(
                    'Are you sure you want to log out?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppTheme.textMedium,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String label,
      bool isLogout, {
        VoidCallback? onTap,
      }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isLogout ? const Color(0xFFFFF1F0) : const Color(0xFFFBF7F4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isLogout ? _redColor : AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isLogout ? _redColor : _darkColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _mutedColor.withOpacity(0.65),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (!isLogout)
          Divider(
            height: 1,
            color: Colors.black.withOpacity(0.06),
            indent: 68,
            endIndent: 14,
          ),
      ],
    );
  }

  Widget _glassIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }

  Widget _glassPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.17)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _smallIcon(
      IconData icon, {
        double size = 38,
        double iconSize = 19,
      }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _softPrimary,
        borderRadius: BorderRadius.circular(size * 0.38),
      ),
      child: Icon(
        icon,
        color: AppTheme.primary,
        size: iconSize,
      ),
    );
  }

  Widget _onlineDot() {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: _greenColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
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
}


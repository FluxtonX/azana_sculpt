import 'package:azana_sculpt/screens/coach/client_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';

class CoachClientsTab extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const CoachClientsTab({super.key, this.onMenuPressed});

  @override
  State<CoachClientsTab> createState() => _CoachClientsTabState();
}

class _CoachClientsTabState extends State<CoachClientsTab> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All Clients';
  int _activeTabIndex = 0;

  final Color _bgColor = const Color(0xFFF7F2EF);
  final Color _darkColor = const Color(0xFF171412);
  final Color _mutedColor = const Color(0xFF82746E);
  final Color _softPrimary = const Color(0xFFFFF1EC);
  final Color _greenColor = const Color(0xFF2E9B63);
  final Color _orangeColor = const Color(0xFFF59E0B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';
    final coachEmail = AuthService().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getPendingPaymentRequestsStream(
            coachEmail.toLowerCase(),
          ),
          builder: (context, pendingSnapshot) {
            final pendingRequests = pendingSnapshot.data ?? [];
            final pendingCount = pendingRequests.length;

            return StreamBuilder<List<UserModel>>(
              stream: DatabaseService().getCoachClientsStream(coachId),
              builder: (context, activeSnapshot) {
                final activeClients = activeSnapshot.data ?? [];

                final uniqueClientsMap = <String, UserModel>{};
                for (final client in activeClients) {
                  uniqueClientsMap[client.uid] = client;
                }

                final uniqueClients = uniqueClientsMap.values.toList();

                final filteredClients = uniqueClients.where((client) {
                  final query = _searchQuery.toLowerCase();

                  final matchesSearch =
                      (client.fullName ?? '').toLowerCase().contains(query) ||
                          client.email.toLowerCase().contains(query);

                  if (_selectedFilter == 'Active') {
                    return matchesSearch && (client.streakCount ?? 0) > 0;
                  } else if (_selectedFilter == 'At Risk') {
                    return matchesSearch && (client.streakCount ?? 0) == 0;
                  }

                  return matchesSearch;
                }).toList();

                return Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                              const EdgeInsets.fromLTRB(20, 18, 20, 0),
                              child: Column(
                                children: [
                                  _buildHeroHeader(
                                    activeCount: uniqueClients.length,
                                    pendingCount: pendingCount,
                                  ),
                                  const SizedBox(height: 22),
                                  _buildCustomTabBar(pendingCount),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          if (_activeTabIndex == 0)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildSearchAndFilter(),
                              ),
                            ),
                          if (_activeTabIndex == 0)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 18),
                            ),
                          if (_activeTabIndex == 0)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildSectionHeader(
                                  title: 'Approved Clients',
                                  actionText: _selectedFilter,
                                  onTap: _showFilterSheet,
                                ),
                              ),
                            ),
                          if (_activeTabIndex == 0)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 12),
                            ),
                          if (_activeTabIndex == 0)
                            _buildActiveClientsSliver(
                              filteredClients,
                              activeSnapshot.connectionState ==
                                  ConnectionState.waiting,
                            )
                          else
                            _buildPendingRequestsSliver(
                              pendingRequests,
                              pendingSnapshot.connectionState ==
                                  ConnectionState.waiting,
                              coachId,
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 110),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required int activeCount,
    required int pendingCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 45,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -58,
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -45,
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassPill('Coach Clients'),
                  GestureDetector(
                    onTap: widget.onMenuPressed,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'My Clients',
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Manage approved clients and review new payment requests.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.76),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStat(
                      value: activeCount.toString(),
                      label: 'Active Transformations',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeroStat(
                      value: pendingCount.toString(),
                      label: 'Pending Requests',
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

  Widget _buildGlassPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.17)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeroStat({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(int pendingCount) {
    return Row(
      children: [
        _buildTabItem(
          0,
          'Approved',
          Icons.check_box_rounded,
        ),
        const SizedBox(width: 12),
        _buildTabItem(
          1,
          'Pending',
          Icons.access_time_filled_rounded,
          badgeCount: pendingCount,
        ),
      ],
    );
  }

  Widget _buildTabItem(
      int index,
      String label,
      IconData icon, {
        int badgeCount = 0,
      }) {
    final isSelected = _activeTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 58,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.28)
                    : const Color(0xFF37261F).withOpacity(0.06),
                blurRadius: isSelected ? 30 : 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : _mutedColor,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : _mutedColor,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 7),
                Container(
                  constraints: const BoxConstraints(minWidth: 21),
                  height: 21,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.20)
                        : AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            decoration: _cardDecoration(radius: 22),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _mutedColor.withOpacity(0.55),
                  size: 24,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _darkColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for a client...',
                      hintStyle: GoogleFonts.outfit(
                        color: _mutedColor.withOpacity(0.65),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: _mutedColor.withOpacity(0.55),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _softPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: _darkColor,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveClientsSliver(
      List<UserModel> filteredClients,
      bool isLoading,
      ) {
    if (isLoading && filteredClients.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredClients.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No clients found',
          subtitle: 'Try changing your search or filter.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(
        itemCount: filteredClients.length,
        itemBuilder: (context, index) {
          return _buildClientCard(filteredClients[index]);
        },
      ),
    );
  }

  Widget _buildPendingRequestsSliver(
      List<Map<String, dynamic>> requests,
      bool isLoading,
      String coachId,
      ) {
    if (isLoading && requests.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(
          icon: Icons.mark_email_read_rounded,
          title: 'No pending approvals',
          subtitle: 'New client payment requests will appear here.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      sliver: SliverList.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildPendingCard(requests[index], coachId);
        },
      ),
    );
  }

  Widget _buildClientCard(UserModel client) {
    final name = client.fullName ?? 'Client';
    final goal = client.fitnessGoal ?? 'Lose Weight';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final isActive = (client.streakCount ?? 0) > 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailScreen(client: client),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(radius: 30),
        child: Row(
          children: [
            Hero(
              tag: 'client_avatar_${client.uid}',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary.withOpacity(0.20),
                          AppTheme.primary,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: isActive ? _greenColor : _orangeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _darkColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    client.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _mutedColor,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _buildChip(
                        icon: goal.toLowerCase().contains('lose')
                            ? Icons.local_fire_department_rounded
                            : Icons.bolt_rounded,
                        label: goal,
                        color: AppTheme.primary,
                        bgColor: _softPrimary,
                      ),
                      _buildChip(
                        icon: Icons.circle,
                        label: isActive
                            ? '${client.streakCount ?? 0} Streak'
                            : 'At Risk',
                        color: isActive ? _greenColor : _orangeColor,
                        bgColor: isActive
                            ? const Color(0xFFEAF8EF)
                            : const Color(0xFFFFF6DF),
                        smallIcon: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> request, String coachId) {
    final email = request['email'] ?? 'No Email';
    final uid = request['uid'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _orangeColor.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: _orangeColor.withOpacity(0.08),
            blurRadius: 35,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6DF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.person_add_rounded,
              color: _orangeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Wants to join your team',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService().updatePaymentRequestStatus(
                uid: uid,
                status: 'approved',
                coachId: coachId,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client Approved!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: _greenColor.withOpacity(0.25),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Approve',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    bool smallIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: smallIcon ? 7 : 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: _softPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppTheme.primary.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _darkColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: _mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F2EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('All Clients'),
              _buildFilterOption('Active'),
              _buildFilterOption('At Risk'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'All Clients'
                  ? Icons.groups_rounded
                  : value == 'Active'
                  ? Icons.local_fire_department_rounded
                  : Icons.warning_rounded,
              color: isSelected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : _darkColor,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
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
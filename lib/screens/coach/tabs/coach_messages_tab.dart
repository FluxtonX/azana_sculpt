import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../chat_screen.dart';

class CoachMessagesTab extends StatefulWidget {
  final bool showBackButton;

  const CoachMessagesTab({super.key, this.showBackButton = false});

  @override
  State<CoachMessagesTab> createState() => _CoachMessagesTabState();
}

class _CoachMessagesTabState extends State<CoachMessagesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Color _bgColor = const Color(0xFFF7F2EF);
  final Color _darkColor = const Color(0xFF171412);
  final Color _mutedColor = const Color(0xFF82746E);
  final Color _softPrimary = const Color(0xFFFFF1EC);
  final Color _greenColor = const Color(0xFF2E9B63);
  final Color _redColor = const Color(0xFFFF4B4B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: DatabaseService().getCoachClientsStream(coachId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final clients = snapshot.data ?? [];

            final filteredClients = clients.where((c) {
              final query = _searchQuery.toLowerCase();
              return (c.fullName ?? '').toLowerCase().contains(query) ||
                  c.email.toLowerCase().contains(query);
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      children: [
                        _buildHeroHeader(
                          conversationCount: filteredClients.length,
                          clients: filteredClients,
                        ),
                        const SizedBox(height: 18),
                        _buildSearchBox(),
                        const SizedBox(height: 20),
                        if (filteredClients.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: 'Online Clients',
                            trailing: 'Active now',
                          ),
                          const SizedBox(height: 13),
                          _buildOnlineClients(filteredClients),
                          const SizedBox(height: 20),
                        ],
                        _buildSectionHeader(
                          title: 'Chats',
                          trailing: '${filteredClients.length} conversations',
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                if (filteredClients.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEmptyState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 115),
                    sliver: SliverList.separated(
                      itemCount: filteredClients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 13),
                      itemBuilder: (context, index) {
                        return _buildClientTile(
                          context,
                          filteredClients[index],
                          coachId,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required int conversationCount,
    required List<UserModel> clients,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
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
            color: AppTheme.primary.withOpacity(0.24),
            blurRadius: 50,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -58,
            top: -64,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: _glassIcon(Icons.arrow_back_rounded),
                    )
                  else
                    _glassIcon(Icons.message_rounded),
                  const Spacer(),
                  _glassPill('Coach Inbox'),
                ],
              ),
              const SizedBox(height: 23),
              Text(
                'Messages',
                style: GoogleFonts.outfit(
                  fontSize: 35,
                  height: 1,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Stay connected with your clients and respond to new workout questions.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _heroStat(
                      value: conversationCount.toString(),
                      label: 'Conversations',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UnreadTotalHeroStat(
                      clients: clients,
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

  Widget _glassIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
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
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _heroStat({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: _cardDecoration(radius: 23),
      child: Row(
        children: [
          _smallIcon(Icons.search_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _darkColor,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _mutedColor,
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
                color: _mutedColor.withOpacity(0.65),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String trailing,
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
        Text(
          trailing,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: _mutedColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineClients(List<UserModel> clients) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: clients.take(8).length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final client = clients[index];
          final name = client.fullName ?? client.email.split('@').first;
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

          return SizedBox(
            width: 74,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary.withOpacity(0.22),
                            AppTheme.primary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 2,
                      child: _onlineDot(),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(34),
        decoration: _cardDecoration(radius: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _smallIcon(
              Icons.chat_bubble_outline_rounded,
              size: 76,
              iconSize: 36,
            ),
            const SizedBox(height: 22),
            Text(
              _searchQuery.isEmpty ? 'No conversations yet' : 'No results found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _darkColor,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _searchQuery.isEmpty
                  ? 'Start messaging your clients'
                  : 'Try searching for another name or email',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
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

  Widget _buildClientTile(
      BuildContext context,
      UserModel client,
      String coachId,
      ) {
    final String chatId = '${client.uid}_$coachId';
    final String name = client.fullName ?? 'No Name';
    final String initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : client.email[0].toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUser: client,
              currentUserId: coachId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(radius: 28),
        child: StreamBuilder<int>(
          stream: DatabaseService().getChatUnreadCountStream(chatId, coachId),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 3,
                      child: _onlineDot(),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _darkColor,
                              ),
                            ),
                          ),
                          Text(
                            unreadCount > 0 ? 'New' : 'Open',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _softPrimary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              unreadCount > 0 ? 'Unread Message' : 'Client Chat',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (unreadCount > 0)
                            Container(
                              constraints: const BoxConstraints(minWidth: 25),
                              height: 25,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: _redColor,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unreadCount',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF3EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                    size: 21,
                  ),
                ),
              ],
            );
          },
        ),
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

  Widget _smallIcon(
      IconData icon, {
        double size = 36,
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

class _UnreadTotalHeroStat extends StatelessWidget {
  final List<UserModel> clients;

  const _UnreadTotalHeroStat({
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';

    if (clients.isEmpty) {
      return _buildBox('0', 'Unread Messages');
    }

    return FutureBuilder<List<int>>(
      future: Future.wait(
        clients.map((client) {
          final chatId = '${client.uid}_$coachId';
          return DatabaseService()
              .getChatUnreadCountStream(chatId, coachId)
              .first;
        }),
      ),
      builder: (context, snapshot) {
        final totalUnread = (snapshot.data ?? []).fold<int>(
          0,
              (sum, count) => sum + count,
        );

        return _buildBox(totalUnread.toString(), 'Unread Messages');
      },
    );
  }

  Widget _buildBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }
}


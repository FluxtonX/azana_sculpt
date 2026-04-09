import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.textDark),
                      ),
                    ),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSearchBox(),
              const SizedBox(height: 24),
              StreamBuilder<List<UserModel>>(
                stream: DatabaseService().getCoachClientsStream(coachId),
                builder: (context, snapshot) {
                  final clients = snapshot.data ?? [];
                  final filteredClients = clients.where((c) {
                    final query = _searchQuery.toLowerCase();
                    return (c.fullName ?? '').toLowerCase().contains(query) ||
                        c.email.toLowerCase().contains(query);
                  }).toList();

                  return Text(
                    '${filteredClients.length} conversations',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
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

                    if (filteredClients.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      itemCount: filteredClients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildClientTile(context, filteredClients[index], coachId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: AppTheme.textLight, size: 20),
          hintText: 'Search conversations...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.textLight.withOpacity(0.5),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No conversations yet' : 'No results found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Start messaging your clients'
                  : 'Try searching for another name or email',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientTile(BuildContext context, UserModel client, String coachId) {
    // Unique chat ID is a combination of client and coach IDs
    final String chatId = '${client.uid}_$coachId';

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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider, width: 0.8),
        ),
        child: StreamBuilder<int>(
          stream: DatabaseService().getChatUnreadCountStream(chatId, coachId),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            
            return Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    client.fullName != null && client.fullName!.isNotEmpty
                        ? client.fullName![0].toUpperCase()
                        : client.email[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.fullName ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textLight.withOpacity(0.5),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}

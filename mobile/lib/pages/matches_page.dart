import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/matching_service.dart';
import '../models/match.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final MatchingService _matchingService = MatchingService.instance;
  final ProfileService _profileService = ProfileService.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Match>>(
        future: _matchingService.getUserMatches(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No matches yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Walk around campus to find students with shared interests!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _MatchCard(match: match);
            },
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final Match match;

  const _MatchCard({required this.match});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final otherUserId = widget.match.getOtherParticipant(user.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<UserProfile?>(
        future: otherUserId != null 
            ? ProfileService.instance.getProfile(otherUserId)
            : Future.value(null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final otherUser = snapshot.data;
          if (otherUser == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('User not found'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: otherUser.photoUrl != null
                          ? NetworkImage(otherUser.photoUrl!)
                          : null,
                      child: otherUser.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherUser.displayName ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (otherUser.classYear != null)
                            Text(
                              'Class of ${otherUser.classYear}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _MatchStatusChip(status: widget.match.status),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Shared interests
                if (widget.match.sharedInterests.isNotEmpty) ...[
                  const Text(
                    'Shared Interests:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.match.sharedInterests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Match time
                Text(
                  'Matched ${_formatTime(widget.match.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    if (widget.match.isPending) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleWave(context, true),
                          icon: const Icon(Icons.waving_hand, size: 18),
                          label: const Text('Wave'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleWave(context, false),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Pass'),
                        ),
                      ),
                    ] else if (widget.match.isMutual) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openChat(context),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Start Chat'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleWave(BuildContext context, bool waved) async {
    try {
      await MatchingService.instance.updateMatchStatus(
        widget.match.id,
        waved ? MatchStatus.mutual : MatchStatus.declined,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(waved ? 'Waved! 👋' : 'Passed'),
            backgroundColor: waved ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openChat(BuildContext context) {
    // Navigate to chat page
    // This would be implemented when the chat page is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat feature coming soon!'),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _MatchStatusChip extends StatelessWidget {
  final MatchStatus status;

  const _MatchStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case MatchStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case MatchStatus.mutual:
        color = Colors.green;
        text = 'Mutual';
        break;
      case MatchStatus.declined:
        color = Colors.red;
        text = 'Declined';
        break;
      case MatchStatus.expired:
        color = Colors.grey;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

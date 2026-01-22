import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pocketbase/pocketbase.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/pocketbase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<RecordModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final pb = context.read<PocketBaseService>().client;
      // Fetch all users, sorted by points (descending)
      final records = await pb.collection('users').getFullList(
        sort: '-points',
      );
      
      print('Loaded ${records.length} users for leaderboard');
      
      if (mounted) {
        setState(() {
          _users = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Optionally show a snackbar or store error to display
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LEADERBOARD'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CyberVibrantTheme.darkBase,
                  Color(0xFF1E1B4B),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: CyberVibrantTheme.electricTeal))
                : _users.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.group_off, size: 64, color: CyberVibrantTheme.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'No crew members found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                               onPressed: _loadLeaderboard,
                               child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final points = user.getIntValue('points');
                      final missions = user.getIntValue('missions_completed');
                      final name = user.getStringValue('name').isNotEmpty 
                          ? user.getStringValue('name') 
                          : user.getStringValue('username');
                      final avatarUrl = user.getStringValue('avatar_url');
                      final rank = index + 1;
                      
                      // Trophy colors for top 3
                      Color? rankColor;
                      if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
                      else if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
                      else if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze
                      else rankColor = CyberVibrantTheme.textMuted;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CyberVibrantTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: rank <= 3 
                              ? Border.all(color: rankColor.withOpacity(0.5), width: 1)
                              : null,
                          boxShadow: rank == 1 ? [
                            BoxShadow(
                              color: rankColor!.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            // Rank
                            SizedBox(
                              width: 30,
                              child: Text(
                                '#$rank',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: rankColor,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: rank <= 3 ? rankColor! : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: CyberVibrantTheme.darkSurface,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Name & Missions
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$missions missions',
                                    style: const TextStyle(
                                      color: CyberVibrantTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Points
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: CyberVibrantTheme.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bolt, color: CyberVibrantTheme.electricTeal, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$points',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: CyberVibrantTheme.electricTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: (50 * index).ms).fadeIn().slideX();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

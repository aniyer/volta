import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/auth_service.dart';
import '../services/pocketbase_service.dart';
import '../services/missions_service.dart';
import 'package:pocketbase/pocketbase.dart';

/// Parent review queue screen
class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  late MissionsService _missionsService;
  late ConfettiController _confettiController;
  
  List<RecordModel> _pendingReviews = [];
  bool _isLoading = true;

  String _getSafeInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

   Map<String, String> _getAuthHeaders() {
    final token = context.read<PocketBaseService>().authStore.token;
    return token.isNotEmpty ? {'Authorization': token} : {};
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingReviews();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingReviews() async {
    _missionsService = MissionsService(context.read<PocketBaseService>());
    final auth = context.read<AuthService>();
    
    print('DEBUG REVIEW: Loading pending reviews for user: ${auth.user?.getStringValue('email')} (${auth.user?.id})');
    print('DEBUG REVIEW: Role: ${auth.user?.getStringValue('role')}');
    
    try {
      final reviews = await _missionsService.getPendingReviews();
      print('DEBUG REVIEW: Found ${reviews.length} reviews');
      
      if (mounted) {
        setState(() {
          _pendingReviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG REVIEW: Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reviews: $e'),
            backgroundColor: CyberVibrantTheme.magmaOrange,
          ),
        );
      }
    }
  }

  Future<void> _approveReview(RecordModel review) async {
    // Extract data safely
    final userList = review.expand['user_id'];
    final childUserId = (userList != null && userList.isNotEmpty) ? userList.first.id : '';
    
    final missionList = review.expand['mission_id'];
    final points = (missionList != null && missionList.isNotEmpty) 
        ? missionList.first.getIntValue('base_points') 
        : 0;
        
    if (childUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not find user to award points to')),
      );
      return;
    }
    
    final success = await _missionsService.approveMission(review.id, childUserId, points);
    
    if (success) {
      _confettiController.play();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mission approved! $points Volts awarded 🎉'),
          backgroundColor: CyberVibrantTheme.electricTeal,
        ),
      );
      
      _loadPendingReviews();
    }
  }

  Future<void> _rejectReview(RecordModel review) async {
    final success = await _missionsService.rejectMission(review.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission sent back for re-do'),
          backgroundColor: CyberVibrantTheme.magmaOrange,
        ),
      );
      
      _loadPendingReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REVIEW QUEUE'),
      ),
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingReviews.isEmpty
                  ? _buildEmptyState()
                  : _buildReviewList(),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                CyberVibrantTheme.electricTeal,
                CyberVibrantTheme.neonViolet,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberVibrantTheme.darkCard,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: CyberVibrantTheme.electricTeal,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No missions waiting for review',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return RefreshIndicator(
      onRefresh: _loadPendingReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReviews.length,
        itemBuilder: (context, index) {
          try {
            final review = _pendingReviews[index];
            
            // Safe expansion access
            final userList = review.expand['user_id'];
            final userData = (userList != null && userList.isNotEmpty) ? userList.first : null;
            
            final missionList = review.expand['mission_id'];
            final missionData = (missionList != null && missionList.isNotEmpty) ? missionList.first : null;
            
            final photoUrl = context.read<PocketBaseService>()
                .client
                .files
                .getUrl(review, review.getStringValue('photo_proof'))
                .toString();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: CyberVibrantTheme.glowingCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Photo proof
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      color: CyberVibrantTheme.darkSurface,
                      child: review.getStringValue('photo_proof').isNotEmpty
                          ? Image.network(
                              photoUrl,
                              headers: _getAuthHeaders(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('IMAGE LOAD ERROR: $error');
                                return const Center(
                                  child: Icon(Icons.broken_image, color: CyberVibrantTheme.magmaOrange),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: CyberVibrantTheme.textMuted,
                              ),
                            ),
                    ),
                  ),
                ),
                
                // Info & actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.3),
                            backgroundImage: (userData?.getStringValue('avatar_url')?.isNotEmpty ?? false)
                                ? NetworkImage(userData!.getStringValue('avatar_url'))
                                : null,
                            child: (userData?.getStringValue('avatar_url')?.isEmpty ?? true)
                                ? Text(
                                    _getSafeInitial(userData?.getStringValue('name') ?? userData?.getStringValue('username')),
                                    style: const TextStyle(
                                      color: CyberVibrantTheme.neonViolet,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (userData?.getStringValue('name').isNotEmpty ?? false) 
                                      ? userData!.getStringValue('name') 
                                      : (userData?.getStringValue('username') ?? 'Unknown'),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  missionData?.getStringValue('title') ?? 'Mission',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.electricTeal, 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${missionData?.getIntValue('base_points') ?? 0} Volts',
                              style: const TextStyle(
                                color: CyberVibrantTheme.electricTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rejectReview(review),
                              icon: const Icon(Icons.refresh),
                              label: const Text('REDO'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CyberVibrantTheme.magmaOrange,
                                side: const BorderSide(
                                  color: CyberVibrantTheme.magmaOrange,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveReview(review),
                              icon: const Icon(Icons.check),
                              label: const Text('APPROVE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CyberVibrantTheme.electricTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          } catch (e, stack) {
            print('ITEM BUILD ERROR: $e');
            print(stack);
            return Card(
              color: Colors.red.withOpacity(0.2),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error rendering item: $e', style: const TextStyle(color: Colors.white)),
              ),
            );
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/auth_service.dart';
import '../services/pocketbase_service.dart';
import '../services/missions_service.dart';
import '../widgets/volta_wheel.dart';

/// Main home screen with the Volta Wheel
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MissionsService _missionsService;
  late ConfettiController _confettiController;
  
  List<WheelMission> _missions = [];
  bool _isLoading = true;
  WheelMission? _selectedMission;
  int _currentIndex = 0;
  int? _previousPoints; // Track points for celebration

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3), // Increased duration
    );
    
    // Initialize previous points
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _previousPoints = context.read<AuthService>().points;
        _loadMissions();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    _missionsService = MissionsService(context.read<PocketBaseService>());
    
    try {
      final records = await _missionsService.getActiveMissions();
      
      if (mounted) {
        setState(() {
          _missions = records.map((r) {
            return WheelMission(
              id: r.id,
              title: r.getStringValue('title'),
              icon: r.getStringValue('icon'),
              points: r.getIntValue('base_points'),
              color: CyberVibrantTheme.neonViolet,
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading missions: $e');
      if (mounted) {
        setState(() {
          _missions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onMissionSelected(WheelMission mission) {
    setState(() {
      _selectedMission = mission;
    });
    
    _confettiController.play();
    
    // Show mission dialog
    _showMissionDialog(mission);
  }

  void _showMissionDialog(WheelMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberVibrantTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.5),
            width: 2,
          ),
        ),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: CyberVibrantTheme.primaryGradient,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Mission',
              style: CyberVibrantTheme.neonText(fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mission.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.electricTeal, 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: CyberVibrantTheme.electricTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${mission.points} Volts',
                    style: const TextStyle(
                      color: CyberVibrantTheme.electricTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LATER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/submit',
                arguments: mission,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberVibrantTheme.magmaOrange,
            ),
            child: const Text('DO IT NOW'),
          ),
        ],
      ),
    );
  }

  void _showCelebrationOverlay(int pointsEarned) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54, 
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: CyberVibrantTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CyberVibrantTheme.electricTeal,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Colors.yellowAccent, size: 64),
                const SizedBox(height: 16),
                Text(
                  'MISSION APPROVED!',
                  style: CyberVibrantTheme.neonText(
                    fontSize: 24, 
                    color: CyberVibrantTheme.electricTeal
                  ).copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '+$pointsEarned Volts',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }); 
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    
    // Check for point increase (Celebration)
    if (_previousPoints != null && auth.points > _previousPoints!) {
      // Trigger celebration
      final diff = auth.points - _previousPoints!;
      _previousPoints = auth.points; // Update immediately to prevent loops
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
        _showCelebrationOverlay(diff); // Define this method
      });
    } else if (_previousPoints == null) {
      _previousPoints = auth.points;
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT: Hamburger Menu & Greeting
                      Row(
                        children: [
                          // Hamburger Menu
                          Theme(
                            data: Theme.of(context).copyWith(
                              cardColor: CyberVibrantTheme.darkCard,
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) {
                                if (value == 'logout') {
                                  context.read<AuthService>().logout();
                                  Navigator.pushReplacementNamed(context, '/login');
                                } else if (value == 'profile') {
                                  Navigator.pushNamed(context, '/profile');
                                }
                              },
                              itemBuilder: (context) => [
                                // Header item (non-selectable or just disabled)
                                PopupMenuItem(
                                  enabled: false,
                                  child: Text('MENU', style: TextStyle(
                                    color: CyberVibrantTheme.textMuted, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  )),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: CyberVibrantTheme.neonViolet, size: 20),
                                      SizedBox(width: 12),
                                      Text('Profile', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: CyberVibrantTheme.magmaOrange, size: 20),
                                      SizedBox(width: 12),
                                      Text('Logout', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Greeting
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                              ),
                              Text(
                                auth.isParent ? 'Parent' : 'Seeker',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // RIGHT: Points & Leaderboard
                      Row(
                        children: [
                           // Points badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: CyberVibrantTheme.successGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.electricTeal, 0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${auth.points}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                            icon: const Icon(Icons.emoji_events, color: CyberVibrantTheme.neonViolet),
                             style: IconButton.styleFrom(
                              backgroundColor: CyberVibrantTheme.darkCard,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // The Wheel
                Expanded(
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : VoltaWheel(
                            missions: _missions,
                            onMissionSelected: _onMissionSelected,
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                CyberVibrantTheme.neonViolet,
                CyberVibrantTheme.electricTeal,
                CyberVibrantTheme.magmaOrange,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
      
      // Bottom navigation
      bottomNavigationBar: NavigationBar(
        backgroundColor: CyberVibrantTheme.darkSurface,
        indicatorColor: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.3),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 1:
              Navigator.pushNamed(context, auth.isParent ? '/review' : '/submit');
              break;
            case 2:
              Navigator.pushNamed(context, '/bazaar');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(auth.isParent ? Icons.fact_check_outlined : Icons.camera_alt_outlined),
            selectedIcon: Icon(auth.isParent ? Icons.fact_check : Icons.camera_alt),
            label: auth.isParent ? 'Review' : 'Submit',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Bazaar',
          ),
        ],
      ),
    );
  }


}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/auth_service.dart';
import '../services/pocketbase_service.dart';
import '../services/missions_service.dart';
import '../widgets/volta_wheel.dart';
import '../utils/icon_mapper.dart';
import 'package:pocketbase/pocketbase.dart';

/// Main home screen with the Volta Wheel
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late MissionsService _missionsService;
  late ConfettiController _confettiController;
  late AnimationController _redoPulseController;
  
  List<WheelMission> _missions = [];
  bool _isLoading = true;
  WheelMission? _selectedMission;
  int _currentIndex = 0;
  int? _previousPoints; // Track points for celebration
  List<RecordModel> _redoMissions = []; // Persistent redo list

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3), // Increased duration
    );
    _redoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 1.0,
      upperBound: 1.4,
    );
    
    // Initialize previous points
    // Initialize previous points
    _loadLastCelebratedPoints();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMissions();
        _checkForRedoMissions();
        _subscribeToRedoUpdates();
      }
    });
  }

  void _subscribeToRedoUpdates() {
    final auth = context.read<AuthService>();
    if (auth.isParent || auth.user == null) return;

    context.read<PocketBaseService>().client.collection('history').subscribe(
      '*', 
      (e) async {
        if (e.action == 'create' || e.action == 'update') {
          final record = e.record;
          if (record != null && record.getStringValue('status') == 'redo' && record.getStringValue('user_id') == auth.user!.id) {
            
            // Re-fetch strictly to ensure full expansion and data consistency
            await _checkForRedoMissions();
            
            // Trigger visual pulse for new updates
            if (mounted) {
              _redoPulseController.forward().then((_) => _redoPulseController.reverse());
            }
          }
        }
      },
      filter: 'user_id = "${auth.user!.id}"', // Server-side filter if supported, otherwise client check above handles it safely
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _redoPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    _missionsService = MissionsService(context.read<PocketBaseService>());
    
    try {
      final records = await _missionsService.getActiveMissions();
      
      if (mounted) {
        setState(() {
          _missions = List.generate(records.length, (index) {
            final r = records[index];
            return WheelMission(
              id: r.id,
              title: r.getStringValue('title'),
              icon: r.getStringValue('icon'),
              description: r.getStringValue('description'),
              points: r.getIntValue('base_points'),
              // Cycle through available segment colors
              color: VoltaWheel.segmentColors[index % VoltaWheel.segmentColors.length],
            );
          });
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

  Future<void> _checkForRedoMissions() async {
    final auth = context.read<AuthService>();
    if (auth.isParent || auth.user == null) return; // Only for kids
    
    _missionsService = MissionsService(context.read<PocketBaseService>());
    final redoMissions = await _missionsService.getRedoMissions(auth.user!.id);
    
    if (mounted) {
      setState(() {
        _redoMissions = redoMissions;
      });
      
      if (_redoMissions.isNotEmpty) {
      if (_redoMissions.isNotEmpty) {
        // Just pulse on load if items exist
        _redoPulseController.forward().then((_) => _redoPulseController.reverse());
      }
      }
    }
  }

  void _showRedoDialog(List<dynamic> redoMissions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CyberVibrantTheme.darkCard,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: CyberVibrantTheme.magmaOrange, size: 28),
            const SizedBox(width: 12),
            Text('Mission Redo!', style: CyberVibrantTheme.neonText(color: CyberVibrantTheme.magmaOrange)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Some missions were sent back for a re-do. Needs better proof!',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ...redoMissions.map((record) {
              final missionList = record.expand['mission_id'] ?? [];
              final title = missionList.isNotEmpty ? missionList.first.getStringValue('title') : 'Unknown Mission';
              final points = missionList.isNotEmpty ? missionList.first.getIntValue('base_points') : 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.refresh, color: CyberVibrantTheme.magmaOrange),
                  ),
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('+$points Volts waiting...', style: const TextStyle(color: CyberVibrantTheme.electricTeal)),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      print('REDO DEBUG: Button clicked for record ${record.id}');
                      
                      try {
                        // 1. Pop the dialog first
                        Navigator.of(dialogContext).pop(); 
                        
                        // 2. Validate Data
                        final missionList = record.expand['mission_id'];
                        print('REDO DEBUG: Mission list: $missionList');
                        
                        if (missionList == null || missionList.isEmpty) {
                          throw 'Mission data not found (expand failed)';
                        }
                        
                        final m = missionList.first;
                        print('REDO DEBUG: Found mission: ${m.id}');
                        
                        final wm = WheelMission(
                          id: m.id,
                          title: m.getStringValue('title'),
                          icon: m.getStringValue('icon'),
                          description: m.getStringValue('description'),
                          points: m.getIntValue('base_points'),
                          color: CyberVibrantTheme.neonViolet,
                        );
                        
                        // 3. Navigate
                        print('REDO DEBUG: Navigating to submit screen...');
                        if (!context.mounted) {
                           print('REDO DEBUG: Context not mounted, cannot navigate');
                           return;
                        }
                        
                        await Navigator.pushNamed(
                          context,
                          '/submit',
                          arguments: {
                            'mission': wm,
                            'historyId': record.id,
                          },
                        );
                        print('REDO DEBUG: Navigation complete');
                        
                      } catch (e, stack) {
                        print('REDO ERROR: $e');
                        print(stack);
                        
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Error'),
                              content: Text('Failed to start redo:\n$e'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                )
                              ],
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberVibrantTheme.magmaOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('REDO'),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LATER', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLastCelebratedPoints() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    final stored = prefs.getInt('last_celebrated_points');
    if (stored != null) {
      setState(() {
        _previousPoints = stored;
      });
    } else {
      // First run, set to current points
      setState(() {
        _previousPoints = context.read<AuthService>().points;
      });
      _updateLastCelebratedPoints(_previousPoints ?? 0);
    }
  }

  Future<void> _updateLastCelebratedPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_celebrated_points', points);
  }

  void _onMissionSelected(WheelMission mission) {
    setState(() {
      _selectedMission = mission;
    });
    
    // _confettiController.play(); // Removed confetti on spinner stop
    
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
              child: Icon(
                IconMapper.getIcon(mission.icon),
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
            const SizedBox(height: 8),
            if (mission.description.isNotEmpty)
              Text(
                mission.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CyberVibrantTheme.textSecondary,
                ),
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
        _updateLastCelebratedPoints(auth.points);
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
                          /// REDO INBOX ICON (Badged) - Moved here
                          if (_redoMissions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ScaleTransition(
                                scale: _redoPulseController,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showRedoDialog(_redoMissions),
                                      icon: const Icon(Icons.mark_email_unread_rounded, color: CyberVibrantTheme.magmaOrange, size: 28),
                                      style: IconButton.styleFrom(
                                        backgroundColor: CyberVibrantTheme.darkCard,
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '${_redoMissions.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

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
              particleDrag: 0.04,
              emissionFrequency: 0.08,
              numberOfParticles: 40,
              gravity: 0.3,
              minBlastForce: 15,
              maxBlastForce: 30,
              createParticlePath: drawLightning,
              colors: const [
                Colors.yellowAccent,
                Colors.cyanAccent,
                Colors.white,
                Color(0xFF00FF00),
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

  Path drawLightning(Size size) {
    double w = size.width;
    double h = size.height;
    Path path = Path();
    path.moveTo(w * 0.4, 0);
    path.lineTo(w, h * 0.3);
    path.lineTo(w * 0.6, h * 0.3); // Cut back
    path.lineTo(w * 0.9, h);
    path.lineTo(0, h * 0.4);
    path.lineTo(w * 0.3, h * 0.4); // Cut forward
    path.close();
    return path;
  }
}

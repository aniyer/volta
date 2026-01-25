import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/auth_service.dart';
import '../services/pocketbase_service.dart';
import '../services/missions_service.dart';
import '../widgets/volta_wheel.dart';

/// Screen for submitting mission proof
class MissionSubmitScreen extends StatefulWidget {
  const MissionSubmitScreen({super.key});

  @override
  State<MissionSubmitScreen> createState() => _MissionSubmitScreenState();
}

class _MissionSubmitScreenState extends State<MissionSubmitScreen> {
  final ImagePicker _picker = ImagePicker();
  late MissionsService _missionsService;
  
  List<WheelMission> _availableMissions = [];
  bool _isLoadingMissions = false;
  XFile? _photo;
  bool _isSubmitting = false;
  WheelMission? _mission;
  final FocusNode _dropdownFocusNode = FocusNode();

  @override
  void dispose() {
    _dropdownFocusNode.dispose();
    super.dispose();
  }

  String? _historyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _missionsService = MissionsService(context.read<PocketBaseService>());
    
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WheelMission) {
      setState(() => _mission = args);
    } else if (args is Map) {
      // Handle redo case
      if (args['mission'] is WheelMission) {
        setState(() {
          _mission = args['mission'];
          _historyId = args['historyId'];
        });
      }
    } else if (_mission == null) {
      _loadMissions();
    }
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoadingMissions = true);
    try {
      final records = await _missionsService.getActiveMissions();
      if (mounted) {
        setState(() {
          _availableMissions = List.generate(records.length, (index) {
            final r = records[index];
            return WheelMission(
              id: r.id,
              title: r.getStringValue('title'),
              icon: r.getStringValue('icon'),
              description: r.getStringValue('description'),
              points: r.getIntValue('base_points'),
              color: VoltaWheel.segmentColors[index % VoltaWheel.segmentColors.length],
            );
          });
          _isLoadingMissions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading missions: $e');
      if (mounted) setState(() => _isLoadingMissions = false);
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );
    
    if (photo != null) {
      setState(() {
        _photo = photo;
      });
    }
  }

  Future<void> _submitMission() async {
    if (_photo == null || _mission == null) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final auth = context.read<AuthService>();
      final missionsService = MissionsService(context.read<PocketBaseService>());
      
      final photoBytes = await _photo!.readAsBytes();
      
      bool? success;
      
      if (_historyId != null) {
        // RESUBMIT (REDO)
        success = await missionsService.resubmitMission(
          historyId: _historyId!,
          photoBytes: photoBytes,
          fileName: 'proof_redo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else {
        // NEW SUBMISSION
        final result = await missionsService.submitMission(
          missionId: _mission!.id,
          userId: auth.user!.id,
          photoBytes: photoBytes,
          fileName: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        success = result != null;
      }
      
      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_historyId != null ? 'Mission re-submitted! 🚀' : 'Mission submitted for review! 🎉'),
            backgroundColor: CyberVibrantTheme.electricTeal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stack) {
      debugPrint('SUBMISSION ERROR: $e\n$stack');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Failed', style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(
              child: SelectableText('Error: $e'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SUBMIT PROOF'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mission Selector or Info
              if (_mission != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: CyberVibrantTheme.glowingCard(),
                  child: Column(
                    children: [
                      Text(
                        'Current Mission',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mission!.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
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
                          '+${_mission!.points} Volts',
                          style: const TextStyle(
                            color: CyberVibrantTheme.electricTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select a Mission',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingMissions)
                      const Center(child: CircularProgressIndicator())
                    else if (_availableMissions.isEmpty)
                      const Center(child: Text('No active missions found.'))
                    else
                      Builder(
                        builder: (context) {
                          return GestureDetector(
                            onTap: () {
                              final RenderBox button = context.findRenderObject() as RenderBox;
                              final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                              
                              final RelativeRect position = RelativeRect.fromRect(
                                Rect.fromPoints(
                                  button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
                                  button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );

                              showMenu<WheelMission>(
                                context: context,
                                position: position,
                                elevation: 8,
                                color: CyberVibrantTheme.darkCard,
                                constraints: BoxConstraints.tightFor(width: button.size.width),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.3),
                                  ),
                                ),
                                items: _availableMissions.map((m) {
                                  return PopupMenuItem(
                                    value: m,
                                    child: Text(m.title, style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                              ).then((value) {
                                if (value != null) {
                                  setState(() => _mission = value);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: CyberVibrantTheme.darkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _mission?.title ?? 'Choose what you did...',
                                    style: TextStyle(
                                      color: _mission != null ? Colors.white : CyberVibrantTheme.textMuted,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: CyberVibrantTheme.textSecondary),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              // Photo area
              Expanded(
                child: GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CyberVibrantTheme.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _photo != null
                            ? CyberVibrantTheme.electricTeal
                            : CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.3),
                        width: 2,
                      ),
                    ),
                    child: _photo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              _photo!.path,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: CyberVibrantTheme.neonViolet,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tap to take proof photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CyberVibrantTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              ElevatedButton(
                onPressed: _photo != null && !_isSubmitting ? _submitMission : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberVibrantTheme.magmaOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SUBMIT FOR REVIEW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
